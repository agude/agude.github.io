# Phase 2: Simple Markdown Output — Implementation Plan

## Overview

Build the dual-output pipeline: generate `.md` files alongside every HTML page on the site. Inline Liquid tags (book links, author links, etc.) render as Markdown when in Markdown mode. Complex layout-injected components (related books, backlinks, card grids, book lists) get simplified text representations or pass through as HTML — Phase 3 upgrades them to proper Markdown renderers. Pages whose body is entirely generated content (author pages, book overview pages) will have `.md` files with just a header until Phase 3 fills in the body.

**Depends on**: Phase 1 (link resolver `resolve_data()` methods).

## Current State Analysis

After Phase 1, the 4 link resolvers expose `resolve_data()` returning structured hashes. The current build pipeline produces only HTML. There is no mechanism for generating alternate output formats.

### Key Discoveries:
- `_includes/head.html:30-34` — already has RSS `{% feed_meta %}` and `{% seo %}` tags; Markdown alternate link goes here
- `_layouts/post.html` — injects title, date, categories, lead image, `{% related_posts %}` around `{{ content }}`
- `_layouts/book.html` — injects title, cover, authors (`{% display_authors %}`), series (`{% series_text %}`), awards, rating (`{% rating_stars %}`), backlinks (`{% book_backlinks %}`), previous reviews (`{% display_previous_reviews %}`), related books (`{% related_books %}`)
- `_includes/figure.html` — 11 lines, receives params via `include`, generates `<figure>` HTML
- Jekyll converts any `.md` PageWithoutAFile through Kramdown → must use `GeneratedStaticFile` to bypass
- `:pre_render` hook fires after Liquid context is built but before Kramdown — natural intercept point
- Jekyll requires separate hooks for `:documents` (collection items) vs `:pages` (standalone files)
- Prior POC: build overhead was ~1s (6-7s → 7-8s), not a concern

### Full Page Inventory (~400 pages total):
- **Collection documents**: ~90 blog posts + ~170 book reviews (body has inline Liquid tags)
- **Author pages (69)**: layout-generated book lists, empty body
- **Series pages (29)**: layout-generated book lists, empty body
- **Category pages (23 + index)**: short body paragraph + layout-generated post lists
- **Book overview pages (6)**: layout-generated book lists, empty body (`/books/`, `/books/by-author/`, etc.)
- **Root pages (~5)**: static Markdown body (`papers.md`, `resume.md`, `linktree.md`, etc.)
- **Supplementary pages (6)**: static Markdown body (`files/sat2vec/results.md`, etc.)
- **Blog index (1)**: paginated post listing
- **Excluded**: `404.md`, `test.md`

## Desired End State

After `make build`, every HTML page on the site has a `.md` counterpart (except 404):

| Page Type | Count | `.md` Content in Phase 2 |
|-----------|-------|--------------------------|
| Blog posts | ~90 | Header + full Markdown body (inline tags rendered as Markdown) |
| Book reviews | ~170 | Header + full Markdown body (inline tags rendered as Markdown) |
| Author pages | 69 | Header only (body is 100% layout-generated; Phase 3 fills in) |
| Series pages | 29 | Header only (body is 100% layout-generated; Phase 3 fills in) |
| Category pages | 23 + index | Header + body paragraph (generated post lists pass through as HTML or are omitted; Phase 3 fills in) |
| Book overview pages | 6 | Header only (body is 100% layout-generated; Phase 3 fills in) |
| Root pages (papers, resume, linktree, etc.) | ~5 | Header + full Markdown body |
| Supplementary pages (files/) | 6 | Header + full Markdown body |
| Blog index (paginated) | 1 | Header only (paginator content omitted) |

Specifically:
- Every HTML page's `<head>` contains `<link rel="alternate" type="text/markdown; charset=UTF-8" ...>`
- `.md` files contain: title header, Markdown body (where available), normalized whitespace
- Pages with body content that uses only Phase-2-aware tags get clean Markdown
- Pages with body content that uses Phase-3 tags (display_books_by_year, etc.) get HTML pass-through in their `.md` body until Phase 3

### Excluded (via `markdown_output: false` in front matter):
- `404.md` — error page, no value as Markdown
- `test.md` — development page
- Any future page can opt out the same way

### Verification:
- `make build` produces `.md` files in `_site/`
- `make test` passes (all existing + new tests)
- Blog post and book review `.md` files are valid Markdown (body content is the original Markdown, not HTML)
- Inline `{% book_link %}` tags in body appear as `[Title](/url/)` not `<a href>` in the `.md` output
- Author/series pages have `.md` files (even if minimal)

## What We're NOT Doing

