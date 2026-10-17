# not-a-script
"""Index the book reviews in _books/ by title, reading each file once.

Shared by push_ratings_from_ranking.py and reorder_ranking.py. Both sit in
this directory, which is on sys.path when either one runs.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

# `uv run` puts only the running script's directory on sys.path.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "common"))

from front_matter import split_front_matter

RATING_RE = re.compile(r"^rating:\s*(\d+)", re.MULTILINE)

# Holds the stub template for new reviews, not a review.
TEMPLATE_DIR = "_template"


@dataclass(frozen=True)
class BookFile:
    """A review file and the text it had when the index read it."""

    path: Path
    text: str

    @property
    def rating(self) -> int | None:
        match = RATING_RE.search(self.text)
        return int(match.group(1)) if match else None


def parse_front_matter(text: str) -> dict | None:
    """Return the parsed YAML front matter, `{}` if it is not a mapping, or None if absent."""
    split = split_front_matter(text)
    if split is None:
        return None
    parsed = yaml.safe_load(split[0])
    return parsed if isinstance(parsed, dict) else {}


def review_paths(books_dir: Path) -> list[Path]:
    """Return the Markdown files in `books_dir` and its subdirectories, minus the template."""
    paths = sorted(books_dir.glob("*.md"))
    for subdir in sorted(books_dir.iterdir()):
        if subdir.is_dir() and subdir.name != TEMPLATE_DIR:
            paths.extend(sorted(subdir.glob("*.md")))
    return paths


def build_title_index(books_dir: Path) -> dict[str, BookFile]:
    """Map each lower-cased review title to its review file.

    An archived review has `canonical_url` and the same title as its
    canonical review, so it is left out. Exits naming both paths when two
    remaining files share a title, before the caller writes anything.
    """
    index: dict[str, BookFile] = {}
    for path in review_paths(books_dir):
        text = path.read_text()
        front_matter = parse_front_matter(text) or {}
        title = front_matter.get("title")
        if "canonical_url" in front_matter or not isinstance(title, str):
            continue

        key = title.lower()
        if key in index:
            sys.exit(
                f"Two book files have the title {title!r}: {index[key].path} and {path}. "
                "Give one a canonical_url or a different title. Nothing was changed."
            )
        index[key] = BookFile(path, text)
    return index
