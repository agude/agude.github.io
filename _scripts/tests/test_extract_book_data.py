"""Tests for ranking/extract_book_data.py pure functions."""

import json

import pytest
from extract_book_data import (
    carry_over_book,
    clean_liquid,
    extract_paragraphs,
    load_existing_state,
    parse_front_matter,
)


def seeded_book(**overrides):
    """A freshly parsed book entry, before any ranking data is merged in."""
    book = {
        "title": "Hyperion",
        "rating": 5,
        "summary": "",
        "elo": 1900,
        "matches": 0,
    }
    book.update(overrides)
    return book


class TestLoadExistingState:
    def test_missing_file_is_empty_state(self, tmp_path):
        assert load_existing_state(tmp_path / "absent.json") == {}

    def test_reads_existing_state(self, tmp_path):
        path = tmp_path / "state.json"
        path.write_text(
            json.dumps(
                {
                    "meta": {"created": "2025-01-02", "total_matches": 2},
                    "matches": [{"winner": "a", "loser": "b"}, {"winner": "c"}],
                    "books": {"hyperion": {"elo": 1820}},
                }
            )
        )
        state = load_existing_state(path)
        assert len(state["matches"]) == 2
        assert state["meta"]["created"] == "2025-01-02"

    def test_malformed_file_raises(self, tmp_path):
        path = tmp_path / "state.json"
        path.write_text("{not json")
        with pytest.raises(SystemExit):
            load_existing_state(path)


class TestCarryOverBook:
    def test_new_book_keeps_seeded_values(self):
        result = carry_over_book(seeded_book(), {})
        assert result["summary"] == ""
        assert result["elo"] == 1900
        assert result["matches"] == 0

    def test_preserves_summary_elo_and_matches(self):
        previous = {"summary": "Hand-written blurb.", "elo": 1820, "matches": 7}
        result = carry_over_book(seeded_book(), previous)
        assert result["summary"] == "Hand-written blurb."
        assert result["elo"] == 1820
        assert result["matches"] == 7

    def test_front_matter_wins_for_rating_and_title(self):
        previous = {"title": "Old Title", "rating": 2, "elo": 1820}
        result = carry_over_book(seeded_book(), previous)
        assert result["title"] == "Hyperion"
        assert result["rating"] == 5

    def test_empty_previous_summary_does_not_overwrite(self):
        result = carry_over_book(seeded_book(summary="Fresh"), {"summary": ""})
        assert result["summary"] == "Fresh"

    def test_zero_matches_is_carried_over(self):
        result = carry_over_book(seeded_book(matches=3), {"matches": 0})
        assert result["matches"] == 0


class TestParseFrontMatter:
    def test_basic_fields(self):
        content = "---\ntitle: Hyperion\nrating: 5\n---\nBody text."
        fm, body = parse_front_matter(content)
        assert fm["title"] == "Hyperion"
        assert fm["rating"] == 5
        assert "Body text." in body

    def test_list_field(self):
        content = "---\nbook_authors:\n- Dan Simmons\n- Another Author\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["book_authors"] == ["Dan Simmons", "Another Author"]

    def test_boolean_and_null(self):
        content = "---\npublished: true\ndraft: false\ncanonical_url: null\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["published"] is True
        assert fm["draft"] is False
        assert fm["canonical_url"] is None

    def test_quoted_values(self):
        content = '---\ntitle: "A Book: With Colon"\n---\n'
        fm, _ = parse_front_matter(content)
        assert fm["title"] == "A Book: With Colon"

    def test_missing_delimiters(self):
        fm, body = parse_front_matter("No front matter here.")
        assert fm == {}
        assert body == ""

    def test_empty_value_is_none(self):
        content = "---\nseries:\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["series"] is None

    def test_duplicate_key_uses_last_value(self):
        content = "---\ntitle: First\ntitle: Second\n---\n"
        fm, _ = parse_front_matter(content)
        assert fm["title"] == "Second"


class TestExtractParagraphs:
    def test_two_paragraphs(self):
        body = "\nFirst paragraph text.\n\nSecond paragraph here.\n"
        first, second = extract_paragraphs(body)
        assert "First paragraph" in first
        assert "Second paragraph" in second

    def test_skips_capture_blocks(self):
        body = "\n{% capture my_var %}stuff{% endcapture %}\n\nActual paragraph.\n"
        first, _ = extract_paragraphs(body)
        assert "Actual paragraph" in first

    def test_empty_body(self):
        first, second = extract_paragraphs("")
        assert first == ""
        assert second == ""


class TestCleanLiquid:
    def test_strips_liquid_tags(self):
        result = clean_liquid("Hello {% book_link 'Hyperion' %} world")
        assert "{%" not in result
        assert "Hello" in result
        assert "world" in result

    def test_strips_output_tags(self):
        result = clean_liquid("By {{ author_name }}, this is great")
        assert "{{" not in result

    def test_strips_html(self):
        result = clean_liquid("The <cite>book</cite> is good")
        assert "<cite>" not in result
        assert "good" in result

    def test_capitalizes_first_letter(self):
        result = clean_liquid("simple text here")
        assert result[0] == "S"

    def test_already_capitalized_unchanged(self):
        result = clean_liquid("Already capitalized")
        assert result == "Already capitalized"

    def test_empty_string(self):
        result = clean_liquid("")
        assert result == ""
