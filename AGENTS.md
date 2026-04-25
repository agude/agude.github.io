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
- **Format MD:** `make format-md` (Run Prettier on all Markdown files).
- **Scripts:** `make scripts` (List available Python scripts with descriptions).
- **Test Scripts:** `make test-scripts` (Run Python script tests via pytest).
- **Hooks:** `make hooks-install` (Install pre-commit hook).

## Architecture Map

- **Content:** `_posts/` (Blog), `_books/` (Reviews collection).
- **Layouts:** `_layouts/`, `_includes/`.
- **Plugins:** `_plugins/src/` (Domain-Driven Design).
  - `infrastructure/`: Low-level utils (Logger, Text, URL), **Link Cache**,
    `GeneratedStaticFile`, `MarkdownWhitespaceNormalizer`.
  - `ui/`: Generic components (Cards, Ratings, Citations).
  - `seo/`: Two parallel subsystems both read by `_includes/head.html`:
    - `JsonLdInjector` populates `site.data['generated_json_ld_scripts']`
      with `<script type="application/ld+json">` tags. Layout-keyed
      dispatch via `LAYOUT_GENERATORS`; unknown layout raises.
    - `SeoMetaInjector` populates `site.data['seo_meta']` with meta tag
      values (title, og_*, twitter_*, description, canonical). Layout
      knowledge limited to title suffixes (`LAYOUT_TITLE_SUFFIX`) and
      article classification (`ARTICLE_LAYOUTS`). The cross-check test
      `test_every_known_layout_has_article_classification` enforces that
      every layout in `LAYOUT_GENERATORS` is explicitly classified.
  - `content/`: Domain logic (Books, Posts, Authors, Series, **Markdown Output**).
- **Tests:** `_tests/` (Mirrors `_plugins/src/` structure).

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
