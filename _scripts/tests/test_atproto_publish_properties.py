"""
Model-based property tests for atproto/publish.py sync_documents.

Hypothesis drives random sequences of local edits, remote edits, syncs,
dry runs, and injected PDS write failures against an in-memory fake PDS.
After every step the fake's state is compared with a plain-Python model.

Profiles (selected with ATPROTO_HYPOTHESIS_PROFILE):
  quick      default; 100 examples, derandomized so runs are reproducible
  discovery  1,000 examples, random seeds, for finding rare sequences

The test is the only consumer of Hypothesis in this suite, so the profiles
are registered here rather than in a shared conftest.
"""

import copy
import io
import json
import os
import re
import tempfile
from collections import Counter
from contextlib import redirect_stderr, redirect_stdout
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pytest
from hypothesis import event, settings
from hypothesis import strategies as st
from hypothesis.stateful import (
    RuleBasedStateMachine,
    precondition,
    rule,
)
from publish import MANAGED_FIELDS, AtprotoClient, PublishError, sync_documents
from test_atproto_publish import (
    LOGIN_RESPONSE,
    PUB_RECORD_RESPONSE,
    PUB_URI,
    TEST_CONFIG,
    MockResponse,
)

# ---------------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------------

settings.register_profile("quick", max_examples=100, derandomize=True, deadline=None)
settings.register_profile("discovery", max_examples=1000, deadline=None)
PROFILE = os.environ.get("ATPROTO_HYPOTHESIS_PROFILE", "quick")
settings.load_profile(PROFILE)

# ---------------------------------------------------------------------------
# Constants and the document pool
# ---------------------------------------------------------------------------

DID = LOGIN_RESPONSE["did"]
TOKEN = LOGIN_RESPONSE["accessJwt"]
PDS_URL = "https://bsky.social"
OTHER_PUB = "at://did:plc:test123/site.standard.publication/rkeyother"
PAGE_SIZE = 2  # small pages so listRecords pagination runs


@dataclass(frozen=True)
class Doc:
    subdir: str  # "posts" or "books"
    filename: str
    fields: dict[str, Any]  # record fields the filename/front matter fix


# Four paths: two posts, two books. Small enough that operations collide.
POOL: dict[str, Doc] = {
    "/blog/alpha/": Doc("posts", "2025-01-01-alpha.md", {"publishedAt": "2025-01-01T00:00:00Z"}),
    "/blog/beta/": Doc("posts", "2025-01-02-beta.md", {"publishedAt": "2025-01-02T00:00:00Z"}),
    "/books/gamma/": Doc(
        "books",
        "gamma.md",
        {"publishedAt": "2024-06-01T00:00:00Z", "tags": ["book-reviews"]},
    ),
    "/books/delta/": Doc(
        "books",
        "delta.md",
        {"publishedAt": "2024-06-01T00:00:00Z", "tags": ["book-reviews"]},
    ),
}
PATHS = sorted(POOL)
# sync_documents reads posts before books, and each directory in sorted
# filename order (Path sort). Write order follows this, so it fixes which
# write is the k-th one.
WRITE_ORDER = sorted(POOL, key=lambda p: (POOL[p].subdir != "posts", POOL[p].filename))
TITLES = ["First", "Second", "Third"]
REMOTE_ONLY_FIELDS = ["bskyPostRef", "comments"]
REMOTE_ONLY_VALUES = ["v1", "v2", "v3"]

INTERACTIONS = [
    "update with remote-only field",
    "unchanged resync",
    "orphan",
    "failure at write 1",
    "failure at later write",
    "recovery after failure",
    "dry run",
]
COUNTS: Counter[str] = Counter()


def _count(label: str) -> None:
    event(label)
    COUNTS[label] += 1


def expected_record(path: str, title: str) -> dict[str, Any]:
    doc = POOL[path]
    return {
        "$type": "site.standard.document",
        "site": PUB_URI,
        "path": path,
        "title": title,
        **doc.fields,
    }


