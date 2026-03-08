#!/usr/bin/env python3
"""Apply rating changes from a ranked.txt file to _books/ front matter.

Usage:
    python apply_rating_changes.py ranked.txt

Input format (one per line):
    Book Title: 4★ → 3★
"""

import re
import sys
from pathlib import Path

BOOKS_DIR = Path(__file__).resolve().parent.parent.parent / "_books"


def parse_changes(path: Path) -> list[tuple[str, int]]:
    """Parse ranked.txt into (title, new_rating) pairs."""
    changes = []
    for line in path.read_text().strip().splitlines():
        line = line.strip()
        if not line:
            continue
        m = re.match(r"^(.+?):\s*\d+★\s*→\s*(\d+)★$", line)
        if not m:
            print(f"  SKIP (bad format): {line}", file=sys.stderr)
            continue
        changes.append((m.group(1), int(m.group(2))))
    return changes


def build_title_to_file(books_dir: Path) -> dict[str, Path]:
    """Map book titles to their file paths."""
    mapping = {}
    for f in books_dir.glob("*.md"):
        text = f.read_text()
        m = re.search(r"^title:\s*\"?(.+?)\"?\s*$", text, re.MULTILINE)
        if m:
            mapping[m.group(1)] = f
    return mapping


def update_rating(filepath: Path, new_rating: int) -> bool:
    """Replace the rating: line in a book's front matter. Returns True if changed."""
    text = filepath.read_text()
    new_text, count = re.subn(
        r"^(rating:\s*)\d+",
        rf"\g<1>{new_rating}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if count == 0:
        return False
    filepath.write_text(new_text)
    return True


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <ranked.txt>", file=sys.stderr)
        sys.exit(1)

    changes_file = Path(sys.argv[1])
    changes = parse_changes(changes_file)
    title_to_file = build_title_to_file(BOOKS_DIR)

    updated = 0
    for title, new_rating in changes:
        filepath = title_to_file.get(title)
        if not filepath:
            print(f"  NOT FOUND: {title}", file=sys.stderr)
            continue
        if update_rating(filepath, new_rating):
            print(f"  {title}: → {new_rating}★  ({filepath.name})")
            updated += 1
        else:
            print(f"  NO RATING LINE: {title}  ({filepath.name})", file=sys.stderr)

    print(f"\n{updated}/{len(changes)} files updated.")


if __name__ == "__main__":
    main()
