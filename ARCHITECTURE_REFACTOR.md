# Architecture Refactor: Data-First Rendering

## Problem

The current architecture has format decisions (HTML vs markdown) scattered throughout the codebase. Each component independently checks `markdown_mode?` and decides how to render itself. This causes problems:

1. **Mixed output** - A book card (HTML) contains author links that check `markdown_mode?` and return markdown, resulting in markdown links inside HTML structures.

2. **Doesn't scale** - Every new component needs markdown awareness. We're patching issues with `force_html` flags.

3. **Tight coupling** - Rendering logic is embedded in each component rather than being a separate concern.

## Current Architecture

### Layer Responsibilities

| Layer | Responsibility | Returns | Format Awareness |
|-------|----------------|---------|------------------|
| **Tags** | Parse Liquid syntax, delegate | Varies | None (thin wrappers) |
| **Utils** | Orchestrate logic flow, public API | Varies | Varies |
| **Finders** | Locate & extract data | Clean data (hashes, docs, arrays) | **None (data only)** |
| **Resolvers** | Find data + format immediately | Pre-formatted string | **HTML or Markdown** |
| **Renderers** | Format pre-fetched data | Pre-formatted string | **HTML only** |

### What Works Well

**Finders** return pure data:
```ruby
# BookFinder returns clean data
{ book: Jekyll::Document, error: nil }

# AllBooksFinder returns structured data
{ standalone_books: [...], series_groups: [...], log_messages: String }
```

**Renderers** accept data and produce HTML:
```ruby
# ByYearRenderer takes pre-fetched data
def initialize(context, data)
  @year_groups = data[:year_groups]  # Already-fetched, clean data
end
```

### The Problem: Resolvers

**Resolvers** mix data discovery + format decision:
```ruby
# AuthorLinkResolver.generate_html
def generate_html(display_text, author_data)
  url = author_data ? author_data['url'] : nil

  # Format decision embedded here
  if MarkdownLinkUtils.markdown_mode?(@context)
    return MarkdownLinkUtils.render_link(display_text, url)
  end

  # HTML output
  span = _build_author_span_element(display_text)
  LinkHelper._generate_link_html(@context, url, span)
end
```

This is fine for standalone links, but **breaks when Renderers call Resolvers**:

```ruby
# BookCardRenderer.authors_html - HTML renderer calling a format-aware resolver
def authors_html
  # BookCardRenderer produces HTML, but AuthorLinker checks markdown_mode?
  # Result: markdown links inside HTML structure
  links = names.map { |n| AuthorLinker.render_author_link(n, @context) }
  "<span class='by-author'> by #{links.join(', ')}</span>"
end
```

## Data Flow Examples

### Standalone Link (Works)
```
{% author_link "Dan Simmons" %}
  ↓
AuthorLinkTag → AuthorLinkUtils → AuthorLinkResolver
  ↓
Resolver checks markdown_mode? → outputs HTML or Markdown
  ↓
✓ Correct format for context
```

### Link Inside Card (Broken)
```
{% book_card_lookup "Endymion" %}
  ↓
BookCardLookupTag → BookFinder (returns data) → BookCardRenderer (HTML)
  ↓
BookCardRenderer calls AuthorLinker.render_author_link()
  ↓
AuthorLinkResolver checks markdown_mode? → outputs Markdown
  ↓
✗ Markdown link inside HTML card structure
```

## Proposed Solutions

### Option 1: Split Resolvers into Finder + Formatter

Separate data fetching from formatting:

```ruby
# AuthorLinkFinder - returns data only
class AuthorLinkFinder
  def find(name)
    { name: "Dan Simmons", url: "/authors/dan_simmons/", found: true }
  end
end

# AuthorLinkHtmlFormatter
class AuthorLinkHtmlFormatter
  def format(data)
    "<a href='#{data[:url]}'><span>#{data[:name]}</span></a>"
  end
end

# AuthorLinkMarkdownFormatter
class AuthorLinkMarkdownFormatter
  def format(data)
    "[#{data[:name]}](#{data[:url]})"
  end
end
```

