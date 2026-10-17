"""Shared Wikidata API utilities for metadata fetcher scripts."""
# not-a-script

from __future__ import annotations

import logging
import sys
import urllib.parse
from collections import deque
from collections.abc import Iterable, Iterator
from typing import TextIO, TypedDict

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

log = logging.getLogger(__name__)

WIKIDATA_API = "https://www.wikidata.org/w/api.php"
USER_AGENT = "alexgude-blog-scripts/0.1 (wikidata metadata fetcher)"

# Shared session with retry/backoff configuration.
_session: requests.Session | None = None


class EntityCandidate(TypedDict):
    """The identity details needed to evaluate a Wikidata search result."""

    id: str
    label: str
    description: str
    aliases: list[str]


def _get_session() -> requests.Session:
    """Return a shared requests session with retry configuration."""
    global _session
    if _session is None:
        log.debug("Creating new requests session with retry config")
        _session = requests.Session()
        _session.headers["User-Agent"] = USER_AGENT
        retry = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            respect_retry_after_header=True,
        )
        adapter = HTTPAdapter(max_retries=retry)
        _session.mount("https://", adapter)
    return _session


def api_get(params: dict[str, str]) -> dict:
    """Make a GET request to the Wikidata API and return parsed JSON."""
    params["format"] = "json"
    log.debug("API request: %s", params.get("action", params))
    try:
        resp = _get_session().get(WIKIDATA_API, params=params, timeout=15)
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException as exc:
        log.error("Wikidata API request failed: %s", exc)
        sys.exit(1)


def _candidate_aliases(result: dict) -> list[str]:
    """Extract alias strings from the varying Wikidata response shapes."""
    aliases = result.get("aliases", [])
    if isinstance(aliases, dict):
        aliases = [alias for language_aliases in aliases.values() for alias in language_aliases]

    normalized: list[str] = []
    for alias in aliases:
        if isinstance(alias, str) and alias:
            normalized.append(alias)
        elif isinstance(alias, dict) and alias.get("value"):
            normalized.append(alias["value"])
    return list(dict.fromkeys(normalized))


def search_entity(name: str, *, limit: int = 5) -> list[EntityCandidate]:
    """Search Wikidata and return candidates without selecting one."""
    log.debug("Searching for entity: %s", name)
    data = api_get(
        {
            "action": "wbsearchentities",
            "search": name,
            "language": "en",
            "type": "item",
            "limit": str(limit),
        }
    )
    candidates: list[EntityCandidate] = []
    for result in data.get("search", []):
        qid = result.get("id")
        if not qid:
            log.warning("Ignoring Wikidata search result without an ID: %s", result)
            continue
        candidates.append(
            {
                "id": qid,
                "label": result.get("label", ""),
                "description": result.get("description", ""),
                "aliases": _candidate_aliases(result),
            }
        )
    return candidates


def print_entity_candidates(
    candidates: list[EntityCandidate],
    *,
    stream: TextIO | None = None,
) -> None:
    """Print search candidates for explicit human or LLM selection."""
    output = stream or sys.stderr
    if not candidates:
        print("No Wikidata candidates found.", file=output)
        return

    print("Wikidata candidates:", file=output)
    for index, candidate in enumerate(candidates):
        details = candidate["description"]
        if candidate["aliases"]:
            aliases = ", ".join(candidate["aliases"])
            details = f"{details}; aliases: {aliases}" if details else f"aliases: {aliases}"
        suffix = f" — {details}" if details else ""
        print(f"  [{index}] {candidate['id']}  {candidate['label']}{suffix}", file=output)


def is_qid(value: str) -> bool:
    """Return whether a value is a syntactically valid Wikidata item ID."""
    return bool(value) and value.startswith("Q") and value[1:].isdigit()


def require_qid(identifier: str) -> str:
    """Validate an explicitly supplied Q-ID, exiting on invalid input."""
    if not is_qid(identifier):
        log.error("An explicit Wikidata Q-ID is required: %s", identifier)
        sys.exit(1)
    return identifier


def fetch_entity(qid: str) -> dict:
    """Fetch a Wikidata entity by Q-ID."""
    log.debug("Fetching entity: %s", qid)
    data = api_get(
        {
            "action": "wbgetentities",
            "ids": qid,
            "props": "claims|sitelinks|labels",
            "languages": "en",
        }
    )
    return data["entities"][qid]


