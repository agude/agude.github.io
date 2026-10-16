"""Tests for ranking/reorder_ranking.py."""

import pytest
import reorder_ranking
from ranking_tree import REPO_ROOT, build_tree, point_module_at
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


class TestRepositoryPaths:
    def test_repo_root_is_repository_root(self):
        assert reorder_ranking.REPO_ROOT == REPO_ROOT

    def test_default_paths_exist(self):
        assert reorder_ranking.BOOKS_DIR.is_dir()
        assert reorder_ranking.BY_RATING.is_file()


class TestMain:
    def test_regroups_ranked_list_by_front_matter_rating(self, tmp_path, monkeypatch):
        build_tree(
            tmp_path,
            "  # 5 Stars\n  - Book One\n  - Book Two\n  # 4 Stars\n  - Book Three\n",
            {
                "book_one": ("Book One", 4),
                "book_two": ("Book Two", 5),
                "book_three": ("Book Three", 5),
            },
        )
        point_module_at(monkeypatch, reorder_ranking, tmp_path)

        reorder_ranking.main()

        assert (tmp_path / "books" / "by_rating.md").read_text() == (
            "---\ntitle: By Rating\nranked_list:\n"
            "  # 5 Stars\n  - Book Two\n  - Book Three\n"
            "  # 4 Stars\n  - Book One\n"
            "layout: page\n---\n\nBody.\n"
        )
