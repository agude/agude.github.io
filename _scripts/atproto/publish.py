#!/usr/bin/env python3
"""
Sync blog posts and book reviews to AT Protocol via standard.site lexicons.

Subcommands
  publish          Sync _posts/ and _books/ to PDS document records (and the
                   publication record from _config.yml); write
                   _data/standard_site.json. Requires publication_uri.
  validate         Check posts/books parse cleanly (no network, no creds);
                   with --site-dir, cross-check derived paths against the
                   built site in both directions.
  delete-orphans   List (and with --yes, delete) remote records that match
                   no local document. Manual use only — never run in CI.
  init-publication Create the site.standard.publication record (one-time setup).

Run from _scripts/:
  uv run python atproto/publish.py publish \\
      --posts-dir ../_posts --books-dir ../_books \\
      --data-out ../_data/standard_site.json [--dry-run]

  uv run python atproto/publish.py validate --posts-dir ../_posts --books-dir ../_books

  uv run python atproto/publish.py init-publication
"""

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo
from typing import Any, Callable

import requests
import yaml

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PDS_URL = "https://bsky.social"
HTTP_TIMEOUT = 30  # seconds; a hung PDS must not stall the deploy job
READ_RETRIES = 3  # idempotent reads retry on transient failures; writes don't

# Must match the `timezone:` key in _config.yml: Jekyll's future-post
# cutoff uses the site timezone, and using UTC here would let an evening
# build see "tomorrow's" post as publishable while Jekyll skips it.
SITE_TZ = ZoneInfo("America/Los_Angeles")


class PublishError(Exception):
    """Fatal pipeline error; main() converts it to a message and exit 1."""
_CONFIG_FILE = Path(__file__).parent.parent.parent / "_config.yml"

POST_FILENAME_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)\.md$")

MANAGED_FIELDS = frozenset(
    {"$type", "site", "path", "title", "description", "tags", "publishedAt"}
)

# Publication fields the pipeline manages; values come from _config.yml so
# site metadata has a single home (title → name, description, url).
PUBLICATION_MANAGED_FIELDS = frozenset({"$type", "url", "name", "description", "preferences"})


def desired_publication_record(config: dict) -> dict[str, Any]:
    for key in ("title", "description", "url"):
        if not config.get(key):
            raise PublishError(f"_config.yml is missing {key!r}")
    return {
        "$type": "site.standard.publication",
        "url": str(config["url"]).rstrip("/"),
        "name": str(config["title"]),
        "description": str(config["description"]),
        "preferences": {"showInDiscover": True},
    }

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------


def load_config(config_path: Path = _CONFIG_FILE) -> dict:
    with open(config_path, encoding="utf-8") as fh:
        return yaml.safe_load(fh) or {}


def get_publication_uri(config: dict) -> str:
    return config.get("standard_site", {}).get("publication_uri", "") or ""


# ---------------------------------------------------------------------------
# Post parsing
# ---------------------------------------------------------------------------


def _slugify(name_slug: str) -> str:
    """
    Approximate Jekyll's default slugify for the permalink :slug token:
    lowercase, runs of non-alphanumerics become a single hyphen, and
    leading/trailing hyphens are stripped (underscores become hyphens).
    Unicode letters/digits are kept via str.isalnum(); the CI cross-check
    (validate --site-dir) verifies every derived path against the real
    build, so any residual divergence from Jekyll fails loudly there.
    """
    out: list[str] = []
    pending_hyphen = False
    for ch in name_slug.lower():
        if ch.isalnum():
            if pending_hyphen and out:
                out.append("-")
            out.append(ch)
            pending_hyphen = False
        else:
            pending_hyphen = True
    return "".join(out)


