"""Tests for _scripts/metadata/update_book_metadata.py."""

from textwrap import dedent

import pytest

from update_book_metadata import (
    MANAGED_FIELDS,
    _strip_field,
    extract_front_matter_keys,
    format_field,
    strip_managed_fields,
)


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


class TestStripManagedFields:
    def test_strips_all_managed_fields(self):
        front_matter = dedent("""\
            title: Test
            wikidata_qid: Q123
            isbn: 978-0-123
            date_published: 2020
            awards:
              - hugo
            same_as_urls:
              - https://example.com
            rating: 5
            """)
        result = strip_managed_fields(front_matter)
        assert "wikidata_qid" not in result
        assert "isbn" not in result
        assert "date_published" not in result
        assert "awards" not in result
        assert "same_as_urls" not in result
        assert "title: Test" in result
        assert "rating: 5" in result

    def test_preserves_non_managed_fields(self):
        front_matter = dedent("""\
            title: Test Book
            book_authors: Author Name
            series: Test Series
            rating: 5
            """)
        result = strip_managed_fields(front_matter)
        assert "title: Test Book" in result
        assert "book_authors: Author Name" in result
        assert "series: Test Series" in result
        assert "rating: 5" in result


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


class TestOnlyFlagBehavior:
    """Tests for --only flag logic (tested via helper functions)."""

    def test_only_awards_filters_to_awards(self):
        only_fields = {"awards"}
        candidates = [f for f in MANAGED_FIELDS if f in only_fields]
        assert candidates == ["awards"]

    def test_only_multiple_fields(self):
        only_fields = {"awards", "isbn"}
        candidates = [f for f in MANAGED_FIELDS if f in only_fields]
        assert set(candidates) == {"isbn", "awards"}

    def test_invalid_field_detected(self):
        only_fields = {"awards", "invalid_field"}
        invalid = only_fields - set(MANAGED_FIELDS)
        assert invalid == {"invalid_field"}


class TestNeverOverwriteWithNull:
    """Tests for the never-overwrite-with-null logic."""

    def test_null_skipped_when_existing(self):
        metadata = {"awards": None, "isbn": "978-0-123"}
        existing = {"awards": ""}  # awards key exists

        # Should skip awards (would overwrite with null), include isbn
        fields_to_write = [
            f for f in ["awards", "isbn"]
            if metadata[f] is not None or f not in existing
        ]
        assert "awards" not in fields_to_write
        assert "isbn" in fields_to_write

    def test_null_allowed_when_not_existing(self):
        metadata = {"awards": None, "isbn": None}
        existing = {}  # No existing fields

        # Both would be candidates (null but not overwriting)
        fields_to_write = [
            f for f in ["awards", "isbn"]
            if metadata[f] is not None or f not in existing
        ]
        # But format_field returns "" for awards=None, so it gets filtered later
        assert "awards" in fields_to_write
        assert "isbn" in fields_to_write

    def test_non_null_overwrites_existing(self):
        metadata = {"awards": ["hugo"], "isbn": "978-0-123"}
        existing = {"awards": "", "isbn": "old-isbn"}

        fields_to_write = [
            f for f in ["awards", "isbn"]
            if metadata[f] is not None or f not in existing
        ]
        assert "awards" in fields_to_write
        assert "isbn" in fields_to_write
