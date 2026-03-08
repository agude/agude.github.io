#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["isbnlib", "PyYAML"]
# ///
"""Format ISBN values in book review front matter.

Reads _books/*.md files and rewrites each isbn field with correct
hyphenation using isbnlib. Handles ISBN-10, ISBN-13, missing hyphens,
and incorrect hyphens. Skips files with no isbn or isbn: null.

Usage:
    uv run format_isbn.py                           # all books
    uv run format_isbn.py _books/matter.md          # single file
    uv run format_isbn.py '_books/hyperion/*.md'    # glob pattern
    uv run format_isbn.py --dry-run                 # preview changes
"""

from __future__ import annotations

import argparse
import glob
import re
import sys
from pathlib import Path

import isbnlib
import yaml

FRONT_MATTER_RE = re.compile(r"\A---\n(.+?\n)---\n", re.DOTALL)
ISBN_LINE_RE = re.compile(r"^(isbn:\s*)(.+)$", re.MULTILINE)


def format_isbn(raw: str) -> str | None:
    """Return a properly hyphenated ISBN-13, or None if invalid.

    Accepts ISBN-10 or ISBN-13 with or without hyphens. ISBN-10 values
    are converted to ISBN-13 before formatting.
    """
    canonical = isbnlib.canonical(raw)
    if not canonical:
        return None

    if len(canonical) == 10:
        canonical = isbnlib.to_isbn13(canonical)
        if not canonical:
            return None

    formatted = isbnlib.mask(canonical)
    if not formatted:
        return None

    return formatted


def extract_isbn(path: str, fm_text: str) -> str | None:
    """Extract the ISBN value from front matter text.

    Tries yaml.safe_load first; falls back to regex if the YAML is
    malformed (e.g. tabs instead of spaces).
    """
    try:
        front_matter = yaml.safe_load(fm_text)
    except yaml.YAMLError:
        print(
            f"  WARNING: malformed YAML in {path}, falling back to regex",
            file=sys.stderr,
        )
        isbn_match = ISBN_LINE_RE.search(fm_text)
        if not isbn_match:
            return None
        raw = isbn_match.group(2).strip().strip("\"'")
        return None if raw == "null" else raw

    if not front_matter or "isbn" not in front_matter:
        return None

    value = front_matter["isbn"]
    return str(value) if value is not None else None


def process_file(path: str, dry_run: bool) -> bool:
    """Format the isbn field in a single file. Returns True if changed."""
    content = Path(path).read_text(encoding="utf-8")

    fm_match = FRONT_MATTER_RE.match(content)
    if not fm_match:
        return False

    raw_value = extract_isbn(path, fm_match.group(1))
    if raw_value is None:
        return False

    formatted = format_isbn(str(raw_value))
    if formatted is None:
        print(f"  WARNING: invalid ISBN {raw_value!r} in {path}", file=sys.stderr)
        return False

    # Replace the isbn line within the front matter block only.
    fm_text = fm_match.group(0)
    isbn_match = ISBN_LINE_RE.search(fm_text)
    if not isbn_match:
        return False

    old_line = isbn_match.group(0)
    new_line = f"isbn: {formatted}"

    if old_line == new_line:
        return False

    if dry_run:
        print(f"  {path}: {old_line} -> {new_line}")
        return True

    new_fm = fm_text[: isbn_match.start()] + new_line + fm_text[isbn_match.end() :]
    content = new_fm + content[fm_match.end() :]
    Path(path).write_text(content, encoding="utf-8")

    print(f"  {path}: {old_line} -> {new_line}")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Format ISBNs in book front matter.")
    parser.add_argument(
        "files", nargs="*", help="Paths to _books/*.md files (default: all)"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Show changes without writing"
    )
    args = parser.parse_args()

    if args.files:
        paths = sorted(
            p for pattern in args.files for p in glob.glob(pattern, recursive=True)
        )
    else:
        paths = sorted(glob.glob("_books/**/*.md", recursive=True))

    changed = 0
    for path in paths:
        if process_file(path, args.dry_run):
            changed += 1

    label = "would change" if args.dry_run else "changed"
    print(f"\n{changed}/{len(paths)} files {label}.")


if __name__ == "__main__":
    main()