def parse_post(path: Path) -> dict | None:
    """
    Parse a post file and return managed record fields, or None to skip.

    Skips unpublished files (published: false — real drafts live in
    _drafts/, which is never scanned; a draft: key in _posts/ is NOT
    honored by Jekyll, so honoring it here would desync the record set
    from the built site) and files that don't match YYYY-MM-DD-slug.md. Raises yaml.YAMLError on broken front matter
    and ValueError on slug/permalink overrides (Jekyll would serve the page
    somewhere other than the derived path, so the record would point at a
    404 — callers must fail, not warn). A present-but-unusable 'date' key
    omits publishedAt so callers fail loudly rather than shipping garbage.
    """
    m = POST_FILENAME_RE.match(path.name)
    if not m:
        return None

    date_str, slug = m.group(1), m.group(2)

    fm = _extract_frontmatter_strict(path.read_text(encoding="utf-8"))

    if fm.get("published") is False:
        return None

    _reject_permalink_overrides(fm)

    record: dict[str, Any] = {
        "$type": "site.standard.document",
        "path": f"/blog/{_slugify(slug)}/",
        "title": str(fm.get("title") or ""),
    }

    if "date" in fm and fm["date"] is not None:
        if _can_derive_date(fm["date"]):
            record["publishedAt"] = _to_publish_date(fm["date"])
    else:
        record["publishedAt"] = f"{date_str}T00:00:00Z"

    # Jekyll builds with future: false, so a future-dated post has no page
    # yet; publishing a record for it would fail the site cross-check. The
    # reverse sweep picks it up once its date arrives and it is built.
    published_at = record.get("publishedAt", "")
    if published_at[:10] > datetime.now(SITE_TZ).strftime("%Y-%m-%d"):
        return None

    if "description" in fm and fm["description"] is not None:
        record["description"] = str(fm["description"]).strip()

    cats = fm.get("categories")
    if cats:
        tags = [str(c) for c in (cats if isinstance(cats, list) else [cats]) if c]
        if tags:
            record["tags"] = tags

    return record


def _reject_permalink_overrides(fm: dict) -> None:
    if "slug" in fm or "permalink" in fm:
        raise ValueError(
            "explicit slug/permalink front matter is not supported: Jekyll "
            "would serve the page away from the filename-derived path, so "
            "the AT record would point at a 404"
        )


def _extract_frontmatter_strict(text: str) -> dict:
    """
    Extract front matter; raises yaml.YAMLError on bad YAML and ValueError
    when the front matter parses to something other than a mapping.
    """
    if not text.startswith("---"):
        return {}
    # Split on delimiter *lines*, not the substring: a --- inside a front
    # matter value must not truncate the YAML.
    m = re.match(r"\A---\s*\n(.*?)\n---\s*(?:\n|\Z)", text, re.DOTALL)
    if not m:
        return {}
    fm = yaml.safe_load(m.group(1)) or {}
    if not isinstance(fm, dict):
        raise ValueError(
            f"front matter is not a YAML mapping (got {type(fm).__name__})"
        )
    return fm


def _can_derive_date(date_val: Any) -> bool:
    """Return True if date_val can produce a valid YYYY-MM-DD publishedAt."""
    if hasattr(date_val, "strftime"):
        return True
    return bool(re.match(r"^\d{4}-\d{2}-\d{2}", str(date_val)))


def _to_publish_date(date_val: Any) -> str:
    if hasattr(date_val, "strftime"):
        return date_val.strftime("%Y-%m-%dT00:00:00Z")
    return f"{str(date_val)[:10]}T00:00:00Z"