**Pros:** Clean separation, testable, extensible
**Cons:** More files, more indirection for simple links

### Option 2: Renderers Pass Output Format Down

Parent components tell children what format to use:

```ruby
# BookCardRenderer always passes :html to children
def authors_html
  links = names.map { |n| AuthorLinker.render_author_link(n, @context, format: :html) }
end

# Standalone usage respects context
AuthorLinker.render_author_link(name, context)  # checks markdown_mode?
AuthorLinker.render_author_link(name, context, format: :html)  # forced HTML
```

**Pros:** Minimal changes, explicit control
**Cons:** Still mixing concerns, just with an override

### Option 3: Formatter Object in Context

Pass a formatter through context instead of a boolean flag:

```ruby
# In context.registers
context.registers[:formatter] = HtmlFormatter.new
# or
context.registers[:formatter] = MarkdownFormatter.new

# Components use the formatter
def generate_link(text, url)
  @context.registers[:formatter].link(text, url)
end
```

**Pros:** Polymorphic, clean interface
**Cons:** Requires updating all components to use formatter

### Option 4: Two-Phase Rendering for Cards

Cards produce intermediate data, then format in second phase:

```ruby
# Phase 1: Build card data (format-agnostic)
card_data = {
  title: "Endymion",
  url: "/books/endymion/",
  authors: [{ name: "Dan Simmons", url: "/authors/..." }],
  rating: 4
}

# Phase 2: Format to target
HtmlCardFormatter.format(card_data)      # Full HTML card
MarkdownCardFormatter.format(card_data)  # [*Endymion*](/...) by [Dan Simmons](/...)
```

**Pros:** Complete separation, cards can have proper markdown representation
**Cons:** Significant refactor of card rendering

## Implementation Plan: Option 1

Split Resolvers into Finder + Formatter. This fixes the issue globally and enables future extension.

### New Architecture

```
Tag → Util → Finder (returns data) → LinkFormatter.html() or .markdown()
```

### Step 1: Create LinkFormatter

A single formatter class with methods for each output format:

```ruby
# _plugins/src/infrastructure/links/link_formatter.rb
module Jekyll::Infrastructure::Links
  class LinkFormatter
    def self.html_link(text, url, wrapper: :span, css_class: nil)
      # Returns: <a href="url"><span class="css_class">text</span></a>
    end

    def self.markdown_link(text, url, italic: false)
      # Returns: [text](url) or [*text*](url)
    end

    def self.format_link(text, url, format:, **options)
      case format
      when :html then html_link(text, url, **options)
      when :markdown then markdown_link(text, url, **options)
      end
    end
  end
end
```

### Step 2: Convert Resolvers to Finders

Each Resolver splits into a Finder that returns data:

```ruby
# Before: AuthorLinkResolver
def resolve(name)
  author_data = find_author(name)
  generate_html(author_data)  # Mixes finding + formatting
end

# After: AuthorLinkFinder
def find(name)
  {
    found: true,
    name: "Dan Simmons",
    display_name: "Dan Simmons",  # Canonical or input
    url: "/authors/dan_simmons/",
    log_output: ""
  }
end
```

### Step 3: Update Utils

Utils call Finder, then choose formatter:

```ruby
# AuthorLinkUtils
def self.render_author_link(name, context, format: nil)
  data = AuthorLinkFinder.new(context).find(name)

  # Determine format from parameter or context
  format ||= MarkdownLinkUtils.markdown_mode?(context) ? :markdown : :html

  data[:log_output] + LinkFormatter.format_link(
    data[:display_name],
    data[:url],
    format: format,
    css_class: 'author-name'
  )
end
```

### Step 4: Update Renderers

Renderers explicitly request HTML format:

```ruby
# BookCardRenderer.authors_html
def authors_html
  links = names.map do |n|
    AuthorLinker.render_author_link(n, @context, format: :html)
  end
  # ...
end
```

