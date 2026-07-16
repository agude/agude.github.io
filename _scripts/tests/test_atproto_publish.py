"""Tests for atproto/publish.py — all HTTP calls are mocked; no network access."""

import json
import sys
from datetime import date, datetime
from pathlib import Path

import pytest
import yaml

import publish
from publish import (
    AtprotoClient,
    _can_derive_date,
    _extract_frontmatter_strict,
    _extract_rkey,
    _get_env,
    _records_differ,
    get_publication_uri,
    init_publication,
    load_config,
    parse_post,
    sync_posts,
    validate_posts,
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
    """Records calls and returns pre-queued responses in FIFO order."""

    def __init__(self) -> None:
        self._queue: list[MockResponse] = []
        self.calls: list[tuple] = []

    def push(self, data: dict | None = None, status_code: int = 200) -> None:
        self._queue.append(MockResponse(data, status_code))

    def _pop(self) -> MockResponse:
        assert self._queue, "MockTransport response queue is empty"
        return self._queue.pop(0)

    def post(self, url: str, json: dict | None = None, headers: dict | None = None) -> MockResponse:
        self.calls.append(("POST", url, json))
        return self._pop()

    def get(self, url: str, params: dict | None = None, headers: dict | None = None) -> MockResponse:
        self.calls.append(("GET", url, params))
        return self._pop()


LOGIN_RESPONSE = {"did": "did:plc:test123", "accessJwt": "token-abc"}
VALID_URI = "at://did:plc:test123/site.standard.publication/3mpwdqt4xn42j"
PUB_URI = "at://did:plc:test123/site.standard.publication/rkeypub"
DOC_URI = "at://did:plc:test123/site.standard.document/rkeydoc1"


def make_client(transport: MockTransport) -> AtprotoClient:
    transport.push(LOGIN_RESPONSE)
    return AtprotoClient("https://bsky.social", "handle.bsky.social", "password", _session=transport)


# ---------------------------------------------------------------------------
# Front matter → record mapping
# ---------------------------------------------------------------------------


class TestParsePost:
    def test_slug_with_underscores_preserved(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-04-favorite_books_of_2025.md"
        f.write_text("---\ntitle: My Post\n---\nContent")
        rec = parse_post(f)
        assert rec is not None
        assert rec["path"] == "/blog/favorite_books_of_2025/"

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

    def test_date_object_in_front_matter(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-06-15-some_post.md"
        f.write_text("---\ntitle: Post\ndate: 2024-03-01\n---\n")
        rec = parse_post(f)
        assert rec is not None
        assert rec["publishedAt"].startswith("2024")

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

    def test_draft_skipped_draft_true(self, tmp_path: Path) -> None:
        f = tmp_path / "2025-01-01-post.md"
        f.write_text("---\ntitle: Post\ndraft: true\n---\n")
        assert parse_post(f) is None

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
        assert _extract_rkey("at://did:plc:abc/site.standard.document/3mpwdqt4xn42j") == "3mpwdqt4xn42j"

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
            "records": [{"uri": DOC_URI, "value": {"path": "/blog/a/", "$type": "site.standard.document"}}],
            "cursor": "cursor1",
        }
        page2 = {
            "records": [{"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"), "value": {"path": "/blog/b/", "$type": "site.standard.document"}}],
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
# sync_posts: create / update / skip decisions
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

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

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
        transport.push({
            "records": [{"uri": DOC_URI, "value": remote_rec}],
        })

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        create_or_put = [c for c in transport.calls if "createRecord" in c[1] or "putRecord" in c[1]]
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
        transport.push({
            "records": [{"uri": DOC_URI, "value": remote_rec}],
        })
        transport.push({})  # putRecord response

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        put_calls = [c for c in transport.calls if "putRecord" in c[1]]
        assert len(put_calls) == 1


# ---------------------------------------------------------------------------
# sync_posts: update preserves unmanaged fields and sets updatedAt
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
        transport.push({"records": [{"uri": DOC_URI, "value": remote_rec}]})
        transport.push({})  # putRecord

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

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
        transport.push({"records": [{"uri": DOC_URI, "value": remote_rec}]})
        transport.push({})

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        put_call = next(c for c in transport.calls if "putRecord" in c[1])
        sent_record = put_call[2]["record"]
        assert "updatedAt" in sent_record


# ---------------------------------------------------------------------------
# sync_posts: duplicate remote path aborts
# ---------------------------------------------------------------------------


class TestDuplicateRemotePath:
    def test_duplicate_path_exits(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        dupe_records = [
            {"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/alpha/"}},
            {"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2"), "value": {"site": PUB_URI, "path": "/blog/alpha/"}},
        ]
        transport.push({"records": dupe_records})

        with pytest.raises(SystemExit) as exc_info:
            sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)
        assert exc_info.value.code == 1


