"""Tests for _scripts/metadata/update_book_metadata.py."""

import datetime
import sys
from textwrap import dedent
from unittest.mock import patch

import pytest
import update_book_metadata
import yaml
from update_book_metadata import (
    MANAGED_FIELDS,
    _strip_field,
    extract_front_matter_keys,
    format_field,
)
from wikidata_fake import BOOK_GRAPH, FakeWikidataApi


class TestExtractFrontMatterKeys:
    def test_extracts_simple_values(self):
        front_matter = dedent("""\
            title: Test Book
            rating: 5
            """)
        result = extract_front_matter_keys(front_matter)
        assert result["title"] == "Test Book"
        assert result["rating"] == "5"

    def test_strips_quotes(self):
        front_matter = dedent("""\
            title: "Quoted Title"
            author: 'Single Quoted'
            """)
        result = extract_front_matter_keys(front_matter)
        assert result["title"] == "Quoted Title"
        assert result["author"] == "Single Quoted"

    def test_handles_null_value(self):
        front_matter = "isbn: null\n"
        result = extract_front_matter_keys(front_matter)
        assert result["isbn"] == "null"

    def test_ignores_list_items(self):
        front_matter = dedent("""\
            awards:
              - hugo
              - nebula
            title: Test
            """)
        result = extract_front_matter_keys(front_matter)
        # awards key exists but value is empty (list continuation not captured)
        assert "awards" in result
        assert result["title"] == "Test"

    def test_handles_colons_in_values(self):
        front_matter = 'url: "https://example.com"\n'
        result = extract_front_matter_keys(front_matter)
        assert result["url"] == "https://example.com"


class TestFormatField:
    def test_simple_string(self):
        result = format_field("title", "Test Book")
        assert result == "title: Test Book"

    def test_string_needing_quotes(self):
        result = format_field("title", "Book: A Story")
        assert result == 'title: "Book: A Story"'

    def test_null_value(self):
        result = format_field("isbn", None)
        assert result == "isbn: null"

    def test_awards_list(self):
        result = format_field("awards", ["hugo", "nebula"])
        expected = "awards:\n  - hugo\n  - nebula"
        assert result == expected

    def test_awards_empty_returns_empty_string(self):
        result = format_field("awards", [])
        assert result == ""

    def test_awards_none_returns_empty_string(self):
        result = format_field("awards", None)
        assert result == ""

    def test_same_as_urls_list(self):
        result = format_field("same_as_urls", ["https://example.com", "https://test.com"])
        assert "same_as_urls:" in result
        # URLs contain colons so they get quoted
        assert '"https://example.com"' in result
        assert '"https://test.com"' in result

    def test_same_as_urls_quotes_special_chars(self):
        result = format_field("same_as_urls", ["https://example.com?foo=bar"])
        assert '"https://example.com?foo=bar"' in result


class TestFormatFieldTypes:
    @pytest.mark.parametrize("value", ["0316769487", "no", "null", "true", "123"])
    def test_string_values_round_trip(self, value):
        assert yaml.safe_load(format_field("isbn", value)) == {"isbn": value}

    def test_award_slugs_round_trip(self):
        parsed = yaml.safe_load(format_field("awards", ["hugo", "no"]))
        assert parsed == {"awards": ["hugo", "no"]}

    def test_full_date_keeps_date_type(self):
        parsed = yaml.safe_load(format_field("date_published", "2021-03-02"))
        assert parsed == {"date_published": datetime.date(2021, 3, 2)}

    def test_year_keeps_integer_type(self):
        assert yaml.safe_load(format_field("date_published", "1965")) == {"date_published": 1965}