def parse_book(path: Path, books_dir: Path) -> dict | None:
    """
    Parse a book review file and return managed record fields, or None to skip.

    Books live in _books/ with no date-prefixed filename; the collection
    permalink is /books/:path/, which keeps the filename stem verbatim
    (unlike posts' :slug, which slugifies). publishedAt comes from the
    required 'date' front matter; when it can't be derived the key is left
    out so callers can fail loudly. Re-read reviews (canonical_url front
    matter) are skipped: the canonical page owns the record. Raises like
    parse_post (yaml.YAMLError, ValueError on slug/permalink overrides).
    """
    fm = _extract_frontmatter_strict(path.read_text(encoding="utf-8"))

    if fm.get("published") is False:
        return None

    # Re-read reviews (nested under _books/<book>/) carry canonical_url
    # pointing at the canonical review page; they are built and served but
    # deliberately get no AT record — the canonical page is the document.
    if fm.get("canonical_url"):
        return None

    # Jekyll's /books/:path/ permalink includes subdirectories, so a nested
    # file would be served at /books/<sub>/<stem>/ while this parser derives
    # /books/<stem>/. Site convention says nested files are re-read reviews;
    # one without canonical_url is an anomaly we refuse to guess about.
    if len(path.relative_to(books_dir).parts) > 1:
        raise ValueError(
            "nested book review lacks canonical_url front matter — nested "
            "files are re-read reviews; add canonical_url or move the file "
            "to the top of _books/"
        )

    _reject_permalink_overrides(fm)

    record: dict[str, Any] = {
        "$type": "site.standard.document",
        "path": f"/books/{path.stem}/",
        "title": str(fm.get("title") or ""),
        "tags": ["book-reviews"],
    }

    if "date" in fm and fm["date"] is not None and _can_derive_date(fm["date"]):
        record["publishedAt"] = _to_publish_date(fm["date"])

    return record


# ---------------------------------------------------------------------------
# AT Protocol client
# ---------------------------------------------------------------------------


class AtprotoClient:
    """Thin wrapper around the XRPC calls needed for standard.site syncing."""

    def __init__(
        self,
        pds_url: str,
        handle: str,
        password: str,
        _session: Any = None,
    ) -> None:
        self._pds = pds_url.rstrip("/")
        self._http = _session if _session is not None else requests.Session()
        self.did: str = ""
        self._jwt: str = ""
        self._login(handle, password)

    def _login(self, handle: str, password: str) -> None:
        resp = self._retry_request(
            lambda: self._http.post(
                f"{self._pds}/xrpc/com.atproto.server.createSession",
                json={"identifier": handle, "password": password},
                timeout=HTTP_TIMEOUT,
            )
        )
        _check(resp)
        data = resp.json()
        self.did = data["did"]
        self._jwt = data["accessJwt"]

    @staticmethod
    def _retry_request(send: Callable[[], Any]) -> Any:
        """
        Retry transient failures (connection errors, 5xx) on idempotent
        calls only; writes stay one-shot so a timeout can't double-create.
        """
        for attempt in range(READ_RETRIES):
            last = attempt == READ_RETRIES - 1
            try:
                resp = send()
            except requests.RequestException:
                if last:
                    raise
            else:
                if resp.status_code < 500 or last:
                    return resp
            time.sleep(2**attempt)
        raise AssertionError("unreachable")

    def _auth(self) -> dict:
        return {"Authorization": f"Bearer {self._jwt}"}

    def list_records(self, collection: str) -> list[dict]:
        """Fetch all records in a collection, following cursor pagination."""
        records: list[dict] = []
        cursor: str | None = None
        while True:
            params: dict[str, Any] = {
                "repo": self.did,
                "collection": collection,
                "limit": 100,
            }
            if cursor:
                params["cursor"] = cursor
            resp = self._retry_request(
                lambda: self._http.get(
                    f"{self._pds}/xrpc/com.atproto.repo.listRecords",
                    params=params,
                    headers=self._auth(),
                    timeout=HTTP_TIMEOUT,
                )
            )
            _check(resp)
            data = resp.json()
            records.extend(data.get("records", []))
            cursor = data.get("cursor")
            if not cursor:
                break
        return records

    def create_record(self, collection: str, record: dict) -> str:
        """Create a record and return its AT-URI."""
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.repo.createRecord",
            json={"repo": self.did, "collection": collection, "record": record},
            headers=self._auth(),
            timeout=HTTP_TIMEOUT,
        )
        _check(resp)
        return resp.json()["uri"]

    def get_record(self, repo: str, collection: str, rkey: str) -> dict | None:
        """Fetch one record ({uri, cid, value}), or None if it doesn't exist."""
        resp = self._retry_request(
            lambda: self._http.get(
                f"{self._pds}/xrpc/com.atproto.repo.getRecord",
                params={"repo": repo, "collection": collection, "rkey": rkey},
                timeout=HTTP_TIMEOUT,
            )
        )
        if resp.status_code == 400 and "RecordNotFound" in resp.text:
            return None
        _check(resp)
        return resp.json()

    def delete_record(self, collection: str, rkey: str) -> None:
        """Delete a record. Only used by the manual delete-orphans command."""
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.repo.deleteRecord",
            json={"repo": self.did, "collection": collection, "rkey": rkey},
            headers=self._auth(),
            timeout=HTTP_TIMEOUT,
        )
        _check(resp)

    def put_record(
        self, collection: str, rkey: str, record: dict, swap_cid: str | None = None
    ) -> None:
        """
        Overwrite an existing record. swap_cid makes the read-modify-write
        atomic: the PDS rejects the write if the record changed since it
        was read (another standard.site client may edit concurrently).
        """
        body: dict[str, Any] = {
            "repo": self.did,
            "collection": collection,
            "rkey": rkey,
            "record": record,
        }
        if swap_cid is not None:
            body["swapRecord"] = swap_cid
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.repo.putRecord",
            json=body,
            headers=self._auth(),
            timeout=HTTP_TIMEOUT,
        )
        _check(resp)


