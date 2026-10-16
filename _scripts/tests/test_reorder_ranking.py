"""Tests for ranking/reorder_ranking.py."""

import json

import pytest
import reorder_ranking
import yaml
from ranking_tree import REPO_ROOT, build_tree, point_module_at
from reorder_ranking import parse_ranked_list


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


def colon_titles_in_real_ranked_list() -> list[str]:
    front = (REPO_ROOT / "books" / "by_rating.md").read_text().split("---", 2)[1]
    return [t for t in yaml.safe_load(front)["ranked_list"] if ": " in t]


ROUND_TRIP_TITLES = [
    "No",
    "Yes",
    "null",
    "Book #1",
    "A: B",
    'He said "hi"',
    "'Quoted'",
    "123",
    *colon_titles_in_real_ranked_list(),
]


def ranked_list_text(titles: list[str]) -> str:
    return "  # 5 Stars\n" + "".join(f"  - {json.dumps(t)}\n" for t in titles)


def read_ranked_list(root) -> list:
    front = (root / "books" / "by_rating.md").read_text().split("---", 2)[1]
    return yaml.safe_load(front)["ranked_list"]


class TestRankedListRoundTrip:
    def test_rewrite_preserves_every_title(self, tmp_path, monkeypatch):
        books = {f"book_{i}": (json.dumps(t), 5) for i, t in enumerate(ROUND_TRIP_TITLES)}
        build_tree(tmp_path, ranked_list_text(ROUND_TRIP_TITLES), books)
        point_module_at(monkeypatch, reorder_ranking, tmp_path)

        reorder_ranking.main()

        result = read_ranked_list(tmp_path)
        assert result == ROUND_TRIP_TITLES
        assert all(isinstance(title, str) for title in result)


class TestUnresolvedEntries:
    def test_unmatched_title_stops_before_writing(self, tmp_path, monkeypatch):
        build_tree(
            tmp_path,
            ranked_list_text(["Book One", "Ghost Book"]),
            {"book_one": ("Book One", 4)},
        )
        point_module_at(monkeypatch, reorder_ranking, tmp_path)
        by_rating = tmp_path / "books" / "by_rating.md"
        original = by_rating.read_text()

        with pytest.raises(SystemExit) as excinfo:
            reorder_ranking.main()

        assert excinfo.value.code not in (0, None)
        assert "Ghost Book" in str(excinfo.value.code)
        assert by_rating.read_text() == original

    def test_unrated_book_stops_before_writing(self, tmp_path, monkeypatch):
        build_tree(tmp_path, ranked_list_text(["Book One"]), {"book_one": ("Book One", 4)})
        book = tmp_path / "_books" / "book_one.md"
        book.write_text("---\ntitle: Book One\n---\n\nNo rating.\n")
        point_module_at(monkeypatch, reorder_ranking, tmp_path)
        by_rating = tmp_path / "books" / "by_rating.md"
        original = by_rating.read_text()

        with pytest.raises(SystemExit) as excinfo:
            reorder_ranking.main()

        assert "Book One" in str(excinfo.value.code)
        assert by_rating.read_text() == original
