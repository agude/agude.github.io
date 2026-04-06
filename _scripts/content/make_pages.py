#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["PyYAML"]
# ///
"""Generate author and series pages from book front matter.

Scans _books/*.md for book_authors and series fields, then creates
stub pages under books/authors/ and books/series/ for any that don't
already exist.

Usage:
    # From anywhere — auto-detects project root via git:
    uv run _scripts/content/make_pages.py

    # Explicit project root:
    uv run _scripts/content/make_pages.py --project-root /path/to/site
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

import yaml

TEMPLATES = {
    "author": """---
layout: author_page
title: {item}
pen_names:
description: >
    Alex Gude's reviews of books written by {item}.
same_as_urls:
---""",
    "series": """---
layout: series_page
title: {item}
description: >
    Alex Gude's reviews of books written in the {item} series.
---""",
}


def find_project_root() -> Path:
    """Find the project root via git."""
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(
            "Error: not inside a git repository and --project-root not given.",
            file=sys.stderr,
        )
        sys.exit(1)
    return Path(result.stdout.strip())


def normalize_filename(name: str) -> str:
    """Normalize a string for use as a filename."""
    s = name.lower()
    s = re.sub(r"[^\w\-_]+", "_", s)
    s = re.sub(r"_+", "_", s)
    return s.strip("_")


def extract_frontmatter(filepath: Path) -> dict:
    """Extract YAML frontmatter from a markdown file."""
    text = filepath.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return {}

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}

    try:
        parsed = yaml.safe_load(text[4:end])
        return parsed if isinstance(parsed, dict) else {}
    except yaml.YAMLError:
        return {}


def extract_metadata_from_books(
    book_dir: Path,
) -> tuple[list[str], list[str]]:
    """Extract unique authors and series from all book files."""
    authors: set[str] = set()
    series: set[str] = set()

    for filepath in sorted(book_dir.glob("*.md")):
        fm = extract_frontmatter(filepath)

        book_authors = fm.get("book_authors")
        if isinstance(book_authors, str):
            if book_authors.strip():
                authors.add(book_authors.strip())
        elif isinstance(book_authors, list):
            for a in book_authors:
                if isinstance(a, str) and a.strip():
                    authors.add(a.strip())

        book_series = fm.get("series")
        if isinstance(book_series, str) and book_series.strip():
            series.add(book_series.strip())

    return sorted(authors), sorted(series)


def build_known_authors(author_dir: Path) -> set[str]:
    """Build a set of normalized names (canonical + pen names) from existing author pages."""
    known: set[str] = set()
    if not author_dir.exists():
        return known

    for filepath in author_dir.glob("*.md"):
        fm = extract_frontmatter(filepath)
        title = fm.get("title")
        if isinstance(title, str) and title.strip():
            known.add(normalize_filename(title))

        pen_names = fm.get("pen_names")
        if isinstance(pen_names, list):
            for name in pen_names:
                if isinstance(name, str) and name.strip():
                    known.add(normalize_filename(name))

    return known


def write_pages(items: list[str], output_dir: Path, template: str) -> int:
    """Write stub pages for items that don't already have files. Returns count created."""
    output_dir.mkdir(parents=True, exist_ok=True)
    created = 0
    for item in items:
        filepath = output_dir / f"{normalize_filename(item)}.md"
        if filepath.exists():
            continue
        filepath.write_text(template.format(item=item), encoding="utf-8")
        print(f"Created {filepath}")
        created += 1
    return created


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate author and series pages from book front matter.",
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=None,
        help="Project root directory (default: auto-detect via git)",
    )
    args = parser.parse_args()

    root = args.project_root or find_project_root()
    book_dir = root / "_books"
    author_dir = root / "books" / "authors"
    series_dir = root / "books" / "series"

    if not book_dir.exists():
        print(f"Error: {book_dir} does not exist.", file=sys.stderr)
        sys.exit(1)

    known_authors = build_known_authors(author_dir)
    all_authors, all_series = extract_metadata_from_books(book_dir)

    new_authors = [a for a in all_authors if normalize_filename(a) not in known_authors]

    print(f"{len(all_authors)} authors, {len(all_series)} series in books.")

    if new_authors:
        n = write_pages(new_authors, author_dir, TEMPLATES["author"])
        print(f"Created {n} new author page(s).")
    else:
        print("No new authors.")

    new_series = write_pages(all_series, series_dir, TEMPLATES["series"])
    if new_series:
        print(f"Created {new_series} new series page(s).")
    else:
        print("No new series.")


if __name__ == "__main__":
    main()
