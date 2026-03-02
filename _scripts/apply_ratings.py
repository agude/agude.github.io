#!/usr/bin/env python3
"""Read new_ratings.md and update rating: in each book's front matter.

The target rating is determined by which section (## N Stars) the book
appears in, NOT the inline arrow text (which may be stale).
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BOOKS_DIR = REPO_ROOT / "_books"
RATINGS_FILE = REPO_ROOT / "new_ratings.md"


def parse_ratings(ratings_path):
    """Parse new_ratings.md, returning {filename: new_rating}."""
    ratings = {}
    current_stars = None
    section_re = re.compile(r"^## (\d) Stars?")
    book_re = re.compile(r"^- `([^`]+\.md)`")

    for line in ratings_path.read_text().splitlines():
        m = section_re.match(line)
        if m:
            current_stars = int(m.group(1))
            continue

        if current_stars is None:
            continue

        m = book_re.match(line)
        if m:
            ratings[m.group(1)] = current_stars

    return ratings


def update_rating(book_path, new_rating):
    """Update the rating: field in a book's front matter. Returns (old, new) or None."""
    text = book_path.read_text()

    # Match rating: N in front matter
    m = re.search(r"^(rating:\s*)(\d+)", text, re.MULTILINE)
    if not m:
        return None

    old_rating = int(m.group(2))
    if old_rating == new_rating:
        return None

    new_text = text[: m.start(2)] + str(new_rating) + text[m.end(2) :]
    book_path.write_text(new_text)
    return (old_rating, new_rating)


def main():
    dry_run = "--dry-run" in sys.argv

    ratings = parse_ratings(RATINGS_FILE)
    print(f"Parsed {len(ratings)} books from {RATINGS_FILE.name}\n")

    changed = 0
    missing = []

    for filename, new_rating in sorted(ratings.items()):
        book_path = BOOKS_DIR / filename
        if not book_path.exists():
            missing.append(filename)
            continue

        if dry_run:
            text = book_path.read_text()
            m = re.search(r"^rating:\s*(\d+)", text, re.MULTILINE)
            if m:
                old = int(m.group(1))
                if old != new_rating:
                    print(f"  {filename}: {old} → {new_rating}")
                    changed += 1
        else:
            result = update_rating(book_path, new_rating)
            if result:
                old, new = result
                print(f"  {filename}: {old} → {new}")
                changed += 1

    print(f"\n{'Would change' if dry_run else 'Changed'} {changed} files.")

    if missing:
        print(f"\nMissing files ({len(missing)}):")
        for f in missing:
            print(f"  {f}")

    if dry_run:
        print("\nRe-run without --dry-run to apply.")


if __name__ == "__main__":
    main()
