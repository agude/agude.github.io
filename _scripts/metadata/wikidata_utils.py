"""Shared Wikidata API utilities for metadata fetcher scripts."""
# not-a-script

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

WIKIDATA_API = "https://www.wikidata.org/w/api.php"
USER_AGENT = "alexgude-blog-scripts/0.1 (wikidata metadata fetcher)"

# Characters that require quoting in YAML scalar values.
_YAML_SPECIAL = set(": # ' \" [ ] { } , & * ? | > ! %".split())


def _needs_yaml_quoting(value: str) -> bool:
    """Return True if the value contains characters that need YAML quoting."""
    return any(ch in value for ch in _YAML_SPECIAL)


def yaml_quoted(value: str) -> str:
    """Return the value quoted for YAML if necessary."""
    if _needs_yaml_quoting(value):
        escaped = value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    return value


def api_get(params: dict[str, str]) -> dict:
    """Make a GET request to the Wikidata API and return parsed JSON."""
    params["format"] = "json"
    url = f"{WIKIDATA_API}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        print(f"Wikidata API returned HTTP {exc.code}: {exc.reason}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as exc:
        print(f"Failed to reach Wikidata API: {exc.reason}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print("Wikidata API returned invalid JSON", file=sys.stderr)
        sys.exit(1)


def search_entity(name: str) -> str | None:
    """Search Wikidata for an entity by name. Return the Q-ID or None."""
    data = api_get(
        {
            "action": "wbsearchentities",
            "search": name,
            "language": "en",
            "type": "item",
            "limit": "5",
        }
    )
    results = data.get("search", [])
    if not results:
        return None

    for i, r in enumerate(results):
        desc = r.get("description", "")
        print(
            f"  [{i}] {r['id']}  {r['label']}" + (f" — {desc}" if desc else ""),
            file=sys.stderr,
        )

    if sys.stdin.isatty():
        print(file=sys.stderr)
        choice = input("Pick a result [0]: ").strip()
        idx = int(choice) if choice.isdigit() and int(choice) < len(results) else 0
    else:
        idx = 0

    qid = results[idx]["id"]
    print(f"\nUsing: {qid} ({results[idx].get('label', '')})\n", file=sys.stderr)
    return qid


def fetch_entity(qid: str) -> dict:
    """Fetch a Wikidata entity by Q-ID."""
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
    qid: str,
    property_map: list[tuple[str, str, str | None]],
) -> list[str]:
    """Extract sameAs URLs from a Wikidata entity using a property map."""
    urls: list[str] = []

    # Wikidata itself
    urls.append(f"https://www.wikidata.org/wiki/{qid}")

    # English Wikipedia from sitelinks
    sitelinks = entity.get("sitelinks", {})
    enwiki = sitelinks.get("enwiki", {}).get("title")
    if enwiki:
        slug = urllib.parse.quote(enwiki.replace(" ", "_"), safe="")
        urls.append(f"https://en.wikipedia.org/wiki/{slug}")

    # Properties
    claims = entity.get("claims", {})
    for prop_id, label, template in property_map:
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
    return list(dict.fromkeys(urls))


# Award family Q-IDs mapped to tag slugs. Specific awards (e.g., "Hugo Award
# for Best Novel") link to these parents via P361 (part of) or P279 (subclass).
AWARD_FAMILIES: dict[str, str] = {
    "Q188914": "hugo",
    "Q194285": "nebula",
    "Q754655": "locus",
    "Q594886": "world_fantasy",
    "Q787680": "bsfa",
    "Q708830": "clarke",
    "Q582610": "sturgeon",
    "Q1030402": "campbell",
    "Q142392": "prometheus",
    "Q6418326": "kitschies",
    "Q5157154": "compton_crook",
}

SPARQL_ENDPOINT = "https://query.wikidata.org/sparql"


def sparql_query(query: str) -> list[dict]:
    """Run a SPARQL query against Wikidata and return the result bindings."""
    url = f"{SPARQL_ENDPOINT}?{urllib.parse.urlencode({'query': query, 'format': 'json'})}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
        return data.get("results", {}).get("bindings", [])
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError) as exc:
        print(f"SPARQL query failed: {exc}", file=sys.stderr)
        return []


def get_earliest_edition_isbn(work_qid: str) -> str | None:
    """Find an ISBN from the editions of a work via the Wikidata API.

    Uses P747 (has edition or translation) on the work entity to find
    edition Q-IDs, fetches them in batches, and returns the first ISBN
    found. Prefers ISBN-13 (P212) over ISBN-10 (P957).
    """
    # Get edition Q-IDs from the work entity.
    work = fetch_entity(work_qid)
    edition_claims = work.get("claims", {}).get("P747", [])
    edition_qids = []
    for claim in edition_claims:
        qid = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id")
        if qid:
            edition_qids.append(qid)

    if not edition_qids:
        return None

    # Fetch editions in batches of 50 (API limit).
    for i in range(0, len(edition_qids), 50):
        batch = edition_qids[i : i + 50]
        data = api_get(
            {
                "action": "wbgetentities",
                "ids": "|".join(batch),
                "props": "claims",
            }
        )
        for qid in batch:
            entity = data.get("entities", {}).get(qid, {})
            isbn_list = get_claim_strings(entity, "P212") or get_claim_strings(
                entity, "P957"
            )
            if isbn_list:
                return isbn_list[0]

    return None


def resolve_qid(arg: str) -> str:
    """Resolve a Q-ID or name string to a Q-ID. Exits on failure."""
    if arg.startswith("Q") and arg[1:].isdigit():
        return arg

    qid = search_entity(arg)
    if qid is None:
        print(f"No Wikidata entity found for: {arg}", file=sys.stderr)
        sys.exit(1)
    return qid


def _resolve_award_family(award_qid: str, seen: set[str] | None = None) -> str | None:
    """Resolve an award Q-ID to a family slug by traversing the hierarchy.

    Follows P361 (part of) and P279 (subclass of) up to 5 levels to find
    a known award family. Returns None if no family is found.
    """
    if seen is None:
        seen = set()

    if award_qid in seen or len(seen) > 5:
        return None
    seen.add(award_qid)

    if award_qid in AWARD_FAMILIES:
        return AWARD_FAMILIES[award_qid]

    entity = fetch_entity(award_qid)
    claims = entity.get("claims", {})

    for prop in ("P361", "P279"):
        for claim in claims.get(prop, []):
            parent_qid = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id")
            if parent_qid:
                result = _resolve_award_family(parent_qid, seen)
                if result:
                    return result

    return None


def fetch_awards(book_qid: str) -> list[str]:
    """Fetch award slugs for a book from Wikidata.

    Queries P166 (award received) and resolves each to a known award family.
    Returns a sorted, deduplicated list of award slugs.
    """
    entity = fetch_entity(book_qid)
    claims = entity.get("claims", {})
    award_claims = claims.get("P166", [])

    slugs: set[str] = set()
    for claim in award_claims:
        award_qid = claim.get("mainsnak", {}).get("datavalue", {}).get("value", {}).get("id")
        if not award_qid:
            continue

        slug = _resolve_award_family(award_qid)
        if slug:
            slugs.add(slug)
        else:
            label = fetch_entity(award_qid).get("labels", {}).get("en", {}).get("value", award_qid)
            print(f"  Unknown award family: {label} ({award_qid})", file=sys.stderr)

    return sorted(slugs)
