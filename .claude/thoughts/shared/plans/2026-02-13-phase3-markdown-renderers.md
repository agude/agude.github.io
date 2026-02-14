# Phase 3: Markdown Renderers & Polish --- Implementation Plan

## Overview

Incrementally build Markdown renderers for the complex components that Phase 2
omitted or simplified: book cards, article cards, list pages, related items,
backlinks, and ranking sections. Also: decouple card renderers
(`extract_data()`), upgrade author/series/category/overview pages from stub
`.md` to full Markdown content, and generate `llms.txt`.

**Depends on**: Phase 2 (Markdown output pipeline, inline tag Markdown mode).

This phase is intentionally less prescriptive than Phases 1 and 2. Each
sub-step is a standalone unit of work. The order below is a recommendation,
not a requirement --- adapt based on what looks most valuable as Phase 2 output
is reviewed.

### Phase 3 MVP vs. Phase 3b

**Phase 3 MVP** (Tiers 1-3 + Tier 6): Card decoupling, book review layout
sections, blog post layout sections, and `llms.txt`. This delivers 80% of the
value --- blog posts and book reviews get full Markdown including
layout-injected sections, plus the index file for agent discovery.

**Phase 3b** (Tiers 4-5): Author, series, category, overview, and index pages.
These are primarily navigational --- lower value per effort. Can be deferred
or dropped if the MVP is sufficient.

## Current State Analysis (after Phase 2)

- Every page on the site has a `.md` counterpart (except 404 and test)
- Blog posts and book reviews have `.md` files with Markdown body content and
  inline links
- Layout-injected sections (related books, backlinks, card grids) are omitted
  from `.md` files
- 98 pages (69 author + 29 series) have `.md` files with header only --- body
  is empty or contains HTML pass-through from unmodified layout tags
- 6 book overview pages (`/books/`, `/books/by-author/`, etc.) have `.md`
  files with header only
- 23 category pages have `.md` files with body paragraph but generated post
  lists are HTML pass-through
- 1 blog index page has `.md` file with header only (paginated content is HTML
  pass-through)
- Root and supplementary pages have full Markdown `.md` files (no work needed
  in Phase 3)
- Card renderers (`BookCardRenderer`, `ArticleCardRenderer`) still mix data
  extraction with HTML generation

### The 21-Component Inventory

| Category | Components | Phase 2 Status | Phase 3 Work |
|---|---|---|---|
| **Card Renderers** | BookCardRenderer, ArticleCardRenderer | No Markdown mode | Decouple `extract_data()`, add Markdown rendering |
| **Book List Renderers** | ByAuthorThenSeries, ByTitleAlpha, ByYear, ForSeries | Not used in MD output | Add Markdown list renderers |
| **Book Feature Renderers** | Backlinks, Ranking, RankedBooks, UnreviewedMentions, Related, Reviews | Omitted in MD | Add Markdown renderers |
| **Post Feature Renderers** | Category, Feed, Related | Omitted in MD | Add Markdown renderers |
| **Link/Text Utils** | AuthorLink, BookLink, SeriesLink, ShortStoryLink, DisplayAuthors | Done in Phase 1+2 | Possibly done |
| **Structural Utils** | BookListRendererUtils | Not used in MD output | Add Markdown mode |

## Desired End State

- Every component in the rendering tree has a Markdown counterpart
- Author pages (69) and series pages (29) have `.md` files with generated book
  lists (upgrading Phase 2 stubs)
- Category pages (23) have `.md` files with post lists (upgrading Phase 2
  stubs)
- Book overview pages (6) have `.md` files with generated book lists
  (upgrading Phase 2 stubs)
- Book review `.md` files include related books, backlinks, and previous
  reviews
- Blog post `.md` files include related posts
- No HTML pass-through remains in any `.md` file
- `llms.txt` exists at site root, indexing all `.md` files
- Full build still completes in reasonable time (~10s)

## What We're NOT Doing

