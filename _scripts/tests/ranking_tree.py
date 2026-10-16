"""Shared fixture tree for the ranking CLI entrypoint tests."""

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]


def write_book(books_dir: Path, slug: str, title: str, rating: int) -> Path:
    path = books_dir / f"{slug}.md"
    path.write_text(f"---\ntitle: {title}\nrating: {rating}\n---\n\nReview of {title}.\n")
    return path


def build_tree(root: Path, ranked_list: str, books: dict[str, tuple[str, int]]) -> None:
    """Write `_books/` and `books/by_rating.md` under `root`."""
    books_dir = root / "_books"
    books_dir.mkdir()
    for slug, (title, rating) in books.items():
        write_book(books_dir, slug, title, rating)
    (root / "books").mkdir()
    (root / "books" / "by_rating.md").write_text(
        f"---\ntitle: By Rating\nranked_list:\n{ranked_list}layout: page\n---\n\nBody.\n"
    )


def point_module_at(monkeypatch, module, root: Path) -> None:
    monkeypatch.setattr(module, "REPO_ROOT", root)
    monkeypatch.setattr(module, "BOOKS_DIR", root / "_books")
    monkeypatch.setattr(module, "BY_RATING", root / "books" / "by_rating.md")
    monkeypatch.setattr(sys, "argv", [module.__file__])
