# AGENTS.md

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

## Architecture Map
- **Content:** `_posts/` (Blog), `_books/` (Reviews collection).
- **Layouts:** `_layouts/`, `_includes/`.
- **Plugins:** `_plugins/src/` (Domain-Driven Design).
    - `infrastructure/`: Low-level utils (Logger, Text, URL) & **Link Cache**.
    - `ui/`: Generic components (Cards, Ratings, Citations).
    - `seo/`: JSON-LD generators & Validation.
    - `content/`: Domain logic (Books, Posts, Authors, Series).
- **Tests:** `_tests/` (Mirrors `_plugins/src/` structure).

## Markdown Source Files
The site generates `.md` versions of posts, books, and pages for LLM/agent consumption.
- **Output:** `/blog/2024/01/01/title.md`, `/books/title.md`, `/index.md`
- **Features:** Liquid tags render as markdown links (`[*Title*](url)`) instead of HTML.
- **Opt-out:** Set `markdown_source: false` in frontmatter to exclude a page.
- **Implementation:** `MarkdownSourceGenerator` in `infrastructure/`.

## Development Rules
1.  **Separation of Concerns:**
    -   **Tags** (`tags/`) are thin wrappers.
    -   **Utils** (`[domain]/[util].rb`) orchestrate logic.
    -   **Finders** fetch data; **Renderers** generate HTML.
    -   *See `_plugins/README.md` for detailed architectural patterns.*
2.  **Error Handling:** Use `PluginLoggerUtils.log_liquid_failure`.
3.  **Testing:** Create a matching test file in `_tests/` for every new class.
4.  **Link Cache:** The site relies on `site.data['link_cache']` (built by `LinkCacheGenerator`) for O(1) lookups of books/authors.
5.  **Markdown Mode:** Link utils check `context.registers[:markdown_mode]` to output markdown links instead of HTML.
