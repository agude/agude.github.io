# Bluesky / standard.site Integration

**Status: LIVE (2026-07-16).** 230 `site.standard.document` records
(105 posts + 125 canonical book reviews) on the PDS, verification
artifacts serving in production, validated by site-validator.fly.dev.

Operator's reference (component map, runbook, gotchas):
`.claude/skills/jekyll-site-dev/references/atproto-standard-site.md`.
Full design and hardening history: `git log --follow bluesky.md`.

## Design decisions and why

- **Records live under the owner's personal account**
  (`alexgude.com` / `did:plc:y5qiqqtzjmlwggzuttldivxq`), not a
  dedicated site account: Bluesky's enhanced cards attribute documents
  to the author, and standard.site subscriptions replace the
  "followable blog account" use case. The one cost: the CI app
  password belongs to the personal account (created without DM
  access).
- **The PDS is the state store.** Record keys are TIDs assigned at
  creation, so AT-URIs are unknowable at build time. Instead of the
  commit-back pattern other tools use (`[skip ci]` commits writing
  URIs into front matter), CI diffs local content against
  `listRecords` and emits `_data/standard_site.json` for the build.
  No repo writes, `contents: read` stays, fresh clones can't
  duplicate.
- **Publish only after every site gate passes.** Records are an
  external, not-automatically-reversible system. Main builds once,
  runs all four gates (AT path cross-check both directions, HTML
  structure, feeds, links), publishes, rebuilds with the link tags,
  re-runs the gates, deploys, then smoke-tests the live `.well-known`.
- **Break, don't fail silently, everywhere**: empty
  `publication_uri`, unverifiable publication record, duplicate
  paths, missing `cid`, slug/permalink overrides, nested book files
  without `canonical_url`, and missing input directories are all hard
  failures.
- **Orphans warn, never auto-delete.** Deleting a post leaves its
  record until a human runs `delete-orphans` (which refuses to act on
  an empty local corpus).
- **No automated announcement posts** — posting volume is low;
  announcements are manual, with `bskyPostRef` as the future link
  between a post and its announcement.

## Manual recovery: duplicate remote records for one path

`sync_documents` aborts if two remote records claim the same `path`;
`delete-orphans` cannot help (neither is an orphan). Only a manual
`publish` racing CI can create this. Delete the **newer** record by
rkey (the error prints both; the older may carry manual fields like
`bskyPostRef`):

<!-- prettier-ignore -->
```
curl -X POST "https://bsky.social/xrpc/com.atproto.repo.deleteRecord" \
  -H "Authorization: Bearer $(curl -s -X POST \
    https://bsky.social/xrpc/com.atproto.server.createSession \
    -H 'Content-Type: application/json' \
    -d '{"identifier":"alexgude.com","password":"'"$BSKY_APP_PASSWORD"'"}' \
    | jq -r .accessJwt)" \
  -H "Content-Type: application/json" \
  -d '{"repo":"did:plc:y5qiqqtzjmlwggzuttldivxq",
       "collection":"site.standard.document","rkey":"<NEWER_RKEY>"}'
```

## Future work

- **`bskyPostRef`**: after announcing a post on Bluesky, add the post
  URI to front matter (e.g. `bluesky_post:`); teach the publish script
  to map it into the record. Enables reply/like integration.
- **`textContent`**: populate from the markdown-output pipeline's
  per-post `.md` renditions.
- **`coverImage`**: `com.atproto.repo.uploadBlob`, ≤1MB (compress to
  ~900KB WebP; posts already carry `image:` front matter).
- **Module rename**: `_scripts/atproto/publish.py` →
  `atproto_publish.py` to de-genericize the flat pytest namespace
  (mechanical; touches CI, docs, tests).

## Reference

- Verification spec: <https://standard.site/docs/verification>
- Document lexicon: <https://standard.site/docs/lexicons/document>
- Publication lexicon: <https://standard.site/docs/lexicons/publication>
- Record-key spec (TID requirement): <https://atproto.com/specs/record-key>
- Ecosystem validator: <https://site-validator.fly.dev>
- Publication record:
  `at://did:plc:y5qiqqtzjmlwggzuttldivxq/site.standard.publication/3mqrj32i3mm2t`
- Owner DID: `did:plc:y5qiqqtzjmlwggzuttldivxq` (verify:
  `dig +short TXT _atproto.alexgude.com`)
