"""Tests for atproto/publish.py — all HTTP calls are mocked; no network access."""

import argparse
import json
import time
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import ClassVar

import pytest
import requests
import yaml

from atproto import publish
from atproto.publish import (
    AtprotoClient,
    _can_derive_date,
    _extract_frontmatter_strict,
    _extract_rkey,
    _get_env,
    _records_differ,
    get_publication_uri,
    init_publication,
    load_config,
    parse_book,
    parse_post,
    sync_documents,
    validate_documents,
)

# ---------------------------------------------------------------------------
# Mock transport
# ---------------------------------------------------------------------------


class MockResponse:
    def __init__(self, data: dict | None = None, status_code: int = 200):
        self._data = data or {}
        self.status_code = status_code
        self.ok = status_code < 300
        self.text = json.dumps(self._data)

    def json(self) -> dict:
        return self._data


class MockTransport:
    """
    Records calls and returns pre-queued responses in FIFO order. URLs
    matching a key in `routes` return that fixed response instead of
    consuming the queue (used for the publication getRecord check that
    runs before every sync).
    """

    def __init__(self) -> None:
        self._queue: list[MockResponse] = []
        self.calls: list[tuple] = []
        self.routes: dict[str, MockResponse] = {}

    def push(self, data: dict | None = None, status_code: int = 200) -> None:
        self._queue.append(MockResponse(data, status_code))

    def _pop(self) -> MockResponse:
        assert self._queue, "MockTransport response queue is empty"
        return self._queue.pop(0)

    def _route_for(self, url: str) -> MockResponse | None:
        for key, resp in self.routes.items():
            if key in url:
                return resp
        return None

    def post(
        self,
        url: str,
        json: dict | None = None,
        headers: dict | None = None,
        timeout: float | None = None,
    ) -> MockResponse:
        self.calls.append(("POST", url, json))
        return self._route_for(url) or self._pop()

    def get(
        self,
        url: str,
        params: dict | None = None,
        headers: dict | None = None,
        timeout: float | None = None,
    ) -> MockResponse:
        self.calls.append(("GET", url, params))
        return self._route_for(url) or self._pop()


LOGIN_RESPONSE = {"did": "did:plc:test123", "accessJwt": "token-abc"}
PUB_URI = "at://did:plc:test123/site.standard.publication/rkeypub"
DOC_URI = "at://did:plc:test123/site.standard.document/rkeydoc1"
NEW_DOC_URI = "at://did:plc:test123/site.standard.document/rknew"
EXISTING_DOC_URI = "at://did:plc:test123/site.standard.document/rkexisting"

# Config whose desired publication record matches PUB_RECORD_RESPONSE, so
# sync tests trigger no publication update unless they want one.
TEST_CONFIG = {
    "title": "Test Site",
    "description": "Test description",
    "url": "https://example.com",
    "standard_site": {"publication_uri": PUB_URI},
}
PUB_RECORD_RESPONSE = {
    "uri": PUB_URI,
    "cid": "pubcid1",
    "value": {
        "$type": "site.standard.publication",
        "url": "https://example.com",
        "name": "Test Site",
        "description": "Test description",
        "preferences": {"showInDiscover": True},
    },
}


def make_client(transport: MockTransport) -> AtprotoClient:
    transport.push(LOGIN_RESPONSE)
    # Every sync/delete-orphans run verifies the publication record first.
    transport.routes["getRecord"] = MockResponse(PUB_RECORD_RESPONSE)
    return AtprotoClient(
        "https://bsky.social", "handle.bsky.social", "password", _session=transport
    )


def write_existing_post(directory: Path) -> dict:
    """Write one past post and return a listRecords page that already holds it.

    sync_documents refuses an empty corpus, so tests about other behavior
    need one document. The remote copy matches, so it causes no write.
    """
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / "2020-01-01-existing.md"
    path.write_text("---\ntitle: Existing\n---\n")
    rec = parse_post(path)
    assert rec is not None
    rec["site"] = PUB_URI
    return {"records": [{"uri": EXISTING_DOC_URI, "cid": "cidexisting", "value": rec}]}


# ---------------------------------------------------------------------------
# Front matter → record mapping
# ---------------------------------------------------------------------------


class TestParsePost:
    def test_slug_underscores_become_hyphens(self, tmp_path: Path) -> None:
        # Jekyll's :slug token slugifies the filename: favorite_books_of_2025
        # is served at /blog/favorite-books-of-2025/.
        f = tmp_path / "2025-01-04-favorite_books_of_2025.md"
        f.write_text("---\ntitle: My Post\n---\nContent")
        rec = parse_post(f)
        assert rec is not None
        assert rec["path"] == "/blog/favorite-books-of-2025/"

    def test_date_from_filename(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-06-15-some_post.md"
        f.write_text("---\ntitle: Post\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["publishedAt"] == "2025-06-15T00:00:00Z"

    def test_date_from_front_matter_overrides_filename(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-06-15-some_post.md"
        f.write_text("---\ntitle: Post\ndate: 2024-03-01\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["publishedAt"] == "2024-03-01T00:00:00Z"

    def test_no_description_key_omitted(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert "description" not in rec

    def test_description_stripped(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ndescription: '  hello  '\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["description"] == "hello"

    def test_categories_become_tags(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ncategories:\n  - book-reviews\n  - sci-fi\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["tags"] == ["book-reviews", "sci-fi"]

    def test_single_string_category_becomes_tag(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ncategories: book-reviews\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["tags"] == ["book-reviews"]

    def test_no_categories_key_omitted(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert "tags" not in rec

    def test_draft_skipped_published_false(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\npublished: false\n---\n")
        assert parse_post(f) is None

    def test_draft_key_not_honored(self, tmp_path: Path) -> None:
        # Jekyll ignores a draft: key outside _drafts/ and builds the page;
        # skipping here would desync the record set from the built site and
        # fail the reverse sweep with a misleading message.
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ndraft: true\n---\n")
        assert parse_post(f) is not None

    def test_non_matching_filename_skipped(self, tmp_path: Path) -> None:
        f = tmp_path / "about.md"
        f.write_text("---\ntitle: About\n---\n")
        assert parse_post(f) is None

    def test_type_field_set_correctly(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["$type"] == "site.standard.document"


# ---------------------------------------------------------------------------
# AtprotoClient helpers
# ---------------------------------------------------------------------------


class TestExtractRkey:
    def test_extracts_last_path_segment(self) -> None:
        assert (
            _extract_rkey("at://did:plc:abc/site.standard.document/3mpwdqt4xn42j")
            == "3mpwdqt4xn42j"
        )

    def test_handles_trailing_slash(self) -> None:
        assert _extract_rkey("at://did:plc:abc/site.standard.document/rkey1/") == "rkey1"


class TestRecordsDiffer:
    def test_equal_records_do_not_differ(self) -> None:
        rec = {"$type": "site.standard.document", "path": "/blog/a/", "title": "A"}
        assert not _records_differ(rec, rec.copy())

    def test_changed_title_differs(self) -> None:
        local = {"$type": "site.standard.document", "path": "/blog/a/", "title": "New"}
        remote = {"$type": "site.standard.document", "path": "/blog/a/", "title": "Old"}
        assert _records_differ(local, remote)

    def test_unmanaged_fields_ignored(self) -> None:
        local = {"$type": "site.standard.document", "path": "/blog/a/", "title": "A"}
        remote = {
            "$type": "site.standard.document",
            "path": "/blog/a/",
            "title": "A",
            "bskyPostRef": "at://...",  # unmanaged
        }
        assert not _records_differ(local, remote)

    def test_added_description_differs(self) -> None:
        local = {"$type": "x", "path": "/p/", "title": "T", "description": "new"}
        remote = {"$type": "x", "path": "/p/", "title": "T"}
        assert _records_differ(local, remote)


# ---------------------------------------------------------------------------
# Pagination
# ---------------------------------------------------------------------------


class TestListRecordsPagination:
    def test_fetches_multiple_pages(self) -> None:
        transport = MockTransport()
        client = make_client(transport)

        page1 = {
            "records": [
                {"uri": DOC_URI, "value": {"path": "/blog/a/", "$type": "site.standard.document"}}
            ],
            "cursor": "cursor1",
        }
        page2 = {
            "records": [
                {
                    "uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"),
                    "value": {"path": "/blog/b/", "$type": "site.standard.document"},
                }
            ],
        }
        transport.push(page1)
        transport.push(page2)

        records = client.list_records("site.standard.document")
        assert len(records) == 2
        assert records[0]["value"]["path"] == "/blog/a/"
        assert records[1]["value"]["path"] == "/blog/b/"

    def test_stops_without_cursor(self) -> None:
        transport = MockTransport()
        client = make_client(transport)

        transport.push({"records": [{"uri": DOC_URI, "value": {"path": "/blog/a/"}}]})
        records = client.list_records("site.standard.document")
        assert len(records) == 1


# ---------------------------------------------------------------------------
# sync_documents: create / update / skip decisions
# ---------------------------------------------------------------------------


class TestSyncPostsDecisions:
    def _post(self, tmp_path: Path, name: str, title: str) -> Path:
        f = tmp_path / name
        f.write_text(f"---\ntitle: {title}\n---\nContent\n")
        return f

    def test_new_post_triggers_create(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "Alpha")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})  # listRecords
        transport.push({"uri": DOC_URI})  # createRecord

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        post_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(post_calls) == 1

    def test_unchanged_post_is_skipped(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "Alpha")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Alpha",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push(
            {
                "records": [{"uri": DOC_URI, "value": remote_rec}],
            }
        )

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        create_or_put = [
            c for c in transport.calls if "createRecord" in c[1] or "putRecord" in c[1]
        ]
        assert len(create_or_put) == 0

    def test_changed_title_triggers_update(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "New Title")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Old Title",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push(
            {
                "records": [{"uri": DOC_URI, "cid": "cid1", "value": remote_rec}],
            }
        )
        transport.push({})  # putRecord response

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_calls = [c for c in transport.calls if "putRecord" in c[1]]
        assert len(put_calls) == 1


# ---------------------------------------------------------------------------
# sync_documents: update preserves unmanaged fields and sets updatedAt
# ---------------------------------------------------------------------------


class TestSyncPostsUpdate:
    def test_unmanaged_fields_preserved_after_update(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-alpha.md"
        f.write_text("---\ntitle: New Title\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Old Title",
            "publishedAt": "2025-01-01T00:00:00Z",
            "bskyPostRef": "at://some/post/ref",  # unmanaged
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "cid1", "value": remote_rec}]})
        transport.push({})  # putRecord

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        sent_record = put_call[2]["record"]
        assert sent_record.get("bskyPostRef") == "at://some/post/ref"

    def test_updated_at_set_on_update(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-alpha.md"
        f.write_text("---\ntitle: Changed\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Original",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "cid1", "value": remote_rec}]})
        transport.push({})

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        sent_record = put_call[2]["record"]
        assert "updatedAt" in sent_record


# ---------------------------------------------------------------------------
# sync_documents: duplicate remote path aborts
# ---------------------------------------------------------------------------


class TestDuplicateRemotePath:
    def test_duplicate_path_exits(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        dupe_records = [
            {"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/alpha/"}},
            {
                "uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"),
                "value": {"site": PUB_URI, "path": "/blog/alpha/"},
            },
        ]
        transport.push({"records": dupe_records})

        with pytest.raises(publish.PublishError):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)


# ---------------------------------------------------------------------------
# sync_documents: orphan remote record warns, is not deleted
# ---------------------------------------------------------------------------


class TestOrphanRecord:
    def test_orphan_warns_not_deleted(self, tmp_path: Path, capsys) -> None:
        transport = MockTransport()
        client = make_client(transport)
        page = write_existing_post(tmp_path)
        page["records"].append({"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/gone/"}})
        transport.push(page)

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        stderr = capsys.readouterr().err
        assert "orphan" in stderr.lower()
        assert "/blog/gone/" in stderr

        delete_calls = [c for c in transport.calls if "deleteRecord" in c[1]]
        assert len(delete_calls) == 0


# ---------------------------------------------------------------------------
# sync_documents: data file contents
# ---------------------------------------------------------------------------


