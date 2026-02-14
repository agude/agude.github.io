---
date: 2026-02-13T17:53:24Z
researcher: agude
git_commit: 741c2e1116a03b3f4d6dad84fc9287eb246078f2
branch: main
repository: agude.github.io
topic: "Rendering Pipeline Architecture and Dual-Output (HTML + Markdown) Feasibility"
tags: [research, codebase, rendering, layouts, plugins, liquid, markdown, llms-txt, dual-output]
status: complete
last_updated: 2026-02-13
last_updated_by: agude
last_updated_note: "Final direction: 3-phase plan (refactor → simple MD → incremental refinement), build perf dismissed, 21-component inventory, hook-based approach"
---

# Research: Rendering Pipeline Architecture and Dual-Output (HTML + Markdown) Feasibility

**Date**: 2026-02-13T17:53:24Z
**Researcher**: agude
**Git Commit**: 741c2e1116a03b3f4d6dad84fc9287eb246078f2
**Branch**: main
**Repository**: agude.github.io

## Research Question

How does the rendering pipeline in this Jekyll site work in detail? Can we serve both HTML pages and raw Markdown (e.g., `alexgude.com` for HTML, `alexgude.com/index.md` for raw text) for agent/LLM consumption? What would that require given the existing architecture — particularly, is data fetching already separated from rendering?

## Summary

The site has a **well-separated rendering architecture** where data fetching (Finders) and HTML generation (Renderers) are already cleanly decoupled. The Jekyll rendering pipeline flows through 5 stages: Front Matter Parsing → Liquid Processing → Markdown Conversion → Layout Application → File Output. The layout chain is 4 levels deep: `compress.html ← substitute.html ← default.html ← [post|book|page|...].html`.

For dual-output, the critical architectural question is **where to intercept** the pipeline. The Liquid tags that generate book cards, related posts, author links, etc. currently return HTML strings. A raw Markdown version would need the same data but rendered as plain text/Markdown instead of HTML. The existing Finder/Renderer separation makes this conceptually clean — the same Finders could feed different Renderers (HTML vs Markdown).

There is **no native Jekyll feature** for dual-output. The most viable approaches involve Jekyll hooks (`:pre_render` to capture Liquid-rendered Markdown before HTML conversion) and/or custom generators to produce `.md` output files alongside HTML.

---

## Detailed Findings

### 1. Jekyll's 5-Stage Rendering Pipeline

Jekyll processes each page through these stages in order:

1. **Front Matter Parsing** — YAML between `---` delimiters is parsed; populates `page` variable
2. **Liquid Processing** — `{% tags %}` and `{{ variables }}` are resolved; only runs on files with front matter; output is NOT re-processed
3. **Markdown Conversion** — Kramdown converts `.md` content to HTML (file extension determines converter)
4. **Layout Application** — Converted output placed into `{{ content }}` in layout templates; layouts nest like Russian dolls (inner → outer)
5. **File Output** — Written to `_site/` directory

**Key implication**: Liquid tags execute in Stage 2, producing HTML strings that go through Markdown conversion (Stage 3) unchanged, then get wrapped by layouts (Stage 4).

