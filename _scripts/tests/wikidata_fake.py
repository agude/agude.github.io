"""A fake Wikidata API that serves wbgetentities from a fixed graph and counts requests."""

from collections import Counter


def item_claims(prop: str, *qids: str) -> dict:
    return {prop: [{"mainsnak": {"datavalue": {"value": {"id": qid}}}} for qid in qids]}


def string_claim(prop: str, value: str) -> dict:
    return {prop: [{"mainsnak": {"datavalue": {"value": value}}}]}


# A work with no ISBN of its own (so the ISBN comes from its editions) and
# three awards: two share a parent that resolves to Hugo, and one resolves
# to no known family.
BOOK_GRAPH = {
    "Q1": {
        "id": "Q1",
        "labels": {"en": {"value": "Fixture Novel"}},
        "sitelinks": {"enwiki": {"title": "Fixture Novel"}},
        "claims": {
            **item_claims("P747", "Q10", "Q11"),
            **item_claims("P166", "Q20", "Q21", "Q22"),
            "P577": [{"mainsnak": {"datavalue": {"value": {"time": "+1989-05-26T00:00:00Z"}}}}],
        },
    },
    "Q10": {
        "labels": {"en": {"value": "French edition"}},
        "claims": {**string_claim("P212", "978-2-000-00000-0"), **item_claims("P407", "Q150")},
    },
    "Q11": {
        "labels": {"en": {"value": "English edition"}},
        "claims": {**string_claim("P212", "978-0-000-00000-0"), **item_claims("P407", "Q1860")},
    },
    "Q20": {"labels": {"en": {"value": "Fixture Award A"}}, "claims": item_claims("P279", "Q30")},
    "Q21": {"labels": {"en": {"value": "Fixture Award B"}}, "claims": item_claims("P279", "Q30")},
    "Q30": {
        "labels": {"en": {"value": "Fixture Award Class"}},
        "claims": item_claims("P361", "Q188914"),
    },
    "Q22": {"labels": {"en": {"value": "Unknown Award"}}, "claims": {}},
}


class FakeWikidataApi:
    """Callable stand-in for wikidata_utils.api_get."""

    def __init__(self, graph: dict[str, dict]):
        self.graph = graph
        self.fetched: Counter = Counter()

    def __call__(self, params: dict[str, str]) -> dict:
        assert params["action"] == "wbgetentities", params
        ids = params["ids"].split("|")
        self.fetched.update(ids)
        return {"entities": {qid: self.graph[qid] for qid in ids}}
