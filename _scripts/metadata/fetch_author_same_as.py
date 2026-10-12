#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""Fetch author metadata from Wikidata for author page front matter.

Example: Q312579

Given a Wikidata Q-ID or an author name, queries the Wikidata API and
extracts wikidata_qid, same_as_urls, and pen_names suitable for author page
front matter. same_as_urls omits the Wikidata URL: the site builds it from
wikidata_qid.

Usage:
    # By Q-ID (preferred, unambiguous):
    uv run fetch_author_same_as.py Q312579

    # By name (prints candidates for explicit Q-ID selection):
    uv run fetch_author_same_as.py "Iain M. Banks"
"""

from __future__ import annotations

import sys

from wikidata_utils import (
    extract_same_as_urls,
    fetch_entity,
    get_claim_strings,
    is_qid,
    print_entity_candidates,
    resolve_qid,
    search_entity,
    yaml_quoted,
)

# Wikidata properties that map to useful author URLs.
# Labels are the properties' Wikidata labels. Tests pin each ID to its
# Wikidata formatter URL; check a new ID's label before adding it.
# Each entry: (property_id, label, url_template or None)
# When url_template is None, the claim value is already a full URL.
AUTHOR_PROPERTY_MAP: list[tuple[str, str, str | None]] = [
    ("P856", "official website", None),
    ("P2963", "Goodreads author ID", "https://www.goodreads.com/author/show/{value}"),
    (
        "P244",
        "Library of Congress Authorities ID",
        "https://id.loc.gov/authorities/names/{value}.html",
    ),
    ("P648", "Open Library ID", "https://openlibrary.org/authors/{value}"),
    ("P1233", "ISFDB author ID", "https://www.isfdb.org/cgi-bin/ea.cgi?{value}"),
    ("P1417", "Britannica Online ID", "https://www.britannica.com/{value}"),
    ("P345", "IMDb ID", "https://www.imdb.com/name/{value}/"),
    ("P7400", "LibraryThing author ID", "https://www.librarything.com/author/{value}"),
    ("P2949", "WikiTree person ID", "https://www.wikitree.com/wiki/{value}"),
    ("P5357", "Encyclopedia of Science Fiction ID", "https://sf-encyclopedia.com/entry/{value}"),
    ("P10883", "The Encyclopedia of Fantasy ID", "https://sf-encyclopedia.com/fe/{value}"),
    ("P1263", "NNDB people ID", "https://www.nndb.com/people/{value}/"),
    ("P2671", "Google Knowledge Graph ID", "https://www.google.com/search?kgmid={value}"),
    ("P646", "Freebase ID", "https://www.google.com/search?kgmid={value}"),
]


def format_yaml(qid: str, urls: list[str], pseudonyms: list[str], title: str) -> str:
    """Format extracted data as YAML front matter fields."""
    lines = [f"title: {yaml_quoted(title)}", f"wikidata_qid: {yaml_quoted(qid)}"]

    if pseudonyms:
        lines.append("pen_names:")
        for name in pseudonyms:
            lines.append(f"  - {yaml_quoted(name)}")

    lines.append("same_as_urls:")
    for url in urls:
        lines.append(f"  - {yaml_quoted(url)}")

    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) < 2:
        print(
            "Usage: uv run fetch_author_same_as.py <Q-ID or author name>",
            file=sys.stderr,
        )
        sys.exit(1)

    arg = " ".join(sys.argv[1:])
    if not is_qid(arg):
        print_entity_candidates(search_entity(arg))
        return

    qid = resolve_qid(arg)

    entity = fetch_entity(qid)
    title = entity.get("labels", {}).get("en", {}).get("value", "")
    urls = extract_same_as_urls(entity, AUTHOR_PROPERTY_MAP)
    pseudonyms = get_claim_strings(entity, "P742")

    print(format_yaml(qid, urls, pseudonyms, title))


if __name__ == "__main__":
    main()
