"""Tests for content/make_pages.py pure functions."""

import make_pages
import pytest
import yaml
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
        assert normalize_filename("José García") == "josé_garcía"
        assert normalize_filename("Tête-à-Tête") == "tête-à-tête"


class TestExtractFrontmatter:
    def test_extracts_yaml(self, tmp_path):
        f = tmp_path / "test.md"
        f.write_text("---\ntitle: Test Book\nauthor: Jane\n---\nContent here.")
        result = extract_frontmatter(f)
        assert result["title"] == "Test Book"
        assert result["author"] == "Jane"

    def test_no_frontmatter_returns_empty(self, tmp_path):
        f = tmp_path / "test.md"
        f.write_text("No front matter here.")
        result = extract_frontmatter(f)
        assert result == {}

    def test_invalid_yaml_returns_empty(self, tmp_path):
        f = tmp_path / "test.md"
        f.write_text("---\n[invalid yaml\n---\n")
        result = extract_frontmatter(f)
        assert result == {}


class TestExtractMetadataFromBooks:
    def test_extracts_authors_and_series(self, tmp_path):
        (tmp_path / "book1.md").write_text(
            "---\ntitle: Book 1\nbook_authors: Jane Doe\nseries: Test Series\n---\n"
        )
        (tmp_path / "book2.md").write_text(
            "---\ntitle: Book 2\nbook_authors:\n  - John Smith\n  - Jane Doe\n---\n"
        )

        authors, series = extract_metadata_from_books(tmp_path)
        assert "Jane Doe" in authors
        assert "John Smith" in authors
        assert "Test Series" in series

    def test_deduplicates_authors(self, tmp_path):
        (tmp_path / "book1.md").write_text("---\nbook_authors: Jane Doe\n---\n")
        (tmp_path / "book2.md").write_text("---\nbook_authors: Jane Doe\n---\n")

        authors, _ = extract_metadata_from_books(tmp_path)
        assert authors.count("Jane Doe") == 1

    def test_empty_dir_returns_empty_lists(self, tmp_path):
        authors, series = extract_metadata_from_books(tmp_path)
        assert authors == []
        assert series == []


class TestTemplates:
    def test_author_template_has_wikidata_qid_field(self):
        # Author pages require wikidata_qid. The stub leaves it blank so the
        # build names the missing field until the QID is filled in.
        page = make_pages.TEMPLATES["author"].format(item="Iain M. Banks", title="Iain M. Banks")
        fm = yaml.safe_load(page.strip("-\n"))
        assert "wikidata_qid" in fm
        assert fm["wikidata_qid"] is None


class TestWritePagesYaml:
    @pytest.mark.parametrize("kind", ["author", "series"])
    @pytest.mark.parametrize("item", ["No: A Story", "No", "null", "123", "Title # One"])
    def test_title_round_trips(self, tmp_path, kind, item):
        make_pages.write_pages([item], tmp_path, make_pages.TEMPLATES[kind])

        (page,) = tmp_path.glob("*.md")
        fm = yaml.safe_load(page.read_text(encoding="utf-8").strip("-\n"))
        assert fm["title"] == item
        assert item in fm["description"]
