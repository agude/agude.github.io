"""Tests for content/backdate_rating.py.

The command-line tests run the script as a subprocess inside a temporary
Git repository, because the script resolves the repository root from its
working directory at import time.
"""

import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import pytest
from backdate_rating import extract_rating, format_datetime, parse_rating

SCRIPT = Path(__file__).resolve().parents[1] / "content" / "backdate_rating.py"


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


def book(rating: str, body: str = "Review text.\n") -> str:
    return f"---\ntitle: Test Book\ndate: 2024-01-01\nrating: {rating}\n---\n{body}"


class HistoryRepo:
    """A temporary Git repository whose commits carry fixed author dates."""

    def __init__(self, root: Path):
        self.root = root
        self.env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        self.env.update(
            GIT_AUTHOR_NAME="Test",
            GIT_AUTHOR_EMAIL="test@example.com",
            GIT_COMMITTER_NAME="Test",
            GIT_COMMITTER_EMAIL="test@example.com",
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_CONFIG_SYSTEM=os.devnull,
        )
        (root / "_books").mkdir()
        self.git("init", "-q", "-b", "main")

    def git(self, *args: str, date: str | None = None) -> str:
        env = self.env if date is None else {**self.env, "GIT_AUTHOR_DATE": date}
        result = subprocess.run(
            ["git", *args],
            cwd=self.root,
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()

    def commit(self, name: str, content: str, date: str) -> str:
        """Write and commit one file; return the commit hash."""
        (self.root / name).write_text(content)
        self.git("add", name)
        self.git("commit", "-q", "-m", f"Edit {name}", date=date)
        return self.git("rev-parse", "HEAD")

    def run(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args],
            cwd=self.root,
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
        )


@dataclass
class RatingHistory:
    repo: HistoryRepo
    first_rating: str  # hash of the commit that first set a non-null rating
    last_change: str  # hash of the last commit that changed the rating


class TestCommandLine:
    PATH = "_books/test_book.md"

    @pytest.fixture
    def history(self, tmp_path: Path) -> RatingHistory:
        """Rating null, then 4, then 5, then a body edit that keeps 5."""
        repo = HistoryRepo(tmp_path)
        repo.commit(self.PATH, book("null"), "2024-01-10T09:00:00+00:00")
        first = repo.commit(self.PATH, book("4"), "2024-02-15T12:30:00-08:00")
        last = repo.commit(self.PATH, book("5"), "2024-05-20T08:00:00+02:00")
        repo.commit(self.PATH, book("5", "Edited text.\n"), "2024-07-04T10:00:00+00:00")
        return RatingHistory(repo, first, last)

    def test_sets_date_to_first_non_null_rating_commit(self, history: RatingHistory) -> None:
        result = history.repo.run(self.PATH)

        expected = "2024-02-15 12:30:00 -0800"
        assert f"Commit: {history.first_rating[:8]} ({expected})" in result.stdout
        assert (history.repo.root / self.PATH).read_text() == book("5", "Edited text.\n").replace(
            "date: 2024-01-01", f"date: {expected}"
        )

    def test_latest_ignores_commits_that_keep_the_rating(self, history: RatingHistory) -> None:
        result = history.repo.run("--latest", self.PATH)

        expected = "2024-05-20 08:00:00 +0200"
        assert f"Commit: {history.last_change[:8]} ({expected})" in result.stdout
        assert f"date: {expected}\n" in (history.repo.root / self.PATH).read_text()

    def test_dry_run_leaves_file_unchanged(self, history: RatingHistory) -> None:
        before = (history.repo.root / self.PATH).read_text()

        result = history.repo.run("--dry-run", self.PATH)

        assert "2024-01-01 -> 2024-02-15 12:30:00 -0800" in result.stdout
        assert (history.repo.root / self.PATH).read_text() == before

    def test_follows_rename_to_earlier_history(self, tmp_path: Path) -> None:
        repo = HistoryRepo(tmp_path)
        old, new = "_books/old_name.md", "_books/new_name.md"
        repo.commit(old, book("3"), "2023-03-03T03:03:03+00:00")
        repo.git("mv", old, new)
        repo.git("commit", "-q", "-m", "Rename", date="2023-09-09T09:09:09+00:00")

        repo.run(new)

        assert "date: 2023-03-03 03:03:03 +0000\n" in (repo.root / new).read_text()