# ---------------------------------------------------------------------------
# sync_posts: orphan remote record warns, is not deleted
# ---------------------------------------------------------------------------


class TestOrphanRecord:
    def test_orphan_warns_not_deleted(self, tmp_path: Path, capsys) -> None:
        transport = MockTransport()
        client = make_client(transport)
        transport.push({
            "records": [{"uri": DOC_URI, "value": {"site": PUB_URI, "path": "/blog/gone/"}}],
        })

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        stderr = capsys.readouterr().err
        assert "orphan" in stderr.lower()
        assert "/blog/gone/" in stderr

        delete_calls = [c for c in transport.calls if "deleteRecord" in c[1]]
        assert len(delete_calls) == 0


# ---------------------------------------------------------------------------
# sync_posts: data file contents
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
        sync_posts(client, tmp_path, data_out, PUB_URI)

        result = json.loads(data_out.read_text())
        assert "/blog/alpha/" in result
        assert result["/blog/alpha/"] == "at://did:plc:test123/site.standard.document/newrkey"

    def test_dry_run_writes_existing_records_only(self, tmp_path: Path) -> None:
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
        sync_posts(client, tmp_path, data_out, PUB_URI, dry_run=True)

        result = json.loads(data_out.read_text())
        assert "/blog/existing/" in result
        assert "/blog/new/" not in result

    def test_data_file_sorted_by_path(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-zzz.md").write_text("---\ntitle: Z\n---\n")
        (tmp_path / "2025-01-02-aaa.md").write_text("---\ntitle: A\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk1"})
        transport.push({"uri": "at://did:plc:test123/site.standard.document/rk2"})

        data_out = tmp_path / "out.json"
        sync_posts(client, tmp_path, data_out, PUB_URI)

        keys = list(json.loads(data_out.read_text()).keys())
        assert keys == sorted(keys)


# ---------------------------------------------------------------------------
# Missing env vars
# ---------------------------------------------------------------------------