def _check(resp: Any) -> None:
    if not resp.ok:
        raise PublishError(f"PDS error {resp.status_code}: {resp.text}")


# ---------------------------------------------------------------------------
# Sync logic
# ---------------------------------------------------------------------------


def _extract_rkey(uri: str) -> str:
    return uri.rstrip("/").rsplit("/", 1)[-1]


def _verify_publication(client: AtprotoClient, publication_uri: str) -> dict:
    """
    The publication URI partitions every remote query; a well-formed but
    wrong value would hide all existing records and cause a full duplicate
    backfill. Verify it belongs to the authenticated account and exists on
    the PDS before any sync runs. Returns the remote {uri, cid, value}.
    """
    m = re.match(r"\Aat://([^/]+)/site\.standard\.publication/([^/]+)\Z", publication_uri)
    if not m:
        raise PublishError(f"publication_uri is malformed: {publication_uri!r}")
    uri_did, rkey = m.group(1), m.group(2)
    if uri_did != client.did:
        raise PublishError(
            f"publication_uri belongs to {uri_did} but the session is "
            f"authenticated as {client.did}"
        )
    remote = client.get_record(client.did, "site.standard.publication", rkey)
    if remote is None:
        raise PublishError(
            f"publication record does not exist on the PDS: {publication_uri}"
        )
    return remote


def _managed_subset(record: dict) -> dict:
    return {k: v for k, v in record.items() if k in MANAGED_FIELDS}


def _records_differ(local: dict, remote: dict) -> bool:
    return _managed_subset(local) != _managed_subset(remote)


def _document_sources(
    posts_dir: Path, books_dir: Path | None
) -> list[tuple[Path, Callable[[Path], dict | None]]]:
    sources: list[tuple[Path, Callable[[Path], dict | None]]] = [
        (posts_dir, parse_post)
    ]
    if books_dir is not None:
        bd = books_dir
        sources.append((bd, lambda f: parse_book(f, bd)))
    return sources


def _source_files(src_dir: Path) -> list[Path]:
    """
    All candidate markdown files under src_dir, recursively, mirroring
    Jekyll: directories starting with '_' (templates) are not read.
    """
    def included(f: Path) -> bool:
        rel = f.relative_to(src_dir)
        if any(part.startswith("_") for part in rel.parts[:-1]):
            return False
        # Jekyll's EntryFilter also skips special/backup files.
        return not (rel.name.startswith(("_", ".", "#")) or rel.name.endswith("~"))

    return sorted(f for f in src_dir.rglob("*.md") if included(f))


