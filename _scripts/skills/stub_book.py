#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Assemble a book review stub from the template and CLI arguments.

Reads _books/_template/book_template.md, replaces sentinel comments with
generated values, and writes the result. After running this script, call
update_book_metadata.py to enrich the front matter with Wikidata data.

Usage:
    uv run stub_book.py \
        --title "Ubik" \
        --author "Philip K. Dick" \
        --qid Q617357

    uv run stub_book.py \
        --title "The Honor of the Queen" \
        --author "David Weber" \
        --series "Honor Harrington" \
        --book-number 2 \
        --qid Q3400447
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _SCRIPT_DIR.parent.parent  # _scripts/skills/ -> project root
TEMPLATE_PATH = _PROJECT_ROOT / "_books" / "_template" / "book_template.md"


def slugify(title: str) -> str:
    """Convert title to snake_case filename, preserving unicode letters."""
    slug = title.lower()
    slug = re.sub(r"[''']", "", slug)  # Remove apostrophes
    # Normalize unicode and replace non-letter/digit with underscore
    slug = unicodedata.normalize("NFC", slug)
    slug = re.sub(r"[^\w]+", "_", slug, flags=re.UNICODE)
    slug = slug.strip("_")
    return slug


def ordinal(n: int) -> str:
    """Return ordinal string for a number (1st, 2nd, 3rd, etc.)."""
    if 11 <= n % 100 <= 13:
        suffix = "th"
    else:
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


def number_word(n: int) -> str:
    """Return word for numbers 1-10, digits otherwise."""
    words = {
        1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth",
        6: "sixth", 7: "seventh", 8: "eighth", 9: "ninth", 10: "tenth",
    }
    return words.get(n, ordinal(n))


def build_front_matter(
    *,
    title: str,
    author: str,
    series: str | None,
    book_number: int,
    qid: str | None,
) -> str:
    """Build YAML front matter content."""
    slug = slugify(title)
    today = date.today().isoformat()

    lines = [
        f"date: {today}",
        f"title: {title}",
        f"book_authors: {author}",
        f"series: {series}" if series else "series: null",
        f"book_number: {book_number}",
        "is_anthology: false",
        "rating: null",
        f"image: /books/covers/{slug}.jpg",
    ]

    if qid:
        lines.append(f"wikidata_qid: {qid}")

    return "\n".join(lines)


def build_opening(
    *,
    series: str | None,
    book_number: int,
) -> str:
    """Build the opening paragraph with Liquid tags."""
    base = "{% book_link page.title %}, by {% author_link page.book_authors link=false %}"

    if series:
        if book_number > 1:
            return f"{base}, is the {number_word(book_number)} book in {{% series_text page.series link=false %}}."
        else:
            return f"{base}, is the first book in {{% series_text page.series link=false %}}."
    else:
        return f"{base}, is a standalone novel."


def build_template(
    *,
    front_matter: str,
    opening: str,
    is_series: bool,
) -> str:
    """Read the template and replace sentinel sections."""
    if not TEMPLATE_PATH.exists():
        print(f"Error: template not found at {TEMPLATE_PATH}", file=sys.stderr)
        sys.exit(1)

    text = TEMPLATE_PATH.read_text()

    # Replace sentinels
    text = text.replace("<!-- FRONT_MATTER -->", front_matter)
    text = text.replace("<!-- OPENING -->", opening)

    # Handle conditional series capture
    output_lines = []
    for line in text.splitlines():
        if "<!-- IF_SERIES -->" in line:
            if is_series:
                output_lines.append(line.replace("<!-- IF_SERIES -->", ""))
            # else: drop the line entirely
        else:
            output_lines.append(line)

    return "\n".join(output_lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Assemble a book review stub from template and arguments.",
    )
    parser.add_argument(
        "--title",
        required=True,
        help="Book title",
    )
    parser.add_argument(
        "--author",
        required=True,
        help="Author name",
    )
    parser.add_argument(
        "--series",
        default=None,
        help="Series name (omit for standalone)",
    )
    parser.add_argument(
        "--book-number",
        type=int,
        default=1,
        help="Book number in series (default: 1)",
    )
    parser.add_argument(
        "--qid",
        default=None,
        help="Wikidata Q-ID (written to front matter for later enrichment)",
    )
    parser.add_argument(
        "--output",
        "-o",
        default=None,
        help="Output path (default: _books/<slug>.md)",
    )

    args = parser.parse_args()

    front_matter = build_front_matter(
        title=args.title,
        author=args.author,
        series=args.series,
        book_number=args.book_number,
        qid=args.qid,
    )

    opening = build_opening(
        series=args.series,
        book_number=args.book_number,
    )

    content = build_template(
        front_matter=front_matter,
        opening=opening,
        is_series=bool(args.series),
    )

    output_path = args.output
    if not output_path:
        slug = slugify(args.title)
        output_path = _PROJECT_ROOT / "_books" / f"{slug}.md"

    Path(output_path).write_text(content, encoding="utf-8")
    print(f"Wrote {output_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
