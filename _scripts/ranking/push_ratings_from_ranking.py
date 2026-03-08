#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# ///
"""Read the ranked_list in books/by_rating.md and update rating: in each book's front matter.

Example: --dry-run

The star tier is determined by the YAML comments (# 5 Stars, # 4 Stars, etc.)
in the ranked_list. Each book under a comment gets that rating pushed to its
front matter.
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BOOKS_DIR = REPO_ROOT / "_books"
BY_RATING = REPO_ROOT / "books" / "by_rating.md"


def parse_ranked_list_with_tiers(path):
    """Return list of (title, star_rating) from ranked_list."""
    text = path.read_text()
    parts = text.split("---", 2)
    if len(parts) < 3:
        sys.exit("Could not parse front matter in by_rating.md")

    front = parts[1]
    books = []
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
            title = stripped[2:].strip()
            if title.startswith('"') and title.endswith('"'):
                title = title[1:-1]
            elif title.startswith("'") and title.endswith("'"):
                title = title[1:-1]
            books.append((title, current_stars))
        elif stripped == "":
            continue
        else:
            break

    return books


def find_book_file(title):
    """Find the book file matching a title (case-insensitive)."""
    for path in BOOKS_DIR.glob("*.md"):
        text = path.read_text()
        m = re.search(r"^title:\s*(.+)$", text, re.MULTILINE)
        if m:
            file_title = m.group(1).strip().strip('"').strip("'")
            if file_title.lower() == title.lower():
                return path

    for subdir in BOOKS_DIR.iterdir():
        if subdir.is_dir() and subdir.name != "_template":
            for path in subdir.glob("*.md"):
                text = path.read_text()
                if re.search(r"^canonical_url:", text, re.MULTILINE):
                    continue
                m = re.search(r"^title:\s*(.+)$", text, re.MULTILINE)
                if m:
                    file_title = m.group(1).strip().strip('"').strip("'")
                    if file_title.lower() == title.lower():
                        return path
    return None


def update_rating(book_path, new_rating):
    """Update the rating: field. Returns (old, new) or None if unchanged."""
    text = book_path.read_text()
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

    books = parse_ranked_list_with_tiers(BY_RATING)
    print(f"Parsed {len(books)} books from by_rating.md\n")

    changed = 0
    missing = []

    for title, new_rating in books:
        path = find_book_file(title)
        if path is None:
            missing.append(title)
            continue

        if dry_run:
            text = path.read_text()
            m = re.search(r"^rating:\s*(\d+)", text, re.MULTILINE)
            if m:
                old = int(m.group(1))
                if old != new_rating:
                    print(f"  {path.name}: {old} → {new_rating}")
                    changed += 1
        else:
            result = update_rating(path, new_rating)
            if result:
                old, new = result
                print(f"  {path.name}: {old} → {new}")
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