def get_claim_strings(entity: dict, prop_id: str) -> list[str]:
    """Extract string values from all claims of a given property."""
    claims = entity.get("claims", {})
    values: list[str] = []
    for claim in claims.get(prop_id, []):
        value = claim.get("mainsnak", {}).get("datavalue", {}).get("value", "")
        if isinstance(value, str) and value:
            values.append(value)
    return values


def get_claim_entity_ids(entity: dict, prop_id: str) -> list[str]:
    """Extract Q-IDs from all item-reference claims of a given property."""
    claims = entity.get("claims", {})
    qids: list[str] = []
    for claim in claims.get(prop_id, []):
        qid = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id")
        if qid:
            qids.append(qid)
    return qids


def get_claim_time(entity: dict, prop_id: str) -> str | None:
    """Extract the first time value from a property.

    Returns the most precise date string available: YYYY-MM-DD, YYYY-MM, or
    YYYY. Wikidata uses 00 for unknown month or day components.
    """
    claims = entity.get("claims", {})
    for claim in claims.get(prop_id, []):
        value = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {})
        if isinstance(value, dict) and "time" in value:
            # Wikidata time format: "+1989-06-00T00:00:00Z"
            time_str = value["time"].lstrip("+")
            year, month, day = time_str.split("T")[0].split("-")[:3]
            if month == "00":
                return year
            if day == "00":
                return f"{year}-{month}"
            return f"{year}-{month}-{day}"
    return None


def extract_same_as_urls(
    entity: dict,
    property_map: list[tuple[str, str, str | None]],
) -> list[str]:
    """Extract sameAs URLs from a Wikidata entity using a property map.

    Omits the Wikidata URL itself: the site builds it from the wikidata_qid
    front matter of books and author pages, and a Wikidata URL in
    same_as_urls fails the build.
    """
    urls: list[str] = []

    # English Wikipedia from sitelinks
    sitelinks = entity.get("sitelinks", {})
    enwiki = sitelinks.get("enwiki", {}).get("title")
    if enwiki:
        slug = urllib.parse.quote(enwiki.replace(" ", "_"), safe="")
        urls.append(f"https://en.wikipedia.org/wiki/{slug}")

    # Properties
    claims = entity.get("claims", {})
    for prop_id, _label, template in property_map:
        if prop_id not in claims:
            continue
        # Take only the first claim per property to avoid foreign-language
        # or alternate-edition duplicates.
        claim = claims[prop_id][0]
        mainsnak = claim.get("mainsnak", {})
        datavalue = mainsnak.get("datavalue", {})
        value = datavalue.get("value", "")

        if isinstance(value, str) and value:
            if template is None:
                urls.append(value)
            else:
                urls.append(template.format(value=value))

    # Deduplicate while preserving order
    log.debug("Extracted %d sameAs URLs", len(urls))
    return list(dict.fromkeys(urls))


# Award family Q-IDs mapped to tag slugs. Specific awards (e.g., "Hugo Award
# for Best Novel") link to these parents via P361 (part of) or P279 (subclass).
AWARD_FAMILIES: dict[str, str] = {
    "Q188914": "hugo",
    "Q194285": "nebula",
    "Q754655": "locus",
    # "Q594886": "world_fantasy",
    # "Q787680": "bsfa",
    # "Q708830": "clarke",
    # "Q582610": "sturgeon",
    # "Q1030402": "campbell",
    # "Q142392": "prometheus",
    # "Q6418326": "kitschies",
    # "Q5157154": "compton_crook",
}


ENGLISH_LANGUAGE_QID = "Q1860"


# The most IDs one wbgetentities request accepts.
ENTITY_BATCH_SIZE = 50


def fetch_editions(work: dict) -> Iterator[dict]:
    """Yield the editions (P747) of a work entity, in claim order.

    Each edition is a dict with its Q-ID, English label, ISBN (ISBN-13
    (P212) before ISBN-10 (P957), or None), and whether it is an
    English-language (P407) edition. Editions are fetched one batch at a
    time, so a caller that stops early skips the remaining requests.
    """
    edition_qids = get_claim_entity_ids(work, "P747")
    log.debug("Fetching %d editions", len(edition_qids))
    for i in range(0, len(edition_qids), ENTITY_BATCH_SIZE):
        batch = edition_qids[i : i + ENTITY_BATCH_SIZE]
        data = api_get(
            {
                "action": "wbgetentities",
                "ids": "|".join(batch),
                "props": "claims|labels",
                "languages": "en",
            }
        )
        for qid in batch:
            entity = data.get("entities", {}).get(qid, {})
            isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(entity, "P957")
            yield {
                "qid": qid,
                "label": entity.get("labels", {}).get("en", {}).get("value", ""),
                "isbn": isbn_list[0] if isbn_list else None,
                "is_english": ENGLISH_LANGUAGE_QID in get_claim_entity_ids(entity, "P407"),
            }


