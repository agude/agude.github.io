#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""Update a book review file's front matter with Wikidata metadata.

Example: ../../_books/matter.md

Reads a _books/*.md file, fetches metadata from Wikidata, and writes
the results (wikidata_qid, isbn, date_published, awards, same_as_urls)
directly into the file's YAML front matter.

By default, only adds missing fields. Use --force to overwrite all, or
--only to refresh specific fields. Never overwrites existing values with
null (protects manually curated data).

Usage:
    uv run update_book_metadata.py _books/matter.md
    uv run update_book_metadata.py _books/matter.md --qid Q302026
    uv run update_book_metadata.py _books/matter.md --force
    uv run update_book_metadata.py _books/matter.md --only awards
    uv run update_book_metadata.py _books/matter.md --only awards,isbn
    uv run update_book_metadata.py _books/matter.md --log-level DEBUG
"""

from __future__ import annotations

import argparse
import logging
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

log = logging.getLogger(__name__)


def search_book_entity(title: str, author: str) -> str:
    """Search Wikidata for a book, prioritizing results that mention the author.

    Fetches up to 15 results for the title, sorts those whose description
    contains the author's surname to the top, then presents the interactive
    picker.
    """
    log.debug("Searching Wikidata for title=%r author=%r", title, author)
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
        log.error("No Wikidata entity found for: %s", title)
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
    log.info("Selected: %s (%s)", qid, results[idx].get("label", ""))
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
        log.error("%s does not start with ---", path)
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


def _strip_field(front_matter: str, field: str) -> str:
    """Remove a single field (and any indented continuation) from front matter."""
    pattern = re.compile(rf"^{field}:.*(?:\n  - .*)*\n?", re.MULTILINE)
    result = pattern.sub("", front_matter)
    # Collapse any double newlines left behind.
    while "\n\n" in result:
        result = result.replace("\n\n", "\n")
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
    log.debug("Fetching metadata for %s", qid)
    entity = fetch_entity(qid)

    # ISBN
    isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(entity, "P957")
    isbn = isbn_list[0] if isbn_list else None
    if not isbn:
        log.info("No ISBN on work entity, querying editions...")
        isbn = get_earliest_edition_isbn(qid)

    # Publication date
    date_published = get_claim_time(entity, "P577")

    # Awards
    awards = fetch_awards(qid)

    # sameAs URLs
    urls = extract_same_as_urls(entity, qid, BOOK_PROPERTY_MAP)

    log.debug("Fetched: isbn=%s date=%s awards=%s urls=%d",
              isbn, date_published, awards, len(urls) if urls else 0)

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
    parser.add_argument(
        "--only",
        help=f"Comma-separated fields to update: {','.join(MANAGED_FIELDS)}",
    )
    parser.add_argument(
        "--log-level",
        default="WARNING",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Set logging level (default: WARNING)",
    )
    args = parser.parse_args()

    # Configure logging.
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(levelname)s: %(message)s",
    )
    # Also enable urllib3 logging at DEBUG to see retry/backoff.
    if args.log_level == "DEBUG":
        logging.getLogger("urllib3").setLevel(logging.DEBUG)

    # Validate --only fields.
    only_fields: set[str] | None = None
    if args.only:
        only_fields = set(args.only.split(","))
        invalid = only_fields - set(MANAGED_FIELDS)
        if invalid:
            log.error("Unknown fields: %s", ", ".join(invalid))
            log.error("Valid fields: %s", ", ".join(MANAGED_FIELDS))
            sys.exit(1)

    # Parse the file.
    log.debug("Parsing %s", args.file)
    front_matter, closing, body = parse_file(args.file)
    existing = extract_front_matter_keys(front_matter)
    log.debug("Existing keys: %s", list(existing.keys()))

    # Resolve Q-ID: --qid flag → front matter → search by title.
    existing_qid = existing.get("wikidata_qid")
    if args.qid:
        qid = args.qid
    elif existing_qid and existing_qid != "null":
        qid = existing_qid
        log.info("Using wikidata_qid from front matter: %s", qid)
    elif only_fields:
        # Can't fetch specific fields without a Q-ID.
        log.warning("Skipping: no wikidata_qid in %s", args.file)
        return
    else:
        title = existing.get("title", "")
        if not title:
            log.error("No title in %s front matter", args.file)
            sys.exit(1)
        author = existing.get("book_authors", "")
        qid = search_book_entity(title, author)

    # Fetch metadata.
    metadata = fetch_metadata(qid)

    # Determine which fields to write.
    if args.force or only_fields:
        candidates = list(only_fields) if only_fields else list(MANAGED_FIELDS)
        # Never overwrite existing non-null values with null.
        fields_to_write = [
            f for f in candidates
            if metadata[f] is not None or f not in existing
        ]
        # Strip only the fields we're updating.
        for field in fields_to_write:
            if field in existing:
                front_matter = _strip_field(front_matter, field)
    else:
        fields_to_write = [f for f in MANAGED_FIELDS if f not in existing]

    if not fields_to_write:
        log.info("All fields already present. Nothing to do.")
        return

    # Build new YAML lines, filtering out empty results (e.g., awards with no data).
    new_lines = []
    fields_written = []
    for field in fields_to_write:
        formatted = format_field(field, metadata[field])
        if formatted:
            new_lines.append(formatted)
            fields_written.append(field)

    if not new_lines:
        empty_fields = [f for f in fields_to_write if not metadata[f]]
        log.info("Skipping: no data for %s", ", ".join(empty_fields))
        return

    # Ensure front matter ends with exactly one newline before we append.
    front_matter = front_matter.rstrip("\n") + "\n"

    # Assemble and write.
    updated_front_matter = front_matter + "\n".join(new_lines) + "\n"
    output = "---\n" + updated_front_matter + closing + body

    with open(args.file, "w", encoding="utf-8") as f:
        f.write(output)

    # Summary.
    for field in fields_written:
        val = metadata[field]
        action = "updated" if field in existing else "added"
        if field == "same_as_urls" and val:
            log.warning("%s: %s (%d URLs)", action, field, len(val))
        elif field == "awards" and val:
            log.warning("%s: %s = %s", action, field, ", ".join(val))
        else:
            log.warning("%s: %s = %s", action, field, val)

    # Report skipped fields.
    scope = set(only_fields) if only_fields else set(MANAGED_FIELDS)
    for field in MANAGED_FIELDS:
        if field in fields_written:
            continue
        if field not in scope:
            continue  # Not requested via --only.
        if field in existing and metadata[field] is None:
            log.info("skipped: %s (would overwrite with null)", field)
        elif field in existing:
            log.info("skipped: %s (already set)", field)
        elif not metadata[field]:
            log.info("skipped: %s (no data from Wikidata)", field)

    log.warning("Updated %s", args.file)


if __name__ == "__main__":
    main()
