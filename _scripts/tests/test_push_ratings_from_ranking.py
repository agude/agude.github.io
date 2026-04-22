"""Tests for ranking/push_ratings_from_ranking.py pure functions."""

import tempfile
from pathlib import Path
from textwrap import dedent

from push_ratings_from_ranking import parse_ranked_list_with_tiers


class TestParseRankedListWithTiers:
    def test_parses_simple_list(self):
        content = dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - Book One
              - Book Two
              # 4 Stars
              - Book Three
            ---
            """)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(content)
            f.flush()
            result = parse_ranked_list_with_tiers(Path(f.name))

        assert result == [
            ("Book One", 5),
            ("Book Two", 5),
            ("Book Three", 4),
        ]

    def test_handles_quoted_titles(self):
        content = dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - "Book: A Story"
              - 'Another Book'
            ---
            """)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(content)
            f.flush()
            result = parse_ranked_list_with_tiers(Path(f.name))

        assert result[0] == ("Book: A Story", 5)
        assert result[1] == ("Another Book", 5)

    def test_handles_all_star_tiers(self):
        content = dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - Five Star Book
              # 4 Stars
              - Four Star Book
              # 3 Stars
              - Three Star Book
              # 2 Stars
              - Two Star Book
              # 1 Star
              - One Star Book
            ---
            """)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(content)
            f.flush()
            result = parse_ranked_list_with_tiers(Path(f.name))

        assert len(result) == 5
        assert result[0][1] == 5
        assert result[1][1] == 4
        assert result[2][1] == 3
        assert result[3][1] == 2
        assert result[4][1] == 1

    def test_empty_list(self):
        content = dedent("""\
            ---
            ranked_list:
            ---
            """)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(content)
            f.flush()
            result = parse_ranked_list_with_tiers(Path(f.name))

        assert result == []

    def test_ignores_blank_lines(self):
        content = dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - Book One

              - Book Two
            ---
            """)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write(content)
            f.flush()
            result = parse_ranked_list_with_tiers(Path(f.name))

        assert len(result) == 2
