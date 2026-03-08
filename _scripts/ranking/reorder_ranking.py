#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# ///
"""Reorder the ranked_list in books/by_rating.md to match current front matter ratings.

Algorithm:
  1. Read the current ranked_list to get each book's global rank (position).
  2. Read each book's rating: from front matter.
  3. Group books by new rating.
  4. Within each group, sort by old global rank (preserves relative order
     and interleaves promoted/demoted books naturally).
  5. Rewrite the ranked_list in by_rating.md.
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BOOKS_DIR = REPO_ROOT / "_books"
BY_RATING = REPO_ROOT / "books" / "by_rating.md"


def parse_ranked_list(path):
    """Return ordered list of book titles from the ranked_list front matter."""
    text = path.read_text()

    # Extract front matter
    parts = text.split("---", 2)
    if len(parts) < 3:
        sys.exit("Could not parse front matter in by_rating.md")

    front = parts[1]
    titles = []
    in_list = False
    for line in front.splitlines():
        if line.strip().startswith("ranked_list:"):
            in_list = True
            continue
        if in_list:
            # Stop at next front matter key (non-indented, non-comment, non-list)
            stripped = line.strip()
            if stripped.startswith("#"):
                continue  # YAML comment
            if stripped.startswith("- "):
                # Extract title, handling quoted strings
                title = stripped[2:].strip()
                if title.startswith('"') and title.endswith('"'):
                    title = title[1:-1]
                elif title.startswith("'") and title.endswith("'"):
                    title = title[1:-1]
                titles.append(title)
            elif stripped == "":
                continue
            else:
                break

    return titles


def get_rating_from_file(book_path):
    """Read rating: from a book's front matter."""
    text = book_path.read_text()
    m = re.search(r"^rating:\s*(\d+)", text, re.MULTILINE)
    if m:
        return int(m.group(1))
    return None


def find_book_file(title):
    """Find the book file for a given title by matching the title: field."""
    for path in BOOKS_DIR.glob("*.md"):
        text = path.read_text()
        m = re.search(r"^title:\s*(.+)$", text, re.MULTILINE)
        if m:
            file_title = m.group(1).strip()
            # Strip quotes
            if file_title.startswith('"') and file_title.endswith('"'):
                file_title = file_title[1:-1]
            elif file_title.startswith("'") and file_title.endswith("'"):
                file_title = file_title[1:-1]
            if file_title.lower() == title.lower():
                return path

    # Check subdirectories (for canonical books like hyperion/)
    for subdir in BOOKS_DIR.iterdir():
        if subdir.is_dir() and subdir.name != "_template":
            for path in subdir.glob("*.md"):
                text = path.read_text()
                # Skip archived reviews (they have canonical_url)
                if re.search(r"^canonical_url:", text, re.MULTILINE):
                    continue
                m = re.search(r"^title:\s*(.+)$", text, re.MULTILINE)
                if m:
                    file_title = m.group(1).strip().strip('"').strip("'")
                    if file_title.lower() == title.lower():
                        return path
    return None


def format_title_for_yaml(title):
    """Format a title for YAML output, quoting if needed."""
    if ":" in title or title.startswith('"') or title.startswith("'"):
        return f'"{title}"'
    return title


def rebuild_front_matter(path, new_ranked_list_text):
    """Replace the ranked_list in the front matter."""
    text = path.read_text()
    parts = text.split("---", 2)
    front = parts[1]

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
            else:
                in_list = False
                list_done = True
                new_lines.append(line)
        else:
            new_lines.append(line)

    new_front = "".join(new_lines)
    new_text = f"---{new_front}---{parts[2]}"
    path.write_text(new_text)


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
        print(f"WARNING: Could not find files for {len(missing)} books:")
        for t in missing:
            print(f"  - {t}")
        print()

    # Step 3: Group by new rating, sort within group by global rank
    tiers = {}
    for rank, title, rating in books:
        tiers.setdefault(rating, []).append((rank, title))

    # Step 4: Build new list
    yaml_lines = []
    for star in sorted(tiers.keys(), reverse=True):
        tier_books = sorted(tiers[star], key=lambda x: x[0])
        yaml_lines.append(f"  # {star} Stars\n")
        for _, title in tier_books:
            yaml_lines.append(f"  - {format_title_for_yaml(title)}\n")

    new_list_text = "".join(yaml_lines)

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