class TestStripField:
    def test_strips_simple_field(self):
        front_matter = dedent("""\
            title: Test
            isbn: 123
            rating: 5
            """)
        result = _strip_field(front_matter, "isbn")
        assert "isbn" not in result
        assert "title: Test" in result
        assert "rating: 5" in result

    def test_strips_list_field(self):
        front_matter = dedent("""\
            title: Test
            awards:
              - hugo
              - nebula
            rating: 5
            """)
        result = _strip_field(front_matter, "awards")
        assert "awards" not in result
        assert "hugo" not in result
        assert "nebula" not in result
        assert "title: Test" in result
        assert "rating: 5" in result

    def test_no_double_newlines_after_strip(self):
        front_matter = dedent("""\
            title: Test
            awards:
              - hugo
            rating: 5
            """)
        result = _strip_field(front_matter, "awards")
        assert "\n\n" not in result

    def test_strips_field_at_end(self):
        front_matter = dedent("""\
            title: Test
            isbn: 123
            """)
        result = _strip_field(front_matter, "isbn")
        assert "isbn" not in result
        assert "title: Test" in result

    def test_field_not_present_unchanged(self):
        front_matter = "title: Test\n"
        result = _strip_field(front_matter, "isbn")
        assert result == "title: Test\n"


class TestManagedFieldsConstant:
    def test_contains_expected_fields(self):
        assert "wikidata_qid" in MANAGED_FIELDS
        assert "isbn" in MANAGED_FIELDS
        assert "date_published" in MANAGED_FIELDS
        assert "awards" in MANAGED_FIELDS
        assert "same_as_urls" in MANAGED_FIELDS

    def test_awards_before_same_as_urls(self):
        # Awards should come before same_as_urls in output order
        awards_idx = MANAGED_FIELDS.index("awards")
        urls_idx = MANAGED_FIELDS.index("same_as_urls")
        assert awards_idx < urls_idx


