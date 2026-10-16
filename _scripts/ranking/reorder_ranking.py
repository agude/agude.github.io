#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = ["PyYAML"]
# ///
"""Reorder the ranked_list in books/by_rating.md to match current front matter ratings.

Example: --dry-run

Algorithm:
  1. Read the current ranked_list to get each book's global rank (position).
  2. Read each book's rating: from front matter.
  3. Group books by new rating.
  4. Within each group, sort by old global rank (preserves relative order
     and interleaves promoted/demoted books naturally).
  5. Rewrite the ranked_list in by_rating.md.

Stops without writing if any ranked title has no matching book file or the
book has no rating.
"""

import re
import sys
from pathlib import Path

import yaml

# `uv run` puts only this script's directory on sys.path.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))

from front_matter import split_front_matter
from yaml_text import yaml_scalar

REPO_ROOT = Path(__file__).resolve().parents[2]
BOOKS_DIR = REPO_ROOT / "_books"
BY_RATING = REPO_ROOT / "books" / "by_rating.md"


def read_front_matter(path):
    """Return the parsed YAML front matter of a Markdown file, or None if it has none."""
    split = split_front_matter(path.read_text())
    if split is None:
        return None
    parsed = yaml.safe_load(split[0])
    return parsed if isinstance(parsed, dict) else {}


def parse_ranked_list(path):
    """Return ordered list of book titles from the ranked_list front matter."""
    front_matter = read_front_matter(path)
    if front_matter is None:
        sys.exit("Could not parse front matter in by_rating.md")

    titles = front_matter.get("ranked_list") or []
    non_strings = [title for title in titles if not isinstance(title, str)]
    if non_strings:
        sys.exit(f"ranked_list entries that are not strings: {non_strings}")
    return titles


def get_rating_from_file(book_path):
    """Read rating: from a book's front matter."""
    text = book_path.read_text()
    m = re.search(r"^rating:\s*(\d+)", text, re.MULTILINE)
    if m:
        return int(m.group(1))
    return None


def _title_matches(path, title):
    file_title = (read_front_matter(path) or {}).get("title")
    return isinstance(file_title, str) and file_title.lower() == title.lower()


def find_book_file(title):
    """Find the book file for a given title by matching the title: field."""
    for path in BOOKS_DIR.glob("*.md"):
        if _title_matches(path, title):
            return path

    # Check subdirectories (for canonical books like hyperion/)
    for subdir in BOOKS_DIR.iterdir():
        if subdir.is_dir() and subdir.name != "_template":
            for path in subdir.glob("*.md"):
                # Skip archived reviews (they have canonical_url)
                if "canonical_url" in (read_front_matter(path) or {}):
                    continue
                if _title_matches(path, title):
                    return path
    return None


def format_ranked_list(tiers):
    """Return ranked_list body lines: a `# N Stars` comment, then each title."""
    yaml_lines = []
    for star in sorted(tiers.keys(), reverse=True):
        yaml_lines.append(f"  # {star} Stars\n")
        for title in tiers[star]:
            yaml_lines.append(f"  - {yaml_scalar(title)}\n")
    return "".join(yaml_lines)


def rebuild_front_matter(path, new_ranked_list_text):
    """Replace the ranked_list in the front matter."""
    split = split_front_matter(path.read_text())
    if split is None:
        sys.exit(f"Could not parse front matter in {path.name}")
    front, body = split

    # Find ranked_list start and end
    lines = front.splitlines(keepends=True)
    new_lines = []
    in_list = False
    list_done = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("ranked_list:"):
            in_list = True
            new_lines.append("ranked_list:\n")
            new_lines.append(new_ranked_list_text)
            continue
        if in_list and not list_done:
            if stripped.startswith("- ") or stripped.startswith("#") or stripped == "":
                continue  # Skip old list content
            in_list = False
            list_done = True
            new_lines.append(line)
        else:
            new_lines.append(line)

    new_front = "".join(new_lines)
    path.write_text(f"---\n{new_front}---\n{body}")


def main():
    dry_run = "--dry-run" in sys.argv

    # Step 1: Get current order
    titles = parse_ranked_list(BY_RATING)
    print(f"Found {len(titles)} books in ranked_list\n")

    # Step 2: Map each title to its global rank and new rating
    books = []  # (global_rank, title, new_rating)
    missing = []

    for rank, title in enumerate(titles):
        path = find_book_file(title)
        if path is None:
            missing.append(title)
            continue
        rating = get_rating_from_file(path)
        if rating is None:
            missing.append(title)
            continue
        books.append((rank, title, rating))

    if missing:
        listing = "\n".join(f"  - {t}" for t in missing)
        sys.exit(
            f"Could not find a rated book file for {len(missing)} ranked titles; "
            f"by_rating.md was not changed:\n{listing}"
        )

    # Step 3: Group by new rating, sort within group by global rank
    tiers = {}
    for rank, title, rating in books:
        tiers.setdefault(rating, []).append((rank, title))

    # Step 4: Build new list
    ordered = {star: [title for _, title in sorted(group)] for star, group in tiers.items()}
    new_list_text = format_ranked_list(ordered)

    if dry_run:
        print("New ranked_list:\n")
        print(new_list_text)
        print("Re-run without --dry-run to apply.")
    else:
        rebuild_front_matter(BY_RATING, new_list_text)
        print("Updated books/by_rating.md\n")
        # Print summary
        for star in sorted(tiers.keys(), reverse=True):
            print(f"  {star} stars: {len(tiers[star])} books")


if __name__ == "__main__":
    main()
