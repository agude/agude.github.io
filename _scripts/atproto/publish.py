#!/usr/bin/env python3
"""
Sync blog posts and book reviews to AT Protocol via standard.site lexicons.

Subcommands
  publish          Sync _posts/ (and _books/ when --books-dir is given) to
                   PDS document records; write _data/standard_site.json.
  validate         Check posts/books parse cleanly (no network, no creds).
  init-publication Create the site.standard.publication record (one-time setup).

Run from _scripts/:
  uv run python atproto/publish.py publish \\
      --posts-dir ../_posts --books-dir ../_books \\
      --data-out ../_data/standard_site.json [--dry-run]

  uv run python atproto/publish.py validate --posts-dir ../_posts --books-dir ../_books

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


def _slugify(name_slug: str) -> str:
    """
    Replicate Jekyll's default slugify for the permalink :slug token:
    lowercase, runs of non-alphanumerics become a single hyphen, and
    leading/trailing hyphens are stripped (underscores become hyphens).
    """
    return re.sub(r"[^a-z0-9]+", "-", name_slug.lower()).strip("-")


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

    path_str = f"/blog/{_slugify(slug)}/"

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


def _extract_frontmatter_strict(text: str) -> dict:
    """Like _extract_frontmatter but raises yaml.YAMLError on bad YAML."""
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    return yaml.safe_load(parts[1]) or {}


def _can_derive_date(date_val: Any) -> bool:
    """Return True if date_val can produce a valid YYYY-MM-DD publishedAt."""
    if hasattr(date_val, "strftime"):
        return True
    return bool(re.match(r"^\d{4}-\d{2}-\d{2}", str(date_val)))


def _to_publish_date(date_val: Any) -> str:
    if hasattr(date_val, "strftime"):
        return date_val.strftime("%Y-%m-%dT00:00:00Z")
    return f"{str(date_val)[:10]}T00:00:00Z"


def parse_book(path: Path) -> dict | None:
    """
    Parse a book review file and return managed record fields, or None to skip.

    Books live in _books/ with no date-prefixed filename; the collection
    permalink is /books/:path/, which keeps the filename stem verbatim
    (unlike posts' :slug, which slugifies). publishedAt comes from the
    required 'date' front matter; when it can't be derived the key is left
    out so callers can fail loudly.
    """
    text = path.read_text(encoding="utf-8")
    fm = _extract_frontmatter(text)

    if fm.get("published") is False or fm.get("draft") is True:
        return None

    if "slug" in fm or "permalink" in fm:
        print(
            f"WARNING: {path.name} has explicit slug/permalink front matter; "
            "using filename-derived stem for AT record path",
            file=sys.stderr,
        )

    record: dict[str, Any] = {
        "$type": "site.standard.document",
        "path": f"/books/{path.stem}/",
        "title": str(fm.get("title", "")),
        "tags": ["book-reviews"],
    }

    if "date" in fm and fm["date"] is not None and _can_derive_date(fm["date"]):
        record["publishedAt"] = _to_publish_date(fm["date"])

    return record


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
    publication_uri: str,
    dry_run: bool = False,
    books_dir: Path | None = None,
) -> None:
    """Sync local posts (and books) to PDS document records; write data file."""

    if not publication_uri:
        # site is a required document field, and an empty value here would
        # also make the merge loop strip site from existing remote records.
        print("ERROR: sync_posts requires a publication_uri", file=sys.stderr)
        sys.exit(1)

    sources: list[tuple[Path, Any]] = [(posts_dir, parse_post)]
    if books_dir is not None:
        sources.append((books_dir, parse_book))

    # --- Collect local documents ---
    # Defense in depth alongside the validate subcommand: never sync a
    # record that violates the lexicon or silently shadows another page.
    local: dict[str, tuple[Path, dict]] = {}
    for src_dir, parser in sources:
        for post_file in sorted(src_dir.glob("*.md")):
            rec = parser(post_file)
            if rec is None:
                continue
            if not rec["title"].strip():
                print(
                    f"ERROR: {post_file.name}: missing or empty 'title'",
                    file=sys.stderr,
                )
                sys.exit(1)
            if not rec.get("publishedAt"):
                print(
                    f"ERROR: {post_file.name}: cannot derive publishedAt "
                    "(books require a 'date' front matter key)",
                    file=sys.stderr,
                )
                sys.exit(1)
            if rec["path"] in local:
                print(
                    f"ERROR: duplicate local path {rec['path']!r}: "
                    f"{local[rec['path']][0].name} and {post_file.name}",
                    file=sys.stderr,
                )
                sys.exit(1)
            rec["site"] = publication_uri
            local[rec["path"]] = (post_file, rec)

    # --- Fetch remote records ---
    # Only records belonging to our publication are managed; documents other
    # apps (Leaflet, pckt, ...) may create in this collection are ignored.
    remote: dict[str, tuple[str, dict]] = {}  # path → (rkey, record_value)
    for item in client.list_records("site.standard.document"):
        uri: str = item["uri"]
        value: dict = item["value"]
        if value.get("site") != publication_uri:
            continue
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
# validate subcommand
# ---------------------------------------------------------------------------


def validate_posts(posts_dir: Path, books_dir: Path | None = None) -> bool:
    """
    Validate all posts (and books) for AT Protocol compatibility.

    Requires no credentials, config, or network access. Returns True if all
    publishable documents are valid; False if any errors were found. Warnings
    (slug/permalink overrides) do not affect the return value.
    """
    errors = 0
    seen_paths: dict[str, Path] = {}

    def _common_checks(doc_file: Path, path_str: str, fm: dict) -> int:
        """Checks shared by posts and books; returns the error count."""
        found = 0

        if path_str in seen_paths:
            print(
                f"ERROR: {doc_file.name}: duplicate path {path_str!r} "
                f"(also claimed by {seen_paths[path_str].name})",
                file=sys.stderr,
            )
            found += 1
        else:
            seen_paths[path_str] = doc_file

        if "slug" in fm or "permalink" in fm:
            print(
                f"WARNING: {doc_file.name}: has explicit slug/permalink; "
                "filename-derived AT record path will be used",
                file=sys.stderr,
            )

        title = str(fm.get("title") or "").strip()
        if not title:
            print(
                f"ERROR: {doc_file.name}: missing or empty 'title'",
                file=sys.stderr,
            )
            found += 1

        return found

    for post_file in sorted(posts_dir.glob("*.md")):
        m = POST_FILENAME_RE.match(post_file.name)
        if not m:
            continue

        slug = m.group(2)
        path_str = f"/blog/{_slugify(slug)}/"

        text = post_file.read_text(encoding="utf-8")
        try:
            fm = _extract_frontmatter_strict(text)
        except yaml.YAMLError as exc:
            print(
                f"ERROR: {post_file.name}: invalid YAML front matter: {exc}",
                file=sys.stderr,
            )
            errors += 1
            continue

        if fm.get("published") is False or fm.get("draft") is True:
            continue

        errors += _common_checks(post_file, path_str, fm)

        # Posts fall back to the filename date, so 'date' is optional but
        # must be usable when present.
        if "date" in fm and fm["date"] is not None:
            if not _can_derive_date(fm["date"]):
                print(
                    f"ERROR: {post_file.name}: cannot derive publishedAt from "
                    f"'date' value {fm['date']!r}",
                    file=sys.stderr,
                )
                errors += 1

    book_files = sorted(books_dir.glob("*.md")) if books_dir is not None else []
    for book_file in book_files:
        path_str = f"/books/{book_file.stem}/"

        text = book_file.read_text(encoding="utf-8")
        try:
            fm = _extract_frontmatter_strict(text)
        except yaml.YAMLError as exc:
            print(
                f"ERROR: {book_file.name}: invalid YAML front matter: {exc}",
                file=sys.stderr,
            )
            errors += 1
            continue

        if fm.get("published") is False or fm.get("draft") is True:
            continue

        errors += _common_checks(book_file, path_str, fm)

        # Books have no filename date to fall back to: 'date' is required.
        if "date" not in fm or fm["date"] is None:
            print(
                f"ERROR: {book_file.name}: missing 'date' front matter "
                "(required for publishedAt)",
                file=sys.stderr,
            )
            errors += 1
        elif not _can_derive_date(fm["date"]):
            print(
                f"ERROR: {book_file.name}: cannot derive publishedAt from "
                f"'date' value {fm['date']!r}",
                file=sys.stderr,
            )
            errors += 1

    return errors == 0


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
    pub_p.add_argument("--books-dir", type=Path, default=None)
    pub_p.add_argument("--data-out", required=True, type=Path)
    pub_p.add_argument("--dry-run", action="store_true")

    sub.add_parser("init-publication", help="Create publication record (one-time)")

    val_p = sub.add_parser(
        "validate",
        help="Validate posts for AT Protocol compatibility (no network, no credentials)",
    )
    val_p.add_argument("--posts-dir", required=True, type=Path)
    val_p.add_argument("--books-dir", type=Path, default=None)

    args = parser.parse_args(argv)

    # validate needs no credentials or config — dispatch before either check.
    if args.cmd == "validate":
        if not validate_posts(args.posts_dir, books_dir=args.books_dir):
            sys.exit(1)
        return

    config = load_config()
    publication_uri = get_publication_uri(config)

    # Pre-Phase-3 state: no publication record configured yet. Skip cleanly
    # (before requiring credentials) so merging the code doesn't block
    # deploys; write an empty data file so the Jekyll build stays consistent.
    if args.cmd == "publish" and not publication_uri:
        print(
            "standard_site.publication_uri not configured; skipping publish "
            "(see bluesky.md Phase 3)",
            file=sys.stderr,
        )
        args.data_out.parent.mkdir(parents=True, exist_ok=True)
        args.data_out.write_text("{}\n", encoding="utf-8")
        return

    handle = _get_env("BSKY_HANDLE")
    password = _get_env("BSKY_APP_PASSWORD")
    client = AtprotoClient(PDS_URL, handle, password)

    if args.cmd == "publish":
        sync_posts(
            client,
            args.posts_dir,
            args.data_out,
            publication_uri,
            dry_run=args.dry_run,
            books_dir=args.books_dir,
        )
    elif args.cmd == "init-publication":
        init_publication(client, config)


if __name__ == "__main__":
    main()
