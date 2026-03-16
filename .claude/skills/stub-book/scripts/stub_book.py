#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Generate a book review stub with front matter and template captures.

Example: stub_book.py --title "The Honor of the Queen" --author "David Weber" --series "Honor Harrington" --book-number 2 --qid Q3400447

Fetches metadata from Wikidata via _scripts/metadata/fetch_book_metadata.py
when --qid is provided. Outputs the complete .md file to stdout.

Usage:
    # With Wikidata metadata:
    uv run stub_book.py --title "Hyperion" --author "Dan Simmons" --qid Q302026

    # Without Wikidata (no entry exists):
    uv run stub_book.py --title "Some Book" --author "Some Author"

    # With series:
    uv run stub_book.py --title "The Honor of the Queen" --author "David Weber" \
        --series "Honor Harrington" --book-number 2 --qid Q3400447

    # Write to file:
    uv run stub_book.py --title "Hyperion" --author "Dan Simmons" --qid Q302026 \
        --output _books/hyperion.md
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

import yaml

# Spelled-out ordinals for small numbers; suffix function for the rest.
_ORDINALS = {
    1: "first",
    2: "second",
    3: "third",
    4: "fourth",
    5: "fifth",
    6: "sixth",
    7: "seventh",
    8: "eighth",
    9: "ninth",
    10: "tenth",
    11: "eleventh",
    12: "twelfth",
}

# Resolve paths relative to the script's location, not CWD.
_SKILL_DIR = Path(__file__).resolve().parent.parent  # .claude/skills/stub-book/
_PROJECT_ROOT = _SKILL_DIR.parent.parent.parent  # project root
TEMPLATE_PATH = _PROJECT_ROOT / "_books" / "_template" / "book_template.md"
METADATA_SCRIPT_DIR = _PROJECT_ROOT / "_scripts" / "metadata"


def ordinal(n: int) -> str:
    """Return the ordinal string for n.

    Spelled-out for 1–12 ("first", "second", ..., "twelfth"),
    numeric with suffix for 13+ ("13th", "21st", "22nd", etc.).
    """
    if n in _ORDINALS:
        return _ORDINALS[n]
    if 11 <= (n % 100) <= 13:
        suffix = "th"
    else:
        suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suffix}"


def snake_case(title: str) -> str:
    """Convert a title to snake_case for filenames."""
    s = title.lower()
    s = re.sub(r"[^\w\s]", "", s)
    s = re.sub(r"\s+", "_", s.strip())
    return s


def fetch_metadata(qid: str) -> dict[str, str | list[str] | None]:
    """Run fetch_book_metadata.py and parse its YAML output."""
    result = subprocess.run(
        ["uv", "run", "fetch_book_metadata.py", qid],
        capture_output=True,
        text=True,
        cwd=str(METADATA_SCRIPT_DIR),
    )

    if result.returncode != 0:
        print(
            f"Warning: fetch_book_metadata.py failed:\n{result.stderr}", file=sys.stderr
        )
        return {}

    if result.stderr:
        print(result.stderr, file=sys.stderr)

    # The output has a "# Title" comment line followed by YAML key-value
    # pairs. Strip the comment so yaml.safe_load gets clean input.
    lines = [line for line in result.stdout.splitlines() if not line.startswith("#")]
    cleaned = "\n".join(lines)

    try:
        parsed = yaml.safe_load(cleaned)
        return parsed if isinstance(parsed, dict) else {}
    except yaml.YAMLError as exc:
        print(f"Warning: could not parse metadata output: {exc}", file=sys.stderr)
        return {}


def build_front_matter(
    *,
    title: str,
    author: str,
    series: str | None,
    book_number: int | None,
    qid: str | None,
    metadata: dict[str, str | list[str] | None],
) -> str:
    """Build the YAML front matter block."""
    slug = snake_case(title)
    today = date.today().isoformat()

    lines = ["---"]
    lines.append(f"date: {today}")
    lines.append(f"title: {title}")
    lines.append(f"book_authors: {author}")
    lines.append(f"series: {series or 'null'}")
    lines.append(f"book_number: {book_number or 'null'}")
    lines.append("is_anthology: false")
    lines.append("rating: null")
    lines.append(f"image: /books/covers/{slug}.jpg")

    if qid:
        lines.append(f"wikidata_qid: {qid}")

    isbn = metadata.get("isbn")
    if isbn:
        lines.append(f"isbn: {isbn}")

    date_published = metadata.get("date_published")
    if date_published:
        lines.append(f"date_published: {date_published}")

    same_as = metadata.get("same_as_urls")
    if isinstance(same_as, list) and same_as:
        lines.append("same_as_urls:")
        for url in same_as:
            lines.append(f'  - "{url}"')

    lines.append("---")
    return "\n".join(lines)


def build_opening(
    *,
    series: str | None,
    book_number: int | None,
) -> str:
    """Build the opening paragraph."""
    tag_line = (
        "{% book_link page.title %}, by {% author_link page.book_authors link=false %},"
    )

    if series and book_number:
        ord_str = ordinal(book_number)
        return f"{tag_line}\nis the {ord_str} book in {{% series_text page.series link=false %}}."
    elif series:
        return f"{tag_line}\nis a book in {{% series_text page.series link=false %}}."
    else:
        return f"{tag_line}\nis ..."


def load_captures_from_template(*, series: str | None) -> str:
    """Read capture blocks from _books/_template/book_template.md.

    Extracts all lines starting with '{% capture' from the template.
    Drops the 'this_series' capture for standalone (non-series) books.
    """
    if not TEMPLATE_PATH.exists():
        print(
            f"Error: template not found at {TEMPLATE_PATH}",
            file=sys.stderr,
        )
        sys.exit(1)

    lines = []
    for line in TEMPLATE_PATH.read_text().splitlines():
        stripped = line.strip()
        if not stripped.startswith("{% capture"):
            continue
        if not series and "this_series" in stripped:
            continue
        lines.append(stripped)

    if not lines:
        print(
            f"Error: no capture blocks found in {TEMPLATE_PATH}",
            file=sys.stderr,
        )
        sys.exit(1)

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a book review stub for _books/.",
    )
    parser.add_argument("--title", required=True, help="Book title")
    parser.add_argument("--author", required=True, help="Author name")
    parser.add_argument(
        "--series", default=None, help="Series name (omit for standalone)"
    )
    parser.add_argument(
        "--book-number", type=int, default=None, help="Position in series"
    )
    parser.add_argument("--qid", default=None, help="Wikidata Q-ID (e.g. Q302026)")
    parser.add_argument(
        "--output",
        "-o",
        default=None,
        help="Write to file instead of stdout",
    )

    args = parser.parse_args()

    # Fetch metadata if QID provided.
    metadata: dict[str, str | list[str] | None] = {}
    if args.qid:
        metadata = fetch_metadata(args.qid)

    front_matter = build_front_matter(
        title=args.title,
        author=args.author,
        series=args.series,
        book_number=args.book_number,
        qid=args.qid,
        metadata=metadata,
    )

    opening = build_opening(series=args.series, book_number=args.book_number)
    captures = load_captures_from_template(series=args.series)

    content = f"{front_matter}\n\n{opening}\n\n{captures}\n"

    if args.output:
        with open(args.output, "w") as f:
            f.write(content)
        print(f"Wrote {args.output}", file=sys.stderr)
    else:
        print(content)


if __name__ == "__main__":
    main()
