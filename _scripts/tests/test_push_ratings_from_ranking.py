"""Tests for ranking/push_ratings_from_ranking.py."""

import sys
from textwrap import dedent

import push_ratings_from_ranking
import pytest
from push_ratings_from_ranking import parse_ranked_list_with_tiers
from ranking_tree import (
    REPO_ROOT,
    book_files,
    build_family_tree,
    build_tree,
    count_reads,
    point_module_at,
    write_book,
)


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

    def test_decodes_yaml_escapes_in_titles(self, tmp_path):
        f = tmp_path / "ranking.md"
        f.write_text(
            dedent("""\
            ---
            ranked_list:
              # 5 Stars
              - 'Don''t'
              - "He said \\"hi\\""
            ---
            """)
        )
        result = parse_ranked_list_with_tiers(f)

        assert result == [("Don't", 5), ('He said "hi"', 5)]


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

    def test_pushes_rating_for_triple_dash_title(self, tmp_path, monkeypatch):
        build_tree(
            tmp_path,
            "  # 5 Stars\n  - A---B\n  - Book Two\n",
            {"a_b": ("A---B", 3), "book_two": ("Book Two", 3)},
        )
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)

        push_ratings_from_ranking.main()

        books = tmp_path / "_books"
        assert (books / "a_b.md").read_text() == (
            "---\ntitle: A---B\nrating: 5\n---\n\nReview of A---B.\n"
        )
        assert (books / "book_two.md").read_text() == (
            "---\ntitle: Book Two\nrating: 5\n---\n\nReview of Book Two.\n"
        )


class TestBookLookup:
    def test_title_resolves_to_canonical_review_not_archive(self, tmp_path, monkeypatch):
        build_family_tree(tmp_path, "  # 3 Stars\n  - Hyperion\n")
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)
        archive = tmp_path / "_books" / "hyperion" / "review-2023-10-17.md"
        archive_before = archive.read_text()

        push_ratings_from_ranking.main()

        assert (tmp_path / "_books" / "hyperion.md").read_text() == (
            "---\ntitle: Hyperion\nrating: 3\n---\n\nReview of Hyperion.\n"
        )
        assert archive.read_text() == archive_before

    @pytest.mark.parametrize("dry_run", [False, True])
    def test_reads_each_book_file_once(self, tmp_path, monkeypatch, dry_run):
        build_family_tree(
            tmp_path, "  # 5 Stars\n  - Hyperion\n  - Dune\n  # 2 Stars\n  - Foundation\n"
        )
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)
        if dry_run:
            monkeypatch.setattr(sys, "argv", [push_ratings_from_ranking.__file__, "--dry-run"])
        reads = count_reads(monkeypatch)

        push_ratings_from_ranking.main()

        files = book_files(tmp_path)
        assert {path: reads[path] for path in files} == dict.fromkeys(files, 1)

    def test_duplicate_title_stops_before_any_write(self, tmp_path, monkeypatch):
        build_family_tree(tmp_path, "  # 5 Stars\n  - Foundation\n  - Dune\n")
        write_book(tmp_path / "_books", "dune_copy", "Dune", 2)
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)
        before = {path: path.read_text() for path in book_files(tmp_path)}

        with pytest.raises(SystemExit) as excinfo:
            push_ratings_from_ranking.main()

        message = str(excinfo.value.code)
        assert excinfo.value.code not in (0, None)
        assert "dune.md" in message
        assert "dune_copy.md" in message
        assert {path: path.read_text() for path in book_files(tmp_path)} == before


class TestEscapedTitles:
    # Titles are decoded as YAML on both sides, so a quoted title in the
    # ranked list matches the same quoted title in the book file.
    @pytest.mark.parametrize(
        "yaml_title",
        ["'Don''t'", '"He said \\"hi\\""'],
    )
    def test_pushes_rating_for_escaped_title(self, tmp_path, monkeypatch, yaml_title):
        build_tree(tmp_path, f"  # 5 Stars\n  - {yaml_title}\n", {})
        book = tmp_path / "_books" / "escaped.md"
        book.write_text(f"---\ntitle: {yaml_title}\nrating: 3\n---\n\nReview.\n")
        point_module_at(monkeypatch, push_ratings_from_ranking, tmp_path)

        push_ratings_from_ranking.main()

        assert book.read_text() == f"---\ntitle: {yaml_title}\nrating: 5\n---\n\nReview.\n"
