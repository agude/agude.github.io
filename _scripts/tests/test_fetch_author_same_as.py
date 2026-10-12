"""Tests for metadata/fetch_author_same_as.py pure functions."""

import sys
from unittest.mock import patch

import fetch_author_same_as
from fetch_author_same_as import AUTHOR_PROPERTY_MAP, format_yaml
from wikidata_utils import extract_same_as_urls


class TestFormatYaml:
    def test_full_metadata(self):
        result = format_yaml(
            qid="Q312579",
            urls=["https://en.wikipedia.org/wiki/Iain_Banks"],
            pseudonyms=["Iain Banks"],
            title="Iain M. Banks",
        )
        assert "title: Iain M. Banks" in result
        assert "wikidata_qid: Q312579" in result
        assert "pen_names:" in result
        assert "  - Iain Banks" in result
        assert "same_as_urls:" in result
        assert "https://en.wikipedia.org/wiki/Iain_Banks" in result

    def test_no_pseudonyms(self):
        result = format_yaml(
            qid="Q312579",
            urls=["https://example.com"],
            pseudonyms=[],
            title="Single Name Author",
        )
        assert "pen_names" not in result
        assert "same_as_urls:" in result

    def test_multiple_pseudonyms(self):
        result = format_yaml(
            qid="Q312579",
            urls=["https://example.com"],
            pseudonyms=["Pen Name One", "Pen Name Two"],
            title="Real Name",
        )
        assert "pen_names:" in result
        assert "  - Pen Name One" in result
        assert "  - Pen Name Two" in result

    def test_multiple_urls(self):
        result = format_yaml(
            qid="Q312579",
            urls=["https://one.com", "https://two.com"],
            pseudonyms=[],
            title="Author",
        )
        assert "same_as_urls:" in result
        assert "https://one.com" in result
        assert "https://two.com" in result

    def test_title_needs_quoting(self):
        result = format_yaml(
            qid="Q312579",
            urls=["https://example.com"],
            pseudonyms=[],
            title="Name: With Colon",
        )
        assert 'title: "Name: With Colon"' in result


class TestAuthorPropertyMap:
    def test_all_entries_have_three_elements(self):
        for entry in AUTHOR_PROPERTY_MAP:
            assert len(entry) == 3

    def test_property_ids_start_with_p(self):
        for prop_id, _, _ in AUTHOR_PROPERTY_MAP:
            assert prop_id.startswith("P")

    def test_templates_contain_value_placeholder(self):
        for _, _, template in AUTHOR_PROPERTY_MAP:
            if template is not None:
                assert "{value}" in template


class TestMain:
    def test_name_search_only_prints_candidates(self, monkeypatch, capsys):
        candidates = [
            {
                "id": "Q1",
                "label": "Iain M. Banks",
                "description": "Scottish author",
                "aliases": ["Iain Banks"],
            }
        ]
        monkeypatch.setattr(sys, "argv", ["fetch_author_same_as.py", "Iain M. Banks"])

        with (
            patch("fetch_author_same_as.search_entity", return_value=candidates),
            patch("fetch_author_same_as.fetch_entity") as fetch_mock,
        ):
            fetch_author_same_as.main()

        fetch_mock.assert_not_called()
        output = capsys.readouterr().err
        assert "Q1" in output
        assert "selected" not in output.lower()

    def test_qid_output_has_wikidata_qid_and_no_wikidata_url(self, monkeypatch, capsys):
        # The site builds the Wikidata link from wikidata_qid; a Wikidata URL
        # in same_as_urls fails the build.
        entity = {
            "labels": {"en": {"value": "Iain Banks"}},
            "sitelinks": {"enwiki": {"title": "Iain Banks"}},
            "claims": {},
        }
        monkeypatch.setattr(sys, "argv", ["fetch_author_same_as.py", "Q312579"])

        with patch("fetch_author_same_as.fetch_entity", return_value=entity):
            fetch_author_same_as.main()

        output = capsys.readouterr().out
        assert "wikidata_qid: Q312579" in output
        assert "https://en.wikipedia.org/wiki/Iain_Banks" in output
        assert "wikidata.org" not in output


# Each property's URL template, checked against the property's Wikidata
# label and formatter URL (P1630) on 2026-10-12. A wrong property ID puts
# another site's identifier into this site's URL pattern.
VERIFIED_AUTHOR_PROPERTIES = {
    "P856": None,  # official website
    "P2963": "https://www.goodreads.com/author/show/{value}",  # Goodreads author ID
    "P244": "https://id.loc.gov/authorities/names/{value}.html",  # Library of Congress
    "P648": "https://openlibrary.org/authors/{value}",  # Open Library ID
    "P1233": "https://www.isfdb.org/cgi-bin/ea.cgi?{value}",  # ISFDB author ID
    "P1417": "https://www.britannica.com/{value}",  # Britannica Online ID
    "P345": "https://www.imdb.com/name/{value}/",  # IMDb ID
    "P7400": "https://www.librarything.com/author/{value}",  # LibraryThing author ID
    "P2949": "https://www.wikitree.com/wiki/{value}",  # WikiTree person ID
    "P5357": "https://sf-encyclopedia.com/entry/{value}",  # Encyclopedia of Science Fiction ID
    "P10883": "https://sf-encyclopedia.com/fe/{value}",  # The Encyclopedia of Fantasy ID
    "P1263": "https://www.nndb.com/people/{value}/",  # NNDB people ID
    "P2671": "https://www.google.com/search?kgmid={value}",  # Google Knowledge Graph ID
    "P646": "https://www.google.com/search?kgmid={value}",  # Freebase ID (Google KG MID)
}


class TestAuthorPropertyIds:
    def test_every_property_is_verified(self):
        assert {prop_id for prop_id, _, _ in AUTHOR_PROPERTY_MAP} == set(VERIFIED_AUTHOR_PROPERTIES)

    def test_templates_match_verified_properties(self):
        for prop_id, _, template in AUTHOR_PROPERTY_MAP:
            assert template == VERIFIED_AUTHOR_PROPERTIES[prop_id], prop_id

    def test_google_knowledge_graph_id_is_extracted(self):
        entity = {
            "sitelinks": {},
            "claims": {"P2671": [{"mainsnak": {"datavalue": {"value": "/g/11h0zktk17"}}}]},
        }
        urls = extract_same_as_urls(entity, AUTHOR_PROPERTY_MAP)
        assert urls == ["https://www.google.com/search?kgmid=/g/11h0zktk17"]
