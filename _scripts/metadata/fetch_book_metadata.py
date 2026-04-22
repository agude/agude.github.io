#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""Fetch book metadata from Wikidata for book review front matter.

Example: Q302026

Given a Wikidata Q-ID or a book title, queries the Wikidata API and
extracts isbn, date_published, and same_as_urls suitable for book front
matter.

Usage:
    # By Q-ID (preferred, unambiguous):
    uv run fetch_book_metadata.py Q302026

    # By title (searches Wikidata, lets you pick from results):
    uv run fetch_book_metadata.py "Hyperion"
"""

from __future__ import annotations

import sys

from wikidata_utils import (
    extract_same_as_urls,
    fetch_entity,
    get_claim_strings,
    get_claim_time,
    get_earliest_edition_isbn,
    resolve_qid,
    yaml_quoted,
)

# Wikidata properties that map to useful book URLs.
BOOK_PROPERTY_MAP: list[tuple[str, str, str | None]] = [
    ("P856", "official website", None),
    ("P2969", "Goodreads (work)", "https://www.goodreads.com/work/editions/{value}"),
    ("P648", "Open Library", "https://openlibrary.org/works/{value}"),
    ("P1233", "ISFDB (title)", "https://www.isfdb.org/cgi-bin/title.cgi?{value}"),
    ("P1274", "ISFDB (title ID)", "https://www.isfdb.org/cgi-bin/title.cgi?{value}"),
    ("P1417", "Britannica", "https://www.britannica.com/{value}"),
    ("P7400", "LibraryThing", "https://www.librarything.com/work/{value}"),
    ("P1085", "LibraryThing (work ID)", "https://www.librarything.com/work/{value}"),
    ("P646", "Freebase", "https://www.google.com/search?kgmid={value}"),
    ("P8947", "Google KG", "https://www.google.com/search?kgmid={value}"),
]


def format_yaml(
    isbn: str | None,
    date_published: str | None,
    urls: list[str],
    title: str,
) -> str:
    """Format extracted data as YAML front matter fields."""
    lines = [f"# {title}"]

    if isbn:
        lines.append(f"isbn: {yaml_quoted(isbn)}")

    if date_published:
        lines.append(f"date_published: {yaml_quoted(date_published)}")

    if urls:
        lines.append("same_as_urls:")
        for url in urls:
            lines.append(f"  - {yaml_quoted(url)}")

    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) < 2:
        print(
            "Usage: uv run fetch_book_metadata.py <Q-ID or book title>", file=sys.stderr
        )
        sys.exit(1)

    arg = " ".join(sys.argv[1:])
    qid = resolve_qid(arg)

    entity = fetch_entity(qid)
    title = entity.get("labels", {}).get("en", {}).get("value", "")

    # ISBN — try the work entity first (P212 then P957), then fall back
    # to SPARQL over edition entities (P629).  Take the first available
    # ISBN regardless of type; old books only have ISBN-10.
    isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(entity, "P957")
    isbn = isbn_list[0] if isbn_list else None

    if not isbn:
        print("No ISBN on work entity, querying editions...", file=sys.stderr)
        isbn = get_earliest_edition_isbn(qid)

    # Publication date (P577)
    date_published = get_claim_time(entity, "P577")

    # sameAs URLs
    urls = extract_same_as_urls(entity, qid, BOOK_PROPERTY_MAP)

    print(format_yaml(isbn, date_published, urls, title))


if __name__ == "__main__":
    main()
