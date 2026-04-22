"""Tests for _scripts/metadata/wikidata_utils.py."""

from unittest.mock import patch

import pytest

from wikidata_utils import (
    AWARD_FAMILIES,
    _needs_yaml_quoting,
    _resolve_award_family,
    extract_same_as_urls,
    fetch_awards,
    get_claim_strings,
    get_claim_time,
    yaml_quoted,
)


class TestYamlQuoted:
    def test_simple_string_unchanged(self):
        assert yaml_quoted("hello") == "hello"

    def test_string_with_colon_quoted(self):
        assert yaml_quoted("foo: bar") == '"foo: bar"'

    def test_string_with_hash_quoted(self):
        assert yaml_quoted("test # comment") == '"test # comment"'

    def test_string_with_quotes_escaped(self):
        assert yaml_quoted('say "hello"') == '"say \\"hello\\""'

    def test_url_with_special_chars(self):
        result = yaml_quoted("https://example.com/path?query=1")
        assert result.startswith('"')
        assert result.endswith('"')

    def test_backslash_not_special_in_yaml(self):
        # Backslashes don't require quoting in YAML
        assert yaml_quoted("path\\to\\file") == "path\\to\\file"


class TestNeedsYamlQuoting:
    def test_plain_string_no_quoting(self):
        assert _needs_yaml_quoting("hello") is False

    def test_colon_needs_quoting(self):
        assert _needs_yaml_quoting("key: value") is True

    def test_bracket_needs_quoting(self):
        assert _needs_yaml_quoting("[item]") is True

    def test_ampersand_needs_quoting(self):
        assert _needs_yaml_quoting("foo & bar") is True


class TestGetClaimStrings:
    def test_extracts_string_values(self):
        entity = {
            "claims": {
                "P123": [
                    {"mainsnak": {"datavalue": {"value": "first"}}},
                    {"mainsnak": {"datavalue": {"value": "second"}}},
                ]
            }
        }
        result = get_claim_strings(entity, "P123")
        assert result == ["first", "second"]

    def test_missing_property_returns_empty(self):
        entity = {"claims": {}}
        result = get_claim_strings(entity, "P123")
        assert result == []

    def test_skips_non_string_values(self):
        entity = {
            "claims": {
                "P123": [
                    {"mainsnak": {"datavalue": {"value": "string"}}},
                    {"mainsnak": {"datavalue": {"value": {"id": "Q123"}}}},
                ]
            }
        }
        result = get_claim_strings(entity, "P123")
        assert result == ["string"]

    def test_skips_empty_strings(self):
        entity = {
            "claims": {
                "P123": [
                    {"mainsnak": {"datavalue": {"value": ""}}},
                    {"mainsnak": {"datavalue": {"value": "valid"}}},
                ]
            }
        }
        result = get_claim_strings(entity, "P123")
        assert result == ["valid"]