def _require_dir(path: Path | None, label: str) -> bool:
    """True if path is None or an existing directory; error otherwise."""
    if path is None or path.is_dir():
        return True
    print(f"ERROR: {label} does not exist: {path}", file=sys.stderr)
    return False


def _collect_documents(posts_dir: Path, books_dir: Path | None):
    """
    Yield (doc_file, record_or_None, errors) for every candidate file.

    Single source of truth for the per-document rules shared by publish
    and validate: parse failures, empty titles, underivable publishedAt,
    and duplicate paths all surface here. record is None when the file is
    skipped (draft, re-review, non-post filename) or failed to parse.
    """
    seen_paths: dict[str, Path] = {}
    for src_dir, parser in _document_sources(posts_dir, books_dir):
        for doc_file in _source_files(src_dir):
            try:
                rec = parser(doc_file)
            except yaml.YAMLError as exc:
                yield doc_file, None, [f"invalid YAML front matter: {exc}"]
                continue
            except ValueError as exc:
                yield doc_file, None, [str(exc)]
                continue
            if rec is None:
                continue

            errors: list[str] = []
            if not rec["title"].strip():
                errors.append("missing or empty 'title'")
            if not rec.get("publishedAt"):
                errors.append(
                    "cannot derive publishedAt from the 'date' front matter "
                    "or filename"
                )
            if rec["path"] in seen_paths:
                errors.append(
                    f"duplicate path {rec['path']!r} "
                    f"(also claimed by {seen_paths[rec['path']].name})"
                )
            else:
                seen_paths[rec["path"]] = doc_file
            yield doc_file, rec, errors