- **No template engine for Markdown** --- renderers build strings in Ruby,
  same pattern as HTML renderers
- **No external Markdown formatter** --- Ruby-native normalizer from Phase 2
  is sufficient
- **No truly new Liquid tags** --- existing layout tags get `render_mode`
  support (same pattern as Phase 2 inline tags), but no new tags are created
- **No content negotiation** --- GitHub Pages can't do it; we serve static
  files at known URLs

## Step 0: Audit Phase 2 Output

Before starting Phase 3 work, run the Phase 2 final verification checks and
identify any gaps:
- Do all expected page types have `.md` files?
- Are blog post/book review `.md` files clean Markdown (no unexpected HTML)?
- Which pages have HTML pass-through in their `.md` body?
- Are there any pages that failed during Phase 2 (warnings in build log)?

This prevents wasted work on assumptions about the Phase 2 baseline.

## Implementation Approach

Phase 3 uses two strategies with a **principled boundary**:

**Tag approach** (for body content): Tags that appear in document body content
--- whether inline (`{% book_link %}`) or block-level (`{%
display_books_by_author %}`) --- get `render_mode` support. The `:pre_render`
hook re-renders the body in Markdown mode and captures the output. This is the
same pattern Phase 2 established for inline tags. **Used for Tiers 4-5**
(author, series, category, overview, index pages).

**Assembler approach** (for layout-injected sections): Sections injected by
the layout (not the body) --- related books, backlinks, previous reviews,
related posts --- are built by
`MarkdownOutputAssembler.build_layout_equivalent()`. The assembler calls
Finders directly (or reads pre-collected data) and formats with
`MarkdownCardUtils`. **Used for Tiers 2-3** (book review and blog post layout
sections).

The boundary: if the content comes from the document body, the tag outputs it.
If the content comes from the layout, the assembler builds it.

Each component follows the same sub-pattern:
1. Decide what the Markdown output should look like
2. If data/HTML are coupled, add `extract_data()` first (following the Phase 1
   data extraction contract standard)
3. Write a Markdown renderer that consumes the data and produces Markdown text
4. Wire it in: tag approach → add `render_mode` check; assembler approach →
   add to `build_layout_equivalent()`
5. Test

Components are independent --- each can be implemented and merged separately.

---

## Step 0B: Refactor Finder Constructors

Before Tier 2 (which calls Finders from the assembler), refactor the four
Finders to accept `site` + `document` instead of `Liquid::Context`.

**Investigation results**: All four Finders (`Related::Finder` for books,
`Related::Finder` for posts, `Backlinks::Finder`, `Reviews::Finder`) currently
take a `Liquid::Context` but only use it for:
1. `context.registers[:site]` → stored as `@site`
2. `context.registers[:page]` → stored as `@page`
3. Passing `context` to `PluginLoggerUtils.log_liquid_failure()` for logging

Their actual data needs are `site` + document front matter. No deep Liquid
machinery.

**Refactoring** (~10 lines per Finder):
1. Change constructor from `initialize(context, ...)` to `initialize(site,
   document, ...)`
2. Update logging calls --- either modify
   `PluginLoggerUtils.log_liquid_failure()` to accept `site` + `document`, or
   create a hook-compatible logging adapter
3. Update the existing tag callers to pass `context.registers[:site],
   context.registers[:page]` instead of `context`
4. All existing tests must pass after refactoring

**Files**: 4 Finders + 4 tags + 4 test files (~12 files modified, 0 new).

This is a prerequisite for Tiers 2-3 (assembler approach). Without it, the
assembler can't call Finders because it has no `Liquid::Context` available in
the `:site, :post_render` hook.

---

## Tier 1: Card Renderer Decoupling (enables everything else)

Most list and feature renderers ultimately call `BookCardUtils.render()` or
`ArticleCardUtils.render()` to produce individual cards. Decoupling these is
the prerequisite for most other work.

### Step 1A: BookCardRenderer `extract_data()`

**File**: `_plugins/src/content/books/core/book_card_renderer.rb`

