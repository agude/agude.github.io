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
hand.

Usage:
    # By Q-ID (preferred, unambiguous):
    uv run list_editions.py Q302026

    # By title (searches Wikidata, lets you pick from results):
    uv run list_editions.py "Hyperion"
"""

from __future__ import annotations

import sys

from wikidata_utils import (
    ENGLISH_LANGUAGE_QID,
    api_get,
    fetch_entity,
    get_claim_entity_ids,
    get_claim_strings,
    resolve_qid,
)


def list_editions(work_qid: str) -> list[dict]:
    """Return per-edition ISBN/language/label info for a work's editions."""
    work = fetch_entity(work_qid)
    edition_qids = get_claim_entity_ids(work, "P747")
    if not edition_qids:
        return []

    editions = []
    for i in range(0, len(edition_qids), 50):
        batch = edition_qids[i : i + 50]
        data = api_get(
            {
                "action": "wbgetentities",
                "ids": "|".join(batch),
                "props": "claims|labels",
                "languages": "en",
            }
        )
        for qid in batch:
            entity = data.get("entities", {}).get(qid, {})
            isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(
                entity, "P957"
            )
            language_qids = get_claim_entity_ids(entity, "P407")
            editions.append(
                {
                    "qid": qid,
                    "label": entity.get("labels", {}).get("en", {}).get("value", ""),
                    "isbn": isbn_list[0] if isbn_list else None,
                    "is_english": ENGLISH_LANGUAGE_QID in language_qids,
                }
            )
    return editions


def pick_selected_isbn(editions: list[dict]) -> str | None:
    """Pick the ISBN that get_earliest_edition_isbn would select.

    Prefers English-language editions; falls back to the first ISBN found.
    """
    fallback = None
    for ed in editions:
        if ed["isbn"] is None:
            continue
        if fallback is None:
            fallback = ed["isbn"]
        if ed["is_english"]:
            return ed["isbn"]
    return fallback


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
    qid = resolve_qid(arg)

    editions = list_editions(qid)
    selected_isbn = pick_selected_isbn(editions)
    print(format_editions(qid, editions, selected_isbn))


if __name__ == "__main__":
    main()