def sync_documents(
    client: AtprotoClient,
    posts_dir: Path,
    data_out: Path,
    publication_uri: str,
    config: dict,
    books_dir: Path | None = None,
    dry_run: bool = False,
) -> None:
    """Sync local posts (and books) to PDS document records; write data file."""

    if not publication_uri:
        # site is a required document field, and an empty value here would
        # also make the merge loop strip site from existing remote records.
        raise PublishError("sync_documents requires a publication_uri")

    if not (_require_dir(posts_dir, "posts dir") and _require_dir(books_dir, "books dir")):
        raise PublishError("missing input directory")

    remote_publication = _verify_publication(client, publication_uri)

    # --- Keep the publication record itself in sync with _config.yml ---
    desired_pub = desired_publication_record(config)
    remote_pub_value = remote_publication["value"]
    pub_subset = {
        k: v for k, v in remote_pub_value.items() if k in PUBLICATION_MANAGED_FIELDS
    }
    if pub_subset != desired_pub:
        merged_pub = dict(remote_pub_value)
        merged_pub.update(desired_pub)
        if dry_run:
            print("[dry-run] Would update publication record")
        else:
            client.put_record(
                "site.standard.publication",
                _extract_rkey(publication_uri),
                merged_pub,
                swap_cid=remote_publication.get("cid"),
            )
            print("Updated publication record from _config.yml")

    # --- Collect local documents ---
    # Shares _collect_documents with validate so the CI gate and the
    # publisher cannot drift; any per-document error aborts the sync.
    local: dict[str, tuple[Path, dict]] = {}
    for doc_file, rec, errors in _collect_documents(posts_dir, books_dir):
        if errors:
            raise PublishError(
                "; ".join(f"{doc_file.name}: {msg}" for msg in errors)
            )
        if rec is None:
            raise AssertionError("collector yielded no record and no errors")
        rec["site"] = publication_uri
        local[rec["path"]] = (doc_file, rec)

    # --- Fetch remote records ---
    # Only records belonging to our publication are managed; documents other
    # apps (Leaflet, pckt, ...) may create in this collection are ignored.
    remote: dict[str, tuple[str, str, dict]] = {}  # path → (rkey, cid, value)
    for item in client.list_records("site.standard.document"):
        uri: str = item["uri"]
        value: dict = item["value"]
        if value.get("site") != publication_uri:
            continue
        path_key: str = value.get("path", "")
        if path_key in remote:
            existing_rkey, _, _ = remote[path_key]
            raise PublishError(
                f"duplicate remote path {path_key!r}: rkeys "
                f"{existing_rkey} and {_extract_rkey(uri)}"
            )
        remote[path_key] = (_extract_rkey(uri), item.get("cid", ""), value)

    # --- Build AT-URI map for paths that already have remote records ---
    data_map: dict[str, str] = {}
    for path_key, (rkey, _, _) in remote.items():
        if path_key in local:
            data_map[path_key] = (
                f"at://{client.did}/site.standard.document/{rkey}"
            )

    # --- Diff and sync ---
    created = updated = unchanged = orphaned = 0

    for path_key, (_doc_file, local_rec) in local.items():
        if path_key not in remote:
            if dry_run:
                print(f"[dry-run] Would create: {path_key}")
            else:
                at_uri = client.create_record("site.standard.document", local_rec)
                data_map[path_key] = at_uri
                print(f"Created: {path_key} → {at_uri}")
            created += 1
        else:
            rkey, cid, remote_rec = remote[path_key]
            if _records_differ(local_rec, remote_rec):
                if not cid:
                    raise PublishError(
                        f"listRecords returned no cid for {path_key!r}; "
                        "refusing a non-atomic overwrite"
                    )
                merged = dict(remote_rec)
                for key in MANAGED_FIELDS:
                    if key in local_rec:
                        merged[key] = local_rec[key]
                    elif key in merged:
                        del merged[key]
                merged["updatedAt"] = datetime.now(timezone.utc).strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
                if dry_run:
                    print(f"[dry-run] Would update: {path_key}")
                else:
                    client.put_record(
                        "site.standard.document", rkey, merged, swap_cid=cid
                    )
                    print(f"Updated: {path_key}")
                updated += 1
            else:
                unchanged += 1

    for path_key in remote:
        if path_key not in local:
            msg = f"orphan remote record (no matching local post): {path_key}"
            print(f"WARNING: {msg}", file=sys.stderr)
            if os.environ.get("GITHUB_ACTIONS"):
                # Surface on the run summary page; plain stderr WARNINGs in
                # a green run are invisible in practice.
                print(f"::warning title=AT Protocol orphan record::{msg}")
            orphaned += 1

    # --- Write data file (never on dry runs: the map would be missing
    # every would-be-created record, and a stale partial file changes the
    # next local build) ---
    if dry_run:
        print(f"[dry-run] Would write {len(data_map)} entries to {data_out}")
    else:
        output = {path_key: data_map[path_key] for path_key in sorted(local) if path_key in data_map}
        data_out.parent.mkdir(parents=True, exist_ok=True)
        data_out.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")

    print(
        f"created={created} updated={updated} unchanged={unchanged} orphaned={orphaned}"
    )


# ---------------------------------------------------------------------------
# validate
# ---------------------------------------------------------------------------


# Sections of _site the reverse sweep covers. The keys are load-bearing:
# removing one stops sweeping that section entirely. Each value matches the
# depth-1 pages that are deliberately not documents — blog pagination and
# the enumerated books listing pages (enumerated, not patterned, so a real
# review named like a listing page cannot be silently exempted). Redirect
# stubs (renamed slugs) are detected by content, not name.
SWEPT_SECTIONS = {
    "blog": re.compile(r"^page\d+$"),
    "books": re.compile(r"^(authors|by-author|by-award|by-rating|by-series|by-title|covers)$"),
}