- **No Markdown renderers for cards, grids, or lists** — complex layout components either pass through as HTML or are omitted (Phase 3 replaces them with proper Markdown)
- **No `llms.txt`** — needs `.md` files to exist first (Phase 3)
- **No build performance optimization** — ~1s overhead is acceptable
- **No Markdown mode for layout-only tags** — tags like `{% display_books_by_year %}`, `{% display_books_by_author %}`, `{% front_page_feed %}`, and `{% related_posts %}` are NOT modified in Phase 2. They output HTML as usual. Pages that use these tags in their body will have HTML in their `.md` files until Phase 3.

## Design Decisions

### 1. Double Liquid Rendering and Side Effects

The hook re-renders each document's body through Liquid a second time (once for HTML, once for Markdown). This means every inline tag fires twice per document. Most tags are pure (no side effects), but `BookLinkResolver.resolve_data()` calls `track_unreviewed_mention()` which writes to `site.data['mention_tracker']`.

**Mitigation**: Resolvers that have side effects check `context.registers[:render_mode]` and skip side effects in Markdown mode. Specifically, `BookLinkResolver.resolve_data()` guards `track_unreviewed_mention()`:

```ruby
track_unreviewed_mention(site, book_title) unless context.registers[:render_mode] == :markdown
```

This is a Phase 1 concern — the guard has been added to the Phase 1 plan's "Design Decisions: track_unreviewed_mention()" section.

Other side-effect audit results:
- `AuthorLinkResolver`: No side effects. Safe.
- `SeriesLinkResolver`: No side effects. Safe.
- `ShortStoryResolver`: No side effects. Safe.
- `RatingStarsTag`, `UnitsTag`: No side effects. Safe.
- `CitedquoteTag`: No side effects (reads from site data, never writes). Safe.

### 2. Shared Markdown Link Formatter

Instead of duplicating `render_markdown_link(data)` as a private method in each of the 4 link tags, extract it into a shared module:

**File**: `_plugins/src/content/markdown_output/markdown_link_formatter.rb` (new)

```ruby
module MarkdownLinkFormatter
  def self.format_link(data)
    text = data[:display_text] || ''
    return text if data[:status] != :found || data[:url].nil?
    "[#{text}](#{data[:url]})"
  end
end
```

All 4 link tags (`book_link`, `author_link`, `series_link`, `short_story_link`) call `MarkdownLinkFormatter.format_link(data)`. Possessive handling for `author_link` appends `'s` after the closing parenthesis: `[Author Name](/url/)'s`.

### 3. Citedquote Markdown: Strip-and-Reformat Approach

`CitationUtils.format_citation_html()` handles 15+ fields with ~10 generators and complex conditional logic. Writing a parallel Markdown-native method would be the largest single task in Phase 2.

Instead, Phase 2 reuses the HTML method and converts the output:

```ruby
def self.format_citation_text(params, site)
  html = format_citation_html(params, site)
  text = html.gsub(/<cite>([^<]+)<\/cite>/, '*\1*')                     # <cite> → *italic*
  text = text.gsub(/<a href="([^"]+)">([^<]+)<\/a>/, '[\2](\1)')        # links → [text](url)
  text.gsub(/<[^>]+>/, '')                                               # strip remaining tags
end
```

This is accurate for all 15+ fields with ~3 lines, because it leverages the existing logic. Quoted container titles (`"Title"`), author names, dates, page numbers, and punctuation are already plain text in the HTML output and survive the strip. Phase 3 can replace this with a Markdown-native method if needed, but the strip approach is lossy in formatting only, not in content.

**Tech debt note**: This regex approach silently breaks if `format_citation_html()` changes its output structure (e.g., adding nested tags, changing attribute formats). Acceptable for Phase 2, but flag for replacement with a Markdown-native method in Phase 3 if citation format evolves.

The citedquote Markdown output:
```markdown
> Quote content here
>
> --- Author Last, First. *Work Title*. Publisher, Date.
```

The `---` (em dash) attribution prefix and the full citation follow the same field ordering as the HTML version.

### 4. Error Isolation

The Markdown pipeline must never break the HTML build. If a tag fails during Markdown-mode re-rendering, the error is caught per-document: `markdown_body` is cleared, the `.md` file is skipped, and the `<link rel="alternate">` doesn't appear. A warning is logged. The HTML build continues unaffected.

This matters because `resolve_data()` can raise `FatalException` for ambiguous books, and Liquid `render!` raises on template errors. These are normal build errors during HTML rendering, but during the Markdown re-render they should be non-fatal warnings.

### 5. Site-Wide Disable for Development

`enable_markdown_output: false` in `_config.yml` disables the entire Markdown pipeline. Default is `true`. Checked by both hooks and the assembler.

