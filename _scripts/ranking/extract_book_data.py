#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# ///
"""Extract book data from _books/ front matter and first paragraphs.

Outputs a JSON state file suitable for the ELO ranking tool. Match history
recorded by the ranking UIs is carried over from any existing state file, so
regenerating after adding a review never discards recorded votes.
"""

import json
import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
BOOKS_DIR = PROJECT_ROOT / "_books"
BY_RATING_FILE = PROJECT_ROOT / "books" / "by_rating.md"
OUTPUT_FILE = Path(__file__).resolve().parent / "book_ranking_state.json"

DEFAULT_CREATED = "2026-03-01"

# Seed ELO based on current rating so the matchup selector
# starts with useful signal.  200-point gaps ≈ 75% expected
# win rate against the tier below.
RATING_TO_ELO = {
    1: 1100,
    2: 1300,
    3: 1500,
    4: 1700,
    5: 1900,
}


def parse_front_matter(content: str) -> dict:
    """Parse YAML front matter between --- delimiters.

    Hand-rolled to avoid a PyYAML dependency.
    """
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, ""
    fm_text = parts[1]
    body = parts[2]
    fm = {}
    current_key = None
    current_list = None

    for line in fm_text.split("\n"):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        # List item under a key
        if stripped.startswith("- ") and current_key is not None:
            value = stripped[2:].strip().strip('"').strip("'")
            if current_list is None:
                current_list = []
            current_list.append(value)
            fm[current_key] = current_list
            continue

        # Key: value pair
        if ":" in stripped:
            # Close any open list
            current_list = None

            key, _, value = stripped.partition(":")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            current_key = key

            if value == "null" or value == "":
                fm[key] = None
            elif value == "true":
                fm[key] = True
            elif value == "false":
                fm[key] = False
            else:
                # Try int
                try:
                    fm[key] = int(value)
                except ValueError:
                    fm[key] = value

    return fm, body


def extract_paragraphs(body: str) -> tuple[str, str]:
    """Extract the first two non-capture paragraphs from the body.

    Skips {% capture %} blocks and blank lines.
    """
    paragraphs = []
    current = []

    for line in body.strip().split("\n"):
        stripped = line.strip()

        if stripped == "":
            if current:
                text = " ".join(current)
                # Skip capture blocks and comment blocks
                if not re.match(r"^\{%\s*(capture|comment)\b", text):
                    paragraphs.append(text)
                current = []
            continue

        current.append(stripped)

    # Don't forget last paragraph
    if current:
        text = " ".join(current)
        if not re.match(r"^\{%\s*(capture|comment)\b", text):
            paragraphs.append(text)

    raw = clean_liquid(paragraphs[0]) if len(paragraphs) > 0 else ""
    extra = clean_liquid(paragraphs[1]) if len(paragraphs) > 1 else ""
    return raw, extra


