"""Tests for metadata/fetch_book_metadata.py pure functions."""

import sys
from unittest.mock import patch

import fetch_book_metadata
from fetch_book_metadata import BOOK_PROPERTY_MAP, format_yaml
from wikidata_utils import extract_same_as_urls


class TestFormatYaml:
    def test_full_metadata(self):
        result = format_yaml(
            qid="Q302026",
            isbn="978-0-553-28368-3",
            date_published="1989-05",
            urls=["https://en.wikipedia.org/wiki/Hyperion_(Simmons_novel)"],
            title="Hyperion",
        )
        assert "# Hyperion" in result
        assert "wikidata_qid: Q302026" in result
        assert "isbn: 978-0-553-28368-3" in result
        assert "date_published: 1989-05" in result
        assert "same_as_urls:" in result
        assert "https://en.wikipedia.org/wiki/Hyperion_(Simmons_novel)" in result

    def test_no_isbn(self):
        result = format_yaml(
            qid="Q302026",
            isbn=None,
            date_published="2020",
            urls=["https://example.com"],
            title="Test Book",
        )
        assert "isbn" not in result
        assert "date_published: 2020" in result

    def test_no_date(self):
        result = format_yaml(
            qid="Q302026",
            isbn="978-0-123-45678-9",
            date_published=None,
            urls=["https://example.com"],
            title="Test Book",
        )
        assert "date_published" not in result
        assert "isbn: 978-0-123-45678-9" in result

    def test_no_urls(self):
        result = format_yaml(
            qid="Q302026",
            isbn="978-0-123-45678-9",
            date_published="2020",
            urls=[],
            title="Test Book",
        )
        assert "same_as_urls" not in result

    def test_multiple_urls(self):
        result = format_yaml(
            qid="Q302026",
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
            qid="Q302026",
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

    def test_qid_output_has_wikidata_qid_and_no_wikidata_url(self, monkeypatch, capsys):
        # The site builds the Wikidata link from wikidata_qid; a Wikidata URL
        # in same_as_urls fails the build.
        entity = {
            "labels": {"en": {"value": "Hyperion"}},
            "sitelinks": {"enwiki": {"title": "Hyperion (Simmons novel)"}},
            "claims": {},
        }
        monkeypatch.setattr(sys, "argv", ["fetch_book_metadata.py", "Q302026"])

        with (
            patch("fetch_book_metadata.fetch_entity", return_value=entity),
            patch("fetch_book_metadata.get_earliest_edition_isbn", return_value=None),
        ):
            fetch_book_metadata.main()

        output = capsys.readouterr().out
        assert "wikidata_qid: Q302026" in output
        assert "https://en.wikipedia.org/wiki/Hyperion_%28Simmons_novel%29" in output
        assert "wikidata.org" not in output


# Each property's URL template, checked against the property's Wikidata
# label and formatter URL (P1630) on 2026-10-12. A wrong property ID puts
# another site's identifier into this site's URL pattern.
VERIFIED_BOOK_PROPERTIES = {
    "P856": None,  # official website
    "P8383": "https://www.goodreads.com/work/editions/{value}",  # Goodreads work ID
    "P648": "https://openlibrary.org/works/{value}",  # Open Library ID
    "P1274": "https://www.isfdb.org/cgi-bin/title.cgi?{value}",  # ISFDB title ID
    "P1417": "https://www.britannica.com/{value}",  # Britannica Online ID
    "P1085": "https://www.librarything.com/work/{value}",  # LibraryThing work ID
    "P2671": "https://www.google.com/search?kgmid={value}",  # Google Knowledge Graph ID
    "P646": "https://www.google.com/search?kgmid={value}",  # Freebase ID (Google KG MID)
}


class TestBookPropertyIds:
    def test_every_property_is_verified(self):
        assert {prop_id for prop_id, _, _ in BOOK_PROPERTY_MAP} == set(VERIFIED_BOOK_PROPERTIES)

    def test_templates_match_verified_properties(self):
        for prop_id, _, template in BOOK_PROPERTY_MAP:
            assert template == VERIFIED_BOOK_PROPERTIES[prop_id], prop_id

    def test_google_knowledge_graph_id_is_extracted(self):
        entity = {
            "sitelinks": {},
            "claims": {"P2671": [{"mainsnak": {"datavalue": {"value": "/g/11b60frqhx"}}}]},
        }
        urls = extract_same_as_urls(entity, BOOK_PROPERTY_MAP)
        assert urls == ["https://www.google.com/search?kgmid=/g/11b60frqhx"]
