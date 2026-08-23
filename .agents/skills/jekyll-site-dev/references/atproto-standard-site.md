# AT Protocol / standard.site Integration

How alexgude.com publishes to the AT Protocol (Bluesky's network) via
the [standard.site](https://standard.site) lexicons. This is the
operator's reference: what's wired where, and what to do when things
change. Design rationale, the full hardening history, and recovery
procedures live in `bluesky.md` at the repo root (excluded from the
built site).

## Identity

- `alexgude.com` **is** the owner's Bluesky handle. The DNS TXT record
  `_atproto.alexgude.com` (managed in Cloudflare) maps the domain to
  the DID `did:plc:y5qiqqtzjmlwggzuttldivxq`. Verify anytime:
  `dig +short TXT _atproto.alexgude.com`.
- All AT records live in that account's PDS (`bsky.social` entryway).
  The publication record's AT-URI is committed in `_config.yml` under
  `standard_site.publication_uri` — it is the partition key for every
  sync and **must never be blank** (blank fails the build by design).

## The pieces

| Piece | Where | Role |
| --- | --- | --- |
| Publish/validate script | `_scripts/atproto/publish.py` | `publish` syncs `_posts/` + `_books/` to `site.standard.document` records (PDS is the state store — no AT-URIs in the repo); `validate` is the credential-free CI gate; `delete-orphans` is manual cleanup; `init-publication` was one-time setup |
| Well-known generator | `_plugins/src/seo/standard_site_well_known_generator.rb` | Emits `_site/.well-known/site.standard.publication` (bare AT-URI, no trailing newline) |
| Link tags | `_includes/head.html` | `rel="site.standard.publication"` on every page; `rel="site.standard.document"` on pages with an entry in the data file |
| Data file | `_data/standard_site.json` | URL → AT-URI map, written by the publish step in CI, gitignored; absent locally and on branches (document tags simply don't render) |
| CI wiring | `.github/workflows/jekyll.yml` (header comment is the authoritative doc) | Branch: validate + build + four site gates. Main only: publish → rebuild with tags → re-run gates → deploy → post-deploy `.well-known` smoke test |
| Secret | `BSKY_APP_PASSWORD` repo secret | App password (created without DM access) for the owner's account |

## Path derivation (must match Jekyll exactly)

- Posts: `/blog/<slug>/` where the filename slug is **slugified**
  (underscores → hyphens, lowercased). Permalink pinned in
  `_config.yml` (`permalink: /blog/:slug/`).
- Books: `/books/<filename-stem>/` **verbatim** (underscores kept).
  Permalink pinned (`collections: books: permalink: /books/:path/`).
- The CI cross-check (`validate --site-dir`) enforces the match in
  both directions on every branch, so drift fails loudly pre-publish.

## Routine operations

- **New post or book review**: nothing extra — the next main deploy
  creates its record. Front-matter rules that affect records are in
  [Content Authoring](content-authoring.md).
- **Edit a post**: the record updates automatically (`putRecord` with
  compare-and-swap; unmanaged fields like `bskyPostRef` survive).
- **Delete/rename a post**: CI warns (`::warning::` annotation) about
  the orphaned record; clean up manually from `_scripts/`:
  `uv run python atproto/publish.py delete-orphans --posts-dir ../_posts --books-dir ../_books` (add `--yes` to delete).
- **Local dry run** (needs `BSKY_HANDLE`/`BSKY_APP_PASSWORD` exported):
  `uv run python atproto/publish.py publish ... --dry-run` — zero
  writes, prints the plan.
- **PDS outage blocking a deploy**: run the workflow manually
  (Actions tab) with `skip_publish: true`.
- **Rotate the secret**: new app password at bsky.app → Settings →
  App Passwords (no DM access) → update the `BSKY_APP_PASSWORD` repo
  secret. Nothing else changes.

## Gotchas

- Record keys are TIDs assigned by the PDS — AT-URIs are **not**
  predictable at build time; that's why the data file exists and why
  the PDS is queried (`listRecords`) instead of committing URIs.
- `actions/upload-pages-artifact` drops dot-prefixed files unless
  `include-hidden-files: true` — that flag is load-bearing for
  `.well-known` (it was silently dropped on the first deploy).
- The future-post cutoff and Jekyll's `future: false` both use the
  site timezone (`America/Los_Angeles`); the constant in `publish.py`
  must track `_config.yml`'s `timezone:` key.
- Other apps (Leaflet, pckt) may write `site.standard.document`
  records into the same PDS collection; everything here is scoped by
  `site == publication_uri` and must stay that way.
