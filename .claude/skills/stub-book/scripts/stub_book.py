#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Assemble a book review stub from the template and CLI arguments.

Reads _books/_template/book_template.md, replaces sentinel comments with
the provided values, and writes the result. All "brains" (choosing the
opening paragraph, deciding which metadata fields to include) live in the
caller — this script is purely mechanical.

Usage:
    uv run stub_book.py \
        --front-matter "title: Hyperion\nbook_authors: Dan Simmons\n..." \
        --opening "{% book_link page.title %}, by ..., is ..." \
        --series \
        --output _books/hyperion.md
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import yaml

_SCRIPT_DIR = Path(__file__).resolve().parent
_SKILL_DIR = _SCRIPT_DIR.parent  # .claude/skills/stub-book/
_PROJECT_ROOT = _SKILL_DIR.parent.parent.parent
TEMPLATE_PATH = _PROJECT_ROOT / "_books" / "_template" / "book_template.md"
METADATA_SCRIPT_DIR = _PROJECT_ROOT / "_scripts" / "metadata"


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
            f"Warning: fetch_book_metadata.py failed:\n{result.stderr}",
            file=sys.stderr,
        )
        return {}

    if result.stderr:
        print(result.stderr, file=sys.stderr)

    lines = [line for line in result.stdout.splitlines() if not line.startswith("#")]
    cleaned = "\n".join(lines)

    try:
        parsed = yaml.safe_load(cleaned)
        return parsed if isinstance(parsed, dict) else {}
    except yaml.YAMLError as exc:
        print(f"Warning: could not parse metadata output: {exc}", file=sys.stderr)
        return {}


def build_template(
    *,
    front_matter: str,
    opening: str,
    series: bool,
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
            if series:
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
        "--front-matter",
        required=True,
        help="YAML front matter content (without --- delimiters)",
    )
    parser.add_argument(
        "--opening",
        required=True,
        help="Opening paragraph (Liquid markup)",
    )
    parser.add_argument(
        "--series",
        action="store_true",
        default=False,
        help="Include the this_series capture block",
    )
    parser.add_argument(
        "--qid",
        default=None,
        help="Wikidata Q-ID — fetches isbn, date_published, same_as_urls and appends to front matter",
    )
    parser.add_argument(
        "--output",
        "-o",
        default=None,
        help="Write to file instead of stdout",
    )

    args = parser.parse_args()

    front_matter = args.front_matter

    # If QID provided, fetch metadata and append to front matter
    if args.qid:
        metadata = fetch_metadata(args.qid)

        extra_lines = []
        extra_lines.append(f"wikidata_qid: {args.qid}")

        isbn = metadata.get("isbn")
        if isbn:
            extra_lines.append(f"isbn: {isbn}")

        date_published = metadata.get("date_published")
        if date_published:
            extra_lines.append(f"date_published: {date_published}")

        same_as = metadata.get("same_as_urls")
        if isinstance(same_as, list) and same_as:
            extra_lines.append("same_as_urls:")
            for url in same_as:
                extra_lines.append(f'  - "{url}"')

        front_matter = front_matter.rstrip() + "\n" + "\n".join(extra_lines)

    content = build_template(
        front_matter=front_matter,
        opening=args.opening,
        series=args.series,
    )

    if args.output:
        Path(args.output).write_text(content, encoding="utf-8")
        print(f"Wrote {args.output}", file=sys.stderr)
    else:
        print(content)


if __name__ == "__main__":
    main()
