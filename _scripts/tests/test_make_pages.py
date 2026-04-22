"""Tests for content/make_pages.py pure functions."""

import tempfile
from pathlib import Path

from make_pages import extract_frontmatter, extract_metadata_from_books, normalize_filename


class TestNormalizeFilename:
    def test_lowercases(self):
        assert normalize_filename("John Smith") == "john_smith"

    def test_replaces_special_chars(self):
        assert normalize_filename("O'Brien") == "o_brien"
        assert normalize_filename("Name-With-Hyphens") == "name-with-hyphens"  # hyphens preserved

    def test_collapses_multiple_underscores(self):
        assert normalize_filename("Name   With   Spaces") == "name_with_spaces"

    def test_strips_leading_trailing_underscores(self):
        assert normalize_filename("_Name_") == "name"
        assert normalize_filename("__test__") == "test"

    def test_handles_unicode(self):
        result = normalize_filename("José García")
        assert "jos" in result


class TestExtractFrontmatter:
    def test_extracts_yaml(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("---\ntitle: Test Book\nauthor: Jane\n---\nContent here.")
            f.flush()
            result = extract_frontmatter(Path(f.name))
        assert result["title"] == "Test Book"
        assert result["author"] == "Jane"

    def test_no_frontmatter_returns_empty(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("No front matter here.")
            f.flush()
            result = extract_frontmatter(Path(f.name))
        assert result == {}

    def test_invalid_yaml_returns_empty(self):
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
            f.write("---\n[invalid yaml\n---\n")
            f.flush()
            result = extract_frontmatter(Path(f.name))
        assert result == {}


class TestExtractMetadataFromBooks:
    def test_extracts_authors_and_series(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            book_dir = Path(tmpdir)
            (book_dir / "book1.md").write_text(
                "---\ntitle: Book 1\nbook_authors: Jane Doe\nseries: Test Series\n---\n"
            )
            (book_dir / "book2.md").write_text(
                "---\ntitle: Book 2\nbook_authors:\n  - John Smith\n  - Jane Doe\n---\n"
            )

            authors, series = extract_metadata_from_books(book_dir)
            assert "Jane Doe" in authors
            assert "John Smith" in authors
            assert "Test Series" in series

    def test_deduplicates_authors(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            book_dir = Path(tmpdir)
            (book_dir / "book1.md").write_text(
                "---\nbook_authors: Jane Doe\n---\n"
            )
            (book_dir / "book2.md").write_text(
                "---\nbook_authors: Jane Doe\n---\n"
            )

            authors, _ = extract_metadata_from_books(book_dir)
            assert authors.count("Jane Doe") == 1

    def test_empty_dir_returns_empty_lists(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            authors, series = extract_metadata_from_books(Path(tmpdir))
            assert authors == []
            assert series == []