Use cases:
- **Debugging**: If the Markdown pipeline breaks the build, flip one switch to isolate the problem
- **`make serve`**: During development, every file save triggers double Liquid rendering for ~400 pages. Set `enable_markdown_output: false` in a `_config_dev.yml` override to skip the pipeline and keep the feedback loop fast

## Implementation Approach

Two parallel systems work together:

1. **Inline tag Markdown mode** — Tags check `context.registers[:render_mode]` and call `resolve_data()` + format as Markdown via `MarkdownLinkFormatter` instead of calling `resolve()` for HTML.

2. **Hook pipeline** — Two `:pre_render` hooks (one for `:documents`, one for `:pages`) re-render each item's body through Liquid with `:render_mode => :markdown`, capturing the Markdown-mode output. A `:site, :post_render` hook assembles the final `.md` file (header + body + layout-equivalent sections) and writes it via `GeneratedStaticFile`.

---

## Step 1: GeneratedStaticFile Infrastructure

### Overview
Create the `GeneratedStaticFile` subclass that writes generated content to `_site/` without Jekyll re-processing it through Kramdown.

### Changes Required:

#### 1. New file: GeneratedStaticFile
**File**: `_plugins/src/infrastructure/generated_static_file.rb`

```ruby
# Subclass of Jekyll::StaticFile that writes generated content
# instead of copying a source file. Used for Markdown output files
# that must bypass Jekyll's Markdown-to-HTML conversion pipeline.
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

#### 2. New test file
**File**: `_tests/src/infrastructure/test_generated_static_file.rb`

Test cases:
- `test_write_creates_file_with_content` — writes to a temp dir, reads back, asserts content matches
- `test_write_creates_parent_directories` — writes to nested path, verifies dirs created
- `test_write_returns_true` — confirms successful write return

### Success Criteria:

#### Automated Verification:
- [ ] `make test TEST=_tests/src/infrastructure/test_generated_static_file.rb`

---

## Step 2: Inline Tag Markdown Mode

### Overview
Each inline Liquid tag that appears in post/book body content gets a `render_mode` check. In Markdown mode, it uses `resolve_data()` (from Phase 1) to get structured data, then formats it as Markdown text instead of HTML.

### Tags to modify (7 tags + 1 include):

#### 1. `book_link` tag
**File**: `_plugins/src/content/books/tags/book_link_tag.rb`

In `render(context)`, check `context.registers[:render_mode]`:
```ruby
def render(context)
  book_title = TagArgs.resolve_value(@title_markup, context)
  link_text_override = ...
  author_filter = ...
  cite_arg = cite_enabled?(context)

  if context.registers[:render_mode] == :markdown
    data = Linker.find_book_link_data(book_title, context, link_text_override, author_filter, nil, cite: cite_arg)
    MarkdownLinkFormatter.format_link(data)
  else
    Linker.render_book_link(book_title, context, link_text_override, author_filter, nil, cite: cite_arg)
  end
