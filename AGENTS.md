# AGENTS.md

`CLAUDE.md` and `GEMINI.md` are symlinks to this file.

## Context

Jekyll-based static site (alexgude.com) running in Docker.
**Crucial:** Always use `make` commands. Never run `jekyll` or `bundle` directly.

## Operations

- **Serve:** `make serve` (Live reload at localhost:4000).
- **Test:** `make test` (Runs all tests in `_tests/`).
- **Test File:** `make test TEST=_tests/src/path/to/test.rb`
- **Build:** `make build` (Production build to `_site/`).
- **Deps:** `make lock` (Update Gemfile.lock via Docker).
- **Lint:** `make lint` / `make format-all`.
- **Lint Python:** `make lint-scripts` (Ruff check + format check) /
  `make format-scripts` (Ruff autofix + format).
- **Format MD:** `make format-md` (Run Prettier on all Markdown files).
- **Scripts:** `make scripts` (List available Python scripts with descriptions).
- **Test Scripts:** `make test-scripts` (Run Python script tests via pytest).
- **Hooks:** `make hooks-install` (Install pre-commit hook).

### Content checks

**No single command runs every check.** `make check` is only an alias for
`check-links`. The suite is three separate commands, and each catches a class
the other two are blind to:

- **`make check-links`** — builds the site, then runs html-proofer over
  `_site/` for broken links, missing images, and empty `alt`.
- **`make check-refs`** — markdown reference links: undefined `[text][id]`,
  duplicate `[id]:`, orphaned `[id]:`. All three fail the build.
- **`make check-liquid`** — strict-Liquid render of every document.

Why they do not overlap:
`.claude/skills/jekyll-site-dev/references/links-and-previews.md`.

## Architecture Map

- **Content:** `_posts/` (Blog), `_books/` (Reviews collection).
- **Layouts:** `_layouts/`, `_includes/`.
- **Plugins:** `_plugins/src/` (Domain-Driven Design).
  - `infrastructure/`: Low-level utils (Logger, Text, URL), **Link Cache**,
    `GeneratedStaticFile`, `MarkdownWhitespaceNormalizer`,
    `MarkdownLinkFormatter`.
  - `ui/`: Generic components (Cards, Ratings, Citations,
    `MarkdownCardUtils`).
  - `seo/`: Three subsystems all read by (or emitting for) `_includes/head.html`:
    - `JsonLdInjector` populates `site.data['generated_json_ld_scripts']`
      with `<script type="application/ld+json">` tags. Layout-keyed
      dispatch via `LAYOUT_GENERATORS`; unknown layout raises.
    - `SeoMetaInjector` populates `site.data['seo_meta']` with meta tag
      values (title, og_*, twitter_*, description, canonical). Layout
      knowledge limited to title suffixes (`LAYOUT_TITLE_SUFFIX`) and
      article classification (`ARTICLE_LAYOUTS`). The cross-check test
      `test_every_known_layout_has_article_classification` enforces that
      every layout in `LAYOUT_GENERATORS` is explicitly classified.
    - `StandardSiteWellKnownGenerator` emits
      `.well-known/site.standard.publication` for AT Protocol / Bluesky
      verification; head.html renders the matching link tags from
      `standard_site.publication_uri` (config) and
      `_data/standard_site.json` (CI-generated). See the skill reference
      `atproto-standard-site.md` and `bluesky.md`.
  - `content/`: Domain logic (Books, Posts, Authors, Series, **Markdown Output**).
- **AT Protocol publish:** `_scripts/atproto/publish.py` syncs posts and
  book reviews to `site.standard.document` records in CI (main only); the
  PDS is the state store. Operational runbook:
  `.claude/skills/jekyll-site-dev/references/atproto-standard-site.md`.
- **Tests:** `_tests/` (Mirrors `_plugins/src/` structure).

## Git Conventions

- **`book-*` branches are active.** They mark books the owner is currently
  reading; never delete them during housekeeping.
- **Do not merge a branch straight into `main`.** The content checks run in
  CI on push and on PRs targeting `main`, so a direct `git merge` publishes
  without any of them running. A malformed reference-link definition reached
  production this way: two `[id]:` definitions got joined onto one line during
  a prose rewrap, kramdown swallowed the second, and the live page rendered a
  bare Wikipedia URL in the middle of a paragraph. Either open a PR, or run
  `make check-links && make check-refs && make check-liquid` locally before
  merging.

## Development Rules

1.  **Separation of Concerns:**
    - **Tags** (`tags/`) are thin wrappers; check `render_mode` and delegate.
    - **Utils** (`[domain]/[util].rb`) orchestrate logic.
    - **Finders** fetch data; **Renderers** generate HTML.
2.  **Error Handling:** Use `PluginLoggerUtils.log_liquid_failure`.
3.  **Testing:** Create a matching test file in `_tests/` for every new class.
4.  **Link Cache:** The site relies on `site.data['link_cache']` (built by
    `LinkCacheGenerator`) for O(1) lookups of books/authors.
5.  **Break, don't fail silently.** When an invariant is violated, raise
    `Jekyll::Errors::FatalException` to stop the build. A broken build is
    always better than silently wrong output — wrong output ships to
    production and is discovered much later.
6.  **Skill doc sync:** When you change plugin architecture, CI workflow,
    hooks, or the markdown-output pipeline, update the matching file in
    `.claude/skills/jekyll-site-dev/references/`.
