"""Shared fixture tree for the ranking CLI entrypoint tests."""

import sys
from collections import Counter
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


def build_family_tree(root: Path, ranked_list: str) -> None:
    """Write a canonical review, its archived review, and two unrelated books.

    The canonical review `_books/hyperion.md` is rated 5. The archived review
    `_books/hyperion/review-2023-10-17.md` has the same title, a
    `canonical_url`, and rating 4, like the real Hyperion family.
    """
    build_tree(
        root,
        ranked_list,
        {"hyperion": ("Hyperion", 5), "dune": ("Dune", 4), "foundation": ("Foundation", 3)},
    )
    archive_dir = root / "_books" / "hyperion"
    archive_dir.mkdir()
    (archive_dir / "review-2023-10-17.md").write_text(
        "---\ntitle: Hyperion\ncanonical_url: /books/hyperion/\nrating: 4\n---\n\nOlder review.\n"
    )


def book_files(root: Path) -> list[Path]:
    return sorted(path.resolve() for path in (root / "_books").rglob("*.md"))


def count_reads(monkeypatch) -> Counter:
    """Count `Path.read_text` calls per resolved path from now on."""
    counts: Counter = Counter()
    original = Path.read_text

    def counting_read_text(self, *args, **kwargs):
        counts[self.resolve()] += 1
        return original(self, *args, **kwargs)

    monkeypatch.setattr(Path, "read_text", counting_read_text)
    return counts


def point_module_at(monkeypatch, module, root: Path) -> None:
    monkeypatch.setattr(module, "REPO_ROOT", root)
    monkeypatch.setattr(module, "BOOKS_DIR", root / "_books")
    monkeypatch.setattr(module, "BY_RATING", root / "books" / "by_rating.md")
    monkeypatch.setattr(sys, "argv", [module.__file__])
