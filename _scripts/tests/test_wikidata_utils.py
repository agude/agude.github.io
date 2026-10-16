"""Tests for _scripts/metadata/wikidata_utils.py."""

from unittest.mock import patch

import pytest
from wikidata_utils import (
    AWARD_FAMILIES,
    _resolve_award_family,
    extract_same_as_urls,
    fetch_awards,
    get_claim_strings,
    get_claim_time,
    get_earliest_edition_isbn,
    is_qid,
    print_entity_candidates,
    require_qid,
    search_entity,
)


class TestEntitySearch:
    def test_returns_candidates_without_selecting_first_result(self):
        search_response = {
            "search": [
                {
                    "id": "Q1",
                    "label": "First result",
                    "description": "first description",
                    "aliases": ["First alias"],
                },
                {
                    "id": "Q2",
                    "label": "Second result",
                    "description": "second description",
                    "aliases": ["Second alias"],
                },
            ]
        }

        with patch("wikidata_utils.api_get", return_value=search_response):
            result = search_entity("title")

        assert result == [
            {
                "id": "Q1",
                "label": "First result",
                "description": "first description",
                "aliases": ["First alias"],
            },
            {
                "id": "Q2",
                "label": "Second result",
                "description": "second description",
                "aliases": ["Second alias"],
            },
        ]

    def test_normalizes_alias_objects_and_deduplicates_them(self):
        search_response = {
            "search": [
                {
                    "id": "Q1",
                    "label": "Label",
                    "aliases": [
                        {"language": "en", "value": "Alias"},
                        "Alias",
                        "Other alias",
                    ],
                }
            ]
        }

        with patch("wikidata_utils.api_get", return_value=search_response):
            result = search_entity("title")

        assert result[0]["aliases"] == ["Alias", "Other alias"]

    def test_ignores_results_without_ids(self):
        with patch(
            "wikidata_utils.api_get",
            return_value={"search": [{"label": "Missing ID"}]},
        ):
            assert search_entity("title") == []