def clean_liquid(text: str) -> str:
    """Strip Liquid tags and output variables, clean up whitespace."""
    # Strip {% ... %} tags
    text = re.sub(r"\{%.*?%\}", "", text)
    # Strip {{ ... }} output tags
    text = re.sub(r"\{\{.*?\}\}", "", text)
    # Strip HTML tags
    text = re.sub(r"<[^>]+>", "", text)
    # Collapse whitespace
    text = re.sub(r"\s+", " ", text).strip()
    # Remove common leading boilerplate
    # ", by , is the Nth book in ."
    text = re.sub(r"^[,\s]+", "", text)
    text = re.sub(r"^by\s*,?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(
        r"^is the \w+( and final)? book in\s*[.\s]*",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r"^is an? [^.]*by\s*[.\s]*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"^is an? [^.]*\.\s*", "", text, flags=re.IGNORECASE)
    # Clean up residual leading punctuation
    text = re.sub(r"^[,.\s]+", "", text)
    # Capitalize first letter
    if text:
        text = text[0].upper() + text[1:]
    return text


def slug_from_path(path: Path) -> str:
    """Convert a file path to a slug key."""
    return path.stem


def build_title_to_slug_map(books: dict) -> dict[str, str]:
    """Build a case-insensitive title -> slug lookup."""
    mapping = {}
    for slug, data in books.items():
        mapping[data["title"].lower()] = slug
    return mapping


def extract_ranked_list(books: dict) -> list[str]:
    """Read the ranked_list from by_rating.md and return as ordered slugs."""
    if not BY_RATING_FILE.exists():
        print(f"Warning: {BY_RATING_FILE} not found, falling back to ELO order")
        slugs = list(books.keys())
        slugs.sort(key=lambda s: -(books[s].get("elo") or 1500))
        return slugs

    content = BY_RATING_FILE.read_text()
    fm, _ = parse_front_matter(content)
    titles = fm.get("ranked_list", [])
    if not titles:
        print("Warning: no ranked_list in by_rating.md, falling back to ELO order")
        slugs = list(books.keys())
        slugs.sort(key=lambda s: -(books[s].get("elo") or 1500))
        return slugs

    title_map = build_title_to_slug_map(books)
    ranked_slugs = []
    unmatched = []

    for title in titles:
        slug = title_map.get(title.lower())
        if slug:
            ranked_slugs.append(slug)
        else:
            unmatched.append(title)

    if unmatched:
        print(f"Warning: {len(unmatched)} titles not matched to book files:")
        for t in unmatched:
            print(f"  - {t}")

    # Append any books not in the ranked list at the end
    ranked_set = set(ranked_slugs)
    for slug in sorted(books.keys()):
        if slug not in ranked_set:
            ranked_slugs.append(slug)

    return ranked_slugs


def load_existing_state(path: Path) -> dict:
    """Return the existing state file, or an empty state if there is none.

    A malformed file raises rather than being silently replaced: the state file
    holds hand-written summaries and hundreds of recorded votes, so a reset is
    never the safe interpretation of a parse error.
    """
    if not path.exists():
        return {}

    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Refusing to overwrite unreadable state file {path}: {exc}") from exc


def carry_over_book(book: dict, previous: dict) -> dict:
    """Merge ranking results from a previous entry into a freshly parsed book.

    Front matter is the source of truth for title, authors, and rating, but the
    ranking UIs own ``summary``, ``elo``, and ``matches``. Those are only ever
    written by hand or by voting, so they are carried over rather than reseeded.
    """
    if not previous:
        return book

    if previous.get("summary"):
        book["summary"] = previous["summary"]
    if previous.get("elo") is not None:
        book["elo"] = previous["elo"]
    if previous.get("matches") is not None:
        book["matches"] = previous["matches"]
    return book


def main():
    previous_state = load_existing_state(OUTPUT_FILE)
    previous_books = previous_state.get("books", {})
    books = {}

    for filepath in sorted(BOOKS_DIR.glob("*.md")):
        if filepath.name.startswith("_"):
            continue

        content = filepath.read_text()
        fm, body = parse_front_matter(content)

        if not fm.get("title"):
            continue

        slug = slug_from_path(filepath)

        authors = fm.get("book_authors", [])
        if isinstance(authors, str):
            authors = [authors]

        summary_raw, summary_extra = extract_paragraphs(body)

        books[slug] = carry_over_book(
            {
                "title": fm["title"],
                "authors": authors,
                "series": fm.get("series"),
                "book_number": fm.get("book_number"),
                "rating": fm.get("rating"),
                "image": fm.get("image"),
                "summary_raw": summary_raw,
                "summary_extra": summary_extra,
                "summary": "",
                "elo": RATING_TO_ELO.get(fm.get("rating"), 1500),
                "matches": 0,
            },
            previous_books.get(slug, {}),
        )

    ranked_list = extract_ranked_list(books)
    matches = previous_state.get("matches", [])
    created = previous_state.get("meta", {}).get("created", DEFAULT_CREATED)
    new_books = [slug for slug in books if slug not in previous_books]

    state = {
        "meta": {
            "created": created,
            "total_matches": len(matches),
        },
        "matches": matches,
        "books": books,
        "ranked_list": ranked_list,
    }

    OUTPUT_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n")
    print(
        f"Wrote {len(books)} books ({len(ranked_list)} ranked, "
        f"{len(new_books)} new, {len(matches)} matches kept) to {OUTPUT_FILE}"
    )


if __name__ == "__main__":
    main()
