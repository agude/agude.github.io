#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""Fetch author metadata from Wikidata for author page front matter.

Example: Q312579

Given a Wikidata Q-ID or an author name, queries the Wikidata API and
extracts same_as_urls and pen_names suitable for author page front matter.

Usage:
    # By Q-ID (preferred, unambiguous):
    uv run fetch_author_same_as.py Q312579

    # By name (searches Wikidata, lets you pick from results):
    uv run fetch_author_same_as.py "Iain M. Banks"
"""

from __future__ import annotations

import sys

from wikidata_utils import (
    extract_same_as_urls,
    fetch_entity,
    get_claim_strings,
    resolve_qid,
    yaml_quoted,
)

# Wikidata properties that map to useful author URLs.
# Each entry: (property_id, label, url_template or None)
# When url_template is None, the claim value is already a full URL.
AUTHOR_PROPERTY_MAP: list[tuple[str, str, str | None]] = [
    ("P856", "official website", None),
    ("P2963", "Goodreads", "https://www.goodreads.com/author/show/{value}"),
    (
        "P244",
        "Library of Congress",
        "https://id.loc.gov/authorities/names/{value}.html",
    ),
    ("P648", "Open Library", "https://openlibrary.org/authors/{value}"),
    ("P1233", "ISFDB", "https://www.isfdb.org/cgi-bin/ea.cgi?{value}"),
    ("P1417", "Britannica", "https://www.britannica.com/{value}"),
    ("P345", "IMDb", "https://www.imdb.com/name/{value}/"),
    ("P7400", "LibraryThing", "https://www.librarything.com/author/{value}"),
    ("P2949", "WikiTree", "https://www.wikitree.com/wiki/{value}"),
    ("P5491", "SFE (entry)", "https://sf-encyclopedia.com/entry/{value}"),
    ("P4657", "SFE (fantasy)", "https://sf-encyclopedia.com/fe/{value}"),
    ("P8947", "Google KG", "https://www.google.com/search?kgmid={value}"),
    ("P2191", "NNDB", "https://www.nndb.com/people/{value}/"),
]


def format_yaml(urls: list[str], pseudonyms: list[str], title: str) -> str:
    """Format extracted data as YAML front matter fields."""
    lines = [f"title: {yaml_quoted(title)}"]

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
    qid = resolve_qid(arg)

    entity = fetch_entity(qid)
    title = entity.get("labels", {}).get("en", {}).get("value", "")
    urls = extract_same_as_urls(entity, qid, AUTHOR_PROPERTY_MAP)
    pseudonyms = get_claim_strings(entity, "P742")

    print(format_yaml(urls, pseudonyms, title))


if __name__ == "__main__":
    main()