class TestEntitySelection:
    def test_qid_validation_is_explicit(self):
        assert is_qid("Q123") is True
        assert is_qid("Q") is False
        assert is_qid("title") is False

        with pytest.raises(SystemExit):
            require_qid("title")

    def test_candidate_output_includes_identity_details(self, capsys):
        candidates = [
            {
                "id": "Q1",
                "label": "Book",
                "description": "a novel",
                "aliases": ["Alternate title"],
            }
        ]

        print_entity_candidates(candidates)

        output = capsys.readouterr().err
        assert "Q1" in output
        assert "Book" in output
        assert "a novel" in output
        assert "Alternate title" in output
        assert "selected" not in output.lower()


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
                "P577": [{"mainsnak": {"datavalue": {"value": {"time": "+1985-06-15T00:00:00Z"}}}}]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985-06-15"

    def test_year_month_only(self):
        entity = {
            "claims": {
                "P577": [{"mainsnak": {"datavalue": {"value": {"time": "+1985-06-00T00:00:00Z"}}}}]
            }
        }
        result = get_claim_time(entity, "P577")
        assert result == "1985-06"

    def test_year_only(self):
        entity = {
            "claims": {
                "P577": [{"mainsnak": {"datavalue": {"value": {"time": "+1985-00-00T00:00:00Z"}}}}]
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
    def test_excludes_wikidata_url(self):
        # Books and authors build their Wikidata link from wikidata_qid at
        # site build time; a Wikidata URL in same_as_urls fails the build.
        entity = {"sitelinks": {"enwiki": {"title": "Test Article"}}, "claims": {}}
        result = extract_same_as_urls(entity, [])
        assert result == ["https://en.wikipedia.org/wiki/Test_Article"]

    def test_includes_wikipedia_url(self):
        entity = {
            "sitelinks": {"enwiki": {"title": "Test Article"}},
            "claims": {},
        }
        result = extract_same_as_urls(entity, [])
        assert "https://en.wikipedia.org/wiki/Test_Article" in result

    def test_wikipedia_title_with_spaces(self):
        entity = {
            "sitelinks": {"enwiki": {"title": "The Left Hand of Darkness"}},
            "claims": {},
        }
        result = extract_same_as_urls(entity, [])
        assert "https://en.wikipedia.org/wiki/The_Left_Hand_of_Darkness" in result

    def test_applies_property_template(self):
        entity = {
            "sitelinks": {},
            "claims": {"P123": [{"mainsnak": {"datavalue": {"value": "12345"}}}]},
        }
        property_map = [("P123", "Test", "https://example.com/{value}")]
        result = extract_same_as_urls(entity, property_map)
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
        result = extract_same_as_urls(entity, property_map)
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
            "claims": {"P361": [{"mainsnak": {"datavalue": {"value": {"id": "Q188914"}}}}]}
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_novel_entity):
            result = _resolve_award_family("Q255032")
            assert result == "hugo"

    def test_traverses_p279_hierarchy(self):
        # Some award -> parent via subclass
        mock_entity = {
            "claims": {"P279": [{"mainsnak": {"datavalue": {"value": {"id": "Q194285"}}}}]}
        }
        with patch("wikidata_utils.fetch_entity", return_value=mock_entity):
            result = _resolve_award_family("Q999999")
            assert result == "nebula"

    def test_unknown_family_returns_none(self):
        mock_entity = {"claims": {}}
        with patch("wikidata_utils.fetch_entity", return_value=mock_entity):
            result = _resolve_award_family("Q999999")
            assert result is None

    @staticmethod
    def _entity(**parents: list[str]) -> dict:
        """An entity whose claims point at parents, keyed by property."""
        return {
            "claims": {
                prop: [{"mainsnak": {"datavalue": {"value": {"id": qid}}}} for qid in qids]
                for prop, qids in parents.items()
            }
        }

    def _resolve(self, start: str, graph: dict[str, dict]) -> tuple[str | None, list[str]]:
        """Resolve start against graph; return the result and the fetched Q-IDs."""
        fetched: list[str] = []

        def fetch(qid: str) -> dict:
            fetched.append(qid)
            return graph[qid]

        with patch("wikidata_utils.fetch_entity", side_effect=fetch):
            return _resolve_award_family(start), fetched

    def _chain(self, hops: int) -> tuple[list[str], dict[str, dict]]:
        """Unknown awards linked by P361, with Hugo (Q188914) at the given hop."""
        qids = [f"Q{900000 + i}" for i in range(hops)]
        parents = [*qids[1:], "Q188914"]
        return qids, {
            qid: self._entity(P361=[parent]) for qid, parent in zip(qids, parents, strict=True)
        }

    def test_cycle_stops_traversal(self):
        graph = {
            "Q999999": self._entity(P361=["Q888888"]),
            "Q888888": self._entity(P361=["Q999999"]),
        }
        result, fetched = self._resolve("Q999999", graph)
        assert result is None
        assert fetched == ["Q999999", "Q888888"]

    def test_chain_at_depth_limit_resolves(self):
        qids, graph = self._chain(5)
        result, fetched = self._resolve(qids[0], graph)
        assert result == "hugo"
        assert fetched == qids

    def test_chain_past_depth_limit_stops(self):
        qids, graph = self._chain(6)
        result, fetched = self._resolve(qids[0], graph)
        assert result is None
        # The depth-5 node is checked but not fetched: its parents would be
        # past the limit.
        assert fetched == qids[:5]

    def test_dead_end_branch_falls_through_to_next_property(self):
        graph = {
            "Q999999": self._entity(P361=["Q900000"], P279=["Q194285"]),
            "Q900000": self._entity(),
        }
        result, fetched = self._resolve("Q999999", graph)
        assert result == "nebula"
        assert fetched == ["Q999999", "Q900000"]

    def test_dead_end_chain_does_not_exhaust_search(self):
        # The limit is on depth, not on how many nodes were visited: a long
        # dead-end P361 chain must not hide a known P279 parent of the root.
        dead = [f"Q{900000 + i}" for i in range(5)]
        graph = {"Q999999": self._entity(P361=[dead[0]], P279=["Q194285"])}
        for qid, parent in zip(dead, [*dead[1:], None], strict=True):
            graph[qid] = self._entity(P361=[parent] if parent else [])
        result, _ = self._resolve("Q999999", graph)
        assert result == "nebula"

    def test_nearest_family_wins(self):
        # Locus is at depth 4 via P361; Nebula is at depth 2 via P279.
        graph = {
            "Q999999": self._entity(P361=["Q900001"], P279=["Q900010"]),
            "Q900001": self._entity(P361=["Q900002"]),
            "Q900002": self._entity(P361=["Q900003"]),
            "Q900003": self._entity(P361=["Q754655"]),
            "Q900010": self._entity(P279=["Q194285"]),
        }
        result, _ = self._resolve("Q999999", graph)
        assert result == "nebula"

    def test_p361_preferred_at_equal_depth(self):
        graph = {"Q999999": self._entity(P279=["Q194285"], P361=["Q188914"])}
        result, _ = self._resolve("Q999999", graph)
        assert result == "hugo"

    def test_family_at_depth_five_via_p279_resolves(self):
        qids = [f"Q{900000 + i}" for i in range(5)]
        graph = {
            qid: self._entity(P279=[parent])
            for qid, parent in zip(qids, [*qids[1:], "Q188914"], strict=True)
        }
        result, _ = self._resolve(qids[0], graph)
        assert result == "hugo"

    def test_family_at_depth_six_via_p279_returns_none(self):
        qids = [f"Q{900000 + i}" for i in range(6)]
        graph = {
            qid: self._entity(P279=[parent])
            for qid, parent in zip(qids, [*qids[1:], "Q188914"], strict=True)
        }
        result, _ = self._resolve(qids[0], graph)
        assert result is None


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


class TestGetEarliestEditionIsbn:
    def _work_entity(self, edition_qids):
        return {
            "claims": {
                "P747": [
                    {"mainsnak": {"datavalue": {"value": {"id": qid}}}} for qid in edition_qids
                ]
            }
        }

    def test_prefers_english_edition_over_earlier_non_english(self):
        # French edition (Q1) is listed before the English one (Q2), but the
        # English ISBN should win.
        work_entity = self._work_entity(["Q1", "Q2"])
        api_response = {
            "entities": {
                "Q1": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-2-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q150"}}}}],
                    }
                },
                "Q2": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-0-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q1860"}}}}],
                    }
                },
            }
        }
        with (
            patch("wikidata_utils.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = get_earliest_edition_isbn("Q0")
            assert result == "978-0-000-00000-0"

    def test_falls_back_to_first_isbn_when_no_english_edition(self):
        work_entity = self._work_entity(["Q1"])
        api_response = {
            "entities": {
                "Q1": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-2-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q150"}}}}],
                    }
                },
            }
        }
        with (
            patch("wikidata_utils.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = get_earliest_edition_isbn("Q0")
            assert result == "978-2-000-00000-0"

    def test_edition_without_language_claim_used_as_fallback(self):
        work_entity = self._work_entity(["Q1"])
        api_response = {
            "entities": {
                "Q1": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-0-000-00000-0"}}}],
                    }
                },
            }
        }
        with (
            patch("wikidata_utils.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = get_earliest_edition_isbn("Q0")
            assert result == "978-0-000-00000-0"

    def test_edition_without_language_not_treated_as_english(self):
        work_entity = self._work_entity(["Q1", "Q2"])
        api_response = {
            "entities": {
                "Q1": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-0-111-11111-1"}}}],
                    }
                },
                "Q2": {
                    "claims": {
                        "P212": [{"mainsnak": {"datavalue": {"value": "978-0-222-22222-2"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q1860"}}}}],
                    }
                },
            }
        }
        with (
            patch("wikidata_utils.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = get_earliest_edition_isbn("Q0")
            assert result == "978-0-222-22222-2"

    def test_isbn10_fallback_when_no_isbn13(self):
        work_entity = self._work_entity(["Q1"])
        api_response = {
            "entities": {
                "Q1": {
                    "claims": {
                        "P957": [{"mainsnak": {"datavalue": {"value": "0-000-00000-0"}}}],
                        "P407": [{"mainsnak": {"datavalue": {"value": {"id": "Q1860"}}}}],
                    }
                },
            }
        }
        with (
            patch("wikidata_utils.fetch_entity", return_value=work_entity),
            patch("wikidata_utils.api_get", return_value=api_response),
        ):
            result = get_earliest_edition_isbn("Q0")
            assert result == "0-000-00000-0"

    def test_no_editions_returns_none(self):
        work_entity = self._work_entity([])
        with patch("wikidata_utils.fetch_entity", return_value=work_entity):
            result = get_earliest_edition_isbn("Q0")
            assert result is None


class TestAwardFamiliesMapping:
    def test_all_families_have_valid_qids(self):
        for qid in AWARD_FAMILIES:
            assert qid.startswith("Q")
            assert qid[1:].isdigit()

    def test_all_slugs_are_lowercase(self):
        for slug in AWARD_FAMILIES.values():
            assert slug == slug.lower()
            assert "_" in slug or slug.isalpha()
