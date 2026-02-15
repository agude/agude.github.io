#!/usr/bin/env python3
"""Update book review dates to match the git commit where the rating changed.

By default, finds the first commit that set a non-null rating (i.e., when the
review was published). With --latest, finds the most recent commit that changed
the rating to a (different) non-null value.

Usage:
    uv run _scripts/backdate_rating.py _books/some_book.md
    uv run _scripts/backdate_rating.py --latest '_books/a_*.md'
    uv run _scripts/backdate_rating.py --dry-run '_books/*.md'
    uv run _scripts/backdate_rating.py --force '_books/some_book.md'
"""

import argparse
import glob
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


RATING_RE = re.compile(r"^rating:\s*(.+)$", re.MULTILINE)
DATE_RE = re.compile(r"^date:\s*(.+)$", re.MULTILINE)
# A bare date is just YYYY-MM-DD with nothing else; a timestamp has time/tz info.
BARE_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def get_repo_root() -> str:
    """Return the absolute path to the git repo root."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


# Computed once at import time
REPO_ROOT = get_repo_root()


def repo_relative_path(filepath: str) -> str:
    """Convert any path to a repo-relative path for consistent git operations."""
    abs_path = os.path.abspath(filepath)
    return os.path.relpath(abs_path, REPO_ROOT)


def get_commits_for_path(filepath: str) -> list[dict]:
    """Return commits touching a specific path (oldest first).

    Each entry has 'hash', 'datetime', and 'path'.
    """
    result = subprocess.run(
        ["git", "log", "--reverse", "--format=%H %aI", "--", filepath],
        capture_output=True,
        text=True,
        check=True,
        cwd=REPO_ROOT,
    )

    commits = []
    for line in result.stdout.strip().splitlines():
        if not line:
            continue
        parts = line.split(" ", 1)
        commits.append(
            {
                "hash": parts[0],
                "datetime": parts[1],
                "path": filepath,
            }
        )

    return commits


def find_old_path(commit_hash: str, filepath: str) -> str | None:
    """If a commit renamed a file to filepath, return the old path."""
    result = subprocess.run(
        ["git", "diff-tree", "--no-commit-id", "-r", "-M", commit_hash],
        capture_output=True,
        text=True,
        check=True,
        cwd=REPO_ROOT,
    )

    for line in result.stdout.splitlines():
        # Rename lines look like: :old_mode new_mode old_hash new_hash R<score>\told_path\tnew_path
        parts = line.split("\t")
        if len(parts) == 3 and parts[2] == filepath:
            status = parts[0].split()[-1]  # e.g. "R099"
            if status.startswith("R"):
                return parts[1]

    return None


def get_commit_list(filepath: str) -> list[dict]:
    """Return all commits touching filepath, chasing renames (oldest first).

    Gets commits for the current path, then checks if the oldest commit
    is a rename. If so, prepends the history from the old path.
    """
    commits = get_commits_for_path(filepath)
    if not commits:
        return commits

    # Check if the oldest commit renamed the file from somewhere else
    oldest = commits[0]
    old_path = find_old_path(oldest["hash"], filepath)

    if old_path:
        # Get the old path's history and prepend it
        old_commits = get_commits_for_path(old_path)
        commits = old_commits + commits

    return commits


def read_file_at_commit(commit_hash: str, filepath: str) -> str | None:
    """Read a file's content at a specific git commit."""
    result = subprocess.run(
        ["git", "show", f"{commit_hash}:{filepath}"],
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    if result.returncode != 0:
        return None
    return result.stdout


def parse_rating(value: str) -> int | None:
    """Parse a rating value string, returning None for null/empty."""
    value = value.strip().strip("'\"")
    if value in ("null", "nil", "~", ""):
        return None
    try:
        return int(value)
    except ValueError:
        return None


def extract_rating(content: str) -> int | None:
    """Extract the rating from file content."""
    match = RATING_RE.search(content)
    if not match:
        return None
    return parse_rating(match.group(1))


def find_rating_commit(filepath: str, use_latest: bool) -> dict | None:
    """Find the commit where the rating changed to a non-null value.

    Reads the file content at each commit to compare ratings directly,
    avoiding patch-parsing issues with renames and copies.

    If use_latest is False, returns the first such commit.
    If use_latest is True, returns the most recent such commit.
    """
    git_path = repo_relative_path(filepath)
    commits = get_commit_list(git_path)
    match = None
    prev_rating = None

    for commit in commits:
        content = read_file_at_commit(commit["hash"], commit["path"])
        if content is None:
            continue

        rating = extract_rating(content)

        if rating is not None and rating != prev_rating:
            if not use_latest:
                return commit
            match = commit

        prev_rating = rating

    return match


def format_datetime(iso_str: str) -> str:
    """Convert ISO datetime to the format used in front matter."""
    dt = datetime.fromisoformat(iso_str)
    return dt.strftime("%Y-%m-%d %H:%M:%S %z")


def update_date(filepath: str, new_date: str, dry_run: bool) -> bool:
    """Update the date field in the file's front matter. Returns True if changed."""
    with open(filepath, "r") as f:
        content = f.read()

    date_match = DATE_RE.search(content)
    if not date_match:
        print(f"  WARNING: No date field found in {filepath}", file=sys.stderr)
        return False

    old_date = date_match.group(1).strip()
    if old_date == new_date:
        print(f"  SKIP (already correct): {filepath}")
        return False

    new_content = (
        content[: date_match.start(1)] + new_date + content[date_match.end(1) :]
    )

    if dry_run:
        print(f"  DRY RUN: {filepath}")
        print(f"    {old_date} -> {new_date}")
    else:
        with open(filepath, "w") as f:
            f.write(new_content)
        print(f"  UPDATED: {filepath}")
        print(f"    {old_date} -> {new_date}")

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Backdate book review dates to the git commit where the rating changed.",
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="Book file paths or glob patterns (e.g., '_books/*.md').",
    )
    parser.add_argument(
        "--latest",
        action="store_true",
        help="Use the most recent rating change instead of the first.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would change without modifying files.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Process files even if they already have a timestamp (not just a date).",
    )
    args = parser.parse_args()

    # Expand globs
    paths = []
    for pattern in args.files:
        expanded = glob.glob(pattern)
        if expanded:
            paths.extend(expanded)
        else:
            paths.append(pattern)

    mode = "latest non-null rating" if args.latest else "first non-null rating"
    print(f"Mode: {mode}")
    print(f"Files: {len(paths)}")
    print()

    updated = 0
    skipped = 0

    for filepath in sorted(paths):
        print(f"Processing: {filepath}")

        # Skip template files
        if "_template" in filepath:
            print("  SKIP (template)")
            skipped += 1
            continue

        # Skip files that already have a full timestamp (not just a bare date)
        if not args.force:
            with open(filepath, "r") as f:
                content = f.read()
            date_match = DATE_RE.search(content)
            if date_match and not BARE_DATE_RE.match(date_match.group(1).strip()):
                print("  SKIP (already has timestamp; use --force to override)")
                skipped += 1
                continue

        commit = find_rating_commit(filepath, args.latest)
        if commit is None:
            print("  SKIP (no non-null rating change found)")
            skipped += 1
            continue

        new_date = format_datetime(commit["datetime"])
        short_hash = commit["hash"][:8]
        print(f"  Commit: {short_hash} ({new_date})")

        if update_date(filepath, new_date, args.dry_run):
            updated += 1
        else:
            skipped += 1

    print()
    print(f"Done: {updated} updated, {skipped} skipped.")


if __name__ == "__main__":
    main()
