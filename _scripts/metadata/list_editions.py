#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""List editions of a book work from Wikidata for manual ISBN review.

Example: Q302026

Given a Wikidata Q-ID or a book title, queries the Wikidata API for all
editions (P747) of the work and prints each edition's Q-ID, label,
language, and ISBN. Flags the edition that
`update_book_metadata.py`/`get_earliest_edition_isbn` would select, so a
mismatch (e.g. a foreign-language ISBN) can be caught and corrected by
hand. Both use the same edition fetch and selection rule.

Usage:
    # By Q-ID (preferred, unambiguous):
    uv run list_editions.py Q302026

    # By title (prints candidates for explicit Q-ID selection):
    uv run list_editions.py "Hyperion"
"""

from __future__ import annotations

import sys

from wikidata_utils import (
    fetch_editions,
    fetch_entity,
    is_qid,
    print_entity_candidates,
    resolve_qid,
    search_entity,
    select_edition_isbn,
)


def list_editions(work_qid: str) -> list[dict]:
    """Return per-edition ISBN/language/label info for a work's editions."""
    return list(fetch_editions(fetch_entity(work_qid)))


def format_editions(work_qid: str, editions: list[dict], selected_isbn: str | None) -> str:
    if not editions:
        return f"No editions (P747) found for {work_qid}."

    lines = [f"Editions of {work_qid}:"]
    for ed in editions:
        marker = " <- selected" if ed["isbn"] and ed["isbn"] == selected_isbn else ""
        lang = "en" if ed["is_english"] else "?"
        isbn = ed["isbn"] or "(no ISBN)"
        lines.append(f"  [{lang}] {ed['qid']}  {ed['label']}  {isbn}{marker}")
    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: uv run list_editions.py <Q-ID or book title>", file=sys.stderr)
        sys.exit(1)

    arg = " ".join(sys.argv[1:])
    if not is_qid(arg):
        print_entity_candidates(search_entity(arg))
        return

    qid = resolve_qid(arg)

    editions = list_editions(qid)
    selected_isbn = select_edition_isbn(editions)
    print(format_editions(qid, editions, selected_isbn))


if __name__ == "__main__":
    main()