Sources:
- [Jekyll Rendering Process](https://jekyllrb.com/docs/rendering-process/)
- [Order of Interpretation](https://jekyllrb.com/tutorials/orderofinterpretation/)

### 2. Layout Chain

The site has an 11-layout system organized in a 4-level hierarchy:

```
compress.html        (Level 1 - HTML compression, no parent)
    ↑
substitute.html      (Level 2 - String replacements for footnotes)
    ↑
default.html         (Level 3 - Full HTML page structure: head, sidebar, main)
    ↑
├── post.html        (Level 4 - Blog post: title, date, categories, lead image, related posts)
├── book.html        (Level 4 - Book review: cover, authors, series, rating, related books)
├── page.html        (Level 4 - Simple page wrapper)
├── author_page.html (Level 4 - Author page with book list)
├── series_page.html (Level 4 - Series page with book list)
├── category.html    (Level 4 - Topic page with post list)
├── page-not-on-sidebar.html (Level 4 - Page with optional lead image)
└── resume.html      (Level 4 - Minimal resume wrapper)
```

#### compress.html
- [_layouts/compress.html](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/compress.html)
- Third-party HTML compressor from http://jch.penibelst.de/
- Currently configured with all compression features disabled (empty arrays in `_config.yml:141-149`), so it's effectively a pass-through

#### substitute.html
- [_layouts/substitute.html](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/substitute.html)
- Post-render string replacement: adds `<hr>` before footnotes div, adds comma separators between consecutive footnote references

#### default.html
- [_layouts/default.html](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/default.html)
- Defines the full HTML page: `<!DOCTYPE html>`, `<html>`, `<head>` (via `head.html` include), `<body>`, sidebar (via `sidebar.html` include), `<main>` content area
- Processes content through `anchor_headings.html` include (adds clickable anchor links to h2-h6 headings)

#### Level 4 Layouts
- Each wraps `{{ content }}` with domain-specific metadata and custom Liquid tags
- `post.html` adds: title, date, categories, lead image, `{% related_posts %}`
- `book.html` adds: title, cover image, authors (`{% display_authors %}`), series (`{% series_text %}`), awards, rating (`{% rating_stars %}`), backlinks (`{% book_backlinks %}`), related books (`{% related_books %}`)

### 3. Plugin Architecture: Finder/Renderer Separation

The custom plugin system in `_plugins/src/` follows a clean layered architecture where **data fetching and HTML rendering are completely separated**.

#### Architecture Layers

```
Liquid Templates
    ↓
Tags (thin wrappers in */tags/)
    ↓ delegate to
Utils (coordinators in */*_utils.rb)
    ↓ call
Finders (data only)  +  Renderers (HTML only)
    ↓ use                    ↓ use
Domain Utils (links, cards, data)
    ↓ use
UI Components (cards, ratings, citations)
    ↓ use
Infrastructure (logging, text, URLs, cache)
```

#### Finders (Data Layer)

Finders return **structured data hashes, never HTML**.

Example — `ByYearFinder` at [_plugins/src/content/books/lists/by_year_finder.rb](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/lists/by_year_finder.rb):

```ruby
def find
  # ... validation ...
  all_books = all_published_books(include_archived: true)
  year_groups_list = group_books_by_year(all_books)
  { year_groups: year_groups_list, log_messages: String.new }
end
```

Returns: `{year_groups: [{year: "2024", books: [...]}, ...], log_messages: ""}`

Other finders follow the same pattern:
- `ByAuthorFinder`, `ByTitleAlphaFinder`, `ByAwardFinder`, `SeriesFinder` — all return structured hashes
- `BookFinder` (lookup) — returns `{book: document, error: nil}`
- `Related::Finder` — returns `{logs: "", books: [doc, doc, doc]}`

#### Renderers (HTML Layer)

Renderers accept structured data and produce HTML strings. They never fetch data.

Example — `ByYearRenderer` at [_plugins/src/content/books/lists/renderers/by_year_renderer.rb](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/lists/renderers/by_year_renderer.rb):

```ruby
def render
  return '' if @year_groups.empty?
  output = +''
  output << generate_navigation(@year_groups)
  output << render_year_groups(@year_groups)
  output
end
```

#### Tag Orchestration Pattern

Tags coordinate the Finder → Renderer pipeline:

```ruby
# In tags/related_books_tag.rb
def render(context)
  finder = Jekyll::Books::Related::Finder.new(context, @max_books)
  result = finder.find
  return result[:logs] if result[:books].empty?
  renderer = Jekyll::Books::Related::Renderer.new(context, result[:books])
  result[:logs] + renderer.render
end
```

#### Where Separation Exists vs Doesn't

**Clean Finder/Renderer separation exists in:**
- Book lists (by year, by author, by title, by award, for series)
- Related books
- Backlinks
- Related posts
- Feed rendering
- Rankings
- Category posts

**Tighter coupling exists in:**
- **Link Resolvers** (`BookLinkResolver`, `AuthorLinkResolver`, `SeriesLinkResolver`) — these combine cache lookup with HTML generation in a single `resolve()` method
- **Card Renderers** (`BookCardRenderer`, `ArticleCardRenderer`) — data extraction and HTML building are in the same class, though separated into distinct method calls

### 4. HTML Output Patterns

All HTML is built via Ruby string concatenation (no templates):

1. **String concatenation with `<<`** — most common pattern
2. **Mutable string with `+''`** — for efficient accumulation
3. **String interpolation** — for inline HTML elements
4. **Pre-built HTML fragments passed as data** — card data hashes carry pre-rendered HTML pieces to generic renderers
5. **Array + join** — for navigation links and lists

Example of the card data hash pattern (HTML fragments as data):
```ruby
card_data = {
  base_class: 'book-card',
  url: @base[:absolute_url],
  title_html: "<strong><cite>#{title}</cite></strong>",  # Pre-rendered HTML
  extra_elements_html: [authors_html, rating_html],       # Array of HTML strings
  description_html: excerpt_html,                          # Pre-rendered HTML
}
CardRendererUtils.render_card(context: @context, card_data: card_data)
```

### 5. LinkCacheGenerator: The Build-Time Foundation

The [LinkCacheGenerator](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/link_cache_generator.rb) runs during Jekyll's generate phase (priority `:normal`) and builds `site.data['link_cache']` with:

```ruby
{
  'authors' => {},              # normalized_name → {url, title}
  'books' => {},                # normalized_title → [{url, title, authors, canonical_url, date}]
  'series' => {},               # normalized_name → {url, title}
  'series_map' => {},           # normalized_name → [book documents]
  'short_stories' => {},        # normalized_title → [{title, parent_book_title, url, slug}]
  'sidebar_nav' => [],          # pages with sidebar_include: true
  'books_topbar_nav' => [],     # pages with book_topbar_include: true
  'backlinks' => {},            # book_url → [{source: doc, type: 'book'|'series'|'short_story'}]
  'favorites_mentions' => {},   # book_url → [post documents]
  'favorites_posts_to_books' => {}, # post_url → [book documents]
  'url_to_canonical_map' => {}, # book_url → canonical_url
  'book_families' => {}         # canonical_url → [all review URLs]
}
```

**Secondary builders** run after the primary cache:
- `ShortStoryBuilder` — scans anthology content for `{% short_story_title %}` tags
- `BacklinkBuilder` — scans book content for `{% book_link %}`, `{% series_link %}`, `{% short_story_link %}` tags
- `FavoritesManager` — scans posts with `is_favorites_list` for `{% book_card_lookup %}` tags
- `LinkValidator` — validates all markdown/HTML links point to cached entities (raises fatal error on violation)
- `CacheMaps` — creates reverse URL-to-data lookups

### 6. JSON-LD System (Hook-Based)

The [JsonLdInjector](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/seo/json_ld_injector.rb) uses Jekyll hooks (not generators):

- `:site, :after_reset` — initializes `site.data['generated_json_ld_scripts']`
- `:documents, :post_convert` — processes each document after Markdown conversion
- `:pages, :post_convert` — processes each page after conversion

Selects generator by document type:
- Book reviews → `BookReviewLdGenerator` (Review + Book schema)
- Blog posts → `BlogPostingLdGenerator` (BlogPosting schema)
- Author pages → `AuthorProfileLdGenerator` (Person schema)
- Generic reviews → `GenericReviewLdGenerator` (Review + configurable item type)

Each generates a Ruby hash → `JSON.pretty_generate` → wraps in `<script type="application/ld+json">` → stores in `site.data['generated_json_ld_scripts'][doc_url]`.

Layouts access via a null-safe filter chain in `_includes/head.html`:
```liquid
{%- assign data = site | optional: 'data' -%}
{%- assign scripts = data | optional: 'generated_json_ld_scripts' -%}
{%- assign generated_script = scripts | optional: page.url -%}
```

### 7. Content Structure

- **105 blog posts** in `_posts/` — front matter: layout, title, description, image, categories
- **111 book reviews** in `_books/` — front matter: date, title, book_authors, series, book_number, rating, image, awards
- **7 standalone pages** at root — various layouts
- **3 section indexes** — books, topics, blog

### 8. External Research: Dual-Output Approaches

#### No Native Jekyll Support

There is no built-in Jekyll feature for generating multiple output formats from the same content. All approaches require custom plugins. ([Jekyll Talk discussion](https://talk.jekyllrb.com/t/jekyll-generate-a-post-twice-once-with-layout-and-once-as-raw-html/6636))

#### Approach A: Hook + Generator

The most documented approach uses a **`:pre_render` hook** to capture Liquid-rendered Markdown (after Stage 2, before Stage 3) and a **custom generator** to write `.md` files.

From [Outputting Markdown from Jekyll using hooks](https://humanwhocodes.com/blog/2019/04/jekyll-hooks-output-markdown/):

```ruby
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  site = doc.site
  template = site.liquid_renderer.file(doc.path).parse(doc.content)
  info = {
    registers: { site: site, page: payload['page'] },
    strict_filters: site.config.dig("liquid", "strict_filters"),
    strict_variables: site.config.dig("liquid", "strict_variables"),
  }
  doc.data['rendered_content'] = template.render!(payload, info)
end
```

This captures content **after Liquid processing but before Markdown-to-HTML conversion** — meaning custom Liquid tags (like `{% book_link %}`, `{% rating_stars %}`) would already be resolved to their HTML output.

#### Approach B: Jekyll Generator with PageWithoutAFile

Create pages programmatically via `Jekyll::PageWithoutAFile`, setting `place_in_layout?` to `false` to prevent layout wrapping.

#### Approach C: llms.txt Specification

[llms.txt](https://llmstxt.org/) is a proposed standard for LLM-friendly content. It provides a curated index pointing to Markdown resources:

```markdown
# Site Name

> Brief summary

## Blog Posts
- [Post Title](https://example.com/post.md) - Description

## Optional
- [Advanced Topic](https://example.com/advanced.md) - Skip for shorter context
```

Widely adopted (BuiltWith tracked 844,000+ sites by late 2025), with notable implementations by Cloudflare, Vercel, Anthropic, and Hugging Face. However, **no major AI platform has publicly confirmed using llms.txt in their actual retrieval pipelines**. Agent adoption is assumed but unproven. It's complementary to dual-output — llms.txt serves as an index, `.md` files serve as content — but shouldn't be prioritized over the `.md` files themselves.

Sources:
- [llms.txt specification](https://llmstxt.org/)
- [Jekyll Hooks docs](https://jekyllrb.com/docs/plugins/hooks/)
- [Jekyll Generators docs](https://jekyllrb.com/docs/plugins/generators/)
- [Outputting Markdown from Jekyll using hooks](https://humanwhocodes.com/blog/2019/04/jekyll-hooks-output-markdown/)
- [Jekyll Talk: dual output](https://talk.jekyllrb.com/t/jekyll-generate-a-post-twice-once-with-layout-and-once-as-raw-html/6636)

---

## Code References

### Layouts
- [`_layouts/compress.html`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/compress.html) — HTML compression (top of chain)
- [`_layouts/substitute.html`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/substitute.html) — Footnote string replacements
- [`_layouts/default.html`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/default.html) — Full page structure
- [`_layouts/post.html`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/post.html) — Blog post layout
- [`_layouts/book.html`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_layouts/book.html) — Book review layout

### Generators
- [`_plugins/src/infrastructure/link_cache_generator.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/link_cache_generator.rb) — Link cache generator
- [`_plugins/src/infrastructure/link_cache/cache_builder.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/link_cache/cache_builder.rb) — Primary cache builder
- [`_plugins/src/infrastructure/link_cache/backlink_builder.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/link_cache/backlink_builder.rb) — Backlink scanner
- [`_plugins/src/seo/json_ld_injector.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/seo/json_ld_injector.rb) — JSON-LD hook system

### Finder/Renderer Pairs
- [`_plugins/src/content/books/lists/by_year_finder.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/lists/by_year_finder.rb) — Year grouping finder
- [`_plugins/src/content/books/lists/renderers/by_year_renderer.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/lists/renderers/by_year_renderer.rb) — Year grouping renderer
- [`_plugins/src/content/books/related/finder.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/related/finder.rb) — Related books finder
- [`_plugins/src/content/books/related/renderer.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/related/renderer.rb) — Related books renderer

### Tag Examples
- [`_plugins/src/content/books/tags/render_book_card_tag.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/tags/render_book_card_tag.rb) — Book card tag (thin wrapper)
- [`_plugins/src/content/books/tags/related_books_tag.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/tags/related_books_tag.rb) — Related books tag (finder→renderer orchestration)

### Card System
- [`_plugins/src/content/books/core/book_card_renderer.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/core/book_card_renderer.rb) — Book card HTML builder
- [`_plugins/src/ui/cards/card_renderer_utils.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/ui/cards/card_renderer_utils.rb) — Generic card renderer

### Link Resolution
- [`_plugins/src/content/authors/author_link_resolver.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/authors/author_link_resolver.rb) — Author link resolution
- [`_plugins/src/content/books/core/book_link_resolver.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/content/books/core/book_link_resolver.rb) — Book link resolution

### Infrastructure
- [`_plugins/src/infrastructure/plugin_logger_utils.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/plugin_logger_utils.rb) — Centralized logging
- [`_plugins/src/infrastructure/text_processing_utils.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/text_processing_utils.rb) — Text normalization
- [`_plugins/src/infrastructure/tag_argument_utils.rb`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_plugins/src/infrastructure/tag_argument_utils.rb) — Tag argument parsing

### Configuration
- [`_config.yml`](https://github.com/agude/agude.github.io/blob/741c2e1116a03b3f4d6dad84fc9287eb246078f2/_config.yml) — Site configuration

---

## Architecture Documentation

### Current Rendering Data Flow

```
[Blog Post .md file]
    │
    ▼ (Stage 1: Front Matter Parsing)
[page variable populated]
    │
    ▼ (Stage 2: Liquid Processing)
[Custom tags resolve: {% book_link %} → <a href="..."><cite>...</cite></a>]
[Custom tags resolve: {% rating_stars %} → <div class="star-rating-4">★★★★☆</div>]
[Custom tags resolve: {% related_books %} → <aside class="related">...</aside>]
    │
    ▼ (Stage 3: Markdown Conversion via Kramdown)
[Markdown → HTML, custom tag output passes through unchanged]
    │
    ▼ (Stage 4: Layout Application)
[post.html wraps: article, title, date, categories, lead image]
  → [default.html wraps: doctype, head, sidebar, anchor headings]
    → [substitute.html: footnote string replacements]
      → [compress.html: HTML compression (currently no-op)]
    │
    ▼ (Stage 5: File Output)
[Written to _site/blog/slug/index.html]
```

### Plugin Domain Organization

```
_plugins/src/
├── content/           # Domain logic
│   ├── authors/       # Author links, pages
│   ├── books/         # Book cards, lists, lookups, related, ranking, reviews, backlinks
│   ├── posts/         # Article cards, feed, category, related
│   ├── series/        # Series links, text formatting
│   └── short_stories/ # Short story links, titles
├── ui/                # Generic UI components
│   ├── cards/         # CardRendererUtils, CardDataExtractorUtils
│   ├── citations/     # CitationUtils
│   ├── quotes/        # CitedQuoteUtils
│   ├── ratings/       # RatingUtils
│   └── tags/          # CitationTag, RatingStarsTag, CitedQuoteTag, UnitsTag
├── infrastructure/    # Low-level utilities
│   ├── link_cache/    # CacheBuilder, BacklinkBuilder, FavoritesManager, etc.
│   ├── links/         # LinkHelperUtils, LinkValidator
│   └── *.rb           # TextProcessing, URL, Logging, FrontMatter, Typography utils
└── seo/               # Structured data
    ├── generators/    # JSON-LD generator modules (Author, BlogPosting, BookReview, Generic)
    └── json_ld_injector.rb  # Hook registration
```

### Key Architectural Patterns

1. **Finder/Renderer Separation**: Finders return data hashes; Renderers consume data and output HTML
2. **Tag Delegation**: Liquid tags are thin wrappers that resolve arguments and delegate to utils
3. **Centralized Cache**: `site.data['link_cache']` built once by generator, consumed by all tags
4. **Hook-Based Extension**: JSON-LD injection uses `:post_convert` hooks rather than generators
5. **Domain-Driven Organization**: Code organized by domain (books, posts, authors) not by function type

---

## Related Research

No prior research documents exist in `thoughts/shared/research/`.

---

## Open Questions

1. **Custom Liquid tag output in raw Markdown**: When a `:pre_render` hook captures content, custom Liquid tags like `{% book_link "Hyperion" %}` will already have been resolved to `<a href="/books/hyperion/"><cite>Hyperion</cite></a>`. For true raw Markdown, these tags would need alternative renderers that output Markdown-style links `[Hyperion](/books/hyperion/)` instead of HTML.

2. **Complex tag output**: Tags like `{% related_books %}` generate entire HTML sections (grids of book cards with images, ratings, etc.). What should their Markdown equivalent look like? A simple list of titles with links? Or should they be omitted entirely from the Markdown version?

3. **Includes in Markdown**: The `{% include figure.html %}` include generates `<figure><img><figcaption>` HTML. Used in 12 posts (28 occurrences). In `:render_mode => :markdown` Liquid pass, this include would still emit HTML unless made mode-aware. Options: (a) create a parallel `figure_markdown.html` include, (b) add a mode check inside `figure.html`, (c) post-process HTML figure elements back to `![alt](url)` Markdown syntax. See follow-up in Category A section below.

4. **Layout-injected content**: Some content is added by layouts, not the Markdown source (e.g., post title/date from `post.html`, author list from `book.html`). A raw Markdown file would need this metadata presented differently.

5. **Build performance**: Generating ~230+ additional `.md` files doubles the output. Impact on build time needs assessment.

6. **Scope decision**: Should all pages get Markdown versions, or only blog posts and book reviews? Static pages like "Resume" may not benefit.

---

## Follow-up Research 2026-02-13T18:12:04Z

### Question: How to signal alternate Markdown format to agents, and how to `rel=` the pages?

**Constraint**: Static site hosted on GitHub Pages — no control over HTTP headers, no server-side content negotiation.

### What's Available on GitHub Pages

| Approach | Available? | Notes |
|---|---|---|
| `<link rel="alternate">` in HTML | Yes | Emitted at build time in `<head>` |
| `llms.txt` index file | Yes | Static file generated at build time |
| URL convention (`.md` alongside HTML) | Yes | Static files in `_site/` |
| HTTP `Accept` content negotiation | No | No server-side logic |
| Custom HTTP headers (`Link:`) | No | GH Pages doesn't support custom headers |
| `Content-Type: text/markdown` on `.md` files | No | GH Pages serves `.md` as `text/plain` |

### Signaling the Markdown Version Exists

The standard mechanism is `<link rel="alternate">` in the HTML `<head>`, using the official `text/markdown` MIME type ([RFC 7763](https://datatracker.ietf.org/doc/rfc7763/)):

```html
<link rel="alternate" type="text/markdown; charset=UTF-8"
      href="https://alexgude.com/blog/my-post/index.md"
      title="Markdown version">
```

This mirrors how RSS/Atom feeds are discovered:
```html
<link rel="alternate" type="application/atom+xml" href="/feed.xml" title="Atom feed">
```

**MIME type parameters:**
- `charset=UTF-8` — required by RFC 7763 (no default value)
- `variant=GFM` — optional, identifies Markdown dialect; defined by RFC 7764 and the [IANA Markdown Variants Registry](https://www.iana.org/assignments/markdown-variants/markdown-variants.xhtml). Registered variants include GFM, CommonMark, kramdown-rfc2629, Pandoc, etc.

**Discovery by agents**: No current evidence that AI crawlers (ClaudeBot, GPTBot, PerplexityBot) actively parse `<link rel="alternate">` tags. However, the llms.txt spec recommends a complementary **URL convention** — appending `.md` to the HTML URL. Between the `<link>` tag and a predictable URL pattern, agents have two discovery paths.

### How to `rel=` the Pages

**HTML version** (canonical):
```html
<!-- Already present via jekyll-seo-tag -->
<link rel="canonical" href="https://alexgude.com/blog/my-post/">

<!-- New: point to Markdown alternate -->
<link rel="alternate" type="text/markdown; charset=UTF-8"
      href="https://alexgude.com/blog/my-post/index.md"
      title="Markdown version">
```

**Markdown version** (alternate):
- On GitHub Pages, you cannot add HTTP `Link:` headers to signal canonical back to HTML
- This is fine — search engines won't index raw `.md` files served as `text/plain` by GH Pages, so there's no duplicate-content risk
- The HTML version is canonical by default (it's the only one with `text/html` content type)
- Google ignores `rel="canonical"` with `type` attributes anyway ([Google docs](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls))

**Summary of `rel=` usage:**
- `rel="canonical"` → HTML page points to itself (already handled by `jekyll-seo-tag`)
- `rel="alternate" type="text/markdown"` → HTML page points to its `.md` counterpart
- No `rel=` needed on the Markdown file itself (plain text, no HTML `<head>`)

### llms.txt as Complementary Index

A generated `/llms.txt` file at the site root provides a single discovery entry point:

```markdown
# Alex Gude

> A blog about technology, data science, machine learning, and more!

## Blog Posts
- [Post Title](https://alexgude.com/blog/my-post/index.md) - Description

## Book Reviews
- [Hyperion](https://alexgude.com/books/hyperion/index.md) - Book review

## Optional
- [Resume](https://alexgude.com/resume/index.md)
```

The "Optional" section signals content that agents can skip for shorter context windows.

### Sources

- [RFC 7763 — text/markdown Media Type](https://datatracker.ietf.org/doc/rfc7763/)
- [RFC 8288 — Web Linking](https://httpwg.org/specs/rfc8288.html)
- [WHATWG HTML Standard — Link Types](https://html.spec.whatwg.org/multipage/links.html)
- [IANA Markdown Variants Registry](https://www.iana.org/assignments/markdown-variants/markdown-variants.xhtml)
- [Google: Consolidate Duplicate URLs](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)
- [llms.txt Specification](https://llmstxt.org/)
- [Cloudflare: Markdown for Agents](https://blog.cloudflare.com/markdown-for-agents/)
- [Vercel: Making Agent-Friendly Pages with Content Negotiation](https://vercel.com/blog/making-agent-friendly-pages-with-content-negotiation)
- [Giles Thomas: Adding /llms.txt with rel="alternate"](https://www.gilesthomas.com/2025/03/llmstxt)
- [RSS Autodiscovery — RSS Board](https://www.rssboard.org/rss-autodiscovery)

---

## Follow-up Research 2026-02-13T18:20:25Z

### Questions: Book card context loss, data+rendering coupling, empty-body pages, encoding

---

### Q1: Book Cards Losing Rendering Context

Book cards are invoked from **13 distinct call paths**, deeply nested inside other renderers:

| Caller | Nesting Depth |
|---|---|
| `{% render_book_card %}` | Tag → BookCardUtils |
| `{% book_card_lookup %}` | Tag → Finder → BookCardUtils |
| `{% display_books_by_year %}` | Tag → ByYearRenderer → BookCardUtils |
| `{% display_books_by_author %}` | Tag → BooksByAuthorRenderer → BookListRendererUtils → BookCardUtils |
| `{% display_books_by_author_then_series %}` | Tag → ByAuthorThenSeriesRenderer → BookListRendererUtils → BookCardUtils |
| `{% display_books_by_title_alpha_group %}` | Tag → ByTitleAlphaRenderer → BookCardUtils |
| `{% display_books_for_series %}` | Tag → ForSeriesRenderer → BookCardUtils |
| `{% display_awards_page %}` | Tag → AwardsRenderer → render_book_grid → BookCardUtils |
| `{% display_ranked_books %}` | Tag → RankedBooks::Renderer → BookCardUtils |
| `{% display_previous_reviews %}` | Tag → Reviews::Renderer → BookCardUtils |
| `{% related_books %}` | Tag → Related::Renderer → BookCardUtils |
| `{% front_page_feed %}` | Tag → Feed::Renderer → BookCardUtils |
| `{% display_all_books_grouped %}` | Tag → BookListRendererUtils → BookCardUtils |

Article cards have **5 call paths** (direct tags, related posts, category posts, feed).

**The context propagation problem**: `Liquid::Context` already flows through every layer (`Tag → Renderer → BookCardUtils → BookCardRenderer → CardRendererUtils`). But intermediate renderers **hard-code HTML structure** around card output. For example, `ByYearRenderer` wraps cards in `<div class="card-grid">` at line 57. If BookCardUtils returns Markdown, it's embedded inside HTML divs.

**The entire tree must be mode-consistent**: Setting a flag in context is fine for propagation, but every renderer in the chain — not just the leaf card renderer — must check the mode. The ByYearRenderer, the ForSeriesRenderer, the Feed::Renderer — all of them build HTML containers that would need Markdown equivalents.

---

### Q2: Data + Rendering Coupling Found

**8 tightly coupled locations** where data fetching and HTML generation happen in the same method:

#### Link Resolvers (4 files — most significant coupling):

1. **`BookLinkResolver.resolve()`** (`book_link_resolver.rb:26`)
   - Data: `find_candidates()` (line 35), `filter_candidates()` (line 39), `track_unreviewed_mention()` (lines 92-108)
   - HTML: `fallback()` builds `<cite>` elements (line 54), `render_result()` builds `<a>` links (line 205)
   - Combined: `log_not_found + fallback(display_text)` concatenates HTML comment + HTML element (line 37)

2. **`AuthorLinkResolver.resolve()`** (`author_link_resolver.rb:27`)
   - Data: `find_author()` from link_cache (line 37)
   - HTML: `generate_html()` builds `<span>` + `<a>` (line 40)
   - Combined: `@log_output + html` (line 79)

3. **`SeriesLinkResolver.resolve()`** (`series_link_resolver.rb:26`)
   - Data: `find_series()` from link_cache (line 35)
   - HTML: `generate_html()` builds `<span>` + `<a>` (line 38)
   - Combined: `@log_output + html` (line 80)

4. **`ShortStoryResolver.resolve()`** (`short_story_resolver.rb:26`)
   - Data: `find_target_location()` from link_cache (line 35)
   - HTML: `render_html()` builds `<cite>` + `<a>` (line 36)
   - Combined: `@log_output + html` (line 108)

#### Card Renderers (2 files):

5. **`BookCardRenderer.render()`** (`book_card_renderer.rb:40`)
   - Data: `CardExtractor.extract_base_data()` (line 41), `FrontMatter.get_list_from_string_or_array()` (line 102)
   - HTML: `title_html()` (line 63), `authors_html()` (line 108), `rating_html()` (line 123), `CardRenderer.render_card()` (line 51)

6. **`ArticleCardRenderer.render()`** (`article_card_renderer.rb:20`)
   - Data: `CardDataExtractorUtils.extract_base_data()` (line 21), `extract_description_html()` (line 51)
   - HTML: `generate_title_html()` (line 60), `CardRendererUtils.render_card()` (line 34)

#### Utilities (2 files):

7. **`DisplayAuthorsUtil.render_author_list()`** (`display_authors_util.rb:22`)
   - Data: `FrontMatter.get_list_from_string_or_array()` (line 24)
   - HTML: Builds author HTML in loop (lines 28-34)

8. **`LinkHelperUtils._build_link_with_url_resolution()`** (`link_helper_utils.rb:55`)
   - Data: `_resolve_canonical_urls()` from link_cache (lines 58-60)
   - HTML: `_build_appropriate_link()` (line 70)

#### Clean Areas (no coupling):
- **All Finders** — return data hashes only (never HTML)
- **All list Renderers** (ByYear, ByAuthor, ForSeries, etc.) — clean at their own level (but call coupled card renderers)
- **All Tags** — thin wrappers, no direct data+HTML mixing
- **UI utilities** (RatingUtils, CitationUtils, CitedQuoteUtils) — pure transformation, no data fetching

---

### Q3: Empty-Body Pages

**125 pages** have minimal or zero Markdown body content:

#### Zero body content (98 pages):
- **69 author pages** (`books/authors/*.md`) — YAML front matter only, all visible content from `{% display_books_by_author page.title %}` in `author_page.html` layout
- **29 series pages** (`books/series/*.md`) — YAML front matter only, all visible content from `{% display_books_for_series page.title %}` in `series_page.html` layout

#### 1-2 sentences (3 pages):
- `books/index.md` — 2 sentences, rest from `{% display_books_by_year %}`
- `books/by_author.md` — 1 sentence, rest from `{% display_books_by_author_then_series %}`
- `topics/index.md` — 2 sentences + Liquid loops calling `{% display_category_posts %}` for every category

#### 1 paragraph (23 pages):
- **23 category pages** (`topics/*.md`) — 1 descriptive paragraph, rest from `{% display_category_posts topic=topic %}` in `category.html` layout

#### Substantial but still tag-heavy (1 page):
- `index.md` — Multiple biographical paragraphs, but recent writings from `{% front_page_feed limit=5 %}`

For these pages, a Markdown version that only captured the source body would be nearly useless. The Markdown output needs to include **generated content from the Finders** — rendered as Markdown (lists of book titles with links, ratings) rather than HTML (card grids with images).

---

### Q4: Encoding and Smart Quotes

Two separate pipelines produce Unicode characters:

**TypographyUtils pipeline** (applied to plugin-rendered titles):
- `"` → `\u201C` / `\u201D` (curly double quotes)
- `'` → `\u2018` / `\u2019` (curly single quotes / apostrophes)
- `---` → `\u2014` (em dash)
- `--` → `\u2013` (en dash)
- `...` → `\u2026` (ellipsis)

**Kramdown pipeline** (applied to Markdown body content):
- Default smart quote processing produces the same Unicode characters
- No explicit Kramdown config in `_config.yml`, so defaults apply

**Other Unicode characters in plugin output:**
- `★` (U+2605) / `☆` (U+2606) — star ratings from RatingUtils
- `&#x202F;` — narrow no-break space in UnitsTag and substitute.html footnotes
- `&middot;` — navigation separators in year/author/award renderers
- `&nbsp;` — non-breaking space in ranked book star labels
- `\u2019` — possessive apostrophe in AuthorLinkResolver
- `—` — em dash prefix on cited quotes in CitedQuoteUtils

**GitHub Pages appears to serve `.md` as `text/plain` with no charset header** (based on observed Firefox behavior — garbled smart quotes consistent with missing charset — but not verified with `curl -I` against a live GitHub Pages `.md` URL. Should be trivially testable before implementation.)

Practical impact: Nearly all modern consumers (browsers, curl, Python requests, LLM APIs) default to UTF-8 when encountering `text/plain` without a charset. The Unicode characters will display correctly. A UTF-8 BOM (`\xEF\xBB\xBF`) at the start of the file could provide an explicit signal, but is likely unnecessary in 2026.

The smart quotes are desirable in Markdown output — they're nicer to read than straight quotes, and LLMs handle Unicode perfectly. The `<link rel="alternate" type="text/markdown; charset=UTF-8">` tag in the HTML version also serves as documentation of the encoding, even though it can't be enforced server-side.

---

## Follow-up Research 2026-02-13T18:28:50Z

### Questions: Firefox UTF-8 rendering, Jekyll re-processing .md files

---

### Q5: Firefox Shows Garbled Characters for text/plain UTF-8

**Root cause**: GitHub Pages serves `.md` files as `text/plain` without a `charset` parameter. Firefox falls back to locale-dependent encoding (often Windows-1252) for HTTP-served `text/plain`. Smart quotes like `"` `"` appear as `â€œ` `â€` in Windows-1252 interpretation. "View → Repair Text Encoding" triggers Firefox's `chardetng` detector which then correctly identifies UTF-8.

Firefox 66+ fixed this for `file:` URLs but NOT for HTTP-served content. HTTP `text/plain` without charset still falls back to locale default.

**What won't work:**
- **UTF-8 BOM** — Breaks Jekyll's YAML front matter parsing (known issue, Jekyll issues #2853, #5363). Even post-fix in Jekyll 3.7+, BOM is discouraged and can cause inconsistent behavior.
- **Changing file extension** — `.txt`, `.md.txt` all served as `text/plain` without charset, same problem.
- **HTML meta tags or comments** — Browsers don't parse HTML in `text/plain` content.
- **Custom HTTP headers** — GitHub Pages doesn't support them.

**Practical reality**: The primary audience for `.md` files is agents/LLMs fetching via API, which universally default to UTF-8. The Firefox display issue affects humans manually browsing to the raw URL — an edge case. The `<link rel="alternate" type="text/markdown; charset=UTF-8">` tag in the HTML version serves as documentation for programmatic consumers.

Sources:
- [Firefox Bug 1407594](https://bugzilla.mozilla.org/show_bug.cgi?id=1407594)
- [Firefox Bug 1071816](https://bugzilla.mozilla.org/show_bug.cgi?id=1071816)
- [Henri Sivonen: The Text Encoding Submenu Is Gone](https://hsivonen.fi/no-encoding-menu/)
- [Jekyll Issue #2853: UTF-8 BOM fails](https://github.com/jekyll/jekyll/issues/2853)

---

### Q6: Jekyll Re-Processes .md Output Files

**Confirmed behavior**: Jekyll 4.4.1 (the version in this project) automatically converts any `.md` or `.markdown` file with front matter through Kramdown. This applies to:
- `Page` objects — always go through the converter pipeline
- `PageWithoutAFile` objects — also go through the converter pipeline (they're still `Page` subclasses)
- `render_with_liquid: false` and `place_in_layout?` returning `false` skip Liquid/layouts but **Kramdown still runs**
- The output extension is forced to `.html` by the converter's `output_ext` method

This means if a Generator creates a new page with `.md` extension to hold raw Markdown output, Jekyll will convert it to HTML — defeating the purpose.

**Three approaches evaluated:**

#### Approach A: Subclassed StaticFile (recommended)

`Jekyll::StaticFile` objects are **copied verbatim** — no Liquid, no Kramdown, no layout. Subclass to write generated content:

```ruby
class GeneratedStaticFile < Jekyll::StaticFile
  def initialize(site, dir, name, content)
    @generated_content = content
    super(site, site.source, dir, name)
  end

  def write(dest)
    dest_path = destination(dest)
    FileUtils.mkdir_p(File.dirname(dest_path))
    File.write(dest_path, @generated_content)
    true
  end
end
```

**Pros**: Clean, within Jekyll's object model, files appear in `site.static_files`, cleaned on rebuild, no post-processing.
**Cons**: ~10 lines of boilerplate for the subclass. The custom `write()` bypasses Jekyll's `modified_time` tracking (normal `StaticFile#write` uses `FileUtils.cp` with mtime preservation), so `jekyll build --incremental` can't skip unchanged `.md` files. Acceptable for full builds but could matter for dev workflow speed with ~230 generated files.

#### Approach B: Custom Extension + Post-Build Rename (the POC approach)

1. Generate files with `.msrc` extension
2. Register a pass-through converter matching `.msrc` with `output_ext` returning `.msrc`
3. Post-build `make` target renames `.msrc` → `.md` in `_site/`

```ruby
class MarkdownSourceConverter < Jekyll::Converter
  safe true
  priority :low

  def matches(ext)
    ext =~ /\.msrc$/i
  end

  def output_ext(ext)
    ".msrc"
  end

  def convert(content)
    content  # pass-through
  end
end
```

**Pros**: Works within Jekyll's converter system.
**Cons**: Extra build step, Liquid still processes the content (unless `render_with_liquid: false`), fragile if rename step fails, must add cleanup to Makefile.

#### Approach C: :site, :post_write Hook

Write `.md` files directly into `_site/` after Jekyll finishes the entire build:

```ruby
Jekyll::Hooks.register :site, :post_write do |site|
  site.posts.docs.each do |post|
    md_path = File.join(site.dest, post.url, "index.md")
    FileUtils.mkdir_p(File.dirname(md_path))
    File.write(md_path, generated_markdown_for(post))
  end
end
```

**Pros**: Simplest implementation, completely bypasses Jekyll pipeline.
**Cons**: Files not tracked by Jekyll (won't appear in `site.static_files`), not cleaned on `jekyll clean`, invisible to other plugins.

**Assessment**: Approach A (subclassed StaticFile) is the architecturally correct choice. It integrates with Jekyll's file tracking, gets cleaned on rebuild, and requires no post-processing steps.

Sources:
- [Jekyll Static Files Documentation](https://jekyllrb.com/docs/static-files/)
- [Jekyll Generators Documentation](https://jekyllrb.com/docs/plugins/generators/)
- [Jekyll PageWithoutAFile PR #6556](https://github.com/jekyll/jekyll/pull/6556)
- [Jekyll Issue #8959: Copy Markdown to output](https://github.com/jekyll/jekyll/issues/8959)
- [Jekyll Converters Documentation](https://jekyllrb.com/docs/plugins/converters/)
- [Outputting Markdown from Jekyll using hooks](https://humanwhocodes.com/blog/2019/04/jekyll-hooks-output-markdown/)

---

## Follow-up Research 2026-02-13T19:15:00Z

### How to Actually Decouple the 8 Coupled Locations

**Key insight**: Decoupling data resolution from HTML rendering is a standalone first step. It doesn't require any dual-output infrastructure — it's a pure refactoring that makes the existing codebase cleaner and happens to enable future Markdown output.

---

### Strategy: Split `resolve()` into `find()` + `render()`

Every coupled location follows the same anti-pattern: a single method that looks up data in the link cache AND builds HTML. The fix is consistent across all 8: **split into a data-returning method and an HTML-building method**, with the public `resolve()` becoming a thin wrapper that calls both.

The refactored resolvers return **data contracts** — plain Ruby hashes with all the information needed to render in any format. The existing HTML rendering becomes one consumer of that data. Future Markdown rendering becomes another.

---

### Location 1–4: Link Resolvers

All four resolvers share the same structure. Here's the pattern, demonstrated with `BookLinkResolver`:

#### Current (`book_link_resolver.rb`)

```ruby
def resolve(title_raw, text_override, author_filter, date_filter = nil, cite: true)
  # ... validation ...
  candidates = find_candidates           # DATA
  result = filter_candidates(candidates) # DATA
  render_result(result, text_override)   # HTML ← coupled here
end
```

`render_result()` at line 205 calls `BookLinkUtils.render_book_link_from_data()` which calls `_build_book_cite_element()` → `TypographyUtils.prepare_display_title()` → wraps in `<cite>` → passes to `LinkHelperUtils._generate_link_html()` → wraps in `<a>`.

#### Refactored

```ruby
# New public method — returns data only
def find(title_raw, text_override, author_filter, date_filter = nil, cite: true)
  # ... same validation ...
  candidates = find_candidates
  display_text = determine_display_text(text_override)
  return { status: :empty_title } if @norm_title.empty?
  return { status: :not_found, display_text: display_text } if candidates.empty?

  result = filter_candidates(candidates, author_filter)
  return { status: :not_found, display_text: display_text } if result.is_a?(String)

  {
    status: :found,
    url: result['url'],
    display_text: text_override || result['title'],
    canonical_title: result['title'],
    cite: cite
  }
end

# Existing resolve() becomes a thin wrapper
def resolve(title_raw, text_override, author_filter, date_filter = nil, cite: true)
  data = find(title_raw, text_override, author_filter, date_filter, cite: cite)
  render_from_data(data)
end
```

#### Data Contracts

**BookLinkResolver**:
```ruby
{ status: :found, url: "/books/hyperion/", display_text: "Hyperion", canonical_title: "Hyperion", cite: true }
{ status: :not_found, display_text: "Unknown Book" }
{ status: :empty_title }
```

**AuthorLinkResolver** (`author_link_resolver.rb`):
```ruby
{ status: :found, url: "/books/authors/dan-simmons/", display_text: "Dan Simmons", possessive: false }
{ status: :not_found, display_text: "Unknown Author", possessive: false }
```

**SeriesLinkResolver** (`series_link_resolver.rb`):
```ruby
{ status: :found, url: "/books/series/hyperion-cantos/", display_text: "Hyperion Cantos" }
{ status: :not_found, display_text: "Unknown Series" }
```

**ShortStoryResolver** (`short_story_resolver.rb`):
```ruby
{ status: :found, url: "/books/stories-of-your-life/#story-slug", display_text: "Story of Your Life" }
{ status: :not_found, display_text: "Unknown Story" }
```

#### Implementation Order for Resolvers

1. **AuthorLinkResolver** — Simplest (37 lines of logic). `find_author()` already isolated at line 53. Split `generate_html()` (line 71) into data return + HTML render.

2. **SeriesLinkResolver** — Near-identical structure. `find_series()` at line 56, `generate_html()` at line 75.

3. **ShortStoryResolver** — Slightly more complex due to `resolve_ambiguity()` (line 62), but data flow is clean. `render_html()` at line 97 is the only HTML producer.

4. **BookLinkResolver** — Most complex (222 lines). Multiple edge cases: date filtering, author disambiguation, unreviewed mention tracking. But the data/HTML boundary is at `render_result()` (line 205) — a clean seam.

#### What Changes in the Util Modules

The `*Utils` modules (`BookLinkUtils`, `AuthorLinkUtils`, `SeriesLinkUtils`, `ShortStoryLinkUtils`) currently expose `render_*_link()` as their public API. After decoupling:

```ruby
module BookLinkUtils
  # Existing (unchanged) — returns HTML
  def self.render_book_link(title, context, ...)
    BookLinkResolver.new(context).resolve(title, ...)
  end

  # New — returns data hash
  def self.find_book_link(title, context, ...)
    BookLinkResolver.new(context).find(title, ...)
  end
end
```

All existing callers continue calling `render_book_link()` — zero downstream changes required.

---

### Location 5–6: Card Renderers

#### BookCardRenderer (`book_card_renderer.rb`)

**Current coupling**: `render()` at line 40 calls `CardExtractor.extract_base_data()` (data) → `title_html()` (HTML) → `authors_html()` (HTML) → `rating_html()` (HTML) → `CardRenderer.render_card()` (HTML). Data extraction and HTML generation are interleaved within the same method chain.

**Refactored**: Extract a `build_card_data_hash()` method that returns raw data, separate from `build_card_html()` that consumes it.

```ruby
# New — returns structured data
def extract_data
  base = CardExtractor.extract_base_data(@book_obj, @context, ...)
  data = base[:data_source_for_keys]
  {
    title: @title_override.to_s.strip.empty? ? base[:raw_title] : @title_override,
    authors: FrontMatter.get_list_from_string_or_array(data['book_authors']),
    rating: data['rating'],
    excerpt: data['excerpt'] || '',
    url: base[:absolute_url],
    image_url: base[:absolute_image_url],
    image_alt: data['image_alt'],
    subtitle: @subtitle,
    log_output: base[:log_output] || ''
  }
end

# Existing render() calls extract_data() then builds HTML
def render
  card_data = extract_data
  return card_data[:log_output] if card_data[:url].nil?
  card_data[:log_output] + build_html_card(card_data)
end
```

The `authors_html()` method at line 101 currently calls `AuthorLinker.render_author_link()` (HTML) for each author. After decoupling, `extract_data()` returns raw author names. The HTML renderer calls `render_author_link()`, and a future Markdown renderer calls `find_author_link()` to get data hashes instead.

#### ArticleCardRenderer (`article_card_renderer.rb`)

Same pattern but simpler — no authors, no rating. `extract_base_data()` at line 21 already returns a clean data hash. The coupling is in `generate_title_html()` (line 59) and `assemble_card_data()` (line 43) which builds HTML fragments. Split the same way.

---

### Location 7: DisplayAuthorsUtil (`display_authors_util.rb`)

**Current**: `render_author_list()` at line 22 extracts names AND builds HTML in one pass.

```ruby
def self.render_author_list(author_input:, context:, linked: true, etal_after: nil)
  author_names = FrontMatter.get_list_from_string_or_array(author_input)  # DATA
  processed_authors = author_names.map { |name|                            # HTML
    linked ? AuthorLinker.render_author_link(name, context) : "<span>#{name}</span>"
  }
  Text.format_list_as_sentence(processed_authors, etal_after: etal_after)  # HTML
end
```

**Refactored**: The data part is trivial — it's just `get_list_from_string_or_array()`. The real fix here is downstream: once AuthorLinkResolver is decoupled (Location 2), this method can call `find_author_link()` instead of `render_author_link()` when building Markdown output. No structural change needed to `DisplayAuthorsUtil` itself — it naturally becomes format-aware once its dependencies are.

---

### Location 8: LinkHelperUtils (`link_helper_utils.rb`)

**Current**: `_build_link_with_url_resolution()` at line 55 resolves canonical URLs from cache (lines 58-60) AND builds `<a>` tags (line 70).

**This location requires the least change**: `_resolve_canonical_urls()` is already a separate private method (line 88). The data/HTML split is:

```ruby
# Already exists as private — make public or add wrapper
def self.resolve_link_data(context, target_url)
  site, page = _extract_context_components(context)
  return { status: :no_context } unless site && page

  target_base_url, target_fragment = _parse_url_parts(target_url.to_s)
  current_canonical, target_canonical = _resolve_canonical_urls(site, page['url'], target_base_url)

  {
    status: :resolved,
    current_canonical_url: current_canonical,
    target_canonical_url: target_canonical,
    target_fragment: target_fragment,
    same_page: current_canonical == target_canonical,
    href: same_page ? (target_fragment ? "##{target_fragment}" : nil) : target_url
  }
end
```

The existing `_generate_link_html()` continues to work unchanged — it's already the HTML-specific consumer.

---

### Dependency Order for Implementation

The 8 locations have dependencies. Implement bottom-up:

```
Phase 1: Foundation (no downstream callers to change)
  1. LinkHelperUtils — add resolve_link_data() alongside existing _generate_link_html()
  2. AuthorLinkResolver — add find(), keep resolve() as wrapper
  3. SeriesLinkResolver — add find(), keep resolve() as wrapper
  4. ShortStoryResolver — add find(), keep resolve() as wrapper
  5. BookLinkResolver — add find(), keep resolve() as wrapper

Phase 2: Consumers (depend on Phase 1)
  6. DisplayAuthorsUtil — no change needed (naturally format-aware via Phase 1)
  7. ArticleCardRenderer — add extract_data()
  8. BookCardRenderer — add extract_data()
```

**Phase 1 is low risk but not zero risk**: Every change adds a new method alongside the existing one. No existing call sites change. All existing tests continue to pass. Each resolver can be merged independently. However, each `find()` method creates a parallel API surface — a plain Ruby hash with no schema enforcement. If `resolve()` evolves without updating `find()`, drift is invisible until something breaks at runtime. Tests on the data contracts mitigate this, but 5 new public methods is real ongoing maintenance.

**Phase 2 is also low risk**: `extract_data()` is new. `render()` continues to work by calling `extract_data()` internally.

### Testing Strategy: TDD

Per project rules (`CLAUDE.md`: "Create a matching test file in `_tests/` for every new class"), each new method needs tests. **Use test-driven development** — write `find()` tests first, then implement.

**TDD cycle per resolver:**
1. Write `find()` tests (3–5 cases covering the data contract)
2. Implement `find()`
3. Green on new tests
4. Refactor `resolve()` to call `find()` internally
5. Green on existing `resolve()` tests (regression safety net)

**What to test in `find()` (focus on the data contract):**
- `:found` — correct hash keys and values (url, display_text, status)
- `:not_found` — returns display_text fallback, correct status
- `:empty_title` — edge case

**What NOT to duplicate**: The existing `resolve()` tests already cover all edge cases (ambiguous titles, author filters, date filters, missing cache, etc.). Those code paths are shared with `find()`. Don't re-test every permutation — the `resolve()` tests are the regression safety net confirming the extraction didn't break anything.

**Phase 1 — new `find()` methods (4 resolvers):**
- ~3–5 test cases per resolver, focused on data contract shape
- Existing `resolve()` tests stay unchanged

**Phase 2 — new `extract_data()` methods (2 card renderers):**
- Same TDD cycle: write `extract_data()` tests first, then implement
- `BookCardRenderer.extract_data()`: all hash keys present, missing authors, missing rating, title override
- `ArticleCardRenderer.extract_data()`: all hash keys present, missing image alt
- Existing `render()` tests stay unchanged

**Estimated test additions**: ~4–6 new test files, ~20–30 test cases total. No changes to existing tests.

---

### What This Enables (Without Building Yet)

After Phase 1+2, every component in the system can answer: "What data do you have?" separately from "How do you render it?" This means:

- A future `MarkdownBookLinkRenderer` can call `BookLinkResolver.new(context).find(title, ...)` and get `{url:, display_text:, cite:}` → render as `[Hyperion](/books/hyperion/)` instead of `<a href="/books/hyperion/"><cite>Hyperion</cite></a>`
- A future `MarkdownBookCardRenderer` can call `BookCardRenderer.new(...).extract_data()` and get `{title:, authors:, rating:, excerpt:, url:}` → render as a Markdown list item
- The list renderers (ByYear, ByAuthor, etc.) that call `BookCardUtils.render()` already have clean Finder/Renderer separation at their level — their Markdown equivalents would call the same Finders, just pass data to Markdown renderers instead

---

## Follow-up Research 2026-02-13T19:15:00Z

### Complete MarkdownOutputGenerator Architecture

This documents the full generation flow for producing `.md` files, to be built *after* the decoupling above.

---

### Generation Flow

```
Jekyll Build Pipeline:
  1. LinkCacheGenerator runs (priority :normal)
  2. MarkdownOutputGenerator runs (priority :low, after cache is ready)
     │
     ├── For each post/book document:
     │   ├── Read front matter (title, date, authors, etc.)
     │   ├── Process body content:
     │   │   ├── Run Liquid on document body (resolves inline tags)
     │   │   │   └── Tags check context.registers[:render_mode] → :markdown
     │   │   │       └── Call find() instead of render() → return Markdown
     │   │   └── Skip Kramdown (body is already Markdown)
     │   ├── Process layout-equivalent content:
     │   │   ├── Call Finders directly (no Liquid needed)
     │   │   │   └── Related::Finder.new(context).find → {books: [...]}
     │   │   │   └── Backlinks::Finder.new(context).find → {backlinks: [...]}
     │   │   └── Pass to Markdown renderers
     │   ├── Assemble: front matter header + body + layout-equivalent sections
     │   ├── Post-process: normalize whitespace
     │   └── Create GeneratedStaticFile with assembled content
     │
     └── Add all GeneratedStaticFiles to site.static_files
```

### Two Content Categories

**Category A: Inline tags in body content** — `{% book_link %}`, `{% author_link %}`, `{% series_link %}`, `{% short_story_link %}`, `{% rating_stars %}`, `{% cited_quote %}`, `{% units %}`

These appear in the Markdown body of posts and book reviews. They're resolved during Liquid processing. For Markdown output, we render the body through Liquid with a `:render_mode => :markdown` flag.

**Also in this category: `{% include figure.html %}`** — used in 12 posts (28 occurrences). This Liquid include generates `<figure><img><figcaption>` HTML. During the Markdown Liquid pass, it will still emit HTML unless the include is made mode-aware. The simplest fix: add a `render_mode` check at the top of `figure.html` that outputs `![caption](url)` instead of the `<figure>` block. Since the include receives its data via `include` parameters (url, caption, image_alt), it already has everything needed for the Markdown version.

Liquid rendering for Markdown output:

```ruby
template = site.liquid_renderer.file(doc.path).parse(doc.content)
payload = site.site_payload.merge('page' => doc.to_liquid)
info = {
  registers: { site: site, page: doc.data, render_mode: :markdown },
  strict_filters: site.config.dig("liquid", "strict_filters"),
}
markdown_body = template.render!(payload, info)
```

Each tag checks `context.registers[:render_mode]`:
```ruby
# In a tag's render() method:
if context.registers[:render_mode] == :markdown
  data = BookLinkResolver.new(context).find(title, ...)
  "[#{data[:display_text]}](#{data[:url]})"
else
  BookLinkResolver.new(context).resolve(title, ...)  # existing HTML path
end
```

**Important: propagation through nested calls.** The `context` object is passed through the entire call chain (`Tag → Renderer → Utils → Resolver`), so `registers[:render_mode]` is automatically available at every level. However, **intermediate renderers also need to check the flag** — not just leaf-level tags. For example, when `{% display_books_by_year %}` runs in Markdown mode:

1. The tag itself checks `render_mode` → delegates to a Markdown renderer instead of `ByYearRenderer`
2. The Markdown renderer calls `BookCardRenderer.extract_data()` (data only) instead of `BookCardUtils.render()` (HTML)
3. `extract_data()` returns raw author names instead of calling `AuthorLinker.render_author_link()` (HTML)

The register propagates automatically through `context`, but every layer that makes an HTML-vs-data choice must check it. This is the same concern raised in Q1 ("the entire tree must be mode-consistent") — the solution is that each layer's Markdown equivalent is a different renderer, not a conditional branch inside the HTML renderer.

**Category B: Layout-injected content** — related books, backlinks, author lists, series text, book lists, category posts, feed items

These don't appear in the document body. They're injected by layouts (`post.html`, `book.html`, `author_page.html`, etc.). For Markdown output, the Generator calls Finders directly and passes data to Markdown-specific renderers.

**Constructing a Liquid::Context from a Generator**: Some Finders (e.g., `Related::Finder.new(context, 3)`) require a `Liquid::Context`. Since the Generator runs during the generate phase (before Liquid rendering), a context must be constructed manually:

```ruby
# In the Generator, for each document:
payload = site.site_payload.merge('page' => doc.to_liquid)
registers = { site: site, page: doc.data, render_mode: :markdown }
context = Liquid::Context.new(
  [payload],                          # environments
  {},                                 # outer_scope
  registers                           # registers
)
```

This gives Finders a valid context with access to `site.data['link_cache']`, `page` data, and the `:render_mode` register. With a constructed context:

```ruby
# For a book review page:
related = Jekyll::Books::Related::Finder.new(context, 3).find
backlinks = fetch_backlinks(site, doc)
authors = doc.data['book_authors']
series = doc.data['series']
rating = doc.data['rating']

md = MarkdownBookRenderer.new(doc, related, backlinks, authors, series, rating).render
```

### Output File Creation

```ruby
class GeneratedStaticFile < Jekyll::StaticFile
  def initialize(site, dir, name, content)
    @generated_content = content
    super(site, site.source, dir, name)
  end

  def write(dest)
    dest_path = destination(dest)
    FileUtils.mkdir_p(File.dirname(dest_path))
    File.write(dest_path, @generated_content)
    true
  end
end

# In the Generator:
md_file = GeneratedStaticFile.new(site, doc.url, 'index.md', final_markdown)
site.static_files << md_file
```

---

## Follow-up Research 2026-02-13T19:15:00Z

### Post-Generation Markdown Formatting

Generated Markdown will have excess whitespace from template assembly: blank lines between sections, indentation artifacts, multiple consecutive blank lines. How to clean it up?

---

### Approach 1: Ruby-Native String Processing (Recommended)

Since the generated Markdown has **predictable structure** (we control the templates), a simple Ruby post-processor is sufficient. No external dependencies needed.

```ruby
module MarkdownWhitespaceNormalizer
  def self.normalize(content)
    # Protect fenced code blocks from modification (``` and ~~~ delimiters)
    code_blocks = []
    protected = content.gsub(/^(?:```|~~~).*?^(?:```|~~~)/m) do |block|
      code_blocks << block
      "\n___CODE_BLOCK_#{code_blocks.length - 1}___\n"
    end

    normalized = protected
      .gsub(/[ \t]+$/, '')       # Remove trailing whitespace per line
      .gsub(/\n{3,}/, "\n\n")    # Collapse 3+ blank lines to 1 blank line
      .gsub(/\A\n+/, '')         # Remove leading blank lines
      .gsub(/\n+\z/, "\n")       # Single trailing newline

    # Restore code blocks
    code_blocks.each_with_index do |block, i|
      normalized.sub!("___CODE_BLOCK_#{i}___", block)
    end

    normalized
  end
end
```

**Pros**: Zero dependencies, fast, runs in-process during generation, trivially testable.
**Cons**: Not Markdown-aware beyond code block protection. Won't fix structural issues (e.g., missing blank line before heading).

This is applied as the last step before creating `GeneratedStaticFile`:

```ruby
final_markdown = MarkdownWhitespaceNormalizer.normalize(assembled_markdown)
md_file = GeneratedStaticFile.new(site, doc.url, 'index.md', final_markdown)
```

---

### Approach 2: External Markdown Formatters

If Ruby-native cleanup proves insufficient, dedicated formatters can normalize output:

#### mdformat (Python)

- **What it does**: CommonMark-compliant formatter. Parses Markdown into AST, re-serializes with consistent formatting.
- **Whitespace handling**: Collapses blank lines, normalizes heading spacing, consistent list indentation.
- **Usage**: `echo "content" | mdformat -` (stdin/stdout)
- **Config**: `--wrap {keep,no,INTEGER}`, `--end-of-line {lf,crlf,keep}`
- **Dependency**: Python 3.8+ with one pip package. In Docker: `apk add python3 py3-pip && pip install mdformat`
- **Tradeoff**: Adds Python to a Ruby project. Alpine + Python can slow Docker builds.

#### Prettier (Node.js)

- **What it does**: Opinionated formatter. Collapses blank lines automatically, normalizes indentation.
- **Config**: `--prose-wrap <always|never|preserve>` — limited Markdown-specific options.
- **Dependency**: Node.js runtime. Heavy addition to a Ruby/Jekyll Docker image.
- **Tradeoff**: Very opinionated — may reformat more than desired (rewraps paragraphs, reformats links). Not recommended for this use case.

#### markdownlint-cli2 (Node.js)

- **What it does**: Linter with auto-fix. Rule MD012 controls maximum consecutive blank lines (configurable).
- **Config**: Highly configurable per-rule. `.markdownlint.json` with `{"MD009": true, "MD012": {"maximum": 1}}`.
- **Dependency**: Node.js. Available as Docker image: `davidanson/markdownlint-cli2`.
- **Tradeoff**: Primarily a linter, not a formatter. Auto-fix is a secondary feature. Overkill for whitespace-only needs.

#### No Ruby-native Markdown formatter gems exist

kramdown and redcarpet are parsers/renderers, not formatters. The Ruby ecosystem has no equivalent to mdformat or Prettier for Markdown normalization.

---

### Approach 3: Hybrid — Ruby + Optional mdformat

Start with the Ruby normalizer (Approach 1). If issues arise with complex Markdown structures, add mdformat as an optional post-build step:

```makefile
# In Makefile
format-markdown:
	@find _site -name "index.md" -exec mdformat {} +
```

This keeps the Docker image lean by default and makes the formatter opt-in.

---

### Recommendation

**Start with Ruby-native** (Approach 1). The generated Markdown has predictable structure — we control every template, so we know what whitespace patterns to expect. The three regex substitutions (trailing whitespace, blank line collapse, trim) handle 95% of cases. Code block protection prevents the main risk.

If edge cases appear (and they may not — the output is generated, not user-authored), mdformat is the cleanest addition because it's lightweight, stdin/stdout friendly, and doesn't reformat aggressively.

**Avoid Prettier and markdownlint-cli2** — both require Node.js, which is a heavy dependency for a Ruby project. Prettier is too opinionated for post-processing. markdownlint is designed for linting human-written Markdown, not normalizing generated output.

Sources:
- [mdformat documentation](https://mdformat.readthedocs.io/en/stable/users/installation_and_usage.html)
- [Prettier Markdown support](https://prettier.io/blog/2017/11/07/1.8.0.html)
- [markdownlint rules (MD009, MD012)](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Ruby string whitespace methods](https://www.writesoftwarewell.com/remove-whitespace-from-string-ruby/)
- [Jekyll hooks for Markdown output](https://humanwhocodes.com/blog/2019/04/jekyll-hooks-output-markdown/)

---

## Architectural Review 2026-02-13T20:00:00Z

This section captures architectural feedback and project direction. The analysis and data in preceding sections remain accurate; the framing and approach are revised here.

---

### Project Direction: Both Projects, Done in Steps

Both the refactoring and dual-output are committed. They should be done sequentially in three phases:

**Phase 1: Refactor** — Decouple data from rendering in the link resolvers. Standalone value (testability, data flow transparency). Makes Phase 2 and 3 easier.

**Phase 2: Simple Markdown** — Build the dual-output pipeline. Inline tags (book links, author links, etc.) render as Markdown. Complex components like cards, grids, and navigation **stay as HTML initially** or render as simplified text. This gets functional `.md` files out the door without needing all 21 Markdown renderers.

**Phase 3: Incremental refinement** — One by one, figure out what the Markdown for complex components (cards, lists, ranked books, etc.) should look like and write proper Markdown renderers for them.

This avoids the trap of designing 21 Markdown renderers before knowing what good Markdown output looks like for each. Phase 2 ships something usable. Phase 3 iterates toward ideal.

---

### Build Performance: Not a Concern

Prior POC data: full build went from 6–7s to 7–8s with dual-output enabled (~1s overhead). Current full build is ~8s. This is a static site built once and deployed — even a 15% overhead is trivial. **Build performance is not a blocking concern.**

---

### The Parallel Rendering Layer: 21 Components (Eventually)

The `render_mode` register ultimately requires a Markdown counterpart for every renderer in every call chain. An exhaustive inventory:

| Category | Components | Count |
|---|---|---|
| Card Renderers | BookCardRenderer, ArticleCardRenderer | 2 |
| Book List Renderers | ByAuthorThenSeries, ByTitleAlpha, ByYear, ForSeries | 4 |
| Book Feature Renderers | Backlinks, Ranking, RankedBooks, UnreviewedMentions, Related, Reviews | 6 |
| Post Feature Renderers | Category, Feed, Related | 3 |
| Link/Text Utils | AuthorLink, BookLink, SeriesLink, ShortStoryLink, DisplayAuthors | 5 |
| Structural Utils | BookListRendererUtils | 1 |
| **Total** | | **21** |

**But not all at once.** The 3-phase approach means:

- **Phase 2 handles 5 of 21** (the link/text utils) with proper Markdown output
- **Phase 2 handles the other 16** with fallback behavior (HTML pass-through, simplified text, or omission)
- **Phase 3 converts the 16** one at a time as good Markdown designs emerge

---

### Generator + Manual Liquid Is Architecturally Backwards

The "MarkdownOutputGenerator Architecture" section (above) proposes running Liquid manually inside a Generator. This fights the pipeline — Generators run during the generate phase, *before* rendering. Manually constructing a `Liquid::Context` mimics Jekyll internals with a fragile approximation.

**The `:pre_render` hook is the natural intercept point.** The document's own Section 8 Approach A described this correctly:

```ruby
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  # Fires AFTER Jekyll has built the Liquid context
  # but BEFORE Kramdown conversion
  # payload and registers are real Jekyll objects, not approximations
end
```

**Revised approach for Category A (inline tags in body)**:
- Use `:pre_render` hook to intercept after Liquid context exists
- Re-render the document body with `:render_mode => :markdown` using the real payload
- Store the Markdown body in `doc.data['markdown_body']`
- A later `:post_write` hook or Generator reads the stored body, assembles layout-equivalent content, and creates `GeneratedStaticFile`

**Category B (layout-injected content)** still requires calling Finders from a Generator, but Finders that need a `Liquid::Context` can use the one captured during the `:pre_render` hook, rather than constructing one from scratch.

---

### Scope of "Dual Output" for Empty-Body Pages

98 of ~230 pages (69 author + 29 series) have zero Markdown body. For those, the `.md` output is 100% generated content — not "serving raw Markdown" but building content from data. This is Phase 3 work.

| Page type | Count | Markdown body | Phase |
|---|---|---|---|
| Blog posts | 105 | Substantial | **Phase 2** — re-render inline tags, leave complex layout sections as-is |
| Book reviews | 111 | Substantial | **Phase 2** — re-render inline tags, leave cards/related as-is |
| Author pages | 69 | Zero | **Phase 3** — needs full Markdown renderer for book lists |
| Series pages | 29 | Zero | **Phase 3** — needs full Markdown renderer for book lists |
| Category pages | 23 | 1 paragraph | **Phase 2/3** — body works immediately, post list is Phase 3 |
| Other pages | ~7 | Varies | Case by case |

---

### Revised Decoupling Scope

**Phase 1 (refactor — do now):**
1. AuthorLinkResolver — add `find()`
2. SeriesLinkResolver — add `find()`
3. ShortStoryResolver — add `find()`
4. BookLinkResolver — add `find()`

These 4 resolvers have the clearest data/HTML seam. Each can be merged independently.

**Defer to Phase 2 (when Markdown renderer design is known):**
5. BookCardRenderer `extract_data()`
6. ArticleCardRenderer `extract_data()`

**Defer to Phase 3 (when specific Markdown designs emerge):**
7. DisplayAuthorsUtil — depends on how author lists render in Markdown cards
8. LinkHelperUtils — may not need change at all

---

### Revised Summary

| Item | Phase | Status |
|---|---|---|
| Decouple 4 link resolvers | **Phase 1** | Do now, standalone value |
| Simple Markdown output (body + inline tags) | **Phase 2** | After Phase 1; complex stuff stays HTML |
| `:pre_render` hook (not Generator) for body | **Phase 2** | Use the natural pipeline intercept |
| Decouple 2 card renderers | **Phase 2** | Design data contract when Markdown card format is known |
| `GeneratedStaticFile` for `.md` output | **Phase 2** | Bypass Jekyll re-processing |
| Whitespace normalizer | **Phase 2** | Ruby-native, applied before file creation |
| `<link rel="alternate">` in HTML `<head>` | **Phase 2** | Standard signaling |
| Markdown renderers for cards, lists, etc. | **Phase 3** | One at a time, design-then-build |
| Empty-body pages (author, series) | **Phase 3** | Needs full Markdown content generation |
| llms.txt | **Phase 3** | After `.md` files exist to point to |