end
```

#### 2. `author_link` tag
**File**: `_plugins/src/content/authors/tags/author_link_tag.rb`

Same pattern — calls `MarkdownLinkFormatter.format_link(data)`. Possessive appends `'s` after the link: `[Author Name](/authors/slug/)'s`.

#### 3. `series_link` tag
**File**: `_plugins/src/content/series/tags/series_link_tag.rb`

Markdown output: `[Series Name](/books/series/slug/)`

#### 4. `short_story_link` tag
**File**: `_plugins/src/content/short_stories/tags/short_story_link_tag.rb`

Markdown output: `[Story Title](/books/slug/#anchor)`

#### 5. `rating_stars` tag
**File**: `_plugins/src/ui/tags/rating_stars_tag.rb`

Markdown output: Unicode stars only, no HTML wrapper. E.g., `rating_stars 4` → `★★★★☆`

The `RatingUtils` module already generates the star characters; the tag just needs to skip the `<div>` wrapper in Markdown mode.

#### 6. `citedquote` tag (block tag)
**File**: `_plugins/src/ui/tags/citedquote_tag.rb`

Markdown output: Blockquote with full plain-text citation. Calls `CitationUtils.format_citation_text()` (new method, see Design Decision #3) which handles the same 15+ fields as the HTML version.

```markdown
> Quote content here
>
> --- Author Last, First. *Work Title*. Publisher, Date.
```

**Implementation**:
1. Add `CitationUtils.format_citation_text(params, site)` — reuses `format_citation_html()` and converts the output (see Design Decision #3). ~3 lines of regex substitution.
2. In `citedquote_tag.rb`, when `render_mode == :markdown`, prefix each content line with `> `, append blank `>` line, then `> --- #{CitationUtils.format_citation_text(params, site)}`.
3. Test file for `CitationUtils` gets new tests for `format_citation_text()` covering: simple author+work, work with `<cite>` → `*italic*`, DOI link → Markdown link, full citation with all fields populated.

**File also modified**: `_plugins/src/ui/citations/citation_utils.rb` (add `format_citation_text()`)

#### 7. `units` tag
**File**: `_plugins/src/ui/tags/units_tag.rb`

Markdown output: Plain text with unit symbol. E.g., `{% units number=100 unit="F" %}` → `100 °F` (with a regular space, no `<abbr>` or `<span>`).

#### 8. `figure.html` include
**File**: `_includes/figure.html`

Add `render_mode` check at top:
```liquid
{% if render_mode == "markdown" %}
![{{ include.image_alt | default: "A figure with a caption" }}]({{ include.url }})
{% else %}
{# existing <figure> HTML #}
{% endif %}
```

Liquid includes access payload variables (top-level scope) directly — they just can't access `context.registers`. The hook already injects `render_mode: "markdown"` into the Liquid payload (see Step 3), which makes it available inside includes as the variable `render_mode`. This is the same mechanism that makes `page`, `site`, and other payload variables work inside includes. No special handling needed.

### Testing approach:

Each tag gets new test cases in its existing test file:
- `test_render_markdown_mode_found` — returns `[text](url)` format
- `test_render_markdown_mode_not_found` — returns plain text (no link)
- Tests use `create_context({}, { site: @site, page: @page, render_mode: :markdown })`

Estimated: ~2-3 new test cases per tag, ~20 total across 7 tag test files.

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `make test`

---

## Step 3: Markdown Body Rendering via Hooks

### Overview
Register hooks for both `:documents` and `:pages` that re-render each item's body through Liquid with `:render_mode => :markdown`. Store the result in `data['markdown_body']` for the assembler to consume.

Jekyll requires separate hooks because documents (collection items) and pages (standalone `.md`/`.html` files) are different types:
- `:documents, :pre_render` — fires for posts, books (collection documents)
- `:pages, :pre_render` — fires for author pages, series pages, category pages, book overview pages, root pages, supplementary pages, blog index, etc.

### Changes Required:

#### 1. Hook registration
**File**: `_plugins/src/content/markdown_output/markdown_body_hook.rb` (new)

```ruby
module MarkdownBodyHook
  def self.render_markdown_body(content, path, site, payload)
    template = site.liquid_renderer.file(path).parse(content)
    info = {
      registers: {
        site: site,
        page: payload['page'],
        render_mode: :markdown
      },
      strict_filters: site.config.dig("liquid", "strict_filters"),
      strict_variables: site.config.dig("liquid", "strict_variables"),
    }

    # Inject render_mode into payload for includes (which can't access registers)
    payload_with_mode = payload.merge('render_mode' => 'markdown')
    template.render!(payload_with_mode, info)
  end

  def self.enabled?(site)
    site.config.fetch('enable_markdown_output', true)
  end

  # Both documents and pages use the same opt-out field.
  # Structural checks (layout, extension) only apply to pages
  # because collection membership already filters documents.
  def self.eligible?(item)
    return false if item.data['markdown_output'] == false
    true
  end

  def self.eligible_document?(doc)
    return false unless doc.respond_to?(:collection)
    return false unless %w[posts books].include?(doc.collection&.label)
    eligible?(doc)
  end

  def self.eligible_page?(page)
    return false unless eligible?(page)
    return false unless page.data['layout']  # Skip layoutless files (feeds, sitemaps)
    return false if page.ext && !['.html', '.md'].include?(page.ext)  # Skip .xml, .json
    true
  end

  def self.compute_markdown_href(item)
    url = item.url
    dir = url.end_with?('/') ? url : "#{File.dirname(url)}/"
    "#{dir}index.md"
  end
end

# Hook for collection documents (posts, books)
Jekyll::Hooks.register :documents, :pre_render do |doc, payload|
  next unless MarkdownBodyHook.enabled?(doc.site)
  next unless MarkdownBodyHook.eligible_document?(doc)
  begin
    doc.data['markdown_body'] = MarkdownBodyHook.render_markdown_body(
      doc.content, doc.path, doc.site, payload
    )
    doc.data['markdown_alternate_href'] = MarkdownBodyHook.compute_markdown_href(doc)
  rescue => e
    Jekyll.logger.warn "MarkdownOutput:", "Failed for #{doc.url}: #{e.message}"
    doc.data.delete('markdown_body')
    doc.data.delete('markdown_alternate_href')
  end
end

# Hook for standalone pages (author, series, category, root pages, etc.)
Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  next unless MarkdownBodyHook.enabled?(page.site)
  next unless MarkdownBodyHook.eligible_page?(page)
  begin
    page.data['markdown_body'] = MarkdownBodyHook.render_markdown_body(
      page.content, page.path, page.site, payload
    )
    page.data['markdown_alternate_href'] = MarkdownBodyHook.compute_markdown_href(page)
  rescue => e
    Jekyll.logger.warn "MarkdownOutput:", "Failed for #{page.url}: #{e.message}"
    page.data.delete('markdown_body')
    page.data.delete('markdown_alternate_href')
  end
end
```

**Per-page opt-out**: Pages opt out by adding `markdown_output: false` to their front matter. No hardcoded filename lists in plugin code. The decision lives with the content. Site-wide disable via `enable_markdown_output: false` in `_config.yml` — see Design Decision #5.

Pages to mark with `markdown_output: false`:
- `404.md`
- `test.md`

**Structural checks** (no layout, non-HTML extension) remain in code because they reflect what *kind* of file it is, not a content decision. A `.xml` feed or a layoutless file structurally can't produce meaningful Markdown output.

**Implementation note on `page.data['layout']`**: Jekyll applies `_config.yml` defaults during the read phase, before rendering hooks fire. So `page.data['layout']` should have the default value by the time `:pre_render` runs. Verify during implementation with a quick test on a page that relies on default layout.

The `:pre_render` hook is the right intercept because:
- The Liquid context (payload) is real, built by Jekyll
- We re-render the body with `:render_mode => :markdown` in the registers
- The result is stored in `data` for the assembler to read later (in `:site, :post_render`)

**Note about pages with generated content**: Author pages, series pages, and book overview pages have body content that consists of layout-injected Liquid tags (e.g., `{% display_books_by_author %}`). These tags are NOT modified in Phase 2, so they output HTML in the Markdown re-render. That's acceptable — the `.md` file will have HTML in the body until Phase 3 adds Markdown mode to those tags. Pages with completely empty body content (no Liquid tags at all) will have an empty `markdown_body` string.

**Note about the blog index**: `blog/index.html` uses Jekyll's paginator (`paginator.posts`, `paginator.total_pages`). The paginator context is populated by Jekyll's pagination generator and IS available in the `:pre_render` payload. However, the paginated content is a list of HTML post previews — it will pass through as HTML in the `.md` file. Phase 3 can replace this.

#### 2. Test file
**File**: `_tests/src/content/markdown_output/test_markdown_body_hook.rb` (new)

Test cases:
- `test_enabled_by_default` — `enabled?` returns true when config key absent
- `test_disabled_via_config` — `enabled?` returns false when `enable_markdown_output: false`
- `test_eligible_document_posts` — posts are eligible
- `test_eligible_document_books` — books are eligible
- `test_eligible_document_other_collection` — non-post/book collections are not eligible
- `test_eligible_document_opt_out` — document with `markdown_output: false` is excluded
- `test_eligible_page_author_page` — author pages are eligible
- `test_eligible_page_category_page` — category pages are eligible
- `test_eligible_page_root_page` — pages like papers.md are eligible
- `test_excluded_page_opt_out` — page with `markdown_output: false` is excluded
- `test_excluded_page_no_layout` — pages without a layout (feeds, sitemaps) are excluded
- `test_excluded_page_non_html_ext` — `.xml` and `.json` pages are excluded
- `test_compute_markdown_href_trailing_slash` — `/papers/` → `/papers/index.md`
- `test_compute_markdown_href_no_trailing_slash` — `/resume` → `/resume/index.md`

Hook integration testing is harder in isolation; the full pipeline is verified by the build test in Step 6.

### Success Criteria:

#### Automated Verification:
- [ ] `make test`

---

## Step 4: MarkdownOutputAssembler

### Overview
A `:site, :post_render` hook that assembles final `.md` files for every eligible document and page. It reads `data['markdown_body']` (set by the `:pre_render` hooks in Step 3), prepends a metadata header, appends simplified layout-equivalent content where applicable, normalizes whitespace, and creates `GeneratedStaticFile` entries.

**Why not a Generator?** Jekyll Generators run during the generate phase, *before* rendering hooks fire. A Generator would run before `markdown_body` is set by the `:pre_render` hooks. The `:site, :post_render` hook fires after all documents and pages have been rendered, so all `markdown_body` values are available. It fires before the write phase, so adding to `site.static_files` still works.

### Changes Required:

#### 1. Assembler
**File**: `_plugins/src/content/markdown_output/markdown_output_assembler.rb` (new)

```ruby
module MarkdownOutputAssembler
  def self.assemble_all(site)
    return unless MarkdownBodyHook.enabled?(site)

    # Collection documents
    process_items(site, site.posts.docs)
    process_items(site, site.collections['books']&.docs || [])

    # Standalone pages
    process_items(site, site.pages)
  end

  def self.process_items(site, items)
    items.each do |item|
      next unless item.data['markdown_body']
      md_content = assemble_markdown(site, item)
      add_static_file(site, item, md_content)
    end
  end

  def self.assemble_markdown(site, item)
    sections = []
    sections << build_header(item)
    sections << item.data['markdown_body']
    sections << build_layout_equivalent(site, item)
    raw = sections.compact.reject(&:empty?).join("\n\n")
    MarkdownWhitespaceNormalizer.normalize(raw)
  end

  def self.build_header(item)
    layout = item.data['layout']
    case layout
    when 'post'         then build_post_header(item)
    when 'book'         then build_book_header(item)
    when 'author_page'  then build_author_header(item)
    when 'series_page'  then build_series_header(item)
    when 'category'     then build_category_header(item)
    else                     build_generic_header(item)
    end
  end

  def self.build_layout_equivalent(site, item)
    # Simplified text for layout-injected sections
    # Phase 2: basic text representations or omitted
    # Phase 3: full Markdown renderers for Tiers 2-3
  end

  def self.add_static_file(site, item, content)
    href = item.data['markdown_alternate_href']
    dir = File.dirname(href)
    name = File.basename(href)
    file = GeneratedStaticFile.new(site, dir, name, content)
    site.static_files << file
  end
end

# Hook: runs after all documents/pages have been rendered
Jekyll::Hooks.register :site, :post_render do |site|
  MarkdownOutputAssembler.assemble_all(site)
end
```

**Phase 3 extension point**: `build_layout_equivalent()` is where Phase 3 Tiers 2-3 add Markdown for layout-injected sections (related books, backlinks, previous reviews, related posts). These sections don't appear in the document body — they're injected by the layout — so the `:pre_render` hook can't capture them. The assembler calls Finders directly. Note: verify during Phase 3 implementation that Finders only need `site` and item data (not a full `Liquid::Context`). If they need Liquid context, collect the data during `:pre_render` instead.

#### 2. Header builders

Headers are built from `data` (front matter), not from HTML. The header format varies by layout.

For a **blog post** (`layout: post`):
```markdown
# Post Title

*February 13, 2026* | #category1, #category2
```

For a **book review** (`layout: book`):
```markdown
# Book Title

by Author One and Author Two
Book 3 of Series Name
★★★★☆

## Review
```

For an **author page** (`layout: author_page`):
```markdown
# Author Name
```

For a **series page** (`layout: series_page`):
```markdown
# Series Name
```

For a **category page** (`layout: category`):
```markdown
# Category Title
```

For **generic pages** (`layout: page`, `page-not-on-sidebar`, `resume`, `default`):
```markdown
# Page Title
```

Author names in book headers are plain text (no links — the Markdown body handles inline author links where they appear).

#### 3. Layout-equivalent content (simplified for Phase 2)

For **blog posts** (`post.html` injects `{% related_posts %}`):
- Phase 2: Omit. Phase 3 adds Markdown related posts.

For **book reviews** (`book.html` injects backlinks, previous reviews, related books):
- Phase 2: Omit. Phase 3 adds Markdown sections.

For **author/series/book overview/category pages** (body is layout-generated lists):
- Phase 2: The body content from the hook may contain HTML from unmodified tags. That's expected. Phase 3 adds Markdown mode to those tags.

For **root/supplementary pages** (papers, resume, linktree, files/*):
- Phase 2: No layout-equivalent needed — body content is already Markdown source with few/no Liquid tags.

#### 4. Whitespace normalizer
**File**: `_plugins/src/infrastructure/markdown_whitespace_normalizer.rb` (new)

```ruby
module MarkdownWhitespaceNormalizer
  def self.normalize(content)
    content
      .gsub(/[ \t]+$/, '')       # Remove trailing whitespace per line
      .gsub(/\n{3,}/, "\n\n")    # Collapse 3+ blank lines to 1
      .gsub(/\A\n+/, '')         # Remove leading blank lines
      .gsub(/\n+\z/, "\n")       # Single trailing newline
  end
end
```

No code block protection. The normalizer applies uniformly. Its operations (collapse triple-blank-lines, trim trailing whitespace) are almost never harmful inside code blocks — legitimate code blocks rarely have 3+ consecutive blank lines. The regex-based protection approach has an edge case with nested fences (a programming blog that demonstrates Markdown syntax), which is worse than the negligible risk of normalizing inside code blocks. If a real problem surfaces, upgrade to a line-by-line scanner that tracks fence state sequentially.

#### 5. Test files

**File**: `_tests/src/content/markdown_output/test_markdown_output_assembler.rb` (new)

Test cases:
- `test_generates_md_file_for_post` — creates static file with correct path
- `test_generates_md_file_for_book` — creates static file with correct path
- `test_generates_md_file_for_page` — creates static file for a standalone page
- `test_skips_items_without_markdown_body` — no static file when hook didn't run
- `test_header_post_includes_title_and_date` — post header format
- `test_header_book_includes_authors_and_rating` — book header format
- `test_header_author_page` — author page header (just title)
- `test_header_series_page` — series page header (just title)
- `test_header_generic_page` — generic page header (just title)
- `test_body_content_preserved` — Markdown body from hook is present in output
- `test_output_path_for_trailing_slash_url` — `/papers/` → `/papers/index.md`

**File**: `_tests/src/infrastructure/test_markdown_whitespace_normalizer.rb` (new)

Test cases:
- `test_collapses_triple_blank_lines`
- `test_removes_trailing_whitespace`
- `test_single_trailing_newline`
- `test_removes_leading_blank_lines`
- `test_preserves_double_blank_lines` — two blank lines (one empty line) are not collapsed

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `make test`

---

## Step 5: HTML `<link rel="alternate">` Tag

### Overview
Add a `<link rel="alternate" type="text/markdown">` tag to the HTML `<head>` for pages that have a Markdown counterpart.

### Changes Required:

#### 1. Head include
**File**: `_includes/head.html`

Add after the RSS/SEO section (around line 34):
```liquid
{% comment %} Markdown alternate for LLM/agent consumption {% endcomment %}
{% if page.markdown_alternate_href %}
  <link rel="alternate"
        type="text/markdown; charset=UTF-8"
        href="{{ page.markdown_alternate_href | absolute_url }}"
        title="Markdown version">
{% endif %}
```

The hook computes `markdown_alternate_href` in Ruby (via `MarkdownBodyHook.compute_markdown_href`) and stores it in `page.data`. This avoids string manipulation in Liquid and guarantees the path matches what the assembler actually writes — single source of truth for the trailing-slash logic.

**Ordering**: The hook runs at `:pre_render`, which fires before the layout is applied. The `markdown_alternate_href` key is set in `page.data` before `head.html` is rendered as part of the layout chain.

### Success Criteria:

#### Automated Verification:
- [ ] `make build` succeeds
- [ ] Spot check: `grep -l 'rel="alternate".*text/markdown' _site/blog/*/index.html | head -5` returns results

---

## Step 6: Integration & Build Verification

### Overview
End-to-end verification that the full pipeline works.

### Changes Required:

#### 1. Require new files in test_helper.rb
**File**: `_tests/test_helper.rb`

Add requires for:
- `src/infrastructure/generated_static_file`
- `src/infrastructure/markdown_whitespace_normalizer`
- `src/content/markdown_output/markdown_link_formatter`
- `src/content/markdown_output/markdown_body_hook`
- `src/content/markdown_output/markdown_output_assembler`

#### 2. Build verification test (optional)
**File**: `_tests/src/content/markdown_output/test_build_integration.rb` (new, optional)

A heavier integration test that runs a minimal Jekyll build and verifies `.md` output files exist. This may be too slow for the unit test suite — if so, verify via `make build` instead.

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `make test`
- [ ] Lint passes: `make lint`
- [ ] Build succeeds: `make build`
- [ ] Blog post `.md` files exist: `ls _site/blog/*/index.md | head -5`
- [ ] Book review `.md` files exist: `ls _site/books/*/index.md | head -5`
- [ ] Author page `.md` files exist: `ls _site/books/authors/*/index.md | head -5`
- [ ] Series page `.md` files exist: `ls _site/books/series/*/index.md | head -5`
- [ ] Root page `.md` files exist: `ls _site/papers/index.md`
- [ ] `.md` files contain Markdown links (not HTML): `grep -l '\[.*\](/' _site/blog/*/index.md | head -3`
- [ ] HTML pages have alternate link: `grep 'text/markdown' _site/blog/*/index.html | head -3`
- [ ] Non-collection pages have alternate link: `grep 'text/markdown' _site/papers/index.html`
- [ ] 404 page does NOT have alternate link: `! grep 'text/markdown' _site/404.html`

---

## Files Changed Summary

| File | Change | New? |
|---|---|---|
| `_plugins/src/infrastructure/generated_static_file.rb` | GeneratedStaticFile class | Yes |
| `_plugins/src/infrastructure/markdown_whitespace_normalizer.rb` | Whitespace normalizer | Yes |
| `_plugins/src/content/markdown_output/markdown_body_hook.rb` | :pre_render hooks | Yes |
| `_plugins/src/content/markdown_output/markdown_output_assembler.rb` | :site, :post_render assembler | Yes |
| `_plugins/src/content/markdown_output/markdown_link_formatter.rb` | Shared link formatter | Yes |
| `_plugins/src/content/books/tags/book_link_tag.rb` | Add render_mode check | No |
| `_plugins/src/content/authors/tags/author_link_tag.rb` | Add render_mode check | No |
| `_plugins/src/content/series/tags/series_link_tag.rb` | Add render_mode check | No |
| `_plugins/src/content/short_stories/tags/short_story_link_tag.rb` | Add render_mode check | No |
| `_plugins/src/ui/tags/rating_stars_tag.rb` | Add render_mode check | No |
| `_plugins/src/ui/tags/citedquote_tag.rb` | Add render_mode check | No |
| `_plugins/src/ui/tags/units_tag.rb` | Add render_mode check | No |
| `_plugins/src/ui/citations/citation_utils.rb` | Add `format_citation_text()` | No |
| `_includes/figure.html` | Add render_mode check | No |
| `_includes/head.html` | Add `<link rel="alternate">` | No |
| `_tests/test_helper.rb` | Require new files | No |
| `_tests/src/infrastructure/test_generated_static_file.rb` | Tests | Yes |
| `_tests/src/infrastructure/test_markdown_whitespace_normalizer.rb` | Tests | Yes |
| `_tests/src/content/markdown_output/test_markdown_body_hook.rb` | Tests | Yes |
| `_tests/src/content/markdown_output/test_markdown_output_assembler.rb` | Tests | Yes |
| `_tests/src/content/markdown_output/test_markdown_link_formatter.rb` | Tests | Yes |
| **7 existing tag test files** | Add render_mode tests (~2-3 each) | No |
| **1 existing citation test file** | Add `format_citation_text()` tests | No |
| **Total** | **~28 files (7 new plugin files, 5 new test files, ~16 modified)** | |

**Output**: `.md` files for ~400 pages (every HTML page except 404 and test).

---

## Performance Budget

Phase 2 adds at most **2 seconds** to the build (current baseline ~7s):
- Double Liquid render: ~400 pages × ~2ms per render = ~0.8s
- Assembly + whitespace normalization: ~400 pages × ~0.5ms = ~0.2s
- File writing via GeneratedStaticFile: ~400 files × ~0.5ms = ~0.2s
- Overhead margin: ~0.8s

Measure after implementation. If overhead exceeds 2s, profile before proceeding to Phase 3.

Phase 3 budget: at most **5 additional seconds** (for ~700 Finder calls across Tiers 2-5).
Total target: under **15 seconds** for a full build.

---

## Implementation Verification: Sitemap

Verify that `jekyll-sitemap` (or equivalent) does **not** include `.md` files in `sitemap.xml`. The `.md` files are added as `GeneratedStaticFile` objects to `site.static_files`. `jekyll-sitemap` typically generates from `site.pages` and `site.posts.docs`, not `site.static_files`, so this should be safe — but verify during implementation. If `.md` files appear in the sitemap, either configure the sitemap plugin to exclude `.md` extensions or override `GeneratedStaticFile#url`.

---

## Closed Design Decisions

1. **Header format**: Plain Markdown headers (no YAML front matter). The audience is LLMs consuming prose, not machines parsing structured metadata. A `# Title` with descriptive text is cleaner and more natural than front matter.

2. **URL format in Markdown links**: Relative URLs in body content (`/blog/slug/`). Matches HTML behavior, simpler, works regardless of domain. Absolute URLs only in `llms.txt` (required by the llms.txt specification) and in `<link rel="alternate">` in HTML (via `absolute_url` filter).

## Development Rule: `render_mode` for New Tags

Any Liquid tag that renders HTML **must** check `context.registers[:render_mode]` and provide a Markdown output path. This prevents new tags from silently injecting HTML into `.md` files.

Add this rule to `_plugins/README.md` as part of Phase 2 implementation. The Phase 3 final verification includes a grep-based lint for HTML in `.md` output — consider promoting this to a permanent CI check after Phase 3.

## References

- Research: `thoughts/shared/research/2026-02-13-rendering-pipeline-dual-output.md`
- Phase 1 plan: `thoughts/shared/plans/2026-02-13-phase1-decouple-link-resolvers.md`
- Jekyll Hooks: https://jekyllrb.com/docs/plugins/hooks/
- Jekyll Generators: https://jekyllrb.com/docs/plugins/generators/ (for background; Phase 2 uses hooks, not generators)
- RFC 7763 (text/markdown): https://datatracker.ietf.org/doc/rfc7763/