class TestEnvVars:
    def test_missing_bsky_handle_exits(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        with pytest.raises(SystemExit) as exc_info:
            _get_env("BSKY_HANDLE")
        assert exc_info.value.code == 1

    def test_missing_bsky_app_password_exits(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        with pytest.raises(SystemExit) as exc_info:
            _get_env("BSKY_APP_PASSWORD")
        assert exc_info.value.code == 1

    def test_present_env_var_returns_value(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("BSKY_HANDLE", "alexgude.com")
        assert _get_env("BSKY_HANDLE") == "alexgude.com"


# ---------------------------------------------------------------------------
# init-publication
# ---------------------------------------------------------------------------


class TestInitPublication:
    def test_creates_publication_record(self, tmp_path: Path) -> None:
        config = {}
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"uri": PUB_URI})

        init_publication(client, config)

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 1

    def test_refuses_if_uri_already_set(self, tmp_path: Path) -> None:
        config = {"standard_site": {"publication_uri": PUB_URI}}
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(SystemExit) as exc_info:
            init_publication(client, config)
        assert exc_info.value.code == 1


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
    def test_sync_posts_requires_publication_uri(self, tmp_path: Path) -> None:
        transport = MockTransport()
        client = make_client(transport)
        with pytest.raises(SystemExit) as exc_info:
            sync_posts(client, tmp_path, tmp_path / "out.json", "")
        assert exc_info.value.code == 1

    def test_created_records_include_site(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        transport.push({"records": []})
        transport.push({"uri": DOC_URI})

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        create_call = next(c for c in transport.calls if "createRecord" in c[1])
        assert create_call[2]["record"]["site"] == PUB_URI

    def test_records_from_other_publications_ignored(
        self, tmp_path: Path, capsys
    ) -> None:
        # A Leaflet/pckt document sharing our collection must not collide
        # with our paths, trip duplicate detection, or count as an orphan.
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: Alpha\n---\n")
        transport = MockTransport()
        client = make_client(transport)
        other = {"site": "at://did:plc:other/site.standard.publication/x", "path": "/blog/alpha/"}
        transport.push({"records": [{"uri": DOC_URI, "value": other}]})
        transport.push({"uri": DOC_URI.replace("rkeydoc1", "rkeydoc2")})

        sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)

        create_calls = [c for c in transport.calls if "createRecord" in c[1]]
        assert len(create_calls) == 1
        assert "orphan" not in capsys.readouterr().err.lower()

    def test_main_publish_skips_cleanly_when_unconfigured(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch, capsys
    ) -> None:
        # Pre-Phase-3 rollout safety: no config → no credentials needed,
        # empty data file written, exit 0.
        monkeypatch.setattr(publish, "load_config", lambda: {})
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        data_out = tmp_path / "out.json"

        publish.main(
            ["publish", "--posts-dir", str(tmp_path), "--data-out", str(data_out)]
        )

        assert json.loads(data_out.read_text()) == {}
        assert "skipping publish" in capsys.readouterr().err


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
        import yaml as yaml_mod
        with pytest.raises(yaml_mod.YAMLError):
            _extract_frontmatter_strict("---\n: bad: yaml: [\n---\n")

    def test_no_frontmatter_returns_empty(self) -> None:
        assert _extract_frontmatter_strict("No front matter") == {}


# ---------------------------------------------------------------------------
# validate_posts
# ---------------------------------------------------------------------------


class TestValidatePosts:
    def _post(self, tmp_path: Path, name: str, content: str) -> Path:
        f = tmp_path / name
        f.write_text(content)
        return f

    def test_valid_post_passes(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-valid.md", "---\ntitle: Valid Post\n---\nContent")
        assert validate_posts(tmp_path) is True

    def test_empty_directory_passes(self, tmp_path: Path) -> None:
        assert validate_posts(tmp_path) is True

    def test_non_post_files_ignored(self, tmp_path: Path) -> None:
        self._post(tmp_path, "about.md", "---\ntitle: ''\n---\n")
        assert validate_posts(tmp_path) is True

    # --- YAML errors ---

    def test_invalid_yaml_fails(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-bad.md", "---\n: bad: yaml: [\n---\nContent")
        assert validate_posts(tmp_path) is False

    def test_invalid_yaml_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-bad.md", "---\n: bad: yaml: [\n---\nContent")
        validate_posts(tmp_path)
        assert "2025-01-01-bad.md" in capsys.readouterr().err

    # --- Missing / empty title ---

    def test_missing_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-no-title.md", "---\ndescription: No title\n---\n")
        assert validate_posts(tmp_path) is False

    def test_missing_title_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-no-title.md", "---\ndescription: No title\n---\n")
        validate_posts(tmp_path)
        assert "2025-01-01-no-title.md" in capsys.readouterr().err

    def test_empty_string_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-empty.md", "---\ntitle: ''\n---\n")
        assert validate_posts(tmp_path) is False

    def test_whitespace_only_title_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-spaces.md", "---\ntitle: '   '\n---\n")
        assert validate_posts(tmp_path) is False

    # --- Underivable date ---

    def test_non_date_string_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-bad-date.md", "---\ntitle: Post\ndate: 'not a date'\n---\n")
        assert validate_posts(tmp_path) is False

    def test_non_date_string_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-bad-date.md", "---\ntitle: Post\ndate: 'not a date'\n---\n")
        validate_posts(tmp_path)
        assert "2025-01-01-bad-date.md" in capsys.readouterr().err

    def test_null_date_passes(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-null-date.md", "---\ntitle: Post\ndate:\n---\n")
        assert validate_posts(tmp_path) is True

    def test_date_object_passes(self, tmp_path: Path) -> None:
        # YAML parses bare 2025-01-01 as a datetime.date object
        self._post(tmp_path, "2025-01-01-real-date.md", "---\ntitle: Post\ndate: 2025-01-01\n---\n")
        assert validate_posts(tmp_path) is True

    # --- Duplicate path ---

    def test_duplicate_path_fails(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha 1\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha 2\n---\n")
        assert validate_posts(tmp_path) is False

    def test_duplicate_path_names_file(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha 1\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha 2\n---\n")
        validate_posts(tmp_path)
        assert "alpha" in capsys.readouterr().err

    def test_draft_does_not_create_duplicate(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-alpha.md", "---\ntitle: Alpha\npublished: false\n---\n")
        self._post(tmp_path, "2025-06-15-alpha.md", "---\ntitle: Alpha\n---\n")
        assert validate_posts(tmp_path) is True

    # --- slug / permalink warnings ---

    def test_slug_warns_exits_zero(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\nslug: custom\n---\n")
        assert validate_posts(tmp_path) is True
        assert "WARNING" in capsys.readouterr().err.upper()

    def test_permalink_warns_exits_zero(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\npermalink: /custom/\n---\n")
        assert validate_posts(tmp_path) is True
        assert "WARNING" in capsys.readouterr().err.upper()

    # --- Draft skipping ---

    def test_published_false_skips_title_check(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-draft.md", "---\ntitle: ''\npublished: false\n---\n")
        assert validate_posts(tmp_path) is True

    def test_draft_true_skips_title_check(self, tmp_path: Path) -> None:
        self._post(tmp_path, "2025-01-01-draft.md", "---\ntitle: ''\ndraft: true\n---\n")
        assert validate_posts(tmp_path) is True

    # --- Multiple errors all reported ---

    def test_multiple_errors_all_reported(self, tmp_path: Path, capsys) -> None:
        self._post(tmp_path, "2025-01-01-a.md", "---\ntitle: ''\n---\n")
        self._post(tmp_path, "2025-01-02-b.md", "---\ntitle: ''\n---\n")
        validate_posts(tmp_path)
        err = capsys.readouterr().err
        assert "2025-01-01-a.md" in err
        assert "2025-01-02-b.md" in err

    # --- No HTTP calls ---

    def test_no_http_transport_needed(self, tmp_path: Path) -> None:
        # validate_posts takes only a Path — no AtprotoClient is created.
        # If it tried to make HTTP calls, requests would error without mocking.
        self._post(tmp_path, "2025-01-01-post.md", "---\ntitle: Post\n---\n")
        assert validate_posts(tmp_path) is True


# ---------------------------------------------------------------------------
# validate via main() CLI — no credentials required
# ---------------------------------------------------------------------------


class TestValidateViaCLI:
    def test_valid_posts_exit_zero(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        (tmp_path / "2025-01-01-good.md").write_text("---\ntitle: Good\n---\n")
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        publish.main(["validate", "--posts-dir", str(tmp_path)])

    def test_invalid_post_exits_one(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        (tmp_path / "2025-01-01-bad.md").write_text("---\ntitle: ''\n---\n")
        monkeypatch.delenv("BSKY_HANDLE", raising=False)
        monkeypatch.delenv("BSKY_APP_PASSWORD", raising=False)
        with pytest.raises(SystemExit) as exc_info:
            publish.main(["validate", "--posts-dir", str(tmp_path)])
        assert exc_info.value.code == 1

# ---------------------------------------------------------------------------
# sync_posts local-post guards (defense in depth alongside validate)
# ---------------------------------------------------------------------------


class TestSyncPostsLocalGuards:
    def test_empty_title_exits(self, tmp_path: Path) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: ''\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(SystemExit) as exc_info:
            sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)
        assert exc_info.value.code == 1

    def test_missing_title_exits(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\nlayout: post\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(SystemExit):
            sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)
        assert "2025-01-01-alpha.md" in capsys.readouterr().err

    def test_duplicate_local_path_exits(self, tmp_path: Path, capsys) -> None:
        (tmp_path / "2025-01-01-alpha.md").write_text("---\ntitle: One\n---\n")
        (tmp_path / "2025-06-15-alpha.md").write_text("---\ntitle: Two\n---\n")
        transport = MockTransport()
        client = make_client(transport)

        with pytest.raises(SystemExit) as exc_info:
            sync_posts(client, tmp_path, tmp_path / "out.json", PUB_URI)
        assert exc_info.value.code == 1
        err = capsys.readouterr().err
        assert "2025-01-01-alpha.md" in err
        assert "2025-06-15-alpha.md" in err
