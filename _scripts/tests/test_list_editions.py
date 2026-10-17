"""Tests for metadata/list_editions.py."""

import sys
from unittest.mock import patch

import list_editions as list_editions_module
from list_editions import format_editions, list_editions


class TestListEditions:
    def test_returns_isbn_label_and_language_per_edition(self):
        work_entity = {
            "claims": {
                "P747": [
                    {"mainsnak": {"datavalue": {"value": {"id": "Q1"}}}},
                    {"mainsnak": {"datavalue": {"value": {"id": "Q2"}}}},
                ]
            }
        }
        api_response = {
            "entities": {
                "Q1": {
                    "labels": {"en": {"value": "French edition"}},
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-2-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q150"}}}}],
                    },
                },
                "Q2": {
                    "labels": {"en": {"value": "English edition"}},
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-0-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q1860"}}}}],
                    },
                },
            }
        }
        with (
            patch("list_editions.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = list_editions("Q0")

        assert result == [
            {
                "qid": "Q1",
                "label": "French edition",
                "isbn": "978-2-000-00000-0",
                "is_english": False,
            },
            {
                "qid": "Q2",
                "label": "English edition",
                "isbn": "978-0-000-00000-0",
                "is_english": True,
            },
        ]

    def test_no_editions_returns_empty_list(self):
        work_entity = {"claims": {}}
        with patch("list_editions.fetch_entity", return_value=work_entity):
            result = list_editions("Q0")
            assert result == []

    def test_edition_with_no_isbn(self):
        work_entity = {"claims": {"P747": [{"mainsnak": {"datavalue": {"value": {"id": "Q1"}}}}]}}
        api_response = {
            "entities": {
                "Q1": {"labels": {}, "claims": {}},
            }
        }
        with (
            patch("list_editions.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = list_editions("Q0")
            assert result == [{"qid": "Q1", "label": "", "isbn": None, "is_english": False}]


class TestFormatEditions:
    def test_no_editions_message(self):
        result = format_editions("Q0", [], None)
        assert result == "No editions (P747) found for Q0."

    def test_marks_selected_isbn(self):
        editions = [
            {"qid": "Q1", "label": "French", "isbn": "978-2-000-00000-0", "is_english": False},
            {"qid": "Q2", "label": "English", "isbn": "978-0-000-00000-0", "is_english": True},
        ]
        result = format_editions("Q0", editions, "978-0-000-00000-0")
        lines = result.splitlines()
        assert "<- selected" not in lines[1]
        assert "<- selected" in lines[2]

    def test_edition_without_isbn_not_marked_selected(self):
        editions = [{"qid": "Q1", "label": "No ISBN", "isbn": None, "is_english": False}]
        result = format_editions("Q0", editions, None)
        assert "<- selected" not in result
        assert "(no ISBN)" in result

    def test_language_marker(self):
        editions = [
            {"qid": "Q1", "label": "French", "isbn": "978-2-0", "is_english": False},
            {"qid": "Q2", "label": "English", "isbn": "978-0-0", "is_english": True},
        ]
        result = format_editions("Q0", editions, None)
        assert "[?] Q1" in result
        assert "[en] Q2" in result


class TestMain:
    def test_title_search_only_prints_candidates(self, monkeypatch, capsys):
        candidates = [
            {
                "id": "Q1",
                "label": "Hyperion",
                "description": "science fiction novel",
                "aliases": [],
            }
        ]
        monkeypatch.setattr(sys, "argv", ["list_editions.py", "Hyperion"])

        with (
            patch("list_editions.search_entity", return_value=candidates),
            patch("list_editions.list_editions") as editions_mock,
        ):
            list_editions_module.main()

        editions_mock.assert_not_called()
        assert "Q1" in capsys.readouterr().err
