"""Tests for metadata/fetch_book_metadata.py pure functions."""

import sys
from unittest.mock import patch

import fetch_book_metadata
from fetch_book_metadata import BOOK_PROPERTY_MAP, format_yaml


class TestFormatYaml:
    def test_full_metadata(self):
        result = format_yaml(
            isbn="978-0-553-28368-3",
            date_published="1989-05",
            urls=["https://www.wikidata.org/wiki/Q302026"],
            title="Hyperion",
        )
        assert "# Hyperion" in result
        assert "isbn: 978-0-553-28368-3" in result
        assert "date_published: 1989-05" in result
        assert "same_as_urls:" in result
        assert "https://www.wikidata.org/wiki/Q302026" in result

    def test_no_isbn(self):
        result = format_yaml(
            isbn=None,
            date_published="2020",
            urls=["https://example.com"],
            title="Test Book",
        )
        assert "isbn" not in result
        assert "date_published: 2020" in result

    def test_no_date(self):
        result = format_yaml(
            isbn="978-0-123-45678-9",
            date_published=None,
            urls=["https://example.com"],
            title="Test Book",
        )
        assert "date_published" not in result
        assert "isbn: 978-0-123-45678-9" in result

    def test_no_urls(self):
        result = format_yaml(
            isbn="978-0-123-45678-9",
            date_published="2020",
            urls=[],
            title="Test Book",
        )
        assert "same_as_urls" not in result

    def test_multiple_urls(self):
        result = format_yaml(
            isbn=None,
            date_published=None,
            urls=["https://one.com", "https://two.com"],
            title="Test",
        )
        assert "  - " in result
        assert "https://one.com" in result
        assert "https://two.com" in result

    def test_title_as_comment(self):
        result = format_yaml(
            isbn=None,
            date_published=None,
            urls=[],
            title="Some Book Title",
        )
        assert result.startswith("# Some Book Title")


class TestBookPropertyMap:
    def test_all_entries_have_three_elements(self):
        for entry in BOOK_PROPERTY_MAP:
            assert len(entry) == 3

    def test_property_ids_start_with_p(self):
        for prop_id, _, _ in BOOK_PROPERTY_MAP:
            assert prop_id.startswith("P")

    def test_templates_contain_value_placeholder(self):
        for _, _, template in BOOK_PROPERTY_MAP:
            if template is not None:
                assert "{value}" in template


class TestMain:
    def test_title_search_only_prints_candidates(self, monkeypatch, capsys):
        candidates = [
            {
                "id": "Q1",
                "label": "Hyperion",
                "description": "science fiction novel",
                "aliases": ["Hyperion Cantos"],
            }
        ]
        monkeypatch.setattr(sys, "argv", ["fetch_book_metadata.py", "Hyperion"])

        with (
            patch("fetch_book_metadata.search_entity", return_value=candidates),
            patch("fetch_book_metadata.fetch_entity") as fetch_mock,
        ):
            fetch_book_metadata.main()

        fetch_mock.assert_not_called()
        output = capsys.readouterr().err
        assert "Q1" in output
        assert "selected" not in output.lower()

    def test_non_qid_argument_is_query_only(self, monkeypatch):
        monkeypatch.setattr(sys, "argv", ["fetch_book_metadata.py", "Q-not-valid"])

        with patch("fetch_book_metadata.search_entity") as search_mock:
            fetch_book_metadata.main()

        search_mock.assert_called_once_with("Q-not-valid")