def _managed(record: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in record.items() if k in MANAGED_FIELDS}


def _remote_only(record: dict[str, Any]) -> bool:
    return any(k not in MANAGED_FIELDS for k in record)


def _strip_updated_at(record: dict[str, Any]) -> dict[str, Any]:
    # updatedAt is set from the wall clock; the model checks only that it exists.
    return {k: v for k, v in record.items() if k != "updatedAt"}


# ---------------------------------------------------------------------------
# Fake PDS
# ---------------------------------------------------------------------------


class FakePds:
    """
    In-memory PDS speaking the XRPC calls sync_documents uses. Writes are
    logged as attempts, including a write the fake fails on purpose.
    """

    def __init__(self) -> None:
        self.records: dict[str, dict[str, Any]] = {}  # rkey -> {collection, value, cid}
        self.log: list[tuple[str, str]] = []  # (kind, path) per write attempt
        self._fail_at: int | None = None
        self._writes = 0
        self._rkeys = 0
        self._cids = 0

    # -- control --------------------------------------------------------

    def begin_sync(self, fail_at: int | None = None) -> None:
        """Reset the per-sync write log; fail_at makes the k-th write return 500."""
        self.log = []
        self._writes = 0
        self._fail_at = fail_at

    # -- helpers used by the state machine -----------------------------

    def _new_cid(self) -> str:
        self._cids += 1
        return f"cid{self._cids}"

    def _new_rkey(self) -> str:
        self._rkeys += 1
        return f"rk{self._rkeys:03d}"

    def _doc_items(self, site: str | None) -> list[tuple[str, dict[str, Any]]]:
        """Document records whose site matches, or all others when site is None."""
        items = []
        for rkey, entry in self.records.items():
            if entry["collection"] != "site.standard.document":
                continue
            if site is None or entry["value"].get("site") == site:
                items.append((rkey, entry))
        return items

    def rkey_for(self, path: str) -> str:
        matches = [rkey for rkey, e in self._doc_items(PUB_URI) if e["value"]["path"] == path]
        assert len(matches) == 1, f"expected one remote record for {path}, found {matches}"
        return matches[0]

    def documents(self) -> dict[str, dict[str, Any]]:
        """Records of this publication, keyed by path."""
        out: dict[str, dict[str, Any]] = {}
        for _rkey, entry in self._doc_items(PUB_URI):
            path = entry["value"]["path"]
            assert path not in out, f"duplicate remote record for {path}"
            out[path] = copy.deepcopy(entry["value"])
        return out

    def foreign(self) -> dict[str, dict[str, Any]]:
        return {
            rkey: copy.deepcopy(entry["value"])
            for rkey, entry in self._doc_items(None)
            if entry["value"].get("site") != PUB_URI
        }

    def add_remote_field(self, path: str, name: str, value: Any) -> None:
        entry = self.records[self.rkey_for(path)]
        entry["value"][name] = value
        entry["cid"] = self._new_cid()

    def add_foreign(self, value: dict[str, Any]) -> str:
        rkey = self._new_rkey()
        self.records[rkey] = {
            "collection": "site.standard.document",
            "value": copy.deepcopy(value),
            "cid": self._new_cid(),
        }
        return rkey

    def snapshot(self) -> dict[str, Any]:
        return copy.deepcopy(self.records)

    # -- transport ------------------------------------------------------

    def _fail_now(self) -> bool:
        self._writes += 1
        return self._fail_at == self._writes

    def post(
        self,
        url: str,
        json: dict | None = None,
        headers: dict | None = None,
        timeout: float | None = None,
    ) -> MockResponse:
        if url.endswith("com.atproto.server.createSession"):
            return MockResponse(LOGIN_RESPONSE)
        if (headers or {}).get("Authorization") != f"Bearer {TOKEN}":
            return MockResponse({"error": "AuthRequired"}, 401)

        if url.endswith("com.atproto.repo.createRecord"):
            record = json["record"]
            self.log.append(("create", record["path"]))
            if self._fail_now():
                return MockResponse({"error": "InternalServerError"}, 500)
            rkey = self._new_rkey()
            self.records[rkey] = {
                "collection": json["collection"],
                "value": copy.deepcopy(record),
                "cid": self._new_cid(),
            }
            return MockResponse({"uri": f"at://{DID}/{json['collection']}/{rkey}"})

        if url.endswith("com.atproto.repo.putRecord"):
            record = json["record"]
            self.log.append(("update", record["path"]))
            if self._fail_now():
                return MockResponse({"error": "InternalServerError"}, 500)
            entry = self.records[json["rkey"]]
            if json.get("swapRecord") != entry["cid"]:
                return MockResponse({"error": "InvalidSwap"}, 400)
            entry["value"] = copy.deepcopy(record)
            entry["cid"] = self._new_cid()
            return MockResponse({})

        return MockResponse({"error": "UnknownMethod"}, 404)

    def get(
        self,
        url: str,
        params: dict | None = None,
        headers: dict | None = None,
        timeout: float | None = None,
    ) -> MockResponse:
        assert params is not None
        if url.endswith("com.atproto.repo.getRecord"):
            if params["collection"] == "site.standard.publication":
                return MockResponse(PUB_RECORD_RESPONSE)
            entry = self.records.get(params["rkey"])
            if entry is None:
                return MockResponse({"error": "RecordNotFound"}, 400)
            return MockResponse({"uri": "", "cid": entry["cid"], "value": entry["value"]})

        if url.endswith("com.atproto.repo.listRecords"):
            items = [
                (rkey, e)
                for rkey, e in self.records.items()
                if e["collection"] == params["collection"]
            ]
            start = int(params.get("cursor") or 0)
            page = items[start : start + PAGE_SIZE]
            data: dict[str, Any] = {
                "records": [
                    {
                        "uri": f"at://{DID}/{params['collection']}/{rkey}",
                        "cid": e["cid"],
                        "value": copy.deepcopy(e["value"]),
                    }
                    for rkey, e in page
                ]
            }
            if start + PAGE_SIZE < len(items):
                data["cursor"] = str(start + PAGE_SIZE)
            return MockResponse(data)

        return MockResponse({"error": "UnknownMethod"}, 404)


# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------


class PublishSyncMachine(RuleBasedStateMachine):
    """
    Model: self.files (path -> title on disk), self.remote (path -> expected
    remote record without updatedAt), self.foreign (rkey -> record of another
    publication), and the data file bytes. The expected write log for a sync
    is derived from the model, not from the SUT.
    """

    def __init__(self) -> None:
        super().__init__()
        self._tmp = tempfile.TemporaryDirectory()
        root = Path(self._tmp.name)
        self.posts_dir = root / "_posts"
        self.books_dir = root / "_books"
        self.posts_dir.mkdir()
        self.books_dir.mkdir()
        self.data_out = root / "standard_site.json"

        self.fake = FakePds()
        self.client = AtprotoClient(PDS_URL, "handle.bsky.social", "password", _session=self.fake)
        self.read_only_client = AtprotoClient.read_only(PDS_URL, DID, _session=self.fake)

        self.files: dict[str, str] = {}
        self.remote: dict[str, dict[str, Any]] = {}
        self.foreign: dict[str, dict[str, Any]] = {}
        self.pending_recovery = False

    def teardown(self) -> None:
        self._tmp.cleanup()

    # -- filesystem -----------------------------------------------------

    def _file_for(self, path: str) -> Path:
        doc = POOL[path]
        base = self.posts_dir if doc.subdir == "posts" else self.books_dir
        return base / doc.filename

    def _write_file(self, path: str, title: str, body: str) -> None:
        front = f"---\ntitle: {title}\n"
        if POOL[path].subdir == "books":
            front += "date: 2024-06-01\n"
        self._file_for(path).write_text(front + "---\n" + body, encoding="utf-8")

    def _data_bytes(self) -> bytes | None:
        return self.data_out.read_bytes() if self.data_out.exists() else None

    # -- model ----------------------------------------------------------

    def _expected_writes(self) -> list[tuple[str, str]]:
        writes = []
        for path in WRITE_ORDER:
            if path not in self.files:
                continue
            want = expected_record(path, self.files[path])
            if path not in self.remote:
                writes.append(("create", path))
            elif _managed(want) != _managed(self.remote[path]):
                writes.append(("update", path))
        return writes

    def _apply(self, kind: str, path: str) -> None:
        want = expected_record(path, self.files[path])
        if kind == "create":
            self.remote[path] = want
            return
        merged = dict(self.remote[path])
        for key in MANAGED_FIELDS:
            if key in want:
                merged[key] = want[key]
            else:
                merged.pop(key, None)
        self.remote[path] = merged

    def _orphans(self) -> list[str]:
        return sorted(set(self.remote) - set(self.files))

    # -- checks ---------------------------------------------------------

    def _check_remote(self) -> None:
        actual = {p: _strip_updated_at(r) for p, r in self.fake.documents().items()}
        assert actual == self.remote, "remote records diverged from the model"
        for path, rec in self.remote.items():
            for name in rec:
                if name not in MANAGED_FIELDS:
                    assert self.fake.documents()[path][name] == rec[name], (
                        f"remote-only field {name} lost on {path}"
                    )
        assert self.fake.foreign() == self.foreign, "record from another publication changed"

    def _check_summary(self, out: str, writes: list[tuple[str, str]]) -> None:
        m = re.search(
            r"^created=(\d+) updated=(\d+) unchanged=(\d+) orphaned=(\d+)$", out, re.MULTILINE
        )
        assert m, f"no summary line in output: {out!r}"
        created = sum(1 for kind, _ in writes if kind == "create")
        updated = sum(1 for kind, _ in writes if kind == "update")
        got = tuple(int(g) for g in m.groups())
        want = (created, updated, len(self.files) - created - updated, len(self._orphans()))
        assert got == want, f"summary {got} != model {want}"

    def _check_data_file(self) -> None:
        expected = {
            p: f"at://{DID}/site.standard.document/{self.fake.rkey_for(p)}"
            for p in sorted(self.files)
        }
        assert self.data_out.read_text(encoding="utf-8") == json.dumps(expected, indent=2) + "\n"

    def _run_sync(self, client: AtprotoClient, dry_run: bool = False) -> tuple[str, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            sync_documents(
                client,
                self.posts_dir,
                self.data_out,
                PUB_URI,
                TEST_CONFIG,
                books_dir=self.books_dir,
                dry_run=dry_run,
            )
        return out.getvalue(), err.getvalue()

    # -- local operations -----------------------------------------------

    @rule(path=st.sampled_from(PATHS), title=st.sampled_from(TITLES))
    def add_or_edit_doc(self, path: str, title: str) -> None:
        self._write_file(path, title, "Body\n")
        self.files[path] = title

    @precondition(lambda self: bool(self.files))
    @rule(data=st.data())
    def edit_body_only(self, data) -> None:
        # Changes the file but not the record: the title is kept, so no write.
        path = data.draw(st.sampled_from(sorted(self.files)), label="path")
        self._write_file(path, self.files[path], "A different body\n")

    @precondition(lambda self: bool(self.files))
    @rule(data=st.data())
    def delete_doc(self, data) -> None:
        path = data.draw(st.sampled_from(sorted(self.files)), label="path")
        self._file_for(path).unlink()
        del self.files[path]

    # -- remote operations ----------------------------------------------

    @precondition(lambda self: bool(self.remote))
    @rule(
        data=st.data(),
        name=st.sampled_from(REMOTE_ONLY_FIELDS),
        value=st.sampled_from(REMOTE_ONLY_VALUES),
    )
    def add_remote_only_field(self, data, name: str, value: str) -> None:
        path = data.draw(st.sampled_from(sorted(self.remote)), label="path")
        self.fake.add_remote_field(path, name, value)
        self.remote[path][name] = value

    @rule(path=st.sampled_from(PATHS), title=st.sampled_from(TITLES))
    def add_unrelated_record(self, path: str, title: str) -> None:
        value = {
            "$type": "site.standard.document",
            "site": OTHER_PUB,
            "path": path,
            "title": title,
            "publishedAt": "2025-03-01T00:00:00Z",
        }
        self.foreign[self.fake.add_foreign(value)] = value

    # -- sync -----------------------------------------------------------

    @rule()
    def sync(self) -> None:
        expected = self._expected_writes()
        orphans = self._orphans()
        has_remote_only_update = any(
            kind == "update" and _remote_only(self.remote[path]) for kind, path in expected
        )

        self.fake.begin_sync()
        out, err = self._run_sync(self.client)

        assert self.fake.log == expected, "write log differs from the model"
        for kind, path in expected:
            self._apply(kind, path)
            if kind == "update":
                assert "updatedAt" in self.fake.documents()[path], "update did not set updatedAt"
        self._check_remote()
        self._check_summary(out, expected)
        for path in orphans:
            assert f"orphan remote record (no matching local post): {path}" in err
        self._check_data_file()

        if has_remote_only_update:
            _count("update with remote-only field")
        if not expected and self.files:
            _count("unchanged resync")
        if orphans:
            _count("orphan")
        if self.pending_recovery:
            _count("recovery after failure")
            self.pending_recovery = False

    @precondition(lambda self: bool(self._expected_writes()))
    @rule(data=st.data())
    def sync_with_failure(self, data) -> None:
        expected = self._expected_writes()
        k = data.draw(st.integers(min_value=1, max_value=len(expected)), label="failing write")
        data_before = self._data_bytes()

        self.fake.begin_sync(fail_at=k)
        with pytest.raises(PublishError, match="PDS error 500"):
            self._run_sync(self.client)

        assert self.fake.log == expected[:k], "attempted writes differ from the model"
        for kind, path in expected[: k - 1]:
            self._apply(kind, path)
        self._check_remote()
        assert self._data_bytes() == data_before, "data file changed on a failed sync"
        self.pending_recovery = True
        _count("failure at write 1" if k == 1 else "failure at later write")

    @rule(data=st.data())
    def dry_run(self, data) -> None:
        expected = self._expected_writes()
        use_read_only = data.draw(st.booleans(), label="read-only client")
        client = self.read_only_client if use_read_only else self.client
        records_before = self.fake.snapshot()
        data_before = self._data_bytes()

        self.fake.begin_sync()
        out, _ = self._run_sync(client, dry_run=True)

        assert self.fake.log == [], "dry run wrote to the PDS"
        assert self.fake.snapshot() == records_before, "dry run changed the fake store"
        assert self._data_bytes() == data_before, "dry run changed the data file"
        self._check_summary(out, expected)
        _count("dry run")


# ---------------------------------------------------------------------------
# Test entry point
# ---------------------------------------------------------------------------


# Hypothesis runs the machine through a unittest TestCase, which pytest collects
# directly; this lets --hypothesis-show-statistics report the event() labels.
TestPublishSyncMachine = PublishSyncMachine.TestCase


def test_interaction_coverage() -> None:
    """Under discovery, every interaction must have run. Runs after the machine."""
    print(f"\nprofile={PROFILE} interaction counts={dict(sorted(COUNTS.items()))}")
    if PROFILE == "discovery":
        missing = [label for label in INTERACTIONS if COUNTS[label] == 0]
        assert not missing, f"interactions never exercised under discovery: {missing}"