class TestDataFile:
    def test_data_file_maps_path_to_uri(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-alpha.md"
        f.write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/newrkey"})

        data_out = tmp_path / "out.json"
        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG)

        result = json.loads(data_out.read_text())
        assert "/blog/alpha/" in result
        assert result["/blog/alpha/"] == "at://did:plc:test123/site.standard.document/newrkey"

    def test_dry_run_writes_no_data_file(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-existing.md").write_text("---\ntitle: Existing\n---\n")
        (tmp_path / "2025-01-02-new.md").write_text("---\ntitle: New\n---\n")

        transport = MockTransport()
        client = make_client(transport)
        existing_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/existing/",
            "title": "Existing",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "value": existing_rec}]})

        data_out = tmp_path / "out.json"
        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG, dry_run=True)

        # A dry-run map would be missing every would-be-created record; a
        # stale partial file must not overwrite the real one.
        assert not data_out.exists()

    def test_data_file_sorted_by_path(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-zzz.md").write_text("---\ntitle: Z\n---\n")
        (tmp_path / "2025-01-02-aaa.md").write_text("---\ntitle: A\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk1"})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk2"})

        data_out = tmp_path / "out.json"
        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG)

        keys = list(json.loads(data_out.read_text()).keys())
        assert keys == sorted(keys)

    def test_data_file_parent_directories_are_created(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": NEW_DOC_URI})

        data_out = tmp_path / "_data" / "nested" / "standard_site.json"
        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG)

        assert json.loads(data_out.read_text()) == {"/blog/alpha/": NEW_DOC_URI}


# ---------------------------------------------------------------------------
# sync_documents: guards and output the mutation run found untested
# ---------------------------------------------------------------------------


class TestSyncMissingBooksDir:
    def test_missing_books_dir_aborts_before_any_write(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        books = tmp_path / "no-books"  # never created
        data_out = tmp_path / "out.json"
        transport = MockTransport()
        client = make_client(transport)
        # Responses the sync would consume if it ignored the missing directory.
        transport.push({"records": []})
        transport.push({"uri": NEW_DOC_URI})

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, posts, data_out, PUB_URI, TEST_CONFIG, books_dir=books)

        assert "missing input directory" in str(exc_info.value)
        assert str(books) in capsys.readouterr().err
        assert [c for c in transport.calls if "createRecord" in c[1]] == []
        assert not data_out.exists()


class TestSyncSiteTimeCutoff:
    def test_sync_applies_the_given_cutoff_to_every_post(self, tmp_path: Path) -> None:
        # A post dated after site_time gets no page, so it must get no record.
        # The cutoff has to reach the sync scan, not only validate.
        (tmp_path / "2025-01-01-later.md").write_text("---\ntitle: Later\n---\n")
        data_out = tmp_path / "out.json"
        transport = MockTransport()
        client = make_client(transport)
        transport.push(write_existing_post(tmp_path))
        transport.push({"uri": NEW_DOC_URI})
        cutoff = publish.parse_site_time("2020-01-01T00:00:00-08:00")

        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG, site_time=cutoff)

        assert [c for c in transport.calls if "createRecord" in c[1]] == []
        assert json.loads(data_out.read_text()) == {"/blog/existing/": EXISTING_DOC_URI}


