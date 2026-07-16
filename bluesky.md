# Bluesky / standard.site Integration Plan

**Status:** Phase 1 ✓ | Phase 2 ✓ | Phase 3 (manual) | Phase 4 ✓ | Phase 5 (post-deploy) | Phase 6 ✓

Implementation plan for publishing this site's posts to the AT Protocol
using the [standard.site](https://standard.site) lexicons, so links to
alexgude.com get enhanced cards on Bluesky and posts are discoverable in
the standard.site ecosystem (Leaflet, pckt.blog, search engines).

This document is self-contained: all API details, record shapes, and file
formats a junior engineer needs are specified below.

## Background

### What already exists

- `alexgude.com` is the owner's Bluesky handle. The DNS TXT record
  `_atproto.alexgude.com` resolves the domain to the DID
  `did:plc:y5qiqqtzjmlwggzuttldivxq`. **Nothing to do here.**
- The site deploys via GitHub Actions (`.github/workflows/jekyll.yml`):
  `test` job on every branch, `build` + `deploy` jobs on `main` only.

### What standard.site requires

Two record types stored in the owner's PDS (Personal Data Server, i.e.
the Bluesky account's data store):

1. **One `site.standard.publication` record** (created once, manually).
   Required fields: `url`, `name`.
2. **One `site.standard.document` record per post.** Required fields:
   `site` (the publication's AT-URI), `title`, `publishedAt`.

The site proves ownership with two static artifacts:

1. `https://alexgude.com/.well-known/site.standard.publication` — a
   plain-text file containing exactly the publication record's AT-URI.
2. A `<link rel="site.standard.document" href="at://...">` tag in each
   post's `<head>`, pointing at that post's document record.

### Hard constraints discovered during research

- **Record keys (rkeys) must be TIDs** (timestamp identifiers like
  `3mpwdqt4xn42j`). Both lexicons declare `"key": "tid"`; PDS validation
  rejects slug-based rkeys. Therefore AT-URIs are **not predictable at
  build time** — the build must learn them from somewhere.
- Blob uploads (cover images) are capped at 1MB. (Out of scope for v1.)
- Repo XRPC calls go to the PDS entryway `https://bsky.social/xrpc/`,
  **not** `api.bsky.app` (that host returns `RecordNotFound` for repo
  operations).

## Architecture

**The PDS is the state store.** No AT-URIs are committed to the repo, no
`[skip ci]` commit-back loop, and the workflow keeps `contents: read`.

On every push to `main`, a publish step runs *before* `jekyll build`:

```
┌─ CI build job (main only) ─────────────────────────────────────┐
│ 1. publish script:                                             │
│    createSession ─► listRecords (our site.standard.document)   │
│    ─► diff against _posts/ ─► createRecord new / putRecord     │
│    changed ─► write _data/standard_site.json (url → AT-URI)    │
│ 2. jekyll build:                                               │
│    head.html reads site.data.standard_site ─► emits link tags  │
│    plugin emits .well-known/site.standard.publication          │
│ 3. deploy as usual                                             │
└────────────────────────────────────────────────────────────────┘
```

Local and branch builds have no `_data/standard_site.json`; the head
include must degrade to emitting no document link tags. That is correct
behavior: verification tags only matter on production.

Idempotency: the script matches remote records to local posts by the
record's `path` field (e.g. `/blog/favorite_books_of_2025/`). A post
with a matching remote record and identical managed fields is skipped;
changed fields trigger a `putRecord` reusing the same rkey.

## Phase 1 — Ruby build side

Everything in this phase works offline and can be merged before any PDS
records exist.

### 1.1 Config key

Add to `_config.yml` (value filled in during Phase 3):

```yaml
standard_site:
  publication_uri: "" # at://did:plc:.../site.standard.publication/<rkey>
```

### 1.2 `.well-known` file generator

New plugin: `_plugins/src/seo/standard_site_well_known_generator.rb`.

- A `Jekyll::Generator` that reads `site.config["standard_site"]["publication_uri"]`.
- If the key is missing or empty: log via
  `PluginLoggerUtils.log_liquid_failure` and generate nothing (the
  feature is not yet configured — this is the pre-Phase-3 state).
- If the value is present but does not match
  `%r{\Aat://did:[a-z0-9:]+/site\.standard\.publication/[a-zA-Z0-9._:~-]+\z}`:
  raise `Jekyll::Errors::FatalException` (repo rule: break, don't fail
  silently).
- Otherwise append a
  `Jekyll::Infrastructure::GeneratedStaticFile.new(site, ".well-known", "site.standard.publication", uri)`
  to `site.static_files` (same mechanism the markdown-output pipeline
  uses). File content is the AT-URI **with no trailing newline** —
  verifiers compare the string exactly; a bare URI is the safe form.

### 1.3 Link tags in `head.html`

Add to `_includes/head.html` (near the markdown-alternate block, which
is the pattern to copy — note the `| optional:` filter usage; the build
runs a strict-Liquid check, `_bin/check_strict.rb`, that fails on bare
accesses to possibly-missing variables):

```liquid
{% comment %} standard.site (AT Protocol) verification links {% endcomment %}
{% assign ss_config = site | optional: 'standard_site' %}
{% assign ss_publication_uri = ss_config | optional: 'publication_uri' %}
{% if ss_publication_uri and ss_publication_uri != "" %}
<link rel="site.standard.publication" href="{{ ss_publication_uri }}">
{% endif %}
{% assign ss_data = site.data | optional: 'standard_site' %}
{% assign ss_document_uri = ss_data | optional: page.url %}
{% if ss_document_uri %}
<link rel="site.standard.document" href="{{ ss_document_uri }}">
{% endif %}
```

The publication link is an optional discovery hint the spec encourages;
it appears on every page. The document link appears only on pages whose
URL has an entry in `_data/standard_site.json`.

### 1.4 Data file hygiene

- Add `_data/standard_site.json` to `.gitignore` (it is CI-generated).
- Add `bluesky.md` (this file) to the `exclude:` list in `_config.yml`
  so the plan is not published to the live site.

### 1.5 Tests

Repo rule: every new class gets a matching test file.

- `_tests/src/seo/test_standard_site_well_known_generator.rb`:
  - missing/empty config → no static file generated, logs a warning.
  - malformed URI → raises `Jekyll::Errors::FatalException`.
  - valid URI → a static file with dir `.well-known`, name
    `site.standard.publication`, exact content, no trailing newline.
- Run `make test` and `make lint`.

**Acceptance:** `make build` with an empty `publication_uri` succeeds
and emits no new artifacts; with a valid dummy URI, `_site/.well-known/site.standard.publication`
exists with exact content, and a post page built with a hand-written
`_data/standard_site.json` contains both link tags.

## Phase 2 — Python publish script

New directory `_scripts/atproto/` with `publish.py`. Tests in
`_scripts/tests/test_atproto_publish.py`. Dependencies: `requests` and
`pyyaml`, both already in `_scripts/pyproject.toml` dev group; add
`"atproto"` to the `pythonpath` list in `pyproject.toml`.

### 2.1 CLI

```
uv run python atproto/publish.py publish \
    --posts-dir ../_posts \
    --data-out ../_data/standard_site.json \
    [--dry-run]

uv run python atproto/publish.py init-publication   # Phase 3, one-time
```

Env vars (both required): `BSKY_HANDLE` (`alexgude.com`),
`BSKY_APP_PASSWORD`. Constants in the script: `PDS_URL =
"https://bsky.social"`, `SITE_URL = "https://alexgude.com"`,
`PUBLICATION_URI` read from `_config.yml` (parse with `yaml.safe_load`).

**Rollout safety:** when `standard_site.publication_uri` is empty
(the pre-Phase-3 state), `publish` prints a notice, writes an empty
`{}` data file, and exits 0 — *before* requiring the env vars — so the
code can merge to `main` without blocking deploys. Once the config is
set, missing credentials become a hard failure. `sync_posts` itself
refuses to run without a publication URI: `site` is a required document
field, and an empty value would otherwise strip `site` from existing
remote records via the managed-field merge.

### 2.2 XRPC calls

All are JSON over HTTPS; raise and exit non-zero on any non-2xx
response (print the response body — PDS errors are descriptive).

| Call | Method/endpoint | Notes |
| --- | --- | --- |
| Login | `POST {PDS_URL}/xrpc/com.atproto.server.createSession` | body `{"identifier": handle, "password": app_password}`; response has `accessJwt` (use as `Authorization: Bearer ...`) and `did` |
| List | `GET {PDS_URL}/xrpc/com.atproto.repo.listRecords?repo={did}&collection=site.standard.document&limit=100` | paginate: pass returned `cursor` back until absent |
| Create | `POST {PDS_URL}/xrpc/com.atproto.repo.createRecord` | body `{"repo": did, "collection": "site.standard.document", "record": {...}}` — PDS assigns the TID rkey; response has `uri` |
| Update | `POST {PDS_URL}/xrpc/com.atproto.repo.putRecord` | body `{"repo": did, "collection": "site.standard.document", "rkey": rkey, "record": {...}}` |

### 2.3 Building the desired record for a post

For each `_posts/YYYY-MM-DD-slug.md`, split front matter (text between
the first two `---` lines, `yaml.safe_load` it) and derive:

```json
{
  "$type": "site.standard.document",
  "site": "<PUBLICATION_URI>",
  "path": "/blog/<slug>/",
  "title": "<front matter title>",
  "description": "<front matter description, stripped>",
  "tags": ["<front matter categories, if any>"],
  "publishedAt": "<YYYY-MM-DD>T00:00:00Z"
}
```

Details:

- **path**: the site permalink is `/blog/:slug/`; slug is the filename
  after the date prefix, underscores preserved
  (`2026-01-04-favorite_books_of_2025.md` → `/blog/favorite_books_of_2025/`).
  If front matter contains an explicit `slug:` or `permalink:` key, use
  it; log a warning so mismatches are visible.
- **publishedAt**: date from the filename unless front matter has
  `date:` (which overrides, matching Jekyll). Midnight UTC is fine.
- **description** / **tags**: omit the key entirely when the front
  matter lacks it (do not send empty strings/arrays). Posts use
  `categories:` (e.g. `book-reviews`), which map to `tags`.
- Skip drafts and anything not matching the `YYYY-MM-DD-*.md` pattern.

### 2.4 Diff and write logic

1. Fetch all remote documents; **keep only records whose `site` equals
   our publication URI** (other apps — Leaflet, pckt — may write to the
   same collection and must be ignored, not treated as duplicates or
   orphans). Build `{record.path: (rkey, record)}`. If two remaining
   records share a `path`, abort with an error listing both AT-URIs
   (duplicates must be cleaned up by hand — never guess).
2. For each local post:
   - **No remote match** → `createRecord`.
   - **Match, managed fields equal** → skip. Managed fields are exactly
     the keys in §2.3.
   - **Match, fields differ** → start from the **remote** record,
     overwrite only the managed fields, set
     `"updatedAt": <now, ISO 8601 UTC>`, and `putRecord` with the same
     rkey. Starting from the remote copy preserves fields this script
     does not manage (`bskyPostRef`, `coverImage`, …) so a future
     manual edit is never clobbered.
3. Remote records whose `path` matches no local post: **warn, never
   delete** (deleted/renamed posts are rare; handle manually).
4. Write `--data-out` as pretty-printed JSON mapping path → AT-URI for
   every local post that has a record (including just-created ones):

```json
{
  "/blog/favorite_books_of_2025/": "at://did:plc:y5qiqqtzjmlwggzuttldivxq/site.standard.document/3mpwdqt4xn42j"
}
```

5. `--dry-run`: do everything except `createRecord`/`putRecord`; print
   the would-be actions; still write `--data-out` for records that
   already exist.
6. Print a summary line: `created=N updated=N unchanged=N orphaned=N`.

### 2.5 `init-publication` subcommand

One-time use in Phase 3. Creates the publication record via
`createRecord` with `collection=site.standard.publication`:

```json
{
  "$type": "site.standard.publication",
  "url": "https://alexgude.com",
  "name": "Alex Gude",
  "description": "Technology, data science, machine learning, and more!",
  "preferences": { "showInDiscover": true }
}
```

(`url` must have no trailing slash — the lexicon says avoid them.)
Prints the returned AT-URI and exits. Refuse to run (with a clear
message) if `_config.yml` already has a non-empty `publication_uri`.

### 2.6 Tests

Mock the HTTP layer (inject a fake session/transport; do not hit the
network). Cover at minimum:

- front matter → record mapping (slug/underscores, date precedence,
  omitted optional fields, categories → tags);
- pagination across multiple `listRecords` pages;
- create vs. update vs. skip decisions;
- update preserves unmanaged remote fields and sets `updatedAt`;
- duplicate remote `path` aborts;
- orphan remote record warns and is not deleted;
- data file contents;
- missing env vars → clear error, non-zero exit.

Run `make test-scripts`.

**Acceptance:** `--dry-run` against the real PDS (records don't exist
yet) lists 105 creates and writes an empty-ish data file, without
erroring.

## Phase 3 — One-time manual setup (site owner)

1. Create an app password at bsky.app → Settings → Privacy and
   Security → App Passwords. **Do not grant DM access.** Name it e.g.
   `site-ci`.
2. Locally: `export BSKY_HANDLE=alexgude.com BSKY_APP_PASSWORD=...`,
   then run `uv run python atproto/publish.py init-publication` from
   `_scripts/`.
3. Put the printed AT-URI into `_config.yml` →
   `standard_site.publication_uri`. Commit.
4. Add the app password as a GitHub Actions repo secret named
   `BSKY_APP_PASSWORD` (Settings → Secrets and variables → Actions).
5. Optional backfill sanity check: run `publish --dry-run` locally,
   eyeball the plan, then run `publish` locally once (105 creates is
   well within the PDS rate limit of 5,000 points/hour at 3
   points/create). CI re-runs are then no-ops.

## Phase 4 — CI wiring

In `.github/workflows/jekyll.yml`, `build` job, insert **before** the
"Build with Jekyll" step (after "Setup Pages"):

```yaml
      - name: Install uv
        if: github.ref == 'refs/heads/main'
        uses: astral-sh/setup-uv@v7

      - name: Publish standard.site records
        if: github.ref == 'refs/heads/main'
        working-directory: _scripts
        run: uv run python atproto/publish.py publish --posts-dir ../_posts --data-out ../_data/standard_site.json
        env:
          BSKY_HANDLE: alexgude.com
          BSKY_APP_PASSWORD: ${{ secrets.BSKY_APP_PASSWORD }}
```

The `build` job must also get a per-ref concurrency group with
`cancel-in-progress: false`: overlapping `main` builds would race the
publish step's listRecords→createRecord cycle and could create
duplicate PDS records for the same path (which then hard-fails every
later build until cleaned up by hand).

Notes:

- The `build` job runs on every branch but this step is gated to
  `main`, so PR builds never need the secret and never mutate the PDS.
- If the publish step fails, the build fails and nothing deploys.
  Intentional (repo rule 5): a half-published state should be loud.
  Exception: while `publication_uri` is unset, the step is a clean
  no-op (see §2.1 rollout safety) so this code can merge before
  Phase 3.
- Update the workflow's header comment (lines 1–14) to mention the new
  step, and update
  `.claude/skills/jekyll-site-dev/references/` (repo rule 6: CI changes
  must be mirrored in the skill docs — for CI, the skill points at the
  workflow header comment itself, so keeping that comment current
  satisfies the rule).

## Phase 5 — Verify

1. After the first `main` deploy:
   `curl https://alexgude.com/.well-known/site.standard.publication`
   → exactly the publication AT-URI.
2. `curl -s https://alexgude.com/blog/<recent-slug>/ | grep site.standard`
   → both link tags present.
3. Run the ecosystem validator at <https://site-validator.fly.dev>
   against the site.
4. Share a post URL in a Bluesky post and confirm the enhanced card
   (publication + author metadata) renders. Cards may lag a few minutes
   after first verification.

## Phase 6 (optional) — Branch-side publish validation

Motivation: branches never run the publish step, so a post that the
publish script can't handle only fails at merge time, blocking the
`main` deploy instead of failing the PR. A network-free `validate`
subcommand closes that gap by running the parsing half of `publish` on
every branch.

### 6.1 `validate` subcommand

Add to `_scripts/atproto/publish.py`:

```
uv run python atproto/publish.py validate --posts-dir ../_posts
```

- Requires **no env vars, no config, no network** — it must never touch
  `AtprotoClient` and must run identically on forks.
- Runs the same `parse_post` path as `publish` over every
  `YYYY-MM-DD-*.md` file and collects errors instead of records:
  - front matter that fails to parse as YAML (note: `parse_post`
    currently swallows `yaml.YAMLError` and returns `{}` — validate
    must surface it as an error, not inherit the silent fallback);
  - missing or empty `title` (the lexicon requires it; `publish` would
    currently create a record with `"title": ""`);
  - a `publishedAt` that cannot be derived;
  - **duplicate `path` across local posts** (two posts whose filenames
    share a slug on different dates collide on `/blog/<slug>/`;
    `sync_posts` currently last-one-wins silently — validate must catch
    it);
  - warn (not error) on explicit `slug:`/`permalink:` front matter,
    same as `publish`.
- Print every problem with its filename; exit 1 if any errors, 0
  otherwise (warnings don't fail).

### 6.2 CI wiring

Add to the **`test` job** (which runs on every branch), after "Run
script tests":

```yaml
      - name: Validate posts for AT Protocol publish
        working-directory: _scripts
        run: uv run python atproto/publish.py validate --posts-dir ../_posts
```

No `if:` gate and no secrets — that is the point. Update the workflow
header comment (repo rule 6).

### 6.3 Tests

Extend `_scripts/tests/test_atproto_publish.py`: valid posts pass;
each error class above fails with the offending filename in the
output; slug/permalink override warns but exits 0; no HTTP calls occur
(the mock transport must stay unused).

**Acceptance:** a branch with a post containing broken front matter
fails the `test` job with a message naming the file; the same tree
passes once fixed; `validate` runs green against the real `_posts/`.

## Future work (explicitly out of scope for v1)

- **`bskyPostRef`**: after manually announcing a post on Bluesky, add
  its post URI to the article's front matter (e.g. `bluesky_post:`);
  teach the script to map it into the record. Enables reply/like
  integration.
- **`textContent`**: populate from the markdown-output pipeline's
  per-post `.md` files (requires feeding built artifacts into the
  publish step, or accepting raw-markdown-with-Liquid as input).
- **`coverImage`**: `com.atproto.repo.uploadBlob`, ≤1MB (compress to
  ~900KB WebP; posts already have `image:` front matter).
- **Book reviews**: extend the script to `_books/` (129 documents;
  permalink structure differs).
- **Automated announcement posts** from CI (decided against for now:
  low posting volume, manual announcements preferred).

## Reference

- Verification spec: <https://standard.site/docs/verification>
- Document lexicon: <https://standard.site/docs/lexicons/document>
- Publication lexicon: <https://standard.site/docs/lexicons/publication>
- Record-key spec (TID requirement): <https://atproto.com/specs/record-key>
- Bluesky timeline integration announcement:
  <https://atproto.com/blog/standard-site-bluesky-timeline>
- Worked DIY example (Eleventy, same API calls):
  <https://brennan.day/publishing-my-eleventy-blog-to-the-atmosphere-with-standard-site/>
- Owner DID: `did:plc:y5qiqqtzjmlwggzuttldivxq` (verify anytime:
  `dig +short TXT _atproto.alexgude.com`)