def _reverse_sweep_errors(site_dir: Path, record_paths: set[str]) -> list[str]:
    """
    The other direction of the site cross-check: every depth-1 built page
    under /blog/ and /books/ must have an AT record, unless it is a known
    listing/pagination page or a redirect stub. Catches documents that the
    source globs silently miss (the failure mode of an accidental skip).
    """
    errors: list[str] = []
    for section, skip_re in SWEPT_SECTIONS.items():
        if not (site_dir / section).is_dir():
            errors.append(
                f"expected section /{section}/ missing from built site — "
                "the reverse sweep would be vacuous"
            )
            continue
        for index_file in sorted((site_dir / section).glob("*/index.html")):
            name = index_file.parent.name
            if skip_re.match(name):
                continue
            head = index_file.read_text(encoding="utf-8", errors="replace")[:600]
            if 'http-equiv="refresh"' in head:
                continue
            path_str = f"/{section}/{name}/"
            if path_str not in record_paths:
                errors.append(
                    f"built page {path_str} has no AT record — if intentional, "
                    "add it to SWEPT_SECTIONS; otherwise a source file is "
                    "being missed"
                )
    return errors


def validate_documents(
    posts_dir: Path,
    books_dir: Path | None = None,
    site_dir: Path | None = None,
) -> bool:
    """
    Validate all posts (and books) for AT Protocol compatibility.

    Requires no credentials, config, or network access. Runs the same
    _collect_documents pipeline as publish so the CI gate cannot drift
    from the gated behavior. With site_dir, additionally cross-checks in
    both directions: every derived record path must exist in the built
    site, and every built document page must map to a record.

    Returns True if all publishable documents are valid.
    """
    if not (
        _require_dir(posts_dir, "posts dir")
        and _require_dir(books_dir, "books dir")
        and _require_dir(site_dir, "site dir")
    ):
        return False

    error_count = 0
    record_paths: set[str] = set()

    for doc_file, rec, errors in _collect_documents(posts_dir, books_dir):
        for msg in errors:
            print(f"ERROR: {doc_file.name}: {msg}", file=sys.stderr)
            error_count += 1
        if rec is None:
            continue
        record_paths.add(rec["path"])

        if site_dir is not None:
            built = site_dir / rec["path"].strip("/") / "index.html"
            if not built.is_file():
                print(
                    f"ERROR: {doc_file.name}: derived path {rec['path']!r} "
                    f"not found in built site ({built})",
                    file=sys.stderr,
                )
                error_count += 1

    if site_dir is not None:
        for msg in _reverse_sweep_errors(site_dir, record_paths):
            print(f"ERROR: {msg}", file=sys.stderr)
            error_count += 1

    return error_count == 0


def delete_orphans(
    client: AtprotoClient,
    posts_dir: Path,
    books_dir: Path,
    publication_uri: str,
    confirmed: bool = False,
) -> None:
    """
    Manual cleanup for remote records that match no local document (e.g.
    after a bad publish or a deleted post). Lists orphans; deletes them
    only when confirmed. Never run in CI — deletion is a human decision.
    """
    if not publication_uri:
        raise PublishError("delete-orphans requires a publication_uri")
    if not (_require_dir(posts_dir, "posts dir") and _require_dir(books_dir, "books dir")):
        raise PublishError("missing input directory")

    _verify_publication(client, publication_uri)

    local_paths: set[str] = set()
    for doc_file, rec, errors in _collect_documents(posts_dir, books_dir):
        if errors:
            raise PublishError(
                "; ".join(f"{doc_file.name}: {msg}" for msg in errors)
            )
        if rec is None:
            raise AssertionError("collector yielded no record and no errors")
        local_paths.add(rec["path"])

    if not local_paths:
        # An existing-but-wrong --posts-dir would classify every remote
        # record as an orphan; never treat an empty local corpus as license
        # to delete everything.
        raise PublishError(
            "no local documents found — refusing to treat every remote "
            "record as an orphan (check --posts-dir/--books-dir)"
        )

    orphans: list[tuple[str, str]] = []  # (path, rkey)
    for item in client.list_records("site.standard.document"):
        value = item["value"]
        if value.get("site") != publication_uri:
            continue
        if value.get("path", "") not in local_paths:
            orphans.append((value.get("path", "<no path>"), _extract_rkey(item["uri"])))

    if not orphans:
        print("No orphan records found.")
        return

    for path_str, rkey in orphans:
        if confirmed:
            client.delete_record("site.standard.document", rkey)
            print(f"Deleted orphan: {path_str} (rkey {rkey})")
        else:
            print(f"Orphan: {path_str} (rkey {rkey})")

    if not confirmed:
        print(f"{len(orphans)} orphan(s) found. Re-run with --yes to delete.")