Add public `extract_data()` that returns a frozen hash following the Phase 1 data extraction contract standard (no presentation data, frozen, raw text, full key set):
```ruby
{
  title: "Book Title",
  authors: ["Author One", "Author Two"],
  rating: 4,
  excerpt: "First paragraph...",
  url: "/books/slug/",
  image_url: "/assets/images/cover.jpg",
  image_alt: "Book cover",
  subtitle: nil
}.freeze
```

Log output stays on the instance variable (`@log_output`), same pattern as
Phase 1's resolvers. Refactor `render()` to call `extract_data()` internally,
same TDD approach as Phase 1 resolvers.

**Test file**: `_tests/src/content/books/core/test_book_card_renderer.rb` (existing)

### Step 1B: ArticleCardRenderer `extract_data()`

**File**: `_plugins/src/content/posts/article_card_renderer.rb`

Same pattern. Returns a frozen hash:
```ruby
{
  title: "Post Title",
  excerpt: "First paragraph...",
  url: "/blog/slug/",
  date: "February 13, 2026",
  image_url: "/assets/images/header.jpg",
  image_alt: "Header image"
}.freeze
```

**Test file**: `_tests/src/content/posts/test_article_card_renderer.rb` (existing)

### Step 1C: Markdown card formatters

New utility that converts card data hashes to Markdown list items:

**File**: `_plugins/src/content/markdown_output/markdown_card_utils.rb` (new)

```ruby
module MarkdownCardUtils
  def self.render_book_card_md(data)
    stars = "★" * data[:rating].to_i + "☆" * (5 - data[:rating].to_i) if data[:rating]
    line = "- [#{data[:title]}](#{data[:url]})"
    line += " by #{data[:authors].join(', ')}" if data[:authors]&.any?
    line += " --- #{stars}" if stars
    line
  end

  def self.render_article_card_md(data)
    "- [#{data[:title]}](#{data[:url]})"
  end
end
```

**Test file**: `_tests/src/content/markdown_output/test_markdown_card_utils.rb` (new)

---

## Tier 2: Book Review Layout Sections

These sections are injected by `book.html` layout (not the document body).
Uses the **assembler approach**:
`MarkdownOutputAssembler.build_layout_equivalent()` calls Finders + Markdown
card formatters. After Tier 1 decouples card data, the assembler can format
cards as Markdown.

### Step 2A: Related Books (Markdown)

Currently: `{% related_books %}` in `book.html` → `Related::Finder` →
`Related::Renderer` → BookCardUtils → HTML card grid.

Markdown equivalent:
```markdown
## Related Books

- [Hyperion](/books/hyperion/) by Dan Simmons --- ★★★★★
- [Dune](/books/dune/) by Frank Herbert --- ★★★★☆
- [Foundation](/books/foundation/) by Isaac Asimov --- ★★★★☆
```

**Implementation** (requires Step 0B --- Finders accept `site` + `document`):
1. In `MarkdownOutputAssembler.build_layout_equivalent()`, call
   `Related::Finder.new(site, item).find`
2. Map each book through `MarkdownCardUtils.render_book_card_md()`
3. Prepend `## Related Books\n\n`

### Step 2B: Book Backlinks (Markdown)

Currently: `{% book_backlinks %}` → Backlinks::Finder → Backlinks::Renderer →
HTML list.

Markdown equivalent:
```markdown
## Mentioned In

- [Post Title](/blog/slug/) (blog post)
- [Other Book](/books/other/) (book review)
```

**Implementation** (requires Step 0B): Call `Backlinks::Finder.new(site,
item).find` or read from `site.data['link_cache']['backlinks']` directly.

### Step 2C: Previous Reviews (Markdown)

Currently: `{% display_previous_reviews %}` → Reviews::Finder → Reviews::Renderer → HTML card list.

Markdown equivalent:
```markdown
## Previous Reviews

- [Hyperion (2020 review)](/books/hyperion-2020/) --- ★★★☆☆
```

