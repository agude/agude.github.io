"""Tests for ranking/reorder_ranking.py pure functions."""

import pytest

from reorder_ranking import format_title_for_yaml, parse_ranked_list


class TestFormatTitleForYaml:
    def test_plain_title(self):
        assert format_title_for_yaml("Hyperion") == "Hyperion"

    def test_title_with_colon_gets_quoted(self):
        result = format_title_for_yaml("Star Wars: A New Hope")
        assert result == '"Star Wars: A New Hope"'

    def test_title_starting_with_quote(self):
        result = format_title_for_yaml('"Repent, Harlequin!"')
        assert result.startswith('"')


class TestParseRankedList:
    def test_parses_titles(self, tmp_path):
        content = (
            "---\n"
            "layout: page\n"
            "ranked_list:\n"
            "  # 5 Stars\n"
            "  - Hyperion\n"
            "  - Dune\n"
            "  # 4 Stars\n"
            "  - Foundation\n"
            "---\n"
            "Body text.\n"
        )
        path = tmp_path / "by_rating.md"
        path.write_text(content)
        titles = parse_ranked_list(path)
        assert titles == ["Hyperion", "Dune", "Foundation"]

    def test_handles_quoted_titles(self, tmp_path):
        content = '---\nranked_list:\n  - "A Book: With Colon"\n---\n'
        path = tmp_path / "by_rating.md"
        path.write_text(content)
        titles = parse_ranked_list(path)
        assert titles == ["A Book: With Colon"]

    def test_empty_ranked_list(self, tmp_path):
        content = "---\nranked_list:\n---\nBody.\n"
        path = tmp_path / "by_rating.md"
        path.write_text(content)
        titles = parse_ranked_list(path)
        assert titles == []

    def test_missing_ranked_list_key(self, tmp_path):
        content = "---\nlayout: page\n---\nBody.\n"
        path = tmp_path / "by_rating.md"
        path.write_text(content)
        titles = parse_ranked_list(path)
        assert titles == []

    def test_missing_front_matter_exits(self, tmp_path):
        path = tmp_path / "by_rating.md"
        path.write_text("No front matter at all.")
        with pytest.raises(SystemExit):
            parse_ranked_list(path)
