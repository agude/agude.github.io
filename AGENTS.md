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
- **Hooks:** `make hooks-install` (Install pre-commit hook).

## Architecture Map

- **Content:** `_posts/` (Blog), `_books/` (Reviews collection).
- **Layouts:** `_layouts/`, `_includes/`.
- **Plugins:** `_plugins/src/` (Domain-Driven Design).
  - `infrastructure/`: Low-level utils (Logger, Text, URL), **Link Cache**,
    `GeneratedStaticFile`, `MarkdownWhitespaceNormalizer`.
  - `ui/`: Generic components (Cards, Ratings, Citations).
  - `seo/`: JSON-LD generators & Validation.
  - `content/`: Domain logic (Books, Posts, Authors, Series, **Markdown Output**).
- **Tests:** `_tests/` (Mirrors `_plugins/src/` structure).

## CI/CD & Hooks

**GitHub Actions** (`.github/workflows/jekyll.yml`) runs on every push:

1. `bundle exec rubocop` (lint).
2. `bundle exec ruby ... load test_*.rb` (tests).
3. `bundle exec ruby _bin/check_strict.rb` (strict Liquid variables).
4. Build, HTML validation, broken-link check (main branch deploys).

**Pre-commit hook** (`_bin/pre-commit.sh`, install via `make hooks-install`):

- Runs `rubocop --autocorrect` inside Docker on staged `.rb` files.
- Runs `prettier --write` inside Docker on staged `.md` files (excluding meta files).
- Auto-corrected files are re-staged automatically.
- Rejects the commit if uncorrectable offenses remain.

## Development Rules

1.  **Separation of Concerns:**
    - **Tags** (`tags/`) are thin wrappers; check `render_mode` and delegate.
    - **Utils** (`[domain]/[util].rb`) orchestrate logic.
    - **Finders** fetch data; **Renderers** generate HTML.
2.  **Error Handling:** Use `PluginLoggerUtils.log_liquid_failure`.
3.  **Testing:** Create a matching test file in `_tests/` for every new class.
4.  **Link Cache:** The site relies on `site.data['link_cache']` (built by
    `LinkCacheGenerator`) for O(1) lookups of books/authors.

## Markdown Output Pipeline

Generates clean `.md` files for every page and a `/llms.txt` index.

### Data Flow

```
PRE-RENDER (:documents/:pages, :pre_render)  [markdown_body_hook.rb]
  │  Eligibility check → Standalone Liquid::Template.parse()
  │  render_mode: :markdown → Tags emit Markdown instead of HTML
  │  Stores data['markdown_body'] + data['markdown_alternate_href']
  ▼
POST-RENDER (:site, :post_render)  [markdown_output_assembler.rb]
  │  For each item with markdown_body:
  │    Header (post/book/generic) + Body + Footer (related content)
  │    → MarkdownWhitespaceNormalizer → GeneratedStaticFile (.md)
  ▼
LLMS.TXT (:site, :post_render)  [llms_txt_generator.rb]
     Indexes all .md files → /llms.txt with absolute URLs
```

### Key Files (`content/markdown_output/`)

| File                           | Purpose                                                                                                               |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `markdown_body_hook.rb`        | Pre-render hooks; re-renders content with `render_mode: :markdown` using standalone template (avoids cache pollution) |
| `markdown_output_assembler.rb` | Post-render hook; assembles header + body + footer into `.md` files                                                   |
| `markdown_card_utils.rb`       | Formats card data hashes as Markdown list items (`- [Title](url) by Author --- stars`)                                |
| `markdown_link_formatter.rb`   | Formats resolved link data as `[text](url)` for link tags                                                             |
| `llms_txt_generator.rb`        | Generates `/llms.txt` index grouped by Blog Posts, Book Reviews, Optional                                             |

### Render Mode Pattern

Tags check `context.registers[:render_mode]` to branch output:

```ruby
def render(context)
  if context.registers[:render_mode] == :markdown
    # Emit Markdown via MarkdownCardUtils / MarkdownLinkFormatter
  else
    # Emit HTML via existing Renderer classes
  end
end
```

Tags with render_mode support: all link tags (`book_link`, `author_link`,
`series_link`, `short_story_link`), all display tags (`display_books_by_year`,
`display_books_by_author_then_series`, `display_books_by_title_alpha_group`,
`display_ranked_books`, `display_awards_page`, `display_books_by_author`,
`display_books_for_series`, `display_category_posts`, `front_page_feed`,
`render_article_card`).

### Gotchas

- **Cache pollution:** The pipeline uses `Liquid::Template.parse()` directly
  (not `site.liquid_renderer`) because Jekyll caches templates by filename and
  `render()` mutates `@registers` with `merge!()`. Using the site renderer
  would leak `render_mode: :markdown` into the HTML pass.
- **Document URL access:** `Jekyll::Document#['url']` reads `data['url']`
  (nil), not `doc.url`. When passing documents to Finders outside Liquid
  context, merge url into data: `item.data.merge('url' => item.url)`.
  `MockDocument` masks this with special `['url']` handling; use `RealDocLike`
  wrapper in tests to catch regressions.
- **Page payload snapshot:** `Page#to_liquid` returns a plain `Hash`
  (snapshot at call time), while `Document#to_liquid` returns a live
  `DocumentDrop`. In `Renderer#run`, `assign_pages!` calls `to_liquid`
  _before_ the `:pre_render` hook fires. Data set in `:pre_render` hooks is
  visible for Documents (live Drop) but **not** for Pages (stale Hash). Fix:
  in `:pages` hooks, also inject into `payload['page']` directly.
- **Strict Liquid:** `render_mode` must always be defined in the payload
  (set to `'html'` by default in pre-render hooks) for strict variable mode.
- **Config:** Feature controlled by `enable_markdown_output` (default: `true`).
  Documents/pages opt out with `markdown_output: false` in front matter.

## Content Authoring

### Excerpt and Opening Paragraph

Jekyll's excerpt is the first "block" of content (before the first blank
line). A `{% capture %}` block placed _above_ the opening paragraph becomes
the excerpt instead of the actual paragraph text. Therefore:

- **`{% capture %}` definitions must go _after_ the opening paragraph.**
- **Inline Liquid tags work fine in the opening paragraph** (e.g.
  `{% game_title page.title %}`), because they produce output in-place
  without creating a separate block.
- Opening paragraphs that need title formatting but can't use capture
  variables should use the inline title tags (`movie_title`, `game_title`,
  `tv_show_title`) or raw `<cite>` HTML (which `MarkdownHtmlConverter`
  will handle as a fallback).

### Media Title Tags

Simple formatting tags for non-book creative works. Emit
`<cite class="...-title">` in HTML, `_italic_` in Markdown.

| Tag             | CSS class       | Example                          |
| --------------- | --------------- | -------------------------------- |
| `movie_title`   | `movie-title`   | `{% movie_title "The Matrix" %}` |
| `game_title`    | `game-title`    | `{% game_title "Elden Ring" %}`  |
| `tv_show_title` | `tv-show-title` | `{% tv_show_title "The Wire" %}` |

Accepts quoted strings or Liquid variables (`{% game_title page.title %}`).
Base class: `ui/tags/cite_title_tag.rb`.