---

## Tier 3: Blog Post Layout Sections

### Step 3A: Related Posts (Markdown)

Currently: `{% related_posts %}` in `post.html` → Related::Finder → Related::Renderer → HTML card grid.

Markdown equivalent:
```markdown
## Related Posts

- [Post Title](/blog/slug/)
- [Another Post](/blog/another/)
```

---

## Tier 4: Author & Series Pages

These pages already have `.md` files from Phase 2 (header only, body is empty
or HTML pass-through from unmodified tags). Phase 3 upgrades them by adding
`render_mode` support to the layout tags that generate their body.

Uses the **tag approach**: the document body IS the tag output (`{%
display_books_by_author %}` etc.), so adding `render_mode` to these tags lets
the `:pre_render` hook capture clean Markdown automatically. No assembler
changes needed.

### Step 4A: Author Page Markdown

Currently: `author_page.html` body contains `{% display_books_by_author
page.title %}` → ByAuthorFinder → renderer → book card grid. In Phase 2, this
tag outputs HTML into the `.md` body.

Phase 3: add `render_mode` check to `{% display_books_by_author %}`. When
`render_mode == :markdown`, use `extract_data()` (from Tier 1) +
`MarkdownCardUtils` to output:

```markdown
## Books by Author Name

- [Book One](/books/book-one/) --- ★★★★★
- [Book Two](/books/book-two/) --- ★★★★☆
```

The `:pre_render` hook captures this as `markdown_body`. The assembler
prepends the header (`# Author Name`) as before.

**Implementation**:
1. Add `render_mode` check to the `display_books_by_author` tag
2. In Markdown mode: call `AllBooksByAuthorFinder`, map through
   `MarkdownCardUtils.render_book_card_md()`
3. The hook captures the Markdown output --- no assembler changes needed

### Step 4B: Series Page Markdown

Same tag approach. Add `render_mode` to `{% display_books_for_series %}`.

Markdown output:
```markdown
## Books in Series Name

1. [Book One](/books/book-one/) --- ★★★★★
2. [Book Two](/books/book-two/) --- ★★★★☆
```

Use numbered list to show reading order. **Note**: verify during
implementation that the series Finder returns books in series order (not
publication date or title order). If not, either fix the Finder's sort order
or use a bulleted list instead.

---

## Tier 5: Category, Overview & Index Pages

These pages already have `.md` files from Phase 2. Phase 3 upgrades the
generated content by adding `render_mode` to the body-content tags. Uses the
**tag approach** (same as Tier 4).

### Step 5A: Category Pages

23 pages with 1 paragraph body + `{% category_posts %}` (or similar) tag. The
body paragraph is already clean Markdown from Phase 2. Add `render_mode` to
the post-list tag so it outputs a Markdown list of posts.

### Step 5B: Book Overview Pages

6 pages (`/books/`, `/books/by-author/`, `/books/by-rating/`,
`/books/by-title/`, `/books/by-series/`, `/books/by-award/`). Body is 100%
generated book lists. Add `render_mode` to `{% display_books_by_year %}`, `{%
display_books_by_author %}`, etc. --- same tag approach, the hook captures the
Markdown output.

### Step 5C: Blog Index

Paginated listing at `/blog/`. The paginator content is body content, so the
tag approach applies. Add `render_mode` to the pagination template logic to
output a Markdown post list.

### Step 5D: Home Page / Special Pages

Case-by-case. `index.md` has biographical text + `{% front_page_feed %}`. Add
`render_mode` to `front_page_feed` tag.

---

## Tier 6: `llms.txt`

### Overview

Generate `/llms.txt` at site root as a curated index of all `.md` files.

**File**: `_plugins/src/content/markdown_output/llms_txt_generator.rb` (new)

Runs inside the same `:site, :post_render` hook as `MarkdownOutputAssembler`,
after assembly completes. (Both need to run after all pages are rendered but
before files are written.) Alternatively, can use a `:site, :post_write` hook
if it needs to scan `_site/` for `.md` files directly.