### Step 5: Clean Up

- Remove `force_html:` parameter (replaced by `format:`)
- Remove markdown_mode checks from individual components
- Delete old Resolver files once Finders are working

### Files to Create

```
_plugins/src/infrastructure/links/link_formatter.rb   # New formatter
_plugins/src/content/authors/author_link_finder.rb    # From resolver
_plugins/src/content/books/core/book_link_finder.rb   # From resolver
_plugins/src/content/series/series_link_finder.rb     # From resolver
_plugins/src/content/short_stories/short_story_finder.rb  # From resolver
```

### Files to Modify

```
_plugins/src/content/authors/author_link_util.rb      # Use finder + formatter
_plugins/src/content/books/core/book_link_util.rb     # Use finder + formatter
_plugins/src/content/series/series_link_util.rb       # Use finder + formatter
_plugins/src/content/short_stories/short_story_title_util.rb  # Use finder + formatter
_plugins/src/content/books/core/book_card_renderer.rb # Use format: :html
```

### Files to Delete (after migration)

```
_plugins/src/content/authors/author_link_resolver.rb
_plugins/src/content/books/core/book_link_resolver.rb
_plugins/src/content/series/series_link_resolver.rb
_plugins/src/content/short_stories/short_story_resolver.rb
```

### Migration Order

1. ✅ Create `LinkFormatter` (no breaking changes)
2. ✅ Create `AuthorLinkFinder` alongside existing resolver
3. ✅ Update `AuthorLinkUtils` to use finder + formatter
4. ✅ Update tests
5. ⏳ Remove old resolver (can be done later)
6. ✅ Create `BookLinkFinder`, `SeriesLinkFinder`, `ShortStoryLinkFinder`
7. ✅ Update their respective utils to use finder + formatter
8. 🔲 Update renderers that call these utils to pass `format: :html`
9. 🔲 Eventually remove the old resolver classes

### Progress

**Completed:**
- `LinkFormatter` - unified formatting interface (16 tests)
- `AuthorLinkFinder` - data-only author lookup (16 tests)
- `AuthorLinkUtils` - now uses finder + formatter with `format:` parameter (11 tests)
- `BookCardRenderer` - updated to use `format: :html` instead of `force_html: true`
- `BookLinkFinder` - data-only book lookup with author/date filtering (18 tests)
- `BookLinkUtils` - now uses finder + formatter with `format:` parameter (21 tests)
- `SeriesLinkFinder` - data-only series lookup (11 tests)
- `SeriesLinkUtils` - now uses finder + formatter with `format:` parameter (12 tests)
- `ShortStoryLinkFinder` - data-only short story lookup with disambiguation (13 tests)
- `ShortStoryLinkUtils` - now uses finder + formatter with `format:` parameter (10 tests)

**Next Steps:**
- Update renderers that call book/series/story utils to pass `format: :html` explicitly
- Eventually remove the old resolver classes (AuthorLinkResolver, BookLinkResolver, SeriesLinkResolver, ShortStoryResolver)

## Files Affected

### Resolvers (mix data + format)
- `_plugins/src/content/authors/author_link_resolver.rb`
- `_plugins/src/content/books/core/book_link_resolver.rb`
- `_plugins/src/content/series/series_link_resolver.rb`
- `_plugins/src/content/short_stories/short_story_resolver.rb`

### Renderers (HTML only, call Resolvers)
- `_plugins/src/content/books/core/book_card_renderer.rb`
- `_plugins/src/content/books/lists/book_list_renderer_utils.rb`
- `_plugins/src/content/books/ranking/renderer.rb`
- `_plugins/src/content/books/reviews/renderer.rb`

### Finders (already clean)
- `_plugins/src/content/books/lookups/book_finder.rb`
- `_plugins/src/content/books/lists/all_books_finder.rb`
- `_plugins/src/content/books/ranking/finder.rb`