# ---------------------------------------------------------------------------
# init-publication subcommand
# ---------------------------------------------------------------------------


def init_publication(client: AtprotoClient, config: dict) -> None:
    existing = get_publication_uri(config)
    if existing:
        raise PublishError(
            f"publication_uri is already set in _config.yml: {existing!r}"
        )
    # The config guard is local-only; also check the PDS so running twice
    # before committing cannot create two publication records.
    remote_pubs = client.list_records("site.standard.publication")
    if remote_pubs:
        uris = ", ".join(item["uri"] for item in remote_pubs)
        raise PublishError(
            f"publication record(s) already exist on the PDS: {uris} — "
            "put the URI in _config.yml instead of creating another"
        )
    at_uri = client.create_record(
        "site.standard.publication", desired_publication_record(config)
    )
    print(f"Publication record created: {at_uri}")
    print("Add this URI to _config.yml → standard_site.publication_uri and commit.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _get_env(name: str) -> str:
    val = os.environ.get(name, "")
    if not val:
        raise PublishError(f"environment variable {name!r} is not set")
    return val


def main(argv: list[str] | None = None) -> None:
    try:
        _dispatch(argv)
    except PublishError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


def _dispatch(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    pub_p = sub.add_parser(
        "publish", help="Sync posts and books to PDS document records"
    )
    pub_p.add_argument("--posts-dir", required=True, type=Path)
    pub_p.add_argument("--books-dir", required=True, type=Path)
    pub_p.add_argument("--data-out", required=True, type=Path)
    pub_p.add_argument("--dry-run", action="store_true")

    sub.add_parser("init-publication", help="Create publication record (one-time)")

    val_p = sub.add_parser(
        "validate",
        help="Validate posts and books for AT Protocol compatibility "
        "(no network, no credentials)",
    )
    val_p.add_argument("--posts-dir", required=True, type=Path)
    val_p.add_argument("--books-dir", required=True, type=Path)
    val_p.add_argument("--site-dir", type=Path, default=None)

    del_p = sub.add_parser(
        "delete-orphans",
        help="List/delete remote records with no local document (manual only)",
    )
    del_p.add_argument("--posts-dir", required=True, type=Path)
    del_p.add_argument("--books-dir", required=True, type=Path)
    del_p.add_argument("--yes", action="store_true", help="Actually delete")

    args = parser.parse_args(argv)

    # validate needs no credentials or config — dispatch before either check.
    if args.cmd == "validate":
        ok = validate_documents(
            args.posts_dir, books_dir=args.books_dir, site_dir=args.site_dir
        )
        if not ok:
            sys.exit(1)
        return

    config = load_config()
    publication_uri = get_publication_uri(config)

    # The pre-Phase-3 "skip when unconfigured" grace path is gone: the URI
    # is committed, so an empty value now means a broken config and must
    # fail the build, not silently un-publish everything (repo rule 5).
    if args.cmd == "publish" and not publication_uri:
        raise PublishError(
            "standard_site.publication_uri is not set in _config.yml — "
            "refusing to publish with a blank partition key"
        )

    handle = _get_env("BSKY_HANDLE")
    password = _get_env("BSKY_APP_PASSWORD")
    client = AtprotoClient(PDS_URL, handle, password)

    if args.cmd == "publish":
        sync_documents(
            client,
            args.posts_dir,
            args.data_out,
            publication_uri,
            config,
            books_dir=args.books_dir,
            dry_run=args.dry_run,
        )
    elif args.cmd == "delete-orphans":
        delete_orphans(
            client,
            args.posts_dir,
            args.books_dir,
            publication_uri,
            confirmed=args.yes,
        )
    elif args.cmd == "init-publication":
        init_publication(client, config)


if __name__ == "__main__":
    main()