Produces:

```markdown
# Alex Gude

> Personal website about technology, data science, machine learning, and book reviews.

## Blog Posts
- [Post Title](https://alexgude.com/blog/slug/index.md): Brief description
- ...

## Book Reviews
- [Book Title](https://alexgude.com/books/slug/index.md): Brief description
- ...

## Optional
- [Author: Jane Doe](https://alexgude.com/books/authors/jane-doe/index.md)
- [Series: Hyperion Cantos](https://alexgude.com/books/series/hyperion-cantos/index.md)
```

The "Optional" section signals lower-priority content for agents with limited context windows.

**Description source**: Use `page.data['description']` if present (many posts
have this in front matter for SEO). Fall back to `page.excerpt` (first
paragraph). If neither exists, omit the description --- the entry becomes
`[Title](url)` with no colon. This is a "best effort" field.

Uses absolute URLs per the llms.txt specification.

---

## Testing Strategy

Each tier adds tests to existing or new test files:

- **Tier 1**: Tests in existing card renderer test files + new `test_markdown_card_utils.rb`
- **Tiers 2-3**: Tests in `test_markdown_output_assembler.rb` (from Phase 2) or new per-component test files if complexity warrants
- **Tiers 4-5**: Tests in existing layout tag test files (render_mode tests, same pattern as Phase 2 inline tag tests)
- **Tier 6**: `test_llms_txt_generator.rb` (new)

### Integration testing:
After each tier, `make build` and spot-check `.md` output files.

---

## Estimated File Changes Per Tier

| Tier | Modified Files | New Files | Scope |
|---|---|---|---|
| 1A-1B | 2 renderers, 2 test files | 0 | Card decoupling |
| 1C | 0 | 1 util + 1 test | Markdown card formatter |
| 0B | 4 Finders, 4 tags, 4 test files | 0 | Finder constructor refactoring |
| 2A-2C | 1 assembler | 0 | Book layout sections (assembler approach) |
| 3A | 1 assembler | 0 | Post layout sections (assembler approach) |
| 4A-4B | layout tags, tag tests | 0 | Author/series pages (tag approach) |
| 5A-5D | layout tags, tag tests | 0 | Category/overview/index pages (tag approach) |
| 6 | 1 test_helper | 1 generator + 1 test | llms.txt |

---

## Success Criteria (per tier)

#### Automated Verification:
- [ ] All tests pass: `make test`
- [ ] Lint passes: `make lint`
- [ ] Build succeeds: `make build`
- [ ] `.md` files contain expected sections (grep for `## Related` etc.)

#### Final Verification (after all tiers):
- [ ] `make build` completes in <15s
- [ ] `.md` counterparts already exist for all pages (from Phase 2) --- Phase
  3 verification is about content quality, not file existence
- [ ] `llms.txt` exists and lists all posts and books
- [ ] No HTML tags in `.md` body content (excluding code blocks): `grep -rL
  '<div\|<span\|<a href' _site/blog/*/index.md | wc -l` matches total count
- [ ] No HTML pass-through in author/series/category/overview page `.md`
  files: `grep -rL '<div\|<span\|<a href' _site/books/authors/*/index.md | wc
  -l` matches total count

#### Permanent CI Check (promote from one-time to recurring):
The HTML-in-Markdown grep above should become a permanent build check (e.g., a
`make lint-md` target or a step in the existing `make lint`). This catches
regressions when new tags are added without `render_mode` support. See Phase
2's "Development Rule: `render_mode` for New Tags".

## References

- Research: `thoughts/shared/research/2026-02-13-rendering-pipeline-dual-output.md` (21-component inventory, data contract analysis)
- Phase 1 plan: `thoughts/shared/plans/2026-02-13-phase1-decouple-link-resolvers.md`
- Phase 2 plan: `thoughts/shared/plans/2026-02-13-phase2-simple-markdown-output.md`
- llms.txt specification: https://llmstxt.org/