class TestSyncErrorMessages:
    def test_empty_publication_uri_message_names_the_uri(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", "", TEST_CONFIG)

        assert "publication_uri" in str(exc_info.value)

    def test_duplicate_remote_path_message_names_path_and_both_rkeys(self, tmp_path: Path) -> None:
        write_existing_post(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        transport.push(
            {
                "records": [
                    {"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/alpha/"}},
                    {
                        "uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"),
                        "value": {"site": PUB_URI, "path": "/blog/alpha/"},
                    },
                ]
            }
        )

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        message = str(exc_info.value)
        assert "/blog/alpha/" in message
        assert "rkeydoc1" in message
        assert "rkeydoc2" in message

    def test_publication_without_cid_message_names_getrecord(self, tmp_path: Path) -> None:
        write_existing_post(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name")
        transport.routes["getRecord"] = MockResponse({"uri": PUB_URI, "value": stale})

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        message = str(exc_info.value)
        assert "getRecord" in message
        assert "non-atomic" in message


class TestPublicationRecordWrites:
    def _drifted(self, transport: MockTransport) -> None:
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name")
        transport.routes["getRecord"] = MockResponse(
            {"uri": PUB_URI, "cid": "oldcid", "value": stale}
        )

    def test_update_writes_to_the_publication_rkey(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        self._drifted(transport)
        transport.push({})  # putRecord (publication)
        transport.push(write_existing_post(tmp_path))

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        assert put_call[2]["collection"] == "site.standard.publication"
        assert put_call[2]["rkey"] == "rkeypub"

    def test_update_reports_the_publication_write(self, tmp_path: Path, capsys) -> None:
        transport = MockTransport()
        client = make_client(transport)
        self._drifted(transport)
        transport.push({})
        transport.push(write_existing_post(tmp_path))

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        assert "Updated publication record" in capsys.readouterr().out

    def test_dry_run_plans_the_publication_update_without_writing(
        self, tmp_path: Path, capsys
    ) -> None:
        transport = MockTransport()
        client = make_client(transport)
        self._drifted(transport)
        transport.push(write_existing_post(tmp_path))

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG, dry_run=True)

        assert [c for c in transport.calls if "putRecord" in c[1]] == []
        assert "[dry-run] Would update publication record" in capsys.readouterr().out

    def test_swap_conflict_message_tells_the_operator_to_rerun(self, tmp_path: Path) -> None:
        write_existing_post(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        self._drifted(transport)
        transport.push({"error": "InvalidSwap", "message": "Record was at bafy-new"}, 400)

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        message = str(exc_info.value)
        assert message.startswith("Updating the publication record failed. ")
        assert "InvalidSwap" in message
        assert "rerun" in message

    def test_other_write_failures_get_no_rerun_hint(self, tmp_path: Path) -> None:
        write_existing_post(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        self._drifted(transport)
        transport.push({"error": "InternalServerError"}, 500)

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        message = str(exc_info.value)
        assert message.startswith("Updating the publication record failed. PDS error 500")
        assert "rerun" not in message


class TestSummaryLine:
    def test_summary_counts_each_updated_document_once(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha 2\n---\n")
        (tmp_path / "2025-01-02-beta.md").write_text("---\ntitle: Beta 2\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote = [
            {
                "uri": DOC_URI,
                "cid": "cid1",
                "value": {
                    "$type": "site.standard.document",
                    "site": PUB_URI,
                    "path": "/blog/alpha/",
                    "title": "Alpha",
                    "publishedAt": "2025-01-01T00:00:00Z",
                },
            },
            {
                "uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"),
                "cid": "cid2",
                "value": {
                    "$type": "site.standard.document",
                    "site": PUB_URI,
                    "path": "/blog/beta/",
                    "title": "Beta",
                    "publishedAt": "2025-01-02T00:00:00Z",
                },
            },
        ]
        transport.push({"records": remote})
        transport.push({})
        transport.push({})

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        lines = capsys.readouterr().out.splitlines()
        assert lines[-1] == "created=0 updated=2 unchanged=0 orphaned=0"


class TestDocumentWriteOutput:
    def test_update_targets_the_document_collection_and_rkey(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: New\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Old",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "doccid7", "value": remote_rec}]})
        transport.push({})  # putRecord

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        assert put_call[2]["collection"] == "site.standard.document"
        assert put_call[2]["rkey"] == "rkeydoc1"
        assert "Updated: /blog/alpha/" in capsys.readouterr().out

    def test_create_reports_the_path_and_new_uri(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": NEW_DOC_URI})

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        lines = capsys.readouterr().out.splitlines()
        assert any("/blog/alpha/" in line and NEW_DOC_URI in line for line in lines)

    def test_dry_run_plan_names_each_create_update_and_the_data_file(
        self, tmp_path: Path, capsys
    ) -> None:
        (tmp_path / "2025-01-02-new.md").write_text("---\ntitle: New\n---\n")
        (tmp_path / "2025-01-01-existing.md").write_text("---\ntitle: Changed\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/existing/",
            "title": "Old",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "cid1", "value": remote_rec}]})
        data_out = tmp_path / "out.json"

        sync_documents(client, tmp_path, data_out, PUB_URI, TEST_CONFIG, dry_run=True)

        out = capsys.readouterr().out
        assert "[dry-run] Would create: /blog/new/" in out
        assert "[dry-run] Would update: /blog/existing/" in out
        assert "Would write" in out
        assert str(data_out) in out


class TestUpdatedAtStamp:
    def test_updated_at_is_utc_on_a_non_utc_host(self, tmp_path: Path, monkeypatch) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Changed\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Original",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "cid1", "value": remote_rec}]})
        transport.push({})

        monkeypatch.setenv("TZ", "America/Los_Angeles")
        time.tzset()
        try:
            assert time.timezone != 0, "tzdata is needed for this test to mean anything"
            before = datetime.now(UTC).replace(microsecond=0)
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
            after = datetime.now(UTC)
        finally:
            monkeypatch.undo()
            time.tzset()

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        stamp = put_call[2]["record"]["updatedAt"]
        parsed = datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=UTC)
        assert before <= parsed <= after


# ---------------------------------------------------------------------------
# Missing env vars
# ---------------------------------------------------------------------------


class TestEnvVars:
    def test_missing_bsky_handle_exits(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        with pytest.raises(publish.PublishError):
            _get_env("BSKY_HANDLE")

    def test_missing_bsky_app_password_exits(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        with pytest.raises(publish.PublishError):
            _get_env("BSKY_APP_PASSWORD")

    def test_present_env_var_returns_value(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("BSKY_HANDLE", "alexgude.com")
        assert _get_env("BSKY_HANDLE") == "alexgude.com"


# ---------------------------------------------------------------------------
# init-publication
# ---------------------------------------------------------------------------


INIT_CONFIG = {"title": "T", "description": "D", "url": "https://example.com"}
OTHER_PUB_URI = "at://did:plc:test123/site.standard.publication/rkeyother"


class TestInitPublication:
    def test_creates_publication_record(self, tmp_path: Path) -> None:
        config = {"title": "T", "description": "D", "url": "https://example.com"}
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})  # no existing publication on PDS
        transport.push({"uri": PUB_URI})  # createRecord

        init_publication(client, config)

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 1
        assert create_calls[0][2]["record"]["name"] == "T"

    def test_create_body_targets_publication_collection(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": PUB_URI})

        init_publication(client, INIT_CONFIG)

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        body = create_calls[0][2]
        assert body["collection"] == "site.standard.publication"
        assert body["repo"] == "did:plc:test123"
        assert body["record"] == {
            "$type": "site.standard.publication",
            "url": "https://example.com",
            "name": "T",
            "description": "D",
            "preferences": {"showInDiscover": True},
        }

    def test_lists_publication_collection_on_pds(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": PUB_URI})

        init_publication(client, INIT_CONFIG)

        list_calls = [c for c in transport.calls if "listRecords" in c[1]]
        assert len(list_calls) == 1
        assert list_calls[0][2]["collection"] == "site.standard.publication"

    def test_refuses_if_pds_already_has_publication(self, tmp_path: Path) -> None:
        config = {"title": "T", "description": "D", "url": "https://example.com"}
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": [{"uri": PUB_URI, "value": {}}]})

        with pytest.raises(publish.PublishError) as exc_info:
            init_publication(client, config)
        message = str(exc_info.value)
        assert "already exist on the PDS" in message
        assert PUB_URI in message
        assert "_config.yml" in message
        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 0

    def test_refusal_lists_every_existing_publication(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push(
            {
                "records": [
                    {"uri": PUB_URI, "value": {}},
                    {"uri": OTHER_PUB_URI, "value": {}},
                ]
            }
        )

        with pytest.raises(publish.PublishError) as exc_info:
            init_publication(client, INIT_CONFIG)
        assert f"{PUB_URI}, {OTHER_PUB_URI}" in str(exc_info.value)

    def test_refuses_if_uri_already_set(self, tmp_path: Path) -> None:
        config = {"standard_site": {"publication_uri": PUB_URI}}
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError) as exc_info:
            init_publication(client, config)
        assert PUB_URI in str(exc_info.value)
        assert "_config.yml" in str(exc_info.value)
        assert not [c for c in transport.calls if "listRecords" in c[1]]
        assert not [c for c in transport.calls if "createRecord" in c[1]]

    def test_prints_created_uri_and_config_instruction(
        self, tmp_path: Path, capsys: pytest.CaptureFixture[str]
    ) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": PUB_URI})

        init_publication(client, INIT_CONFIG)

        assert capsys.readouterr().out.splitlines() == [
            f"Publication record created: {PUB_URI}",
            "Add this URI to _config.yml → standard_site.publication_uri and commit.",
        ]


# ---------------------------------------------------------------------------
# load_config / get_publication_uri
# ---------------------------------------------------------------------------


class TestLoadConfig:
    def test_reads_yaml(self, tmp_path: Path) -> None:
        cfg = tmp_path / "_config.yml"
        cfg.write_text("standard_site:\n  publication_uri: 'at://example'\n")
        result = load_config(cfg)
        assert result["standard_site"]["publication_uri"] == "at://example"

    def test_empty_uri_returns_empty_string(self) -> None:
        config = {"standard_site": {"publication_uri": ""}}
        assert get_publication_uri(config) == ""

    def test_missing_key_returns_empty_string(self) -> None:
        assert get_publication_uri({}) == ""


# ---------------------------------------------------------------------------
# publication_uri guards and scoping
# ---------------------------------------------------------------------------


class TestPublicationUriGuards:
    def test_sync_documents_requires_publication_uri(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        with pytest.raises(publish.PublishError):
            sync_documents(client, tmp_path, tmp_path / "out.json", "", TEST_CONFIG)

    def test_created_records_include_site(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": DOC_URI})

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        create_call = next(c for c in transport.calls if "createRecord" in c[1])
        assert create_call[2]["record"]["site"] == PUB_URI

    def test_records_from_other_publications_ignored(self, tmp_path: Path, capsys) -> None:
        # A Leaflet/pckt document sharing our collection must not collide
        # with our paths, trip duplicate detection, or count as an orphan.
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        other = {"site": "at://did:plc:other/site.standard.publication/x", "path": "/blog/alpha/"}
        transport.push({"records": [{"uri": DOC_URI, "value": other}]})
        transport.push({"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2")})

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 1
        assert "orphan" not in capsys.readouterr().err.lower()

    def test_main_publish_fails_hard_when_unconfigured(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        # The URI is committed; a blank value means a broken config and
        # must fail the build, not silently un-publish everything.
        monkeypatch.setattr(publish, "load_config", lambda: {})
        data_out = tmp_path / "out.json"
        books = tmp_path / "books"
        books.mkdir()

        with pytest.raises(SystemExit) as exc_info:
            publish.main(
                [
                    "publish",
                    "--posts-dir",
                    str(tmp_path),
                    "--books-dir",
                    str(books),
                    "--data-out",
                    str(data_out),
                ]
            )
        assert exc_info.value.code == 1
        assert "publication_uri" in capsys.readouterr().err
        assert not data_out.exists()


# ---------------------------------------------------------------------------
# validate subcommand helpers
# ---------------------------------------------------------------------------


class TestCanDeriveDate:
    def test_date_object_passes(self) -> None:
        from datetime import date as date_type

        assert _can_derive_date(date_type(2025, 1, 1)) is True

    def test_datetime_object_passes(self) -> None:
        from datetime import datetime as dt_type

        assert _can_derive_date(dt_type(2025, 1, 1, 0, 0)) is True

    def test_iso_string_passes(self) -> None:
        assert _can_derive_date("2025-01-01") is True

    def test_non_date_string_fails(self) -> None:
        assert _can_derive_date("not a date") is False

    def test_integer_fails(self) -> None:
        assert _can_derive_date(2025) is False

    def test_year_month_only_fails(self) -> None:
        assert _can_derive_date("2025-01") is False


class TestExtractFrontmatterStrict:
    def test_valid_yaml_returns_dict(self, tmp_path: Path) -> None:
        result = _extract_frontmatter_strict("---\ntitle: Hello\n---\nBody")
        assert result == {"title": "Hello"}

    def test_invalid_yaml_raises(self) -> None:
        with pytest.raises(yaml.YAMLError):
            _extract_frontmatter_strict("---\n: bad: yaml: [\n---\n")

    def test_no_frontmatter_returns_empty(self) -> None:
        assert _extract_frontmatter_strict("No front matter") == {}

    def test_non_mapping_frontmatter_raises(self) -> None:
        # A bare string between the fences is not a mapping; used to
        # AttributeError deep in the parser instead of a per-file error.
        with pytest.raises(ValueError):
            _extract_frontmatter_strict("---\njust a string\n---\n")


# ---------------------------------------------------------------------------
# validate_documents
# ---------------------------------------------------------------------------


class TestValidatePosts:
    def _post(self, tmp_path: Path, name: str, content: str) -> Path:
        f = tmp_path / name
        f.write_text(content)
        return f

    def test_valid_post_passes(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-valid.md", "---\ntitle: Valid Post\n---\nContent")
        assert validate_documents(tmp_path) is True

    def test_empty_directory_passes(self, tmp_path: Path) -> None:
        assert validate_documents(tmp_path) is True

    def test_non_post_files_ignored(self, tmp_path: Path) -> None:
        self._post(tmp_path, "about.md", "---\ntitle: ''\n---\n")
        assert validate_documents(tmp_path) is True

    # --- YAML errors ---

    def test_invalid_yaml_fails(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-bad.md", "---\n: bad: yaml: [\n---\nContent")
        assert validate_documents(tmp_path) is False

    def test_invalid_yaml_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-bad.md", "---\n: bad: yaml: [\n---\nContent")
        validate_documents(tmp_path)
        assert "2025-01-01-bad.md" in capsys.readouterr().err

    # --- Missing / empty title ---

    def test_missing_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-no-title.md", "---\ndescription: No title\n---\n")
        assert validate_documents(tmp_path) is False

    def test_missing_title_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-no-title.md", "---\ndescription: No title\n---\n")
        validate_documents(tmp_path)
        assert "2025-01-01-no-title.md" in capsys.readouterr().err

    def test_empty_string_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-empty.md", "---\ntitle: ''\n---\n")
        assert validate_documents(tmp_path) is False

    def test_whitespace_only_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-spaces.md", "---\ntitle: '   '\n---\n")
        assert validate_documents(tmp_path) is False

    # --- Underivable date ---

    def test_non_date_string_fails(self, tmp_path: Path) -> None:
        self._post(
            tmp_path, "2025-01-01-bad-date.md", "---\ntitle: Post\ndate: 'not a date'\n---\n"
        )
        assert validate_documents(tmp_path) is False

    def test_non_date_string_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(
            tmp_path, "2025-01-01-bad-date.md", "---\ntitle: Post\ndate: 'not a date'\n---\n"
        )
        validate_documents(tmp_path)
        assert "2025-01-01-bad-date.md" in capsys.readouterr().err

    def test_null_date_passes(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-null-date.md", "---\ntitle: Post\ndate:\n---\n")
        assert validate_documents(tmp_path) is True

    def test_date_object_passes(self, tmp_path: Path) -> None:
        # YAML parses bare 2025-01-01 as a datetime.date object
        self._post(tmp_path, "2025-01-01-real-date.md", "---\ntitle: Post\ndate: 2025-01-01\n---\n")
        assert validate_documents(tmp_path) is True

    # --- Duplicate path ---

    def test_duplicate_path_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha 1\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha 2\n---\n")
        assert validate_documents(tmp_path) is False

    def test_duplicate_path_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha 1\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha 2\n---\n")
        validate_documents(tmp_path)
        assert "alpha" in capsys.readouterr().err

    def test_unpublished_does_not_create_duplicate(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha\npublished: false\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha\n---\n")
        assert validate_documents(tmp_path) is True

    # --- slug / permalink overrides are hard errors ---
    # Jekyll honors slug:/permalink:, so the page would be served away from
    # the derived path and the AT record would point at a 404.

    def test_slug_override_fails(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\nslug: custom\n---\n")
        assert validate_documents(tmp_path) is False
        assert "slug/permalink" in capsys.readouterr().err

    def test_permalink_override_fails(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\npermalink: /custom/\n---\n")
        assert validate_documents(tmp_path) is False
        assert "2025-01-01-post.md" in capsys.readouterr().err

    # --- Draft skipping ---

    def test_published_false_skips_title_check(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-draft.md", "---\ntitle: ''\npublished: false\n---\n")
        assert validate_documents(tmp_path) is True

    def test_published_false_book_skips_title_check(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (books / "draft.md").write_text("---\ntitle: ''\ndate: 2025-01-01\npublished: false\n---\n")
        assert validate_documents(posts, books_dir=books) is True

    # --- Multiple errors all reported ---

    def test_multiple_errors_all_reported(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-a.md", "---\ntitle: ''\n---\n")
        self._post(tmp_path, "2025-01-02-b.md", "---\ntitle: ''\n---\n")
        validate_documents(tmp_path)
        err = capsys.readouterr().err
        assert "2025-01-01-a.md" in err
        assert "2025-01-02-b.md" in err

    # --- No HTTP calls ---

    def test_no_http_transport_needed(self, tmp_path: Path) -> None:
        # validate_documents takes only a Path — no AtprotoClient is created.
        # If it tried to make HTTP calls, requests would error without mocking.
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\n---\n")
        assert validate_documents(tmp_path) is True


# ---------------------------------------------------------------------------
# validate via main() CLI — no credentials required
# ---------------------------------------------------------------------------


class TestValidateViaCLI:
    def _books(self, tmp_path: Path) -> Path:
        books = tmp_path / "books"
        books.mkdir(exist_ok=True)
        return books

    def test_valid_posts_exit_zero(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        (tmp_path / "2025-01-01-good.md").write_text("---\ntitle: Good\n---\n")
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        publish.main(
            [
                "validate",
                "--posts-dir",
                str(tmp_path),
                "--books-dir",
                str(self._books(tmp_path)),
            ]
        )

    def test_invalid_post_exits_one(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        (tmp_path / "2025-01-01-bad.md").write_text("---\ntitle: ''\n---\n")
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        with pytest.raises(SystemExit):
            publish.main(
                [
                    "validate",
                    "--posts-dir",
                    str(tmp_path),
                    "--books-dir",
                    str(self._books(tmp_path)),
                ]
            )


# ---------------------------------------------------------------------------
# sync_documents local-post guards (defense in depth alongside validate)
# ---------------------------------------------------------------------------


class TestSyncPostsLocalGuards:
    def test_empty_title_exits(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: ''\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

    def test_missing_title_exits(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\nlayout: post\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        assert "2025-01-01-alpha.md" in str(exc_info.value)

    def test_duplicate_local_path_exits(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: One\n---\n")
        (tmp_path / "2025-06-15-alpha.md").write_text("---\ntitle: Two\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        msg = str(exc_info.value)
        assert "2025-01-01-alpha.md" in msg
        assert "2025-06-15-alpha.md" in msg


# ---------------------------------------------------------------------------
# _slugify (must match Jekyll's :slug permalink token)
# ---------------------------------------------------------------------------


class TestSlugify:
    def test_underscores_become_hyphens(self) -> None:
        assert publish._slugify("favorite_books_of_2025") == "favorite-books-of-2025"

    def test_plain_slug_unchanged(self) -> None:
        assert publish._slugify("some-post") == "some-post"

    def test_lowercases(self) -> None:
        assert publish._slugify("Some_Post") == "some-post"

    def test_collapses_runs_and_strips_edges(self) -> None:
        assert publish._slugify("_a__weird..slug_") == "a-weird-slug"

    def test_validate_uses_slugified_path_for_duplicates(self, tmp_path: Path) -> None:
        # Same slug after slugification must collide even if raw names differ.
        (tmp_path / "2025-01-01-a_post.md").write_text("---\ntitle: One\n---\n")
        (tmp_path / "2025-06-15-a-post.md").write_text("---\ntitle: Two\n---\n")
        assert validate_documents(tmp_path) is False


# ---------------------------------------------------------------------------
# Book reviews (_books/ collection)
# ---------------------------------------------------------------------------


class TestParseBook:
    def test_path_keeps_underscores(self, tmp_path: Path) -> None:
        # Collection :path permalinks keep the stem verbatim, unlike :slug.
        f = tmp_path / "a_canticle_for_leibowitz.md"
        f.write_text("---\ntitle: A Canticle for Leibowitz\ndate: 2025-11-16 08:35:33 -0800\n---\n")
        rec = parse_book(f, tmp_path)
        assert rec is not None
        assert rec["path"] == "/books/a_canticle_for_leibowitz/"

    def test_published_at_from_date(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\ndate: 2025-11-16 08:35:33 -0800\n---\n")
        rec = parse_book(f, tmp_path)
        assert rec is not None
        assert rec["publishedAt"] == "2025-11-16T00:00:00Z"

    def test_missing_date_omits_published_at(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\n---\n")
        rec = parse_book(f, tmp_path)
        assert rec is not None
        assert "publishedAt" not in rec

    def test_fixed_book_reviews_tag(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\ndate: 2025-01-01\n---\n")
        rec = parse_book(f, tmp_path)
        assert rec is not None
        assert rec["tags"] == ["book-reviews"]

    def test_unpublished_skipped(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\ndate: 2025-01-01\npublished: false\n---\n")
        assert parse_book(f, tmp_path) is None

    def test_no_description_key(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\ndate: 2025-01-01\n---\n")
        rec = parse_book(f, tmp_path)
        assert rec is not None
        assert "description" not in rec


class TestValidateBooks:
    def _dirs(self, tmp_path: Path) -> tuple[Path, Path]:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        return posts, books

    def test_valid_book_passes(self, tmp_path: Path) -> None:
        posts, books = self._dirs(tmp_path)
        (books / "book.md").write_text("---\ntitle: Book\ndate: 2025-01-01\n---\n")
        assert validate_documents(posts, books_dir=books) is True

    def test_missing_date_fails(self, tmp_path: Path, capsys) -> None:
        posts, books = self._dirs(tmp_path)
        (books / "book.md").write_text("---\ntitle: Book\n---\n")
        assert validate_documents(posts, books_dir=books) is False
        assert "book.md" in capsys.readouterr().err

    def test_missing_title_fails(self, tmp_path: Path) -> None:
        posts, books = self._dirs(tmp_path)
        (books / "book.md").write_text("---\ndate: 2025-01-01\n---\n")
        assert validate_documents(posts, books_dir=books) is False

    def test_invalid_yaml_fails(self, tmp_path: Path) -> None:
        posts, books = self._dirs(tmp_path)
        (books / "book.md").write_text("---\ntitle: [unclosed\n---\n")
        assert validate_documents(posts, books_dir=books) is False

    def test_unpublished_book_skipped(self, tmp_path: Path) -> None:
        posts, books = self._dirs(tmp_path)
        (books / "book.md").write_text("---\npublished: false\n---\n")
        assert validate_documents(posts, books_dir=books) is True

    def test_no_books_dir_posts_only(self, tmp_path: Path) -> None:
        posts, _ = self._dirs(tmp_path)
        (posts / "2025-01-01-a.md").write_text("---\ntitle: A\n---\n")
        assert validate_documents(posts) is True


class TestSyncBooks:
    def test_books_synced_alongside_posts(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (posts / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        (books / "some_book.md").write_text("---\ntitle: Book\ndate: 2025-02-02\n---\n")

        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk1"})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk2"})

        data_out = tmp_path / "out.json"
        sync_documents(client, posts, data_out, PUB_URI, TEST_CONFIG, books_dir=books)

        result = json.loads(data_out.read_text())
        assert "/blog/alpha/" in result
        assert "/books/some_book/" in result

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 2
        book_rec = create_calls[1][2]["record"]
        assert book_rec["site"] == PUB_URI
        assert book_rec["tags"] == ["book-reviews"]

    def test_book_without_date_exits(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (books / "book.md").write_text("---\ntitle: Book\n---\n")

        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError):
            sync_documents(
                client, posts, tmp_path / "out.json", PUB_URI, TEST_CONFIG, books_dir=books
            )


# ---------------------------------------------------------------------------
# Review fixes: bad post dates, override errors, unicode slugs, site-dir
# ---------------------------------------------------------------------------


class TestBadPostDate:
    def test_parse_post_omits_underivable_published_at(self, tmp_path: Path) -> None:
        # 'date: soon' used to yield publishedAt "soonT00:00:00Z".
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ndate: soon\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert "publishedAt" not in rec

    def test_validate_flags_underivable_post_date(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-post.md").write_text("---\ntitle: Post\ndate: soon\n---\n")
        assert validate_documents(tmp_path) is False
        assert "publishedAt" in capsys.readouterr().err

    def test_sync_exits_on_underivable_post_date(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-post.md").write_text("---\ntitle: Post\ndate: soon\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        with pytest.raises(publish.PublishError):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)


class TestOverridesRaise:
    def test_parse_post_raises_on_slug(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\nslug: custom\n---\n")
        with pytest.raises(ValueError):
            parse_post(f)

    def test_parse_book_raises_on_permalink(self, tmp_path: Path) -> None:
        f = tmp_path / "book.md"
        f.write_text("---\ntitle: Book\ndate: 2025-01-01\npermalink: /x/\n---\n")
        with pytest.raises(ValueError):
            parse_book(f, tmp_path)

    def test_sync_exits_on_slug_override(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-post.md").write_text("---\ntitle: Post\nslug: c\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        assert "2025-01-01-post.md" in str(exc_info.value)

    def test_sync_reports_real_yaml_error(self, tmp_path: Path) -> None:
        # Broken YAML used to be swallowed and misdiagnosed as a title error.
        (tmp_path / "2025-01-01-post.md").write_text("---\ntitle: [unclosed\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        with pytest.raises(publish.PublishError, match="invalid YAML front matter") as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        assert "2025-01-01-post.md" in str(exc_info.value)


class TestSlugifyUnicode:
    def test_unicode_letters_kept(self) -> None:
        assert publish._slugify("café_review") == "café-review"

    def test_leading_trailing_stripped(self) -> None:
        assert publish._slugify("__post__") == "post"


class TestSiteDirCrossCheck:
    def _site_with(self, tmp_path: Path, *paths: str) -> Path:
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True, exist_ok=True)
        (site / "books").mkdir(parents=True, exist_ok=True)
        for rel in paths:
            d = site / rel.strip("/")
            d.mkdir(parents=True)
            (d / "index.html").write_text("<!DOCTYPE html>")
        return site

    def test_built_paths_pass(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-my_post.md").write_text("---\ntitle: P\n---\n")
        site = self._site_with(tmp_path, "/blog/my-post/")
        assert validate_documents(posts, site_dir=site) is True

    def test_missing_built_path_fails(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-my_post.md").write_text("---\ntitle: P\n---\n")
        site = self._site_with(tmp_path)  # empty _site
        assert validate_documents(posts, site_dir=site) is False
        assert "not found in built site" in capsys.readouterr().err

    def test_books_checked_too(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (books / "some_book.md").write_text("---\ntitle: B\ndate: 2025-01-01\n---\n")
        site = self._site_with(tmp_path, "/blog/x/")  # book path missing
        assert validate_documents(posts, books_dir=books, site_dir=site) is False
        assert "/books/some_book/" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Second review: re-reviews, null titles, missing dirs, reverse sweep,
# delete-orphans
# ---------------------------------------------------------------------------


class TestReReviewSkip:
    def test_canonical_url_book_skipped(self, tmp_path: Path) -> None:
        f = tmp_path / "review-2023-10-17.md"
        f.write_text(
            "---\ntitle: Hyperion\ndate: 2023-10-17\ncanonical_url: /books/hyperion/\n---\n"
        )
        assert parse_book(f, tmp_path) is None

    def test_nested_re_review_found_but_skipped(self, tmp_path: Path) -> None:
        # Recursion must see subdirectory files; canonical_url then skips them.
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        (books / "hyperion").mkdir(parents=True)
        (books / "hyperion.md").write_text("---\ntitle: Hyperion\ndate: 2023-01-01\n---\n")
        (books / "hyperion" / "review-2023-10-17.md").write_text(
            "---\ntitle: Hyperion\ndate: 2023-10-17\ncanonical_url: /books/hyperion/\n---\n"
        )
        results = list(publish._collect_documents(posts, books))
        assert len(results) == 1
        assert results[0][1]["path"] == "/books/hyperion/"

    def test_nested_review_without_canonical_url_is_error(self, tmp_path: Path) -> None:
        # Jekyll's /books/:path/ permalink would serve a nested file at
        # /books/sub/real_review/, not the stem-derived /books/real_review/.
        # Site convention says nested = re-read review; a nested file
        # without canonical_url is an anomaly the pipeline must not guess
        # a path for.
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        (books / "sub").mkdir(parents=True)
        (books / "sub" / "real_review.md").write_text("---\ntitle: R\ndate: 2025-01-01\n---\n")
        results = list(publish._collect_documents(posts, books))
        assert len(results) == 1
        _doc_file, rec, errors = results[0]
        assert rec is None
        assert any("canonical_url" in e for e in errors)

    def test_underscore_template_dirs_ignored(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        (books / "_templates").mkdir(parents=True)
        (books / "_templates" / "tintin.md").write_text("---\ntitle: T\n---\n")
        assert list(publish._collect_documents(posts, books)) == []


class TestNullTitle:
    def test_post_null_title_is_empty_not_none_string(self, tmp_path: Path) -> None:
        # 'title:' with no value parses to None; str(None) is 'None' which
        # slipped past the empty-title guard.
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle:\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["title"] == ""

    def test_book_null_title_fails_validate(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (books / "book.md").write_text("---\ntitle:\ndate: 2025-01-01\n---\n")
        assert validate_documents(posts, books_dir=books) is False


class TestMissingDirs:
    def test_validate_fails_on_missing_posts_dir(self, tmp_path: Path, capsys) -> None:
        assert validate_documents(tmp_path / "nope") is False
        assert "does not exist" in capsys.readouterr().err

    def test_validate_fails_on_missing_books_dir(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        assert validate_documents(posts, books_dir=tmp_path / "nope") is False

    def test_validate_fails_on_missing_site_dir(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        assert validate_documents(posts, site_dir=tmp_path / "nope") is False

    def test_sync_exits_on_missing_posts_dir(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        # The directory check must fire, not the later empty-corpus guard.
        with pytest.raises(publish.PublishError, match="missing input directory"):
            sync_documents(client, tmp_path / "nope", tmp_path / "out.json", PUB_URI, TEST_CONFIG)


class TestReverseSweep:
    def _site(self, tmp_path: Path, pages: dict[str, str]) -> Path:
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True, exist_ok=True)
        (site / "books").mkdir(parents=True, exist_ok=True)
        for rel, content in pages.items():
            d = site / rel.strip("/")
            d.mkdir(parents=True)
            (d / "index.html").write_text(content)
        return site

    def test_built_page_without_record_fails(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        site = self._site(tmp_path, {"/blog/orphan-page/": "<!DOCTYPE html>"})
        assert validate_documents(posts, site_dir=site) is False
        assert "has no AT record" in capsys.readouterr().err

    def test_redirect_stub_skipped(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        stub = '<!DOCTYPE html><meta http-equiv="refresh" content="0; url=/blog/new/">'
        site = self._site(tmp_path, {"/blog/old-slug/": stub})
        assert validate_documents(posts, site_dir=site) is True

    def test_pagination_and_listing_pages_skipped(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        site = self._site(
            tmp_path,
            {
                "/blog/page2/": "<!DOCTYPE html>",
                "/books/by-author/": "<!DOCTYPE html>",
                "/books/authors/": "<!DOCTYPE html>",
            },
        )
        assert validate_documents(posts, site_dir=site) is True

    def test_matched_page_passes(self, tmp_path: Path) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-my_post.md").write_text("---\ntitle: P\n---\n")
        site = self._site(tmp_path, {"/blog/my-post/": "<!DOCTYPE html>"})
        assert validate_documents(posts, site_dir=site) is True

    def test_large_pages_are_read_by_prefix(self, tmp_path: Path, monkeypatch) -> None:
        # The sweep only needs the first 600 characters to spot a redirect
        # stub; it must not read whole pages.
        padding = "x" * 10_000_000
        stub = '<!DOCTYPE html><meta http-equiv="refresh" content="0; url=/blog/new/">'
        site = self._site(
            tmp_path,
            {
                "/blog/old-slug/": stub + padding,
                "/blog/orphan-page/": "<!DOCTYPE html>" + padding,
                "/blog/my-post/": "<!DOCTYPE html>" + padding,
            },
        )
        chars_read: dict[Path, int] = {}
        original_open = Path.open

        class CountingFile:
            def __init__(self, path: Path, handle) -> None:
                self._path = path
                self._handle = handle

            def read(self, size: int = -1) -> str:
                data = self._handle.read(size)
                chars_read[self._path] = chars_read.get(self._path, 0) + len(data)
                return data

            def __enter__(self):
                return self

            def __exit__(self, *exc_info) -> None:
                self._handle.close()

        def counting_open(self: Path, *args, **kwargs):
            handle = original_open(self, *args, **kwargs)
            return CountingFile(self, handle) if self.name == "index.html" else handle

        monkeypatch.setattr(Path, "open", counting_open)

        errors = publish._reverse_sweep_errors(site, {"/blog/my-post/"})

        assert len(errors) == 1
        assert "/blog/orphan-page/" in errors[0]
        index_files = sorted(site.glob("*/*/index.html"))
        assert sorted(chars_read) == index_files
        assert all(count <= 600 for count in chars_read.values()), chars_read


class TestDeleteOrphans:
    def _dirs(self, tmp_path: Path) -> tuple[Path, Path]:
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        return posts, books

    def test_lists_without_deleting_by_default(self, tmp_path: Path, capsys) -> None:
        posts, books = self._dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(
            {
                "records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/gone/"}}],
            }
        )

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=False)

        assert "Re-run with --yes" in capsys.readouterr().out
        delete_calls = [c for c in transport.calls if "deleteRecord" in c[1]]
        assert len(delete_calls) == 0

    def test_deletes_with_yes(self, tmp_path: Path) -> None:
        posts, books = self._dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(
            {
                "records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/gone/"}}],
            }
        )
        transport.push({})  # deleteRecord response

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        delete_calls = [c for c in transport.calls if "deleteRecord" in c[1]]
        assert len(delete_calls) == 1
        assert delete_calls[0][2]["rkey"] == "rkeydoc1"

    def test_non_orphans_untouched(self, tmp_path: Path, capsys) -> None:
        posts, books = self._dirs(tmp_path)
        (posts / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote = {"site": PUB_URI, "path": "/blog/alpha/", "$type": "site.standard.document"}
        transport.push({"records": [{"uri": DOC_URI, "value": remote}]})

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        assert "No orphan records found" in capsys.readouterr().out

    def test_other_publication_records_ignored(self, tmp_path: Path, capsys) -> None:
        posts, books = self._dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        other = {"site": "at://did:plc:other/site.standard.publication/x", "path": "/blog/x/"}
        transport.push({"records": [{"uri": DOC_URI, "value": other}]})

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        assert "No orphan records found" in capsys.readouterr().out


# ---------------------------------------------------------------------------
# Third review: blast-radius guard, file-prefix filter, timeouts
# ---------------------------------------------------------------------------


class TestSyncEmptyCorpus:
    @pytest.mark.parametrize("dry_run", [False, True])
    def test_refuses_and_keeps_the_data_file(self, tmp_path: Path, dry_run: bool) -> None:
        # An existing-but-wrong --posts-dir must not write {} and drop every
        # document link tag. The previous data file stays as it was.
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        data_out = tmp_path / "out.json"
        data_out.write_text('{"/blog/kept/": "at://kept"}\n')
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/a/"}}]})

        with pytest.raises(publish.PublishError, match="no local documents found"):
            sync_documents(
                client, posts, data_out, PUB_URI, TEST_CONFIG, books_dir=books, dry_run=dry_run
            )

        assert data_out.read_text() == '{"/blog/kept/": "at://kept"}\n'
        assert [c for c in transport.calls if c[0] == "POST" and "createSession" not in c[1]] == []


class TestDeleteOrphansBlastRadius:
    def test_refuses_when_no_local_documents(self, tmp_path: Path, capsys) -> None:
        # An existing-but-wrong --posts-dir must never classify the whole
        # remote corpus as orphans.
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError) as exc_info:
            publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)
        assert "refusing" in str(exc_info.value)
        delete_calls = [c for c in transport.calls if "deleteRecord" in c[1]]
        assert len(delete_calls) == 0


def _orphan_dirs(tmp_path: Path) -> tuple[Path, Path]:
    posts = tmp_path / "posts"
    books = tmp_path / "books"
    posts.mkdir()
    books.mkdir()
    return posts, books


def _calls(transport: MockTransport, method: str, endpoint: str) -> list[tuple]:
    return [c for c in transport.calls if c[0] == method and endpoint in c[1]]


ORPHAN_PAGE = {"records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/gone/"}}]}


class TestDeleteOrphansGuards:
    """Refusals, scoping, and the confirmation default of delete_orphans."""

    def test_confirmed_defaults_to_false(self, tmp_path: Path, capsys) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)

        publish.delete_orphans(client, posts, books, PUB_URI)

        assert _calls(transport, "POST", "deleteRecord") == []
        assert "Re-run with --yes" in capsys.readouterr().out

    @pytest.mark.parametrize("missing", ["posts", "books"])
    def test_missing_input_dir_refused_before_any_request(
        self, tmp_path: Path, capsys, missing: str
    ) -> None:
        posts, books = _orphan_dirs(tmp_path)
        absent = tmp_path / f"no-{missing}"
        if missing == "posts":
            posts = absent
        else:
            books = absent
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)

        with pytest.raises(publish.PublishError, match=r"(?i)missing input directory"):
            publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        assert str(absent) in capsys.readouterr().err
        assert _calls(transport, "POST", "deleteRecord") == []
        assert [c for c in transport.calls if "com.atproto.repo" in c[1]] == []

    def test_empty_publication_uri_refused(self, tmp_path: Path) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(publish.PublishError, match="publication_uri"):
            publish.delete_orphans(client, posts, books, "", confirmed=True)

        assert [c for c in transport.calls if "com.atproto.repo" in c[1]] == []

    def test_empty_local_corpus_refusal_names_flags(self, tmp_path: Path) -> None:
        posts, books = _orphan_dirs(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)

        with pytest.raises(publish.PublishError) as exc_info:
            publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        message = str(exc_info.value)
        assert "no local documents found" in message.lower()
        assert "--posts-dir/--books-dir" in message
        assert _calls(transport, "POST", "deleteRecord") == []

    def test_book_review_counts_as_local_document(self, tmp_path: Path, capsys) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        (books / "moby-dick.md").write_text("---\ntitle: Moby Dick\ndate: 2025-01-01\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(
            {"records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/books/moby-dick/"}}]}
        )

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        assert _calls(transport, "POST", "deleteRecord") == []
        assert "No orphan records found" in capsys.readouterr().out

    def test_unreadable_local_document_aborts_before_delete(self, tmp_path: Path) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-untitled.md").write_text("---\ntitle: '  '\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)

        with pytest.raises(publish.PublishError, match=r"2025-01-01-untitled\.md"):
            publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        assert _calls(transport, "POST", "deleteRecord") == []

    def test_foreign_publication_record_does_not_end_scan(self, tmp_path: Path) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        other = {"site": "at://did:plc:other/site.standard.publication/x", "path": "/blog/x/"}
        ours = {"site": PUB_URI, "path": "/blog/gone/"}
        transport.push(
            {
                "records": [
                    {"uri": DOC_URI, "value": other},
                    {"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"), "value": ours},
                ]
            }
        )
        transport.push({})  # deleteRecord response

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        delete_calls = _calls(transport, "POST", "deleteRecord")
        assert [c[2]["rkey"] for c in delete_calls] == ["rkeydoc2"]


class TestDeleteOrphansOutput:
    """What delete_orphans sends to the PDS and prints for each orphan."""

    def test_lists_document_collection(self, tmp_path: Path) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=False)

        (list_call,) = _calls(transport, "GET", "listRecords")
        assert list_call[2]["collection"] == "site.standard.document"

    def test_dry_run_prints_orphan_path_and_rkey(self, tmp_path: Path, capsys) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=False)

        out = capsys.readouterr().out
        assert "/blog/gone/" in out
        assert "rkeydoc1" in out
        assert _calls(transport, "POST", "deleteRecord") == []

    def test_deletion_sends_collection_and_prints_path_and_rkey(
        self, tmp_path: Path, capsys
    ) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push(ORPHAN_PAGE)
        transport.push({})  # deleteRecord response

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=True)

        (delete_call,) = _calls(transport, "POST", "deleteRecord")
        assert delete_call[2] == {
            "repo": client.did,
            "collection": "site.standard.document",
            "rkey": "rkeydoc1",
        }
        out = capsys.readouterr().out
        assert "/blog/gone/" in out
        assert "rkeydoc1" in out

    def test_record_without_path_printed_as_placeholder(self, tmp_path: Path, capsys) -> None:
        posts, books = _orphan_dirs(tmp_path)
        (posts / "2025-01-01-keep.md").write_text("---\ntitle: Keep\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": [{"uri": DOC_URI, "value": {"site": PUB_URI}}]})

        publish.delete_orphans(client, posts, books, PUB_URI, confirmed=False)

        out = capsys.readouterr().out
        assert "<no path>" in out
        assert "rkeydoc1" in out


class TestSourceFileFilter:
    def test_special_prefix_files_skipped(self, tmp_path: Path) -> None:
        # Jekyll's EntryFilter skips _/./# prefixed and ~ suffixed entries.
        (tmp_path / "_scratch.md").write_text("---\ntitle: X\n---\n")
        (tmp_path / ".hidden.md").write_text("---\ntitle: X\n---\n")
        (tmp_path / "#draft.md").write_text("---\ntitle: X\n---\n")
        (tmp_path / "real.md").write_text("---\ntitle: X\n---\n")
        names = [f.name for f in publish._source_files(tmp_path)]
        assert names == ["real.md"]


class TestHttpTimeouts:
    def test_all_client_calls_pass_timeout(self) -> None:
        class TimeoutAssertingTransport(MockTransport):
            def post(self, url, json=None, headers=None, timeout=None):
                assert timeout is not None, f"no timeout on POST {url}"
                return super().post(url, json=json, headers=headers)

            def get(self, url, params=None, headers=None, timeout=None):
                assert timeout is not None, f"no timeout on GET {url}"
                return super().get(url, params=params, headers=headers)

        transport = TimeoutAssertingTransport()
        transport.push(LOGIN_RESPONSE)
        client = AtprotoClient("https://bsky.social", "h", "p", _session=transport)
        transport.push({"records": []})
        client.list_records("site.standard.document")
        transport.push({"uri": DOC_URI})
        client.create_record("site.standard.document", {})
        transport.push({})
        client.put_record("site.standard.document", "rk", {})
        transport.push({})
        client.delete_record("site.standard.document", "rk")


# ---------------------------------------------------------------------------
# Fourth review: verification, CAS, retries, future posts, publication sync
# ---------------------------------------------------------------------------


class TestFutureDatedPosts:
    def test_future_post_skipped(self, tmp_path: Path) -> None:
        # Jekyll builds with future: false; a record for an unbuilt page
        # would fail the forward cross-check on every branch.
        f = tmp_path / "2099-01-01-scheduled.md"
        f.write_text("---\ntitle: Later\n---\n")
        assert parse_post(f) is None

    def test_past_post_kept(self, tmp_path: Path) -> None:
        f = tmp_path / "2020-01-01-old.md"
        f.write_text("---\ntitle: Old\n---\n")
        assert parse_post(f) is not None

    def test_future_front_matter_date_skipped(self, tmp_path: Path) -> None:
        f = tmp_path / "2020-01-01-old.md"
        f.write_text("---\ntitle: Old\ndate: 2099-06-01\n---\n")
        assert parse_post(f) is None

    def test_cutoff_compares_the_time_of_day(self, tmp_path: Path) -> None:
        # Jekyll compares whole timestamps: a post scheduled for 23:00 is
        # not built by a 10:00 run on the same day.
        f = tmp_path / "2026-11-14-evening.md"
        f.write_text("---\ntitle: Evening\ndate: 2026-11-14 23:00:00 -0800\n---\n")
        morning = publish.parse_site_time("2026-11-14T10:00:00-08:00")
        late = publish.parse_site_time("2026-11-14T23:00:00-08:00")
        assert parse_post(f, morning) is None
        assert parse_post(f, late) is not None

    def test_cutoff_uses_the_given_time_not_now(self, tmp_path: Path) -> None:
        f = tmp_path / "2026-11-15-midnight.md"
        f.write_text("---\ntitle: Midnight\n---\n")
        assert parse_post(f, publish.parse_site_time("2026-11-14T23:59:59-08:00")) is None
        assert parse_post(f, publish.parse_site_time("2026-11-15T00:00:00-08:00")) is not None

    def test_book_after_site_time_skipped(self, tmp_path: Path) -> None:
        # Jekyll keeps a future-dated review in the collection but writes no page.
        f = tmp_path / "later.md"
        f.write_text("---\ntitle: Later\ndate: 2026-11-14 23:00:00 -0800\n---\n")
        assert parse_book(f, tmp_path, publish.parse_site_time("2026-11-14T10:00:00-08:00")) is None
        assert parse_book(f, tmp_path, publish.parse_site_time("2026-11-15T07:00:00Z")) is not None

    @pytest.mark.parametrize(
        "fixture",
        json.loads((Path(__file__).parent / "fixtures/atproto_dates.json").read_text()),
        ids=lambda fixture: fixture["date_yaml"],
    )
    def test_yaml_dates_match_jekyll(self, tmp_path: Path, fixture: dict) -> None:
        # The Ruby suite checks the same fixtures against actual Jekyll output.
        text = f"---\ntitle: Fixture\ndate: {fixture['date_yaml']}\n---\n"
        instant = datetime.fromisoformat(fixture["instant"])
        post = tmp_path / f"{instant:%Y-%m-%d}-fixture.md"
        book = tmp_path / "fixture.md"
        post.write_text(text)
        book.write_text(text)
        date_value = yaml.safe_load(f"date: {fixture['date_yaml']}")["date"]
        assert publish.document_instant(date_value) == instant
        for seconds in (-1, 0, 1):
            cutoff = instant + timedelta(seconds=seconds)
            expected = seconds >= 0
            assert (parse_post(post, cutoff) is not None) == expected
            assert (parse_book(book, tmp_path, cutoff) is not None) == expected

    def test_default_cutoff_is_fixed_for_the_document_scan(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ) -> None:
        for name in ("alpha", "beta"):
            (tmp_path / f"2026-11-15-{name}.md").write_text("---\ntitle: Fixture\n---\n")
        before = publish.parse_site_time("2026-11-14T23:59:59-08:00")
        after = before + timedelta(seconds=2)
        clock_reads = []

        class AdvancingDatetime(datetime):
            @classmethod
            def now(cls, tz=None):
                clock_reads.append(tz)
                return before if len(clock_reads) == 1 else after

        monkeypatch.setattr(publish, "datetime", AdvancingDatetime)
        assert list(publish._collect_documents(tmp_path, None)) == []
        assert len(clock_reads) == 1

    def test_document_instant_rejects_unknown_formats(self) -> None:
        with pytest.raises(ValueError, match="cannot tell when Jekyll publishes"):
            publish.document_instant("November 14, 2026")

    def test_validate_applies_site_time_across_midnight(self, tmp_path: Path) -> None:
        # A run whose build fixed site.time before midnight must not expect a
        # page for a post dated the next day, even when validation runs after.
        posts = tmp_path / "_posts"
        posts.mkdir()
        (posts / "2026-11-15-new.md").write_text("---\ntitle: New\n---\n")
        site = tmp_path / "_site"
        (site / "books").mkdir(parents=True)
        (site / "blog").mkdir()
        before_midnight = publish.parse_site_time("2026-11-14T23:58:00-08:00")
        assert validate_documents(posts, site_dir=site, site_time=before_midnight)
        after_midnight = publish.parse_site_time("2026-11-15T00:03:00-08:00")
        assert not validate_documents(posts, site_dir=site, site_time=after_midnight)

    @pytest.mark.parametrize("text", ["2026-11-14T23:58:00", "tomorrow"])
    def test_site_time_requires_an_offset_timestamp(self, text: str) -> None:
        with pytest.raises(argparse.ArgumentTypeError):
            publish.parse_site_time(text)


class TestPublicationVerification:
    def test_wrong_did_rejected(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-a.md").write_text("---\ntitle: A\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        alien = "at://did:plc:someoneelse/site.standard.publication/rk"

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", alien, TEST_CONFIG)
        assert "authenticated as" in str(exc_info.value)

    def test_missing_publication_record_rejected(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-a.md").write_text("---\ntitle: A\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.routes["getRecord"] = MockResponse(
            {"error": "RecordNotFound", "message": "nope"}, status_code=400
        )

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        assert "does not exist on the PDS" in str(exc_info.value)

    def test_verification_happens_before_any_write(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-a.md").write_text("---\ntitle: A\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.routes["getRecord"] = MockResponse(
            {"error": "RecordNotFound", "message": "nope"}, status_code=400
        )

        with pytest.raises(publish.PublishError):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        writes = [c for c in transport.calls if "createRecord" in c[1] or "putRecord" in c[1]]
        assert writes == []


class TestPublicationRecordSync:
    def test_drifted_publication_updated_with_swap(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name", extraField="keep me")
        transport.routes["getRecord"] = MockResponse(
            {"uri": PUB_URI, "cid": "oldcid", "value": stale}
        )
        transport.push({})  # putRecord (publication)
        transport.push(write_existing_post(tmp_path))  # listRecords (documents)

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_calls = [c for c in transport.calls if "putRecord" in c[1]]
        assert len(put_calls) == 1
        body = put_calls[0][2]
        assert body["collection"] == "site.standard.publication"
        assert body["swapRecord"] == "oldcid"
        assert body["record"]["name"] == "Test Site"
        assert body["record"]["extraField"] == "keep me"  # unmanaged preserved

    def test_matching_publication_not_touched(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push(write_existing_post(tmp_path))

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_calls = [c for c in transport.calls if "putRecord" in c[1]]
        assert put_calls == []

    def test_drifted_publication_without_cid_is_not_written(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name")
        transport.routes["getRecord"] = MockResponse({"uri": PUB_URI, "value": stale})
        transport.push(write_existing_post(tmp_path))  # listRecords, if the sync gets that far

        with pytest.raises(publish.PublishError, match="cid"):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        assert [c for c in transport.calls if "putRecord" in c[1]] == []

    def test_invalid_local_document_blocks_publication_update(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-post.md").write_text("---\ntitle: Post\nslug: custom\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name")
        transport.routes["getRecord"] = MockResponse(
            {"uri": PUB_URI, "cid": "oldcid", "value": stale}
        )
        transport.push({})  # putRecord (publication), if attempted

        with pytest.raises(publish.PublishError, match=r"2025-01-01-post\.md"):
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        assert [c for c in transport.calls if "putRecord" in c[1]] == []

    def test_publication_swap_conflict_aborts_with_clear_message(self, tmp_path: Path) -> None:
        write_existing_post(tmp_path)
        transport = MockTransport()
        client = make_client(transport)
        stale = dict(PUB_RECORD_RESPONSE["value"], name="Old Name")
        transport.routes["getRecord"] = MockResponse(
            {"uri": PUB_URI, "cid": "oldcid", "value": stale}
        )
        transport.push(
            {"error": "InvalidSwap", "message": "Record was at bafy-new"}, status_code=400
        )

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        message = str(exc_info.value)
        assert "InvalidSwap" in message
        assert "publication" in message
        assert [c for c in transport.calls if "listRecords" in c[1]] == []


class TestDocumentUpdateCAS:
    def test_update_passes_swap_cid(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: New\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Old",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "cid": "doccid7", "value": remote_rec}]})
        transport.push({})  # putRecord

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        assert put_call[2]["swapRecord"] == "doccid7"


class TestRetries:
    class FlakyTransport(MockTransport):
        """First N calls to a URL substring raise ConnectionError."""

        def __init__(self, flaky_url: str, failures: int) -> None:
            super().__init__()
            self._flaky_url = flaky_url
            self._failures = failures

        def _maybe_fail(self, url: str) -> None:
            import requests as _requests

            if self._flaky_url in url and self._failures > 0:
                self._failures -= 1
                raise _requests.ConnectionError("transient")

        def post(self, url, json=None, headers=None, timeout=None):
            self._maybe_fail(url)
            return super().post(url, json=json, headers=headers)

        def get(self, url, params=None, headers=None, timeout=None):
            self._maybe_fail(url)
            return super().get(url, params=params, headers=headers)

    def test_login_retries_transient_failure(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(publish.time, "sleep", lambda s: None)
        transport = self.FlakyTransport("createSession", failures=2)
        transport.push(LOGIN_RESPONSE)
        client = AtprotoClient("https://bsky.social", "h", "p", _session=transport)
        assert client.did == "did:plc:test123"

    def test_login_gives_up_after_retries(self, monkeypatch: pytest.MonkeyPatch) -> None:
        import requests as _requests

        monkeypatch.setattr(publish.time, "sleep", lambda s: None)
        transport = self.FlakyTransport("createSession", failures=99)
        with pytest.raises(_requests.ConnectionError):
            AtprotoClient("https://bsky.social", "h", "p", _session=transport)

    def test_list_records_retries(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(publish.time, "sleep", lambda s: None)
        transport = self.FlakyTransport("listRecords", failures=1)
        transport.push(LOGIN_RESPONSE)
        client = AtprotoClient("https://bsky.social", "h", "p", _session=transport)
        transport.push({"records": []})
        assert client.list_records("site.standard.document") == []


class TestOrphanAnnotations:
    def test_github_actions_warning_annotation(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        monkeypatch.setenv("GITHUB_ACTIONS", "true")
        (tmp_path / "2025-01-01-keep.md").write_text("---\ntitle: K\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        keep = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/keep/",
            "title": "K",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        gone = {"site": PUB_URI, "path": "/blog/gone/"}
        transport.push(
            {
                "records": [
                    {"uri": DOC_URI, "cid": "c1", "value": keep},
                    {"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"), "cid": "c2", "value": gone},
                ]
            }
        )

        sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)

        assert "::warning" in capsys.readouterr().out


class TestFrontmatterDelimiterLines:
    def test_triple_dash_inside_value_not_a_delimiter(self) -> None:
        text = '---\ntitle: "a --- b"\n---\nBody'
        assert _extract_frontmatter_strict(text) == {"title": "a --- b"}


class TestMissingSweepSection:
    def test_missing_section_dir_is_error(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True)  # books section missing
        assert validate_documents(posts, site_dir=site) is False
        assert "missing from built site" in capsys.readouterr().err


# ---------------------------------------------------------------------------
# Fifth review: site-timezone cutoff, missing cid
# ---------------------------------------------------------------------------


class TestSiteTimezoneCutoff:
    def test_cutoff_uses_site_timezone(
        self, monkeypatch: pytest.MonkeyPatch, tmp_path: Path
    ) -> None:
        # 2025-06-02T02:00 UTC is still 2025-06-01 19:00 in Los Angeles: a
        # post dated 06-02 is "future" to Jekyll and must be skipped even
        # though UTC has already rolled over.
        import datetime as dt

        real_datetime = publish.datetime

        class FrozenDatetime(dt.datetime):
            @classmethod
            def now(cls, tz=None):
                return real_datetime(2025, 6, 2, 2, 0, 0, tzinfo=dt.UTC).astimezone(tz)

        monkeypatch.setattr(publish, "datetime", FrozenDatetime)
        f = tmp_path / "2025-06-02-tomorrow.md"
        f.write_text("---\ntitle: T\n---\n")
        assert parse_post(f) is None

        g = tmp_path / "2025-06-01-today.md"
        g.write_text("---\ntitle: T\n---\n")
        assert parse_post(g) is not None


class TestMissingCid:
    def test_update_without_cid_refuses(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: New\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        remote_rec = {
            "$type": "site.standard.document",
            "site": PUB_URI,
            "path": "/blog/alpha/",
            "title": "Old",
            "publishedAt": "2025-01-01T00:00:00Z",
        }
        transport.push({"records": [{"uri": DOC_URI, "value": remote_rec}]})  # no cid

        with pytest.raises(publish.PublishError) as exc_info:
            sync_documents(client, tmp_path, tmp_path / "out.json", PUB_URI, TEST_CONFIG)
        assert "non-atomic" in str(exc_info.value)


# ---------------------------------------------------------------------------
# Well-known file check in validate --site-dir
# ---------------------------------------------------------------------------


class TestWellKnownInSite:
    def _site(self, tmp_path: Path) -> tuple[Path, Path]:
        posts = tmp_path / "posts"
        posts.mkdir()
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True)
        (site / "books").mkdir(parents=True)
        return posts, site

    def test_missing_well_known_fails(self, tmp_path: Path, capsys) -> None:
        posts, site = self._site(tmp_path)
        ok = validate_documents(posts, site_dir=site, expected_publication_uri=PUB_URI)
        assert ok is False
        assert "missing" in capsys.readouterr().err

    def test_wrong_content_fails(self, tmp_path: Path, capsys) -> None:
        posts, site = self._site(tmp_path)
        wk = site / ".well-known"
        wk.mkdir()
        (wk / "site.standard.publication").write_text("at://did:plc:wrong/x/y")
        ok = validate_documents(posts, site_dir=site, expected_publication_uri=PUB_URI)
        assert ok is False
        assert "does not match" in capsys.readouterr().err

    def test_trailing_newline_fails(self, tmp_path: Path) -> None:
        # Verifiers compare exactly; a newline is a mismatch.
        posts, site = self._site(tmp_path)
        wk = site / ".well-known"
        wk.mkdir()
        (wk / "site.standard.publication").write_text(PUB_URI + "\n")
        assert validate_documents(posts, site_dir=site, expected_publication_uri=PUB_URI) is False

    def test_exact_content_passes(self, tmp_path: Path) -> None:
        posts, site = self._site(tmp_path)
        wk = site / ".well-known"
        wk.mkdir()
        (wk / "site.standard.publication").write_text(PUB_URI)
        assert validate_documents(posts, site_dir=site, expected_publication_uri=PUB_URI) is True

    def test_no_expected_uri_skips_check(self, tmp_path: Path) -> None:
        posts, site = self._site(tmp_path)
        assert validate_documents(posts, site_dir=site) is True


# ---------------------------------------------------------------------------
# Validate failure accounting, input-dir paths, and exact built paths
# ---------------------------------------------------------------------------


class TestValidateFailureAccounting:
    """Every failure category fails the run, even when another category
    would cancel it out in a shared error count."""

    def test_message_error_and_missing_page_both_fail(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-untitled.md").write_text("---\ntitle: ''\n---\n")
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True)
        (site / "books").mkdir()
        assert validate_documents(posts, site_dir=site) is False
        err = capsys.readouterr().err
        assert "2025-01-01-untitled.md" in err
        assert "not found in built site" in err

    @pytest.mark.parametrize("wk_content", [None, "at://did:plc:wrong/x/y"])
    def test_well_known_failure_and_orphan_page_both_fail(
        self, tmp_path: Path, capsys, wk_content: str | None
    ) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        site = tmp_path / "_site"
        (site / "blog" / "orphan-page").mkdir(parents=True)
        (site / "blog" / "orphan-page" / "index.html").write_text("<!DOCTYPE html>")
        (site / "books").mkdir()
        if wk_content is not None:
            wk = site / ".well-known"
            wk.mkdir()
            (wk / "site.standard.publication").write_text(wk_content)
        assert validate_documents(posts, site_dir=site, expected_publication_uri=PUB_URI) is False
        err = capsys.readouterr().err
        assert "has no AT record" in err
        assert "site.standard.publication" in err

    def test_error_after_unparseable_file_is_still_reported(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        (posts / "2025-01-01-broken.md").write_text("---\ntitle: [unclosed\n---\n")
        (posts / "2025-01-02-untitled.md").write_text("---\ntitle: ''\n---\n")
        assert validate_documents(posts) is False
        err = capsys.readouterr().err
        assert "2025-01-01-broken.md" in err
        assert "2025-01-02-untitled.md" in err


class TestValidateInputDirPaths:
    def test_missing_posts_dir_path_is_printed(self, tmp_path: Path, capsys) -> None:
        missing = tmp_path / "no-posts"
        assert validate_documents(missing) is False
        assert str(missing) in capsys.readouterr().err

    def test_missing_books_dir_path_is_printed(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        missing = tmp_path / "no-books"
        assert validate_documents(posts, books_dir=missing) is False
        assert str(missing) in capsys.readouterr().err

    def test_missing_site_dir_path_is_printed(self, tmp_path: Path, capsys) -> None:
        posts = tmp_path / "posts"
        posts.mkdir()
        missing = tmp_path / "no-site"
        assert validate_documents(posts, site_dir=missing) is False
        assert str(missing) in capsys.readouterr().err


class TestBuiltPathExactness:
    def test_book_path_ending_in_uppercase_x_is_found(self, tmp_path: Path) -> None:
        # The built path is the record path verbatim; stripping characters
        # beyond slashes would look for /books/Ends_/ and miss the page.
        posts = tmp_path / "posts"
        books = tmp_path / "books"
        posts.mkdir()
        books.mkdir()
        (books / "Ends_X.md").write_text("---\ntitle: Book\ndate: 2025-01-01\n---\n")
        site = tmp_path / "_site"
        (site / "blog").mkdir(parents=True)
        (site / "books" / "Ends_X").mkdir(parents=True)
        (site / "books" / "Ends_X" / "index.html").write_text("<!DOCTYPE html>")
        assert validate_documents(posts, books_dir=books, site_dir=site) is True


# ---------------------------------------------------------------------------
# Credential-free dry run: read-only client
# ---------------------------------------------------------------------------


CONFIGURED_DID = "did:plc:y5qiqqtzjmlwggzuttldivxq"


def _dry_run_transport(monkeypatch: pytest.MonkeyPatch) -> MockTransport:
    """Serve the publication and an empty document list to main()."""
    transport = MockTransport()
    transport.routes["createSession"] = MockResponse(LOGIN_RESPONSE)
    transport.routes["getRecord"] = MockResponse(PUB_RECORD_RESPONSE)
    transport.routes["listRecords"] = MockResponse({"records": []})
    monkeypatch.setattr(publish.requests, "Session", lambda: transport)
    monkeypatch.setattr(publish, "load_config", lambda: TEST_CONFIG)
    return transport


def _run_main(argv: list[str]) -> int:
    try:
        publish.main(argv)
    except SystemExit as exc:
        return exc.code
    return 0


def _publish_argv(tmp_path: Path, data_out: Path, *extra: str) -> list[str]:
    posts = tmp_path / "posts"
    books = tmp_path / "books"
    posts.mkdir(exist_ok=True)
    books.mkdir(exist_ok=True)
    return [
        "publish",
        "--posts-dir",
        str(posts),
        "--books-dir",
        str(books),
        "--data-out",
        str(data_out),
        *extra,
    ]


class TestCredentialFreeDryRun:
    def test_dry_run_needs_no_credentials(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        transport = _dry_run_transport(monkeypatch)
        data_out = tmp_path / "out.json"

        write_existing_post(tmp_path / "posts")
        code = _run_main(_publish_argv(tmp_path, data_out, "--dry-run"))

        assert code == 0, capsys.readouterr().err
        assert [c for c in transport.calls if "createSession" in c[1]] == []
        assert [c for c in transport.calls if c[0] == "POST"] == []
        assert not data_out.exists()

    def test_dry_run_ignores_credentials_when_set(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        # The dry run must not depend on the caller's environment.
        monkeypatch.setenv("BSKY_HANDLE", "handle.bsky.social")
        monkeypatch.setenv("BSKY_APP_PASSWORD", "password")
        transport = _dry_run_transport(monkeypatch)

        write_existing_post(tmp_path / "posts")
        code = _run_main(_publish_argv(tmp_path, tmp_path / "out.json", "--dry-run"))

        assert code == 0, capsys.readouterr().err
        assert [c for c in transport.calls if "createSession" in c[1]] == []

    def test_publish_without_dry_run_still_requires_credentials(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        transport = _dry_run_transport(monkeypatch)

        code = _run_main(_publish_argv(tmp_path, tmp_path / "out.json"))

        assert code == 1
        assert "BSKY_HANDLE" in capsys.readouterr().err
        assert transport.calls == []


class TestReadOnlyClient:
    class HeaderRecordingTransport(MockTransport):
        def __init__(self) -> None:
            super().__init__()
            self.get_headers: list[dict | None] = []

        def get(self, url, params=None, headers=None, timeout=None):
            self.get_headers.append(headers)
            return super().get(url, params=params, headers=headers, timeout=timeout)

    def test_list_records_sends_no_authorization(self) -> None:
        transport = self.HeaderRecordingTransport()
        client = AtprotoClient.read_only("https://bsky.social", CONFIGURED_DID, _session=transport)
        transport.push({"records": [{"uri": DOC_URI, "value": {}}], "cursor": "c1"})
        transport.push({"records": [{"uri": DOC_URI, "value": {}}]})

        client.list_records("site.standard.document")

        assert len(transport.get_headers) == 2
        for headers in transport.get_headers:
            assert "Authorization" not in (headers or {})
        assert all(c[2]["repo"] == CONFIGURED_DID for c in transport.calls)

    @pytest.mark.parametrize(
        ("method", "args"),
        [
            ("create_record", ("site.standard.document", {})),
            ("put_record", ("site.standard.document", "rk", {})),
            ("delete_record", ("site.standard.document", "rk")),
        ],
    )
    def test_writes_refused_before_any_request(self, method: str, args: tuple) -> None:
        transport = MockTransport()
        client = AtprotoClient.read_only("https://bsky.social", CONFIGURED_DID, _session=transport)

        with pytest.raises(publish.PublishError, match=f"read-only client: refusing {method}"):
            getattr(client, method)(*args)
        assert transport.calls == []


class TestAmbientCredentials:
    """
    The client's own requests.Session, as Requests prepares each request.
    MockTransport replaces the session, so it cannot see what Requests adds
    from the environment, such as a .netrc entry for the host.
    """

    class CaptureAdapter(requests.adapters.BaseAdapter):
        def __init__(self) -> None:
            super().__init__()
            self.responses = {
                "createSession": LOGIN_RESPONSE,
                "getRecord": PUB_RECORD_RESPONSE,
                "listRecords": {"records": []},
                "createRecord": {"uri": DOC_URI},
                "putRecord": {},
            }
            self.sent: dict[str, str | None] = {}

        def send(self, request, **kwargs):
            endpoint = request.url.split("?")[0].rsplit(".", 1)[1]
            self.sent[endpoint] = request.headers.get("Authorization")
            response = requests.Response()
            response.status_code = 200
            response._content = json.dumps(self.responses[endpoint]).encode()
            response.request = request
            return response

        def close(self) -> None:
            pass

    @pytest.fixture
    def adapter(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
        netrc = tmp_path / "netrc"
        netrc.write_text("machine bsky.social login netrc-user password netrc-pass\n")
        netrc.chmod(0o600)
        monkeypatch.setenv("NETRC", str(netrc))

        adapter = self.CaptureAdapter()
        real_session = requests.Session

        def session_with_adapter():
            session = real_session()
            session.mount("https://", adapter)
            return session

        monkeypatch.setattr(publish.requests, "Session", session_with_adapter)
        return adapter

    def test_read_only_client_ignores_netrc(self, adapter) -> None:
        client = AtprotoClient.read_only("https://bsky.social", CONFIGURED_DID)

        client.get_record(CONFIGURED_DID, "site.standard.publication", "rkeypub")
        client.list_records("site.standard.document")

        assert adapter.sent == {"getRecord": None, "listRecords": None}

    def test_logged_in_client_ignores_netrc(self, adapter) -> None:
        client = AtprotoClient("https://bsky.social", "handle.bsky.social", "password")

        client.list_records("site.standard.document")
        client.create_record("site.standard.document", {})
        client.put_record("site.standard.document", "rk", {}, swap_cid="cid1")

        assert adapter.sent == {
            "createSession": None,
            "listRecords": "Bearer token-abc",
            "createRecord": "Bearer token-abc",
            "putRecord": "Bearer token-abc",
        }


class TestDidFromPublicationUri:
    def test_configured_uri(self) -> None:
        uri = get_publication_uri(load_config())
        assert publish.did_from_publication_uri(uri) == CONFIGURED_DID

    @pytest.mark.parametrize(
        "uri",
        [
            "at://alexgude.com/site.standard.publication/3mqrj32i3mm2t",
            f"{CONFIGURED_DID}/site.standard.publication/3mqrj32i3mm2t",
            "",
        ],
    )
    def test_rejects_non_did_uris(self, uri: str) -> None:
        with pytest.raises(publish.PublishError):
            publish.did_from_publication_uri(uri)


# ---------------------------------------------------------------------------
# CI wiring: branch dry run and main-only publish
# ---------------------------------------------------------------------------


WORKFLOW = Path(__file__).resolve().parents[2] / ".github" / "workflows" / "jekyll.yml"


def _workflow_steps(job: str) -> list[dict]:
    workflow = yaml.safe_load(WORKFLOW.read_text(encoding="utf-8"))
    return workflow["jobs"][job]["steps"]


def _step(steps: list[dict], name: str) -> dict:
    matches = [s for s in steps if s.get("name") == name]
    assert len(matches) == 1, f"expected one {name!r} step, found {len(matches)}"
    return matches[0]


class TestWorkflowDryRun:
    def test_branch_ci_runs_the_dry_run_after_validate(self) -> None:
        steps = _workflow_steps("test")
        names = [s.get("name") for s in steps]
        assert "Dry-run AT Protocol publish" in names
        validate_at = names.index("Validate posts for AT Protocol publish")
        assert names[validate_at + 1] == "Dry-run AT Protocol publish"

        step = steps[validate_at + 1]
        assert step["if"] == "github.ref != 'refs/heads/main'"
        assert step["working-directory"] == "_scripts"
        assert step["run"].split() == [
            "uv",
            "run",
            "python",
            "atproto/publish.py",
            "publish",
            "--posts-dir",
            "../_posts",
            "--books-dir",
            "../_books",
            "--data-out",
            '"$RUNNER_TEMP/standard_site.json"',
            "--dry-run",
        ]
        # Blocking: a failed dry run fails the branch.
        assert "continue-on-error" not in step

    def test_branch_dry_run_gets_no_secrets(self) -> None:
        step = _step(_workflow_steps("test"), "Dry-run AT Protocol publish")
        assert "env" not in step
        text = yaml.safe_dump(step)
        assert "secrets" not in text
        assert "BSKY_" not in text

    def test_real_publish_stays_main_only(self) -> None:
        step = _step(_workflow_steps("build"), "Publish standard.site records")
        assert step["if"] == "github.ref == 'refs/heads/main' && inputs.skip_publish != true"
        assert "--dry-run" not in step["run"]
        assert step["env"]["BSKY_APP_PASSWORD"] == "${{ secrets.BSKY_APP_PASSWORD }}"

    def test_every_build_job_cutoff_uses_the_fixed_time(self) -> None:
        # Both builds, both cross-checks, and publish must agree on which
        # documents are due, or a document that becomes due mid-run gets a
        # record without a page, or a page without a record.
        steps = _workflow_steps("build")
        names = [s.get("name") for s in steps]
        assert names.index("Fix the build time") < names.index("Build with Jekyll")

        overlay = '--config "_config.yml,$RUNNER_TEMP/build_time.yml"'
        builds = [s["run"] for s in steps if "jekyll build" in s.get("run", "")]
        assert len(builds) == 2
        assert all(overlay in command for command in builds)

        flag = '--site-time "${{ steps.build-time.outputs.value }}"'
        commands = [s["run"] for s in steps if "atproto/publish.py" in s.get("run", "")]
        assert len(commands) == 3
        assert all(flag in command for command in commands)


# ---------------------------------------------------------------------------
# CLI dispatch: argument parsing, client choice, handler arguments, exit codes
# ---------------------------------------------------------------------------


class _HandlerRecorder:
    """Stands in for a handler and records the exact arguments it receives."""

    def __init__(self, returns: object = None) -> None:
        self.returns = returns
        self.calls: list[tuple[tuple, dict]] = []

    def __call__(self, *args, **kwargs):
        self.calls.append((args, kwargs))
        return self.returns


class _FakeClient:
    """Stands in for AtprotoClient; records how it was constructed."""

    made: ClassVar[list["_FakeClient"]] = []

    def __init__(self, *args) -> None:
        self.args = args
        self.mode = "credentialed"
        _FakeClient.made.append(self)

    @classmethod
    def read_only(cls, *args) -> "_FakeClient":
        client = cls(*args)
        client.mode = "read-only"
        return client


@pytest.fixture
def dispatch(monkeypatch: pytest.MonkeyPatch) -> dict[str, _HandlerRecorder]:
    recorders = {
        "sync_documents": _HandlerRecorder(),
        "validate_documents": _HandlerRecorder(returns=True),
        "delete_orphans": _HandlerRecorder(),
        "init_publication": _HandlerRecorder(),
    }
    for name, recorder in recorders.items():
        monkeypatch.setattr(publish, name, recorder)
    monkeypatch.setattr(publish, "AtprotoClient", _FakeClient)
    monkeypatch.setattr(publish, "load_config", lambda: TEST_CONFIG)
    monkeypatch.setenv("BSKY_HANDLE", "handle.example")
    monkeypatch.setenv("BSKY_APP_PASSWORD", "app-password")
    _FakeClient.made = []
    return recorders


def _exit_code_of(argv: list[str]) -> object:
    with pytest.raises(SystemExit) as exc:
        publish.main(argv)
    return exc.value.code


def _publish_flags(tmp_path: Path) -> list[str]:
    return [
        "--posts-dir",
        str(tmp_path / "posts"),
        "--books-dir",
        str(tmp_path / "books"),
        "--data-out",
        str(tmp_path / "out.json"),
    ]


class TestDispatchSubcommands:
    def test_subcommand_is_required(self, dispatch: dict[str, _HandlerRecorder]) -> None:
        assert _exit_code_of([]) == 2
        assert dispatch["sync_documents"].calls == []

    def test_unknown_subcommand_is_rejected(self, dispatch: dict[str, _HandlerRecorder]) -> None:
        assert _exit_code_of(["publsh"]) == 2

    def test_publish_passes_every_argument_to_sync_documents(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        argv = ["publish", *_publish_flags(tmp_path), "--site-time", "2026-01-02T03:04:05+00:00"]

        publish.main(argv)

        ((args, kwargs),) = dispatch["sync_documents"].calls
        client, posts, data_out, publication_uri, config = args
        assert client.args == (publish.PDS_URL, "handle.example", "app-password")
        assert client.mode == "credentialed"
        assert posts == tmp_path / "posts"
        assert data_out == tmp_path / "out.json"
        assert publication_uri == PUB_URI
        assert config is TEST_CONFIG
        assert kwargs == {
            "books_dir": tmp_path / "books",
            "dry_run": False,
            "site_time": datetime.fromisoformat("2026-01-02T03:04:05+00:00"),
        }

    def test_publish_dry_run_uses_read_only_client_and_skips_credentials(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        monkeypatch.delenv("BSKY_HANDLE")
        monkeypatch.delenv("BSKY_APP_PASSWORD")

        publish.main(["publish", *_publish_flags(tmp_path), "--dry-run"])

        ((args, kwargs),) = dispatch["sync_documents"].calls
        client = args[0]
        assert client.mode == "read-only"
        assert client.args == (publish.PDS_URL, "did:plc:test123")
        assert len(_FakeClient.made) == 1
        assert kwargs["dry_run"] is True
        assert kwargs["site_time"] is None

    def test_publish_missing_path_is_a_parse_error(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        flags = _publish_flags(tmp_path)
        for flag in ("--posts-dir", "--books-dir", "--data-out"):
            index = flags.index(flag)
            argv = ["publish", *flags[:index], *flags[index + 2 :]]
            assert _exit_code_of(argv) == 2, flag
        assert dispatch["sync_documents"].calls == []

    def test_publish_rejects_unparseable_site_time(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        argv = ["publish", *_publish_flags(tmp_path), "--site-time", "yesterday"]
        assert _exit_code_of(argv) == 2
        assert dispatch["sync_documents"].calls == []

    def test_validate_passes_every_argument_to_validate_documents(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        argv = [
            "validate",
            "--posts-dir",
            str(tmp_path / "posts"),
            "--books-dir",
            str(tmp_path / "books"),
            "--site-dir",
            str(tmp_path / "site"),
            "--site-time",
            "2026-01-02T03:04:05+00:00",
        ]

        publish.main(argv)

        ((args, kwargs),) = dispatch["validate_documents"].calls
        assert args == (tmp_path / "posts",)
        assert kwargs == {
            "books_dir": tmp_path / "books",
            "site_dir": tmp_path / "site",
            "expected_publication_uri": PUB_URI,
            "site_time": datetime.fromisoformat("2026-01-02T03:04:05+00:00"),
        }
        assert dispatch["sync_documents"].calls == []
        assert _FakeClient.made == []

    def test_validate_exits_one_on_failure_and_zero_on_success(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        argv = ["validate", "--posts-dir", str(tmp_path), "--books-dir", str(tmp_path)]

        dispatch["validate_documents"].returns = False
        assert _exit_code_of(argv) == 1

        dispatch["validate_documents"].returns = True
        publish.main(argv)

    def test_validate_requires_posts_and_books_dirs(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        assert _exit_code_of(["validate", "--books-dir", str(tmp_path)]) == 2
        assert _exit_code_of(["validate", "--posts-dir", str(tmp_path)]) == 2
        assert dispatch["validate_documents"].calls == []

    def test_site_dir_and_site_time_default_to_none(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        argv = ["validate", "--posts-dir", str(tmp_path), "--books-dir", str(tmp_path)]

        publish.main(argv)

        ((_, kwargs),) = dispatch["validate_documents"].calls
        assert kwargs["site_dir"] is None
        assert kwargs["site_time"] is None

    def test_delete_orphans_passes_arguments_and_confirmation(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        flags = ["--posts-dir", str(tmp_path / "posts"), "--books-dir", str(tmp_path / "books")]

        publish.main(["delete-orphans", *flags])
        publish.main(["delete-orphans", "--yes", *flags])

        unconfirmed, confirmed = dispatch["delete_orphans"].calls
        for (args, kwargs), expected_confirmed in ((unconfirmed, False), (confirmed, True)):
            client, posts, books, publication_uri = args
            assert client.args == (publish.PDS_URL, "handle.example", "app-password")
            assert client.mode == "credentialed"
            assert posts == tmp_path / "posts"
            assert books == tmp_path / "books"
            assert publication_uri == PUB_URI
            assert kwargs == {"confirmed": expected_confirmed}

    def test_delete_orphans_requires_posts_and_books_dirs(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        assert _exit_code_of(["delete-orphans", "--books-dir", str(tmp_path)]) == 2
        assert _exit_code_of(["delete-orphans", "--posts-dir", str(tmp_path)]) == 2
        assert dispatch["delete_orphans"].calls == []

    def test_delete_orphans_yes_takes_no_value(
        self, tmp_path: Path, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        flags = ["--posts-dir", str(tmp_path), "--books-dir", str(tmp_path)]

        publish.main(["delete-orphans", "--yes", *flags])

        ((_, kwargs),) = dispatch["delete_orphans"].calls
        assert kwargs == {"confirmed": True}

    def test_init_publication_uses_credentialed_client_and_config(
        self, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        publish.main(["init-publication"])

        ((args, kwargs),) = dispatch["init_publication"].calls
        client, config = args
        assert client.args == (publish.PDS_URL, "handle.example", "app-password")
        assert client.mode == "credentialed"
        assert config is TEST_CONFIG
        assert kwargs == {}
        assert dispatch["sync_documents"].calls == []

    def test_credentials_are_read_from_their_environment_names(
        self, monkeypatch: pytest.MonkeyPatch, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        monkeypatch.setenv("BSKY_HANDLE", "other.example")
        monkeypatch.setenv("BSKY_APP_PASSWORD", "other-password")

        publish.main(["init-publication"])

        ((args, _),) = dispatch["init_publication"].calls
        assert args[0].args == (publish.PDS_URL, "other.example", "other-password")

    def test_missing_credentials_fail_before_the_handler_runs(
        self, monkeypatch: pytest.MonkeyPatch, capsys, dispatch: dict[str, _HandlerRecorder]
    ) -> None:
        monkeypatch.delenv("BSKY_APP_PASSWORD")

        assert _exit_code_of(["init-publication"]) == 1
        assert "BSKY_APP_PASSWORD" in capsys.readouterr().err
        assert dispatch["init_publication"].calls == []
