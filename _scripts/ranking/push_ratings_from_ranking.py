#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = ["PyYAML"]
# ///
"""Read the ranked_list in books/by_rating.md and update rating: in each book's front matter.

Example: --dry-run

The star tier is determined by the YAML comments (# 5 Stars, # 4 Stars, etc.)
in the ranked_list. Each book under a comment gets that rating pushed to its
front matter.

Stops before writing anything if two book files share a title or a title
appears twice in the ranked_list.
"""

import re
import sys
from pathlib import Path

import yaml

# `uv run` puts only this script's directory on sys.path.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))

from book_index import build_title_index
from front_matter import split_front_matter

REPO_ROOT = Path(__file__).resolve().parents[2]
BOOKS_DIR = REPO_ROOT / "_books"
BY_RATING = REPO_ROOT / "books" / "by_rating.md"


def parse_ranked_list_with_tiers(path):
    """Return list of (title, star_rating) from ranked_list.

    Titles are read as YAML, like the titles in the book files, so quoting
    and escapes decode the same way on both sides. Each title's rating comes
    from the nearest `# N Stars` comment above it, which YAML drops, so the
    comments are read from the lines.
    """
    split = split_front_matter(path.read_text())
    if split is None:
        sys.exit("Could not parse front matter in by_rating.md")

    front, _ = split
    parsed = yaml.safe_load(front)
    titles = (parsed if isinstance(parsed, dict) else {}).get("ranked_list") or []
    non_strings = [title for title in titles if not isinstance(title, str)]
    if non_strings:
        sys.exit(f"ranked_list entries that are not strings: {non_strings}")

    stars = []
    current_stars = None
    in_list = False

    for line in front.splitlines():
        stripped = line.strip()
        if stripped.startswith("ranked_list:"):
            in_list = True
            continue
        if not in_list:
            continue

        # Parse tier comments like "# 5 Stars"
        m = re.match(r"#\s*(\d)\s*Stars?", stripped)
        if m:
            current_stars = int(m.group(1))
            continue

        if stripped.startswith("- "):
            if current_stars is None:
                sys.exit("Found book entry before any # N Stars comment")
            stars.append(current_stars)
        elif stripped == "":
            continue
        else:
            break

    if len(stars) != len(titles):
        sys.exit(
            f"ranked_list has {len(titles)} titles but {len(stars)} '- ' lines; "
            "write one title per line"
        )
    return list(zip(titles, stars, strict=True))


def repeated_titles(books):
    """Return titles that appear more than once in books, ignoring case.

    Each repeated title is returned once, spelled as it first appears.
    """
    first_spelling = {}
    repeated = []
    for title, _stars in books:
        key = title.lower()
        if key not in first_spelling:
            first_spelling[key] = title
        elif first_spelling[key] not in repeated:
            repeated.append(first_spelling[key])
    return repeated


def update_rating(book, new_rating):
    """Update the rating: field of a BookFile. Returns (old, new) or None if unchanged."""
    m = re.search(r"^(rating:\s*)(\d+)", book.text, re.MULTILINE)
    if not m:
        return None

    old_rating = int(m.group(2))
    if old_rating == new_rating:
        return None

    new_text = book.text[: m.start(2)] + str(new_rating) + book.text[m.end(2) :]
    book.path.write_text(new_text)
    return (old_rating, new_rating)


def main():
    dry_run = "--dry-run" in sys.argv

    books = parse_ranked_list_with_tiers(BY_RATING)
    print(f"Parsed {len(books)} books from by_rating.md\n")
    repeated = repeated_titles(books)
    if repeated:
        listing = "\n".join(f"  - {title}" for title in repeated)
        sys.exit(f"Titles listed more than once in by_rating.md; nothing was changed:\n{listing}")
    index = build_title_index(BOOKS_DIR)

    changed = 0
    missing = []

    for title, new_rating in books:
        book = index.get(title.lower())
        if book is None:
            missing.append(title)
            continue

        if dry_run:
            old = book.rating
            if old is not None and old != new_rating:
                print(f"  {book.path.name}: {old} → {new_rating}")
                changed += 1
        else:
            result = update_rating(book, new_rating)
            if result:
                old, new = result
                print(f"  {book.path.name}: {old} → {new}")
                changed += 1

    print(f"\n{'Would change' if dry_run else 'Changed'} {changed} files.")

    if missing:
        print(f"\nMissing files ({len(missing)}):")
        for t in missing:
            print(f"  - {t}")

    if dry_run and changed:
        print("\nRe-run without --dry-run to apply.")


if __name__ == "__main__":
    main()