class TestGetClaimTime:
    def test_full_date(self):
        entity = {
            "claims": {
                "P577": [
                    {"mainsnak": {"datavalue": {"value": {"time": "+1985-06-15T00:00:00Z"}}}}
                ]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985-06-15"

    def test_year_month_only(self):
        entity = {
            "claims": {
                "P577": [
                    {"mainsnak": {"datavalue": {"value": {"time": "+1985-06-00T00:00:00Z"}}}}
                ]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985-06"

    def test_year_only(self):
        entity = {
            "claims": {
                "P577": [
                    {"mainsnak": {"datavalue": {"value": {"time": "+1985-00-00T00:00:00Z"}}}}
                ]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985"

    def test_missing_property_returns_none(self):
        entity = {"claims": {}}
        result = get_claim_time(entity, "P577")
        assert result is None

    def test_takes_first_value(self):
        entity = {
            "claims": {
                "P577": [
                    {"mainsnak": {"datavalue": {"value": {"time": "+1985-01-01T00:00:00Z"}}}},
                    {"mainsnak": {"datavalue": {"value": {"time": "+1990-01-01T00:00:00Z"}}}},
                ]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985-01-01"


class TestExtractSameAsUrls:
    def test_includes_wikidata_url(self):
        entity = {"sitelinks": {}, "claims": {}}
        result = extract_same_as_urls(entity, "Q123", [])
        assert "https://www.wikidata.org/wiki/Q123" in result

    def test_includes_wikipedia_url(self):
        entity = {
            "sitelinks": {"enwiki": {"title": "Test Article"}},
            "claims": {},
        }
        result = extract_same_as_urls(entity, "Q123", [])
        assert "https://en.wikipedia.org/wiki/Test_Article" in result

    def test_wikipedia_title_with_spaces(self):
        entity = {
            "sitelinks": {"enwiki": {"title": "The Left Hand of Darkness"}},
            "claims": {},
        }
        result = extract_same_as_urls(entity, "Q123", [])
        assert "https://en.wikipedia.org/wiki/The_Left_Hand_of_Darkness" in result

    def test_applies_property_template(self):
        entity = {
            "sitelinks": {},
            "claims": {
                "P123": [{"mainsnak": {"datavalue": {"value": "12345"}}}]
            },
        }
        property_map = [("P123", "Test", "https://example.com/{value}")]
        result = extract_same_as_urls(entity, "Q1", property_map)
        assert "https://example.com/12345" in result

    def test_deduplicates_urls(self):
        entity = {
            "sitelinks": {},
            "claims": {
                "P1": [{"mainsnak": {"datavalue": {"value": "https://example.com"}}}],
                "P2": [{"mainsnak": {"datavalue": {"value": "https://example.com"}}}],
            },
        }
        property_map = [
            ("P1", "First", None),
            ("P2", "Second", None),
        ]
        result = extract_same_as_urls(entity, "Q1", property_map)
        assert result.count("https://example.com") == 1


class TestResolveAwardFamily:
    def test_direct_match(self):
        # Hugo Award Q-ID is directly in AWARD_FAMILIES
        with patch("wikidata_utils.fetch_entity") as mock_fetch:
            result = _resolve_award_family("Q188914")
            assert result == "hugo"
            mock_fetch.assert_not_called()

    def test_traverses_p361_hierarchy(self):
        # Hugo Award for Best Novel -> Hugo Award
        mock_novel_entity = {
            "claims": {
                "P361": [{"mainsnak": {"datavalue": {"value": {"id": "Q188914"}}}}]
            }
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_novel_entity):
            result = _resolve_award_family("Q255032")
            assert result == "hugo"

    def test_traverses_p279_hierarchy(self):
        # Some award -> parent via subclass
        mock_entity = {
            "claims": {
                "P279": [{"mainsnak": {"datavalue": {"value": {"id": "Q194285"}}}}]
            }
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_entity):
            result = _resolve_award_family("Q999999")
            assert result == "nebula"

    def test_unknown_family_returns_none(self):
        mock_entity = {"claims": {}}
        with patch("wikidata_utils.fetch_entity", return_value=mock_entity):
            result = _resolve_award_family("Q999999")
            assert result is None

    def test_max_depth_prevents_infinite_loop(self):
        # Each entity points to another unknown entity
        mock_entity = {
            "claims": {
                "P361": [{"mainsnak": {"datavalue": {"value": {"id": "Q888888"}}}}]
            }
        }
        call_count = 0

        def mock_fetch(qid):
            nonlocal call_count
            call_count += 1
            return mock_entity

        with patch("wikidata_utils.fetch_entity", side_effect=mock_fetch):
            result = _resolve_award_family("Q999999")
            assert result is None
            assert call_count <= 6  # Max depth is 5 + initial


class TestFetchAwards:
    def test_returns_sorted_slugs(self):
        mock_book_entity = {
            "claims": {
                "P166": [
                    {"mainsnak": {"datavalue": {"value": {"id": "Q194285"}}}},  # Nebula
                    {"mainsnak": {"datavalue": {"value": {"id": "Q188914"}}}},  # Hugo
                ]
            }
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_book_entity):
            result = fetch_awards("Q123")
            assert result == ["hugo", "nebula"]

    def test_deduplicates_same_family(self):
        # Two different Hugo awards should result in one "hugo" slug
        mock_book_entity = {
            "claims": {
                "P166": [
                    {"mainsnak": {"datavalue": {"value": {"id": "Q188914"}}}},
                    {"mainsnak": {"datavalue": {"value": {"id": "Q188914"}}}},
                ]
            }
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_book_entity):
            result = fetch_awards("Q123")
            assert result == ["hugo"]

    def test_no_awards_returns_empty_list(self):
        mock_book_entity = {"claims": {}}
        with patch("wikidata_utils.fetch_entity", return_value=mock_book_entity):
            result = fetch_awards("Q123")
            assert result == []

    def test_unknown_awards_logged_and_skipped(self):
        mock_book_entity = {
            "claims": {
                "P166": [
                    {"mainsnak": {"datavalue": {"value": {"id": "Q999999"}}}},
                ]
            }
        }
        mock_unknown_entity = {
            "claims": {},
            "labels": {"en": {"value": "Unknown Award"}},
        }
        with patch("wikidata_utils.fetch_entity") as mock_fetch:
            mock_fetch.side_effect = [mock_book_entity, mock_unknown_entity, mock_unknown_entity]
            result = fetch_awards("Q123")
            assert result == []


class TestAwardFamiliesMapping:
    def test_all_families_have_valid_qids(self):
        for qid in AWARD_FAMILIES.keys():
            assert qid.startswith("Q")
            assert qid[1:].isdigit()

    def test_all_slugs_are_lowercase(self):
        for slug in AWARD_FAMILIES.values():
            assert slug == slug.lower()
            assert "_" in slug or slug.isalpha()
