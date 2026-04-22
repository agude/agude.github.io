"""Tests for content/backdate_rating.py pure functions."""

from backdate_rating import extract_rating, format_datetime, parse_rating


class TestParseRating:
    def test_parses_integer(self):
        assert parse_rating("5") == 5
        assert parse_rating("1") == 1

    def test_strips_whitespace(self):
        assert parse_rating("  4  ") == 4

    def test_strips_quotes(self):
        assert parse_rating('"3"') == 3
        assert parse_rating("'2'") == 2

    def test_null_returns_none(self):
        assert parse_rating("null") is None
        assert parse_rating("nil") is None
        assert parse_rating("~") is None

    def test_empty_returns_none(self):
        assert parse_rating("") is None
        assert parse_rating("   ") is None

    def test_invalid_returns_none(self):
        assert parse_rating("abc") is None
        assert parse_rating("3.5") is None


class TestExtractRating:
    def test_extracts_simple_rating(self):
        content = "---\ntitle: Test\nrating: 4\n---\n"
        assert extract_rating(content) == 4

    def test_extracts_null_as_none(self):
        content = "---\ntitle: Test\nrating: null\n---\n"
        assert extract_rating(content) is None

    def test_no_rating_returns_none(self):
        content = "---\ntitle: Test\n---\n"
        assert extract_rating(content) is None

    def test_handles_whitespace(self):
        content = "rating:    5   \n"
        assert extract_rating(content) == 5


class TestFormatDatetime:
    def test_formats_iso_datetime(self):
        result = format_datetime("2024-03-15T10:30:00-07:00")
        assert result == "2024-03-15 10:30:00 -0700"

    def test_formats_utc(self):
        result = format_datetime("2024-01-01T00:00:00+00:00")
        assert result == "2024-01-01 00:00:00 +0000"
