"""Tests for ranking/push_ratings_from_ranking.py."""

from textwrap import dedent

import push_ratings_from_ranking
from push_ratings_from_ranking import parse_ranked_list_with_tiers
from ranking_tree import REPO_ROOT, build_tree, point_module_at


class TestParseRankedListWithTiers:
    def test_parses_simple_list(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - Book One
              - Book Two
              # 4 Stars
              - Book Three
            ---
            """)
        )
        result = parse_ranked_list_with_tiers(f)

        assert result == [
            ("Book One", 5),
            ("Book Two", 5),
            ("Book Three", 4),
        ]

    def test_handles_quoted_titles(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - "Book: A Story"
              - 'Another Book'
            ---
            """)
        )
        result = parse_ranked_list_with_tiers(f)

        assert result[0] == ("Book: A Story", 5)
        assert result[1] == ("Another Book", 5)

    def test_handles_all_star_tiers(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
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
        )
        result = parse_ranked_list_with_tiers(f)

        assert len(result) == 5
        assert result[0][1] == 5
        assert result[1][1] == 4
        assert result[2][1] == 3
        assert result[3][1] == 2
        assert result[4][1] == 1

    def test_empty_list(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
            ---
            ranked_list:
            ---
            """)
        )
        result = parse_ranked_list_with_tiers(f)

        assert result == []

    def test_ignores_blank_lines(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - Book One

              - Book Two
            ---
            """)
        )
        result = parse_ranked_list_with_tiers(f)

        assert len(result) == 2


class TestRepositoryPaths:
    def test_repo_root_is_repository_root(self):
        assert push_ratings_from_ranking.REPO_ROOT == REPO_ROOT

    def test_default_paths_exist(self):
        assert push_ratings_from_ranking.BOOKS_DIR.is_dir()
        assert push_ratings_from_ranking.BY_RATING.is_file()


class TestMain:
    def test_pushes_tier_ratings_into_book_files(self, tmp_path, monkeypatch):
        build_tree(
            tmp_path,
            "  # 5 Stars\n  - Book One\n  # 4 Stars\n  - Book Two\n",
            {"book_one": ("Book One", 3), "book_two": ("Book Two", 4)},
        )
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)

        push_ratings_from_ranking.main()

        books = tmp_path / "_books"
        assert (books / "book_one.md").read_text() == (
            "---\ntitle: Book One\nrating: 5\n---\n\nReview of Book One.\n"
        )
        assert (books / "book_two.md").read_text() == (
            "---\ntitle: Book Two\nrating: 4\n---\n\nReview of Book Two.\n"
        )
