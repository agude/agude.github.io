"""Tests for .claude/skills/stub-book/scripts/stub_book.py pure functions."""

from unittest.mock import patch
import subprocess

import yaml

from stub_book import (
    build_front_matter,
    build_opening,
    fetch_metadata,
    ordinal,
    snake_case,
)


def parse_front_matter(text: str) -> dict:
    """Extract and parse YAML from between --- delimiters."""
    parts = text.split("---")
    # parts[0] is empty (before first ---), parts[1] is the YAML content
    return yaml.safe_load(parts[1])


class TestSnakeCase:
    def test_simple_title(self):
        assert snake_case("Hyperion") == "hyperion"

    def test_multi_word(self):
        assert snake_case("The Honor of the Queen") == "the_honor_of_the_queen"

    def test_apostrophe_stripped(self):
        assert snake_case("Ender's Game") == "enders_game"

    def test_colon_stripped(self):
        assert snake_case("Star Wars: A New Hope") == "star_wars_a_new_hope"

    def test_leading_trailing_whitespace(self):
        assert snake_case("  Dune  ") == "dune"

    def test_multiple_spaces_collapsed(self):
        assert snake_case("The   Long    Way") == "the_long_way"

    def test_unicode_preserved(self):
        assert snake_case("Tête-à-Tête") == "têteàtête"


class TestOrdinal:
    def test_first_through_third(self):
        assert ordinal(1) == "first"
        assert ordinal(2) == "second"
        assert ordinal(3) == "third"

    def test_spelled_out_up_to_twelve(self):
        assert ordinal(10) == "tenth"
        assert ordinal(12) == "twelfth"

    def test_thirteen_uses_suffix(self):
        assert ordinal(13) == "13th"

    def test_teens_use_th(self):
        assert ordinal(11) == "eleventh"  # spelled out
        assert ordinal(14) == "14th"

    def test_twenty_first(self):
        assert ordinal(21) == "21st"

    def test_twenty_second(self):
        assert ordinal(22) == "22nd"

    def test_twenty_third(self):
        assert ordinal(23) == "23rd"

    def test_twenty_fourth(self):
        assert ordinal(24) == "24th"

    def test_hundred_eleventh(self):
        # 111 should use "th" (teen exception applies to mod 100)
        assert ordinal(111) == "111th"

    def test_hundred_twelve(self):
        assert ordinal(112) == "112th"

    def test_hundred_thirteen(self):
        assert ordinal(113) == "113th"

    def test_hundred_twenty_one(self):
        assert ordinal(121) == "121st"

    def test_large_number(self):
        assert ordinal(1000) == "1000th"


class TestBuildFrontMatter:
    def test_minimal_no_metadata(self):
        result = build_front_matter(
            title="Some Book",
            author="Some Author",
            series=None,
            book_number=None,
            qid=None,
            metadata={},
        )
        parsed = parse_front_matter(result)
        assert parsed["title"] == "Some Book"
        assert parsed["book_authors"] == "Some Author"
        assert parsed["series"] is None
        assert parsed["book_number"] is None
        assert parsed["rating"] is None
        assert parsed["image"] == "/books/covers/some_book.jpg"
        assert "wikidata_qid" not in parsed
        assert "isbn" not in parsed

    def test_with_qid_and_metadata(self):
        result = build_front_matter(
            title="Hyperion",
            author="Dan Simmons",
            series="Hyperion Cantos",
            book_number=1,
            qid="Q302026",
            metadata={
                "isbn": "978-0-553-28368-3",
                "date_published": "1989-05",
                "same_as_urls": [
                    "https://www.wikidata.org/wiki/Q302026",
                    "https://en.wikipedia.org/wiki/Hyperion_(Simmons_novel)",
                ],
            },
        )
        parsed = parse_front_matter(result)
        assert parsed["wikidata_qid"] == "Q302026"
        assert parsed["isbn"] == "978-0-553-28368-3"
        assert parsed["date_published"] == "1989-05"
        assert len(parsed["same_as_urls"]) == 2

    def test_front_matter_delimiters(self):
        result = build_front_matter(
            title="Test",
            author="Author",
            series=None,
            book_number=None,
            qid=None,
            metadata={},
        )
        lines = result.splitlines()
        assert lines[0] == "---"
        assert lines[-1] == "---"


class TestBuildOpening:
    def test_standalone(self):
        result = build_opening(series=None, book_number=None)
        assert "is ..." in result
        assert "series_text" not in result

    def test_series_with_number(self):
        result = build_opening(series="Honor Harrington", book_number=2)
        assert "second book" in result
        assert "series_text" in result

    def test_series_without_number(self):
        result = build_opening(series="Honor Harrington", book_number=None)
        assert "a book in" in result

    def test_large_book_number(self):
        result = build_opening(series="Discworld", book_number=41)
        assert "41st book" in result


class TestFetchMetadata:
    def test_success(self):
        fake_stdout = (
            "# Hyperion\n"
            "isbn: 978-0-553-28368-3\n"
            "date_published: 1989-05\n"
            "same_as_urls:\n"
            '  - "https://www.wikidata.org/wiki/Q302026"\n'
        )
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout=fake_stdout, stderr=""
            )
            result = fetch_metadata("Q302026")

        assert result["isbn"] == "978-0-553-28368-3"
        assert result["date_published"] == "1989-05"
        assert result["same_as_urls"] == ["https://www.wikidata.org/wiki/Q302026"]

    def test_failure_returns_empty(self):
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=1, stdout="", stderr="error"
            )
            result = fetch_metadata("Q999999")

        assert result == {}

    def test_malformed_yaml_returns_empty(self):
        with patch("stub_book.subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=[], returncode=0, stdout="{{bad yaml", stderr=""
            )
            result = fetch_metadata("Q123")

        assert result == {}