def select_edition_isbn(editions: Iterable[dict]) -> str | None:
    """Return the ISBN of the first English edition that has one.

    Falls back to the first ISBN of any edition, or None if no edition has
    an ISBN. Stops reading `editions` at the first English ISBN.
    """
    fallback = None
    for edition in editions:
        if edition["isbn"] is None:
            continue
        if edition["is_english"]:
            log.debug(
                "Found English-language ISBN %s in edition %s", edition["isbn"], edition["qid"]
            )
            return edition["isbn"]
        if fallback is None:
            fallback = edition["isbn"]
    if fallback:
        log.debug("No English-language edition found; using ISBN %s", fallback)
    return fallback


def get_earliest_edition_isbn(work: dict) -> str | None:
    """Find an ISBN among the editions of a work entity.

    Returns an ISBN found on an English-language edition if one exists,
    otherwise the first ISBN found in any language.
    """
    return select_edition_isbn(fetch_editions(work))


def resolve_qid(identifier: str) -> str:
    """Validate an explicitly supplied Q-ID without searching or selecting."""
    return require_qid(identifier)


MAX_AWARD_DEPTH = 5


def _cached_entity(qid: str, cache: dict[str, dict]) -> dict:
    """Return the entity for `qid`, fetching it only if `cache` lacks it."""
    if qid not in cache:
        cache[qid] = fetch_entity(qid)
    return cache[qid]


def _resolve_award_family(award_qid: str, cache: dict[str, dict] | None = None) -> str | None:
    """Resolve an award Q-ID to a family slug by traversing the hierarchy.

    Searches breadth-first through P361 (part of) and P279 (subclass of)
    parents. The award itself is depth 0; ancestors up to depth 5 are
    examined, and ancestors deeper than that are ignored. The nearest known
    award family wins; at equal depth, P361 parents come before P279 parents.
    Returns None if no family is found within that depth. Entities are read
    through `cache`, so awards that share ancestors fetch them once.
    """
    cache = {} if cache is None else cache
    visited = {award_qid}
    queue: deque[tuple[str, int]] = deque([(award_qid, 0)])

    while queue:
        qid, depth = queue.popleft()

        if qid in AWARD_FAMILIES:
            log.debug("Resolved %s to family %s", qid, AWARD_FAMILIES[qid])
            return AWARD_FAMILIES[qid]

        if depth == MAX_AWARD_DEPTH:
            log.debug("Award hierarchy depth limit reached at %s", qid)
            continue

        entity = _cached_entity(qid, cache)
        for prop in ("P361", "P279"):
            for parent_qid in get_claim_entity_ids(entity, prop):
                if parent_qid in visited:
                    continue
                log.debug("Traversing %s -> %s via %s", qid, parent_qid, prop)
                visited.add(parent_qid)
                queue.append((parent_qid, depth + 1))

    return None


def fetch_awards(book: dict) -> list[str]:
    """Fetch award slugs for a book entity from Wikidata.

    Reads P166 (award received) and resolves each award to a known award
    family. Returns a sorted, deduplicated list of award slugs.
    """
    award_qids = get_claim_entity_ids(book, "P166")

    if not award_qids:
        log.debug("No awards (P166) found for %s", book.get("id"))
        return []

    log.debug("Found %d award claims for %s", len(award_qids), book.get("id"))

    cache: dict[str, dict] = {}
    slugs: set[str] = set()
    for award_qid in award_qids:
        slug = _resolve_award_family(award_qid, cache)
        if slug:
            slugs.add(slug)
        else:
            award = _cached_entity(award_qid, cache)
            label = award.get("labels", {}).get("en", {}).get("value", award_qid)
            log.info("Unknown award family: %s (%s)", label, award_qid)

    log.debug("Resolved awards: %s", sorted(slugs))
    return sorted(slugs)
