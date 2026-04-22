#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""Update a book review file's front matter with Wikidata metadata.

Example: ../../_books/matter.md

Reads a _books/*.md file, fetches metadata from Wikidata, and writes
the results (wikidata_qid, isbn, date_published, same_as_urls) directly
into the file's YAML front matter.

Usage:
    uv run update_book_metadata.py _books/matter.md
    uv run update_book_metadata.py _books/matter.md --qid Q302026
    uv run update_book_metadata.py _books/matter.md --force
"""

from __future__ import annotations

import argparse
import re
import sys

from fetch_book_metadata import BOOK_PROPERTY_MAP
from wikidata_utils import (
    api_get,
    extract_same_as_urls,
    fetch_awards,
    fetch_entity,
    get_claim_strings,
    get_claim_time,
    get_earliest_edition_isbn,
    yaml_quoted,
)


def search_book_entity(title: str, author: str) -> str:
    """Search Wikidata for a book, prioritizing results that mention the author.

    Fetches up to 15 results for the title, sorts those whose description
    contains the author's surname to the top, then presents the interactive
    picker.
    """
    data = api_get(
        {
            "action": "wbsearchentities",
            "search": title,
            "language": "en",
            "type": "item",
            "limit": "15",
        }
    )
    results = data.get("search", [])
    if not results:
        print(f"No Wikidata entity found for: {title}", file=sys.stderr)
        sys.exit(1)

    # Sort: results whose description mentions the author's surname first.
    author_surname = author.split()[-1].lower() if author else ""
    if author_surname:
        results.sort(
            key=lambda r: author_surname not in r.get("description", "").lower()
        )

    for i, r in enumerate(results):
        desc = r.get("description", "")
        print(
            f"  [{i}] {r['id']}  {r['label']}" + (f" — {desc}" if desc else ""),
            file=sys.stderr,
        )

    if sys.stdin.isatty():
        print(file=sys.stderr)
        choice = input("Pick a result [0]: ").strip()
        idx = int(choice) if choice.isdigit() and int(choice) < len(results) else 0
    else:
        idx = 0

    qid = results[idx]["id"]
    print(f"\nUsing: {qid} ({results[idx].get('label', '')})\n", file=sys.stderr)
    return qid


# Fields this script manages, in output order.
MANAGED_FIELDS = ("wikidata_qid", "isbn", "date_published", "awards", "same_as_urls")

# Regex to match a managed field and any indented continuation lines
# (e.g. same_as_urls list items).
_MANAGED_RE = re.compile(
    r"^(?:" + "|".join(MANAGED_FIELDS) + r"):.*(?:\n  - .*)*",
    re.MULTILINE,
)


def extract_front_matter_keys(front_matter: str) -> dict[str, str]:
    """Extract top-level key: value pairs from front matter text.

    Returns a dict mapping key names to their scalar string values.
    List values and complex structures are not parsed; only presence
    of the key matters for most uses. For scalar values we strip
    surrounding quotes.
    """
    result: dict[str, str] = {}
    for match in re.finditer(r"^(\w+):\s*(.*)$", front_matter, re.MULTILINE):
        key = match.group(1)
        val = match.group(2).strip()
        # Strip quotes.
        if len(val) >= 2 and val[0] == val[-1] and val[0] in ('"', "'"):
            val = val[1:-1]
        result[key] = val
    return result


def parse_file(path: str) -> tuple[str, str, str]:
    """Split a Jekyll file into (front_matter_text, closing_marker, body).

    Returns the front matter content (between the --- markers, not including
    the markers themselves), the closing --- line, and everything after it.
    """
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if not content.startswith("---\n"):
        print(f"Error: {path} does not start with ---", file=sys.stderr)
        sys.exit(1)

    end = content.index("\n---", 4)
    front_matter = content[4 : end + 1]  # includes trailing newline
    body = content[end + 5 :]  # skip past \n---\n
    return front_matter, "---\n", body


def strip_managed_fields(front_matter: str) -> str:
    """Remove lines for managed fields from front matter text."""
    result = _MANAGED_RE.sub("", front_matter)
    # Clean up any resulting double blank lines.
    while "\n\n\n" in result:
        result = result.replace("\n\n\n", "\n\n")
    return result


def format_field(key: str, value) -> str:
    """Format a single field as YAML text."""
    if key == "awards":
        if not value:
            return ""
        lines = [f"{key}:"]
        for award in value:
            lines.append(f"  - {award}")
        return "\n".join(lines)

    if value is None:
        return f"{key}: null"

    if key == "same_as_urls":
        lines = [f"{key}:"]
        for url in value:
            lines.append(f"  - {yaml_quoted(url)}")
        return "\n".join(lines)

    if isinstance(value, str):
        return f"{key}: {yaml_quoted(value)}"

    return f"{key}: {value}"


def fetch_metadata(qid: str) -> dict:
    """Fetch book metadata from Wikidata, returning a dict of field values."""
    entity = fetch_entity(qid)

    # ISBN
    isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(entity, "P957")
    isbn = isbn_list[0] if isbn_list else None
    if not isbn:
        print("No ISBN on work entity, querying editions...", file=sys.stderr)
        isbn = get_earliest_edition_isbn(qid)

    # Publication date
    date_published = get_claim_time(entity, "P577")

    # Awards
    awards = fetch_awards(qid)

    # sameAs URLs
    urls = extract_same_as_urls(entity, qid, BOOK_PROPERTY_MAP)

    return {
        "wikidata_qid": qid,
        "isbn": isbn,
        "date_published": date_published,
        "awards": awards if awards else None,
        "same_as_urls": urls if urls else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update book front matter with Wikidata metadata."
    )
    parser.add_argument("file", help="Path to a _books/*.md file")
    parser.add_argument("--qid", help="Wikidata Q-ID (skips search)")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing fields instead of skipping",
    )
    args = parser.parse_args()

    # Parse the file.
    front_matter, closing, body = parse_file(args.file)
    existing = extract_front_matter_keys(front_matter)

    # Resolve Q-ID: --qid flag → front matter → search by title.
    if args.qid:
        qid = args.qid
    elif existing.get("wikidata_qid"):
        qid = existing["wikidata_qid"]
        print(f"Using wikidata_qid from front matter: {qid}", file=sys.stderr)
    else:
        title = existing.get("title", "")
        if not title:
            print(f"Error: no title in {args.file} front matter", file=sys.stderr)
            sys.exit(1)
        author = existing.get("book_authors", "")
        qid = search_book_entity(title, author)

    # Fetch metadata.
    metadata = fetch_metadata(qid)

    # Determine which fields to write.
    if args.force:
        fields_to_write = list(MANAGED_FIELDS)
        front_matter = strip_managed_fields(front_matter)
    else:
        fields_to_write = [f for f in MANAGED_FIELDS if f not in existing]

    if not fields_to_write:
        print("All fields already present. Nothing to do.", file=sys.stderr)
        return

    # Build new YAML lines.
    new_lines = []
    for field in fields_to_write:
        formatted = format_field(field, metadata[field])
        if formatted:
            new_lines.append(formatted)

    # Ensure front matter ends with exactly one newline before we append.
    front_matter = front_matter.rstrip("\n") + "\n"

    # Assemble and write.
    updated_front_matter = front_matter + "\n".join(new_lines) + "\n"
    output = "---\n" + updated_front_matter + closing + body

    with open(args.file, "w", encoding="utf-8") as f:
        f.write(output)

    # Summary.
    action = "replaced" if args.force else "added"
    for field in fields_to_write:
        val = metadata[field]
        if field == "same_as_urls" and val:
            print(f"  {action}: {field} ({len(val)} URLs)", file=sys.stderr)
        elif field == "awards" and val:
            print(f"  {action}: {field} = {', '.join(val)}", file=sys.stderr)
        else:
            display = "null" if val is None else val
            print(f"  {action}: {field} = {display}", file=sys.stderr)

    skipped = [f for f in MANAGED_FIELDS if f not in fields_to_write]
    for field in skipped:
        print(f"  skipped: {field} (already set)", file=sys.stderr)

    print(f"\nUpdated {args.file}", file=sys.stderr)


if __name__ == "__main__":
    main()
