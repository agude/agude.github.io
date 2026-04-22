"""Tests for metadata/format_isbn.py pure functions."""

import pytest

from format_isbn import extract_isbn, format_isbn


class TestFormatIsbn:
    def test_formats_isbn13_without_hyphens(self):
        result = format_isbn("9780316769488")
        assert result == "978-0-316-76948-8"

    def test_formats_isbn13_with_wrong_hyphens(self):
        result = format_isbn("978-031-676-9488")
        assert result == "978-0-316-76948-8"

    def test_converts_isbn10_to_isbn13(self):
        result = format_isbn("0316769487")
        assert result.startswith("978-")
        assert len(result) == 17  # ISBN-13 with hyphens

    def test_invalid_isbn_returns_none(self):
        assert format_isbn("1234567890") is None
        assert format_isbn("notanisbn") is None
        assert format_isbn("") is None

    def test_already_formatted_unchanged(self):
        isbn = "978-0-316-76948-8"
        result = format_isbn(isbn)
        assert result == isbn


class TestExtractIsbn:
    def test_extracts_simple_isbn(self):
        fm = "title: Test\nisbn: 9780316769488\n"
        assert extract_isbn("test.md", fm) == "9780316769488"

    def test_extracts_quoted_isbn(self):
        fm = 'isbn: "978-0-316-76948-8"\n'
        assert extract_isbn("test.md", fm) == "978-0-316-76948-8"

    def test_null_returns_none(self):
        fm = "isbn: null\n"
        assert extract_isbn("test.md", fm) is None

    def test_missing_isbn_returns_none(self):
        fm = "title: Test\nauthor: Someone\n"
        assert extract_isbn("test.md", fm) is None

    def test_handles_malformed_yaml(self):
        # Regex fallback requires `isbn:` at start of line
        fm = "title: Test\nisbn: 123\nfoo:\tbar\n"  # tabs in values trigger YAML error
        result = extract_isbn("test.md", fm)
        assert result == "123"