class TestMetadataSelection:
    def test_search_does_not_select_a_candidate(self, tmp_path, monkeypatch, capsys):
        book_file = tmp_path / "book.md"
        original = dedent("""\
            ---
            title: Hyperion
            book_authors: Dan Simmons
            rating: 5
            ---
            Review text.
            """)
        book_file.write_text(original, encoding="utf-8")
        candidates = [
            {
                "id": "Q1",
                "label": "Hyperion",
                "description": "novel by Dan Simmons",
                "aliases": [],
            },
            {
                "id": "Q2",
                "label": "Hyperion (film)",
                "description": "unrelated film",
                "aliases": [],
            },
        ]
        monkeypatch.setattr(
            sys,
            "argv",
            ["update_book_metadata.py", str(book_file)],
        )

        with (
            patch("update_book_metadata.search_book_entity", return_value=candidates),
            patch("update_book_metadata.fetch_metadata") as fetch_mock,
            pytest.raises(SystemExit),
        ):
            update_book_metadata.main()

        fetch_mock.assert_not_called()
        assert book_file.read_text(encoding="utf-8") == original
        assert "Q1" in capsys.readouterr().err

    def test_invalid_explicit_qid_fails_before_write(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        original = "---\ntitle: Hyperion\n---\nReview text.\n"
        book_file.write_text(original, encoding="utf-8")
        monkeypatch.setattr(
            sys,
            "argv",
            ["update_book_metadata.py", str(book_file), "--qid", "not-a-qid"],
        )

        with (
            patch("update_book_metadata.fetch_metadata") as fetch_mock,
            pytest.raises(SystemExit),
        ):
            update_book_metadata.main()

        fetch_mock.assert_not_called()
        assert book_file.read_text(encoding="utf-8") == original

    def test_explicit_qid_is_used_for_writes(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        book_file.write_text("---\ntitle: Hyperion\n---\nReview text.\n", encoding="utf-8")
        metadata = {
            "wikidata_qid": "Q1",
            "isbn": "978-0-553-28368-3",
            "date_published": None,
            "awards": None,
            "same_as_urls": None,
        }
        monkeypatch.setattr(
            sys,
            "argv",
            ["update_book_metadata.py", str(book_file), "--qid", "Q1"],
        )

        with patch("update_book_metadata.fetch_metadata", return_value=metadata) as fetch_mock:
            update_book_metadata.main()

        fetch_mock.assert_called_once_with("Q1")
        content = book_file.read_text(encoding="utf-8")
        assert "wikidata_qid: Q1" in content
        assert 'isbn: "978-0-553-28368-3"' in content


class TestFetchMetadata:
    def test_same_as_urls_exclude_wikidata_url(self):
        # The site builds the Wikidata link from wikidata_qid; a Wikidata URL
        # in same_as_urls fails the build.
        entity = {
            "sitelinks": {"enwiki": {"title": "Hyperion (Simmons novel)"}},
            "claims": {"P212": [{"mainsnak": {"datavalue": {"value": "978-0-553-28368-3"}}}]},
        }
        with (
            patch("update_book_metadata.fetch_entity", return_value=entity),
            patch("update_book_metadata.fetch_awards", return_value=[]),
        ):
            metadata = update_book_metadata.fetch_metadata("Q302026")

        assert metadata["wikidata_qid"] == "Q302026"
        assert metadata["same_as_urls"] == [
            "https://en.wikipedia.org/wiki/Hyperion_%28Simmons_novel%29"
        ]

    def test_fetches_each_entity_once(self):
        # The work has no ISBN, so the ISBN comes from its editions; two of
        # its awards share a parent; one award has no known family.
        api = FakeWikidataApi(BOOK_GRAPH)
        with patch("wikidata_utils.api_get", side_effect=api):
            metadata = update_book_metadata.fetch_metadata("Q1")

        assert metadata == {
            "wikidata_qid": "Q1",
            "isbn": "978-0-000-00000-0",
            "date_published": "1989-05-26",
            "awards": ["hugo"],
            "same_as_urls": ["https://en.wikipedia.org/wiki/Fixture_Novel"],
        }
        assert dict(api.fetched) == dict.fromkeys(
            ["Q1", "Q10", "Q11", "Q20", "Q21", "Q22", "Q30"], 1
        )


NEW_METADATA = {
    "wikidata_qid": "Q1",
    "isbn": "978-0-553-28368-3",
    "date_published": "1989-05-26",
    "awards": ["hugo"],
    "same_as_urls": ["https://new.example/one", "https://new.example/two"],
}


def run_main(monkeypatch, book_file, *flags, metadata=None):
    """Run main() on `book_file` with fetch_metadata mocked; return the mock."""
    monkeypatch.setattr(sys, "argv", ["update_book_metadata.py", str(book_file), *flags])
    with patch(
        "update_book_metadata.fetch_metadata", return_value=dict(metadata or NEW_METADATA)
    ) as fetch_mock:
        update_book_metadata.main()
    return fetch_mock


def front_matter_of(book_file) -> dict:
    return yaml.safe_load(book_file.read_text(encoding="utf-8").split("---", 2)[1])


class TestMainFrontMatterParsing:
    def test_blank_qid_does_not_swallow_next_field(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        original = "---\ntitle: Hyperion\nwikidata_qid:\nisbn: 978-0-553-28368-3\n---\nText.\n"
        book_file.write_text(original, encoding="utf-8")
        monkeypatch.setattr(sys, "argv", ["update_book_metadata.py", str(book_file)])

        with (
            patch("update_book_metadata.search_book_entity", return_value=[]) as search_mock,
            patch("update_book_metadata.fetch_metadata") as fetch_mock,
            pytest.raises(SystemExit),
        ):
            update_book_metadata.main()

        # A blank QID means "search", not "use the next line as the QID".
        search_mock.assert_called_once()
        fetch_mock.assert_not_called()
        assert book_file.read_text(encoding="utf-8") == original

    @pytest.mark.parametrize("indent", ["", "  ", "    "])
    def test_list_fields_are_replaced_at_any_indent(self, tmp_path, monkeypatch, indent):
        book_file = tmp_path / "book.md"
        book_file.write_text(
            "---\ntitle: Hyperion\n"
            f"awards:\n{indent}- locus\n{indent}- nebula\n"
            f"same_as_urls:\n{indent}- https://old.example/one\n{indent}- https://old.example/two\n"
            "rating: 5\n---\nText.\n",
            encoding="utf-8",
        )

        run_main(monkeypatch, book_file, "--qid", "Q1", "--only", "awards,same_as_urls")

        fm = front_matter_of(book_file)
        assert fm["awards"] == ["hugo"]
        assert fm["same_as_urls"] == NEW_METADATA["same_as_urls"]
        assert fm["title"] == "Hyperion"
        assert fm["rating"] == 5
        assert "old.example" not in book_file.read_text(encoding="utf-8")

    def test_comments_and_unmanaged_fields_are_preserved(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        head = "---\n# Review metadata\ntitle: Hyperion\n\n# Ratings\nrating: 5\n"
        book_file.write_text(head + "awards:\n  - locus\n---\nText.\n", encoding="utf-8")

        run_main(monkeypatch, book_file, "--qid", "Q1", "--only", "awards")

        assert book_file.read_text(encoding="utf-8") == head + "awards:\n  - hugo\n---\nText.\n"

    def test_unparseable_result_leaves_file_unchanged(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        original = "---\ntitle: [unclosed\n---\nText.\n"
        book_file.write_text(original, encoding="utf-8")

        with pytest.raises(SystemExit) as excinfo:
            run_main(monkeypatch, book_file, "--qid", "Q1")

        assert excinfo.value.code not in (0, None)
        assert book_file.read_text(encoding="utf-8") == original


class TestMainFieldSelection:
    """Field selection, tested through main() on real files."""

    def test_only_writes_just_the_named_fields(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        book_file.write_text("---\ntitle: Hyperion\nisbn: old\n---\nText.\n", encoding="utf-8")

        run_main(monkeypatch, book_file, "--qid", "Q1", "--only", "awards,isbn")

        fm = front_matter_of(book_file)
        assert fm == {"title": "Hyperion", "isbn": "978-0-553-28368-3", "awards": ["hugo"]}

    def test_unknown_only_field_exits_without_fetching(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        original = "---\ntitle: Hyperion\n---\nText.\n"
        book_file.write_text(original, encoding="utf-8")

        monkeypatch.setattr(
            sys,
            "argv",
            ["update_book_metadata.py", str(book_file), "--qid", "Q1", "--only", "awards,bogus"],
        )

        with (
            patch("update_book_metadata.fetch_metadata") as fetch_mock,
            pytest.raises(SystemExit) as excinfo,
        ):
            update_book_metadata.main()

        assert excinfo.value.code == 1
        fetch_mock.assert_not_called()
        assert book_file.read_text(encoding="utf-8") == original

    def test_force_never_overwrites_existing_value_with_null(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        book_file.write_text(
            "---\ntitle: Hyperion\nawards:\n  - locus\nisbn: old\n---\nText.\n", encoding="utf-8"
        )

        run_main(
            monkeypatch,
            book_file,
            "--qid",
            "Q1",
            "--force",
            metadata={**NEW_METADATA, "awards": None},
        )

        fm = front_matter_of(book_file)
        assert fm["awards"] == ["locus"]
        assert fm["isbn"] == "978-0-553-28368-3"

    def test_default_mode_adds_only_missing_fields(self, tmp_path, monkeypatch):
        book_file = tmp_path / "book.md"
        book_file.write_text(
            "---\ntitle: Hyperion\nwikidata_qid: Q1\nisbn: old\n---\nText.\n", encoding="utf-8"
        )

        run_main(monkeypatch, book_file)

        fm = front_matter_of(book_file)
        assert fm["isbn"] == "old"
        assert fm["awards"] == ["hugo"]
        assert fm["date_published"] == datetime.date(1989, 5, 26)
