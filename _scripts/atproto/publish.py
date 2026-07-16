#!/usr/bin/env python3
"""
Sync blog posts to AT Protocol via standard.site lexicons.

Subcommands
  publish          Sync _posts/ to PDS document records; write _data/standard_site.json.
  init-publication Create the site.standard.publication record (one-time setup).

Run from _scripts/:
  uv run python atproto/publish.py publish \\
      --posts-dir ../_posts \\
      --data-out ../_data/standard_site.json [--dry-run]

  uv run python atproto/publish.py init-publication
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests
import yaml

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

PDS_URL = "https://bsky.social"
SITE_URL = "https://alexgude.com"

_CONFIG_FILE = Path(__file__).parent.parent.parent / "_config.yml"

POST_FILENAME_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})-(.+)\.md$")

MANAGED_FIELDS = frozenset(
    {"$type", "site", "path", "title", "description", "tags", "publishedAt"}
)

PUBLICATION_RECORD: dict[str, Any] = {
    "$type": "site.standard.publication",
    "url": SITE_URL,
    "name": "Alex Gude",
    "description": "Technology, data science, machine learning, and more!",
    "preferences": {"showInDiscover": True},
}

# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------


def load_config(config_path: Path = _CONFIG_FILE) -> dict:
    with open(config_path, encoding="utf-8") as fh:
        return yaml.safe_load(fh) or {}


def get_publication_uri(config: dict) -> str:
    return config.get("standard_site", {}).get("publication_uri", "") or ""


# ---------------------------------------------------------------------------
# Post parsing
# ---------------------------------------------------------------------------


def parse_post(path: Path) -> dict | None:
    """
    Parse a post file and return managed record fields, or None to skip.

    Skips drafts (published: false or draft: true) and files that don't
    match YYYY-MM-DD-slug.md.
    """
    m = POST_FILENAME_RE.match(path.name)
    if not m:
        return None

    date_str, slug = m.group(1), m.group(2)

    text = path.read_text(encoding="utf-8")
    fm = _extract_frontmatter(text)

    if fm.get("published") is False or fm.get("draft") is True:
        return None

    if "slug" in fm or "permalink" in fm:
        print(
            f"WARNING: {path.name} has explicit slug/permalink front matter; "
            "using filename-derived slug for AT record path",
            file=sys.stderr,
        )

    path_str = f"/blog/{slug}/"

    if "date" in fm and fm["date"] is not None:
        pub_date = _to_publish_date(fm["date"])
    else:
        pub_date = f"{date_str}T00:00:00Z"

    record: dict[str, Any] = {
        "$type": "site.standard.document",
        "path": path_str,
        "title": str(fm.get("title", "")),
        "publishedAt": pub_date,
    }

    if "description" in fm and fm["description"] is not None:
        record["description"] = str(fm["description"]).strip()

    cats = fm.get("categories")
    if cats:
        tags = [str(c) for c in (cats if isinstance(cats, list) else [cats]) if c]
        if tags:
            record["tags"] = tags

    return record


def _extract_frontmatter(text: str) -> dict:
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError:
        return {}


def _to_publish_date(date_val: Any) -> str:
    if hasattr(date_val, "strftime"):
        return date_val.strftime("%Y-%m-%dT00:00:00Z")
    return f"{str(date_val)[:10]}T00:00:00Z"


# ---------------------------------------------------------------------------
# AT Protocol client
# ---------------------------------------------------------------------------


class AtprotoClient:
    """Thin wrapper around the XRPC calls needed for standard.site syncing."""

    def __init__(
        self,
        pds_url: str,
        handle: str,
        password: str,
        _session: Any = None,
    ) -> None:
        self._pds = pds_url.rstrip("/")
        self._http = _session if _session is not None else requests.Session()
        self.did: str = ""
        self._jwt: str = ""
        self._login(handle, password)

    def _login(self, handle: str, password: str) -> None:
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.server.createSession",
            json={"identifier": handle, "password": password},
        )
        _check(resp)
        data = resp.json()
        self.did = data["did"]
        self._jwt = data["accessJwt"]

    def _auth(self) -> dict:
        return {"Authorization": f"Bearer {self._jwt}"}

    def list_records(self, collection: str) -> list[dict]:
        """Fetch all records in a collection, following cursor pagination."""
        records: list[dict] = []
        cursor: str | None = None
        while True:
            params: dict[str, Any] = {
                "repo": self.did,
                "collection": collection,
                "limit": 100,
            }
            if cursor:
                params["cursor"] = cursor
            resp = self._http.get(
                f"{self._pds}/xrpc/com.atproto.repo.listRecords",
                params=params,
                headers=self._auth(),
            )
            _check(resp)
            data = resp.json()
            records.extend(data.get("records", []))
            cursor = data.get("cursor")
            if not cursor:
                break
        return records

    def create_record(self, collection: str, record: dict) -> str:
        """Create a record and return its AT-URI."""
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.repo.createRecord",
            json={"repo": self.did, "collection": collection, "record": record},
            headers=self._auth(),
        )
        _check(resp)
        return resp.json()["uri"]

    def put_record(self, collection: str, rkey: str, record: dict) -> None:
        """Overwrite an existing record."""
        resp = self._http.post(
            f"{self._pds}/xrpc/com.atproto.repo.putRecord",
            json={
                "repo": self.did,
                "collection": collection,
                "rkey": rkey,
                "record": record,
            },
            headers=self._auth(),
        )
        _check(resp)


def _check(resp: Any) -> None:
    if not resp.ok:
        print(f"PDS error {resp.status_code}: {resp.text}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# Sync logic
# ---------------------------------------------------------------------------


def _extract_rkey(uri: str) -> str:
    return uri.rstrip("/").rsplit("/", 1)[-1]


def _managed_subset(record: dict) -> dict:
    return {k: v for k, v in record.items() if k in MANAGED_FIELDS}


def _records_differ(local: dict, remote: dict) -> bool:
    return _managed_subset(local) != _managed_subset(remote)


def sync_posts(
    client: AtprotoClient,
    posts_dir: Path,
    data_out: Path,
    dry_run: bool = False,
    publication_uri: str = "",
) -> None:
    """Sync local posts to PDS document records and write the data file."""

    # --- Collect local posts ---
    local: dict[str, tuple[Path, dict]] = {}
    for post_file in sorted(posts_dir.glob("*.md")):
        rec = parse_post(post_file)
        if rec is None:
            continue
        if publication_uri:
            rec["site"] = publication_uri
        local[rec["path"]] = (post_file, rec)

    # --- Fetch remote records ---
    remote: dict[str, tuple[str, dict]] = {}  # path → (rkey, record_value)
    for item in client.list_records("site.standard.document"):
        uri: str = item["uri"]
        value: dict = item["value"]
        path_key: str = value.get("path", "")
        if path_key in remote:
            existing_uri, _ = remote[path_key]
            print(
                f"ERROR: duplicate remote path {path_key!r}: {existing_uri} and {uri}",
                file=sys.stderr,
            )
            sys.exit(1)
        remote[path_key] = (_extract_rkey(uri), value)

    # --- Build AT-URI map for paths that already have remote records ---
    data_map: dict[str, str] = {}
    for path_key, (rkey, _) in remote.items():
        if path_key in local:
            data_map[path_key] = (
                f"at://{client.did}/site.standard.document/{rkey}"
            )

    # --- Diff and sync ---
    created = updated = unchanged = orphaned = 0

    for path_key, (_post_file, local_rec) in local.items():
        if path_key not in remote:
            if dry_run:
                print(f"[dry-run] Would create: {path_key}")
            else:
                at_uri = client.create_record("site.standard.document", local_rec)
                data_map[path_key] = at_uri
                print(f"Created: {path_key} → {at_uri}")
            created += 1
        else:
            rkey, remote_rec = remote[path_key]
            if _records_differ(local_rec, remote_rec):
                merged = dict(remote_rec)
                for key in MANAGED_FIELDS:
                    if key in local_rec:
                        merged[key] = local_rec[key]
                    elif key in merged:
                        del merged[key]
                merged["updatedAt"] = datetime.now(timezone.utc).strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
                if dry_run:
                    print(f"[dry-run] Would update: {path_key}")
                else:
                    client.put_record("site.standard.document", rkey, merged)
                    print(f"Updated: {path_key}")
                updated += 1
            else:
                unchanged += 1

    for path_key in remote:
        if path_key not in local:
            print(
                f"WARNING: orphan remote record (no matching local post): {path_key}",
                file=sys.stderr,
            )
            orphaned += 1

    # --- Write data file ---
    output = {path_key: data_map[path_key] for path_key in sorted(local) if path_key in data_map}
    data_out.parent.mkdir(parents=True, exist_ok=True)
    data_out.write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")

    print(
        f"created={created} updated={updated} unchanged={unchanged} orphaned={orphaned}"
    )


# ---------------------------------------------------------------------------
# init-publication subcommand
# ---------------------------------------------------------------------------


def init_publication(client: AtprotoClient, config: dict) -> None:
    existing = get_publication_uri(config)
    if existing:
        print(
            f"ERROR: publication_uri is already set in _config.yml: {existing!r}",
            file=sys.stderr,
        )
        sys.exit(1)
    at_uri = client.create_record("site.standard.publication", PUBLICATION_RECORD)
    print(f"Publication record created: {at_uri}")
    print("Add this URI to _config.yml → standard_site.publication_uri and commit.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _get_env(name: str) -> str:
    val = os.environ.get(name, "")
    if not val:
        print(f"ERROR: environment variable {name!r} is not set", file=sys.stderr)
        sys.exit(1)
    return val


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    pub_p = sub.add_parser("publish", help="Sync posts to PDS document records")
    pub_p.add_argument("--posts-dir", required=True, type=Path)
    pub_p.add_argument("--data-out", required=True, type=Path)
    pub_p.add_argument("--dry-run", action="store_true")

    sub.add_parser("init-publication", help="Create publication record (one-time)")

    args = parser.parse_args(argv)

    handle = _get_env("BSKY_HANDLE")
    password = _get_env("BSKY_APP_PASSWORD")
    config = load_config()
    client = AtprotoClient(PDS_URL, handle, password)

    if args.cmd == "publish":
        sync_posts(
            client,
            args.posts_dir,
            args.data_out,
            dry_run=args.dry_run,
            publication_uri=get_publication_uri(config),
        )
    elif args.cmd == "init-publication":
        init_publication(client, config)


if __name__ == "__main__":
    main()
