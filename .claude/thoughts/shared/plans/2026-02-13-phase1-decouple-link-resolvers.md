# Phase 1: Decouple Link Resolvers — Implementation Plan

## Overview

Add a `resolve_data()` public method to each of the 4 link resolvers, returning structured data hashes instead of HTML. Refactor `resolve()` to call `resolve_data()` internally, proving the data contract is complete. Add corresponding `find_*_data()` convenience methods to each Utils module.

This is a standalone refactoring with immediate value (testability, data flow transparency) that also enables Phase 2 (Markdown output).

## Current State Analysis

The 4 link resolvers each have a single public method `resolve()` that combines data lookup with HTML rendering:

| Resolver | File | Lines | Seam Point |
|---|---|---|---|
| `AuthorLinkResolver` | `_plugins/src/content/authors/author_link_resolver.rb` | 83 | `generate_html()` line 71 |
| `SeriesLinkResolver` | `_plugins/src/content/series/series_link_resolver.rb` | 84 | `generate_html()` line 75 |
| `ShortStoryResolver` | `_plugins/src/content/short_stories/short_story_resolver.rb` | 140 | `render_html()` line 97 |
| `BookLinkResolver` | `_plugins/src/content/books/core/book_link_resolver.rb` | 221 | `render_result()` line 205 |

Each resolver is instantiated with a `Liquid::Context` and used once per call. Instance variables are set during resolution and consumed by the rendering step. The data/HTML boundary is clean in each case — private methods already separate "find data" from "build HTML".

### Key Discoveries:
- `find_author()` (line 53), `find_series()` (line 56), `find_target_location()` (line 53), `find_candidates()` (line 78) — data methods already isolated as private helpers
- `generate_html()` / `render_html()` / `render_result()` — HTML methods already isolated as private helpers
- Instance variables (`@log_output`, `@name_input`, `@possessive`, etc.) accumulate during resolution and are consumed by both data and HTML steps
- Resolvers are single-use (new instance per call), so shared instance variables are safe
- Utils modules (`AuthorLinkUtils`, `SeriesLinkUtils`, etc.) are thin one-line delegators

## Desired End State

Each resolver has two public methods:
- `resolve(...)` — returns HTML string (existing behavior, unchanged API)
- `resolve_data(...)` — returns a plain Ruby hash with resolution results

Each Utils module has two public methods:
- `render_*_link(...)` — returns HTML (existing, unchanged)
- `find_*_link_data(...)` — returns data hash (new)

`resolve()` is internally refactored to call `resolve_data()` + a private `render_html_from_data()`. All existing tests pass without modification, proving the refactoring is correct. The data contract is complete for external consumers (who receive only the hash). The internal HTML path additionally reads instance state (`@log_output`, `@context`) — this is the right tradeoff, not a gap.

### Verification:
- `make test` passes (all existing + new tests green)
- No downstream callers change
- No new dependencies

## What We're NOT Doing

- **No Markdown rendering** — that's Phase 2
- **No changes to Tags or downstream callers** — they continue calling `render_*_link()`
- **No card renderer decoupling** — `BookCardRenderer` / `ArticleCardRenderer` are Phase 2/3
- **No `DisplayAuthorsUtil` changes** — it naturally becomes format-aware once its dependencies are decoupled
- **No `LinkHelperUtils` changes** — may not need change at all

## Implementation Approach

For each resolver (in order of complexity, simplest first):

1. **Write `resolve_data()` tests** in the existing test file (TDD)
2. **Implement `resolve_data()`** as a new public method sharing existing private helpers
3. **Add private `render_html_from_data()`** that converts the data hash to HTML
4. **Refactor `resolve()`** to call `resolve_data()` + `render_html_from_data()`
5. **Run existing tests** — all must pass (regression safety net)
6. **Add Utils wrapper** `find_*_link_data()` + its test

This approach means `resolve()` is NOT left unchanged — it's refactored to use `resolve_data()` internally. This is deliberate: it proves the data contract is complete for external consumers and eliminates the parallel-API drift problem. (The internal HTML path also reads instance state — see "Design Decisions: No `log_output` in data hashes" — but external callers get a self-contained hash.)

---

## Design Decisions

### Data extraction contract standard

This standard applies to all `resolve_data()` methods in Phase 1 and all `extract_data()` methods in Phase 3. Any method that returns a structured data hash for consumption by renderers must follow these rules:

1. **No presentation-layer data** — No HTML, no log comments, no pre-formatted strings. Raw values only.
2. **Frozen hashes** — Return `result.freeze` to signal the hash is a contract, not a mutable scratchpad.
3. **Raw text values** — `display_text` and similar fields contain unescaped, un-typographied text. Renderers apply formatting.
4. **Full key sets** — Every status variant returns the same set of keys. Missing values are explicit `nil`, never absent keys.

### No `log_output` in data hashes

The existing resolvers accumulate HTML comment strings (e.g., `<!-- RENDER_AUTHOR_LINK: Could not find ... -->`) via `PluginLoggerUtils.log_liquid_failure()` and prepend them to the HTML output. These serve as invisible diagnostics in the page source.

**`resolve_data()` does NOT include these in the returned hash.** Including pre-formatted HTML comments in a data contract leaks presentation into the data layer and would force Phase 2's Markdown renderer to deal with HTML strings.

Instead:
- `resolve_data()` calls the logger during resolution (console logging side effect is correct — the resolution IS happening)
- The logger's return value (HTML comment string) is stored in `@log_output` on the resolver instance
- `render_html_from_data()` is a private method on the same single-use instance, so it reads `@log_output` directly and prepends it to HTML output
- External callers via `AuthorLinkUtils.find_author_link_data()` get a clean hash — no HTML contamination

### All status variants return the full key set

Every data hash returned by `resolve_data()` contains the same set of keys for that resolver, regardless of status. Keys that don't apply for a given status are explicitly set to `nil`. This eliminates ambiguity — a missing key is always a bug, never an intentional omission.

For example, AuthorLinkResolver always returns `{ status:, url:, display_text:, possessive: }`. For `:empty_name`, `url`, `display_text`, and `possessive` are all explicitly `nil`. A consumer accessing `data[:display_text]` on an `:empty_name` hash gets `nil` by contract, not by accident.

### Status variants are detailed; downstream consumers can collapse

The data contracts distinguish `:no_site`, `:empty_name`/`:empty_title`, `:not_found`, and `:found`. The HTML renderer genuinely needs these distinctions (`:no_site` skips the `<span>` wrapper; `:empty_name` returns `""`; `:not_found` wraps in `<span>` without a link).

Downstream consumers (Phase 2 Markdown renderers) can collapse all non-`:found` statuses into a single branch:
```ruby
data[:status] == :found ? "[#{data[:display_text]}](#{data[:url]})" : data[:display_text].to_s
```

### `display_text` is always raw text

`display_text` contains the unescaped, un-typographied input string. `render_html_from_data()` applies the appropriate processing per resolver type:
- Authors/Series: `CGI.escapeHTML()` → HTML-safe
- Books/ShortStories: `TypographyUtils.prepare_display_title()` → smart quotes, em dashes, then HTML-safe

Phase 2's Markdown renderer can use `display_text` directly — raw text is valid Markdown.

### Frozen return values

`resolve_data()` returns `result.freeze`. This signals that the hash is a contract — not a mutable scratchpad — and prevents accidental downstream mutation.

### `track_unreviewed_mention()` is a deliberate side effect

`BookLinkResolver.resolve_data()` calls `track_unreviewed_mention()` when a book title is not found in the cache. This writes to `site.data['mention_tracker']`, recording which books appear in content but don't have review pages.

This side effect stays in `resolve_data()` because:
- Mention tracking is a build-time data concern, not a presentation concern
- Since `resolve()` delegates to `resolve_data()`, the tracking must be in `resolve_data()` for existing behavior to be preserved

**Render-mode guard**: Phase 2 re-renders each document's body through Liquid a second time for Markdown output. Without a guard, `track_unreviewed_mention()` would fire twice per document. The guard:

```ruby
track_unreviewed_mention(site, book_title) unless @context.registers[:render_mode] == :markdown
```

This ensures mention tracking fires exactly once (during the HTML render), not during the Markdown re-render. The guard must be added in Phase 1 so that `resolve_data()` is safe for dual-output use from the start.

`resolve_data()` is therefore "data extraction with build-time side effects" — not a pure function. This is the same category as the console logging: shared build state that must happen during resolution regardless of how the result is rendered.

---

## Data Contracts

### AuthorLinkResolver

Keys: `status`, `url`, `display_text`, `possessive`

```ruby
# Found:
{ status: :found, url: "/authors/jane-doe.html", display_text: "Jane Doe", possessive: false }

# Not found:
{ status: :not_found, url: nil, display_text: "John Smith", possessive: false }

# Empty name (after normalization):
{ status: :empty_name, url: nil, display_text: nil, possessive: nil }

# No site in context:
{ status: :no_site, url: nil, display_text: "Jane Doe", possessive: nil }
```

### SeriesLinkResolver

Keys: `status`, `url`, `display_text`

```ruby
# Found:
{ status: :found, url: "/books/series/hyperion-cantos/", display_text: "Hyperion Cantos" }

# Not found:
{ status: :not_found, url: nil, display_text: "Unknown Series" }

# Empty title:
{ status: :empty_title, url: nil, display_text: nil }

# No site:
{ status: :no_site, url: nil, display_text: "Some Series" }
```

### ShortStoryResolver

Keys: `status`, `url`, `display_text`

```ruby
# Found:
{ status: :found, url: "/books/stories-of-your-life/#story-slug", display_text: "Story of Your Life" }

# Not found:
{ status: :not_found, url: nil, display_text: "Unknown Story" }

# Ambiguous (no book filter, multiple locations):
{ status: :ambiguous, url: nil, display_text: "Ambiguous Story" }

# Empty title:
{ status: :empty_title, url: nil, display_text: nil }

# No site:
{ status: :no_site, url: nil, display_text: "Some Story" }
```

### BookLinkResolver

Keys: `status`, `url`, `display_text`, `canonical_title`, `cite`

```ruby
# Found:
{ status: :found, url: "/books/hyperion/", display_text: "Hyperion", canonical_title: "Hyperion", cite: true }

# Not found (title not in cache, or date/author mismatch):
{ status: :not_found, url: nil, display_text: "Unknown Book", canonical_title: nil, cite: true }

# Empty title:
{ status: :empty_title, url: nil, display_text: nil, canonical_title: nil, cite: nil }

# No site:
{ status: :no_site, url: nil, display_text: "Some Book", canonical_title: nil, cite: nil }

# Ambiguous (multiple authors, no filter):
# Raises Jekyll::Errors::FatalException — same as current behavior
# This is a build error, not a data state
```

---

## Step 1: AuthorLinkResolver (simplest — 83 lines)

### Changes Required:

#### 1. Resolver
**File**: `_plugins/src/content/authors/author_link_resolver.rb`

Add public `resolve_data()` method that:
- Handles edge cases (no site, empty name) returning status hashes
- Calls existing private `find_author()` and `determine_display_text()`
- Returns the data contract hash

Add private `render_html_from_data(data)` that:
- Dispatches on `data[:status]`
- For `:no_site`: returns `CGI.escapeHTML(data[:display_text])`
- For `:empty_name`: returns `@log_output` (instance variable set during `resolve_data()`)
- For `:found` / `:not_found`: prepends `@log_output` + calls existing `generate_html()` logic (build span, add possessive suffix, wrap in link)

**Note**: `render_html_from_data()` is a private instance method, not a pure function of the hash. It reads `@context` (for `LinkHelper._generate_link_html()` which does baseurl prefixing and current-page detection) and `@log_output` (for diagnostic HTML comments) from the resolver instance. This is fine because both `resolve_data()` and `render_html_from_data()` run on the same single-use instance.

Refactor `resolve()` to: `data = resolve_data(...); render_html_from_data(data)`

#### 2. Utils Module
**File**: `_plugins/src/content/authors/author_link_util.rb`

Add:
```ruby
def self.find_author_link_data(author_name_raw, context, link_text_override_raw = nil, possessive = nil)
  Jekyll::Authors::AuthorLinkResolver.new(context).resolve_data(author_name_raw, link_text_override_raw, possessive)
end
```

#### 3. Resolver Tests
**File**: `_tests/src/content/authors/test_author_link_resolver.rb`

New test cases for `resolve_data()`:
- `test_resolve_data_found` — returns `{ status: :found, url: ..., display_text: ..., possessive: false }`
- `test_resolve_data_found_possessive` — returns `{ ..., possessive: true }`
- `test_resolve_data_not_found` — returns `{ status: :not_found, url: nil, display_text: ... }`
- `test_resolve_data_empty_name` — returns `{ status: :empty_name }`
- `test_resolve_data_no_site` — returns `{ status: :no_site, display_text: ... }`
- `test_resolve_data_with_override` — `display_text` uses the override
- `test_resolve_data_pen_name` — `display_text` preserves pen name input

#### 4. Utils Tests
**File**: `_tests/src/content/authors/test_author_link_util.rb`

New test case:
- `test_find_author_link_data_delegates` — confirms the Utils method returns a data hash (not HTML)

---

## Review Checkpoint

After Step 1 (AuthorLinkResolver), pause and review the pattern before replicating it 3 more times:

- Is the data hash shape ergonomic for tests? Are assertions clear?
- Does `render_html_from_data()` need more instance state than expected?
- Is the test setup (mock site, mock context) reusable without boilerplate?
- Does the Utils wrapper feel right, or should it be structured differently?

This is the cheapest point to course-correct. The pattern established here will be replicated in Steps 2-4 and adapted for card renderers in Phase 3.

---

## Step 2: SeriesLinkResolver (near-identical — 84 lines)

### Changes Required:

#### 1. Resolver
**File**: `_plugins/src/content/series/series_link_resolver.rb`

Same pattern as AuthorLinkResolver. Add `resolve_data()`, `render_html_from_data()`, refactor `resolve()`.

`resolve_data()` calls existing `find_series()` and `determine_display_text()`.

#### 2. Utils Module
**File**: `_plugins/src/content/series/series_link_util.rb`

Add:
```ruby
def self.find_series_link_data(series_title_raw, context, link_text_override_raw = nil)
  Jekyll::Series::SeriesLinkResolver.new(context).resolve_data(series_title_raw, link_text_override_raw)
end
```

#### 3. Resolver Tests
**File**: `_tests/src/content/series/test_series_link_resolver.rb`

New test cases:
- `test_resolve_data_found` — `{ status: :found, url: ..., display_text: ... }`
- `test_resolve_data_not_found` — `{ status: :not_found, url: nil }`
- `test_resolve_data_empty_title` — `{ status: :empty_title }`
- `test_resolve_data_no_site` — `{ status: :no_site }`
- `test_resolve_data_with_override` — uses override text

#### 4. Utils Tests
**File**: `_tests/src/content/series/test_series_link_util.rb`

- `test_find_series_link_data_delegates` — returns data hash

---

## Step 3: ShortStoryResolver (more complex — 140 lines)

### Changes Required:

#### 1. Resolver
**File**: `_plugins/src/content/short_stories/short_story_resolver.rb`

Add `resolve_data()` that:
- Handles no site, empty title
- Calls existing `find_target_location()` (which includes `resolve_ambiguity()`)
- Returns status-based hash including `:ambiguous` status

The disambiguation logic (`try_canonical_locations`, `all_same_book?`, `try_book_filter`) is already in the data layer — it only fetches and filters. `render_html()` is the only HTML producer. The split is clean.

For the ambiguous case: `resolve()` currently renders the fallback display text as `<cite>` (no link). `resolve_data()` returns `{ status: :ambiguous }` and the HTML renderer handles it.

#### 2. Utils Module
**File**: `_plugins/src/content/short_stories/short_story_link_util.rb`

Add:
```ruby
def self.find_short_story_link_data(story_title_raw, context, from_book_title_raw = nil)
  Jekyll::ShortStories::ShortStoryResolver.new(context).resolve_data(story_title_raw, from_book_title_raw)
end
```

#### 3. Resolver Tests
**File**: `_tests/src/content/short_stories/test_short_story_resolver.rb`

New test cases:
- `test_resolve_data_found` — `{ status: :found, url: "...#slug", display_text: ... }`
- `test_resolve_data_not_found` — `{ status: :not_found }`
- `test_resolve_data_ambiguous` — `{ status: :ambiguous }` (multiple locations, no book filter, no canonical)
- `test_resolve_data_resolved_by_book_filter` — `{ status: :found }` when book filter disambiguates
- `test_resolve_data_empty_title` — `{ status: :empty_title }`
- `test_resolve_data_no_site` — `{ status: :no_site }`

#### 4. Utils Tests
**File**: `_tests/src/content/short_stories/test_short_story_link_util.rb`

- `test_find_short_story_link_data_delegates` — returns data hash

---

## Step 4: BookLinkResolver (most complex — 221 lines)

### Changes Required:

#### 1. Resolver
**File**: `_plugins/src/content/books/core/book_link_resolver.rb`

Add `resolve_data()` that:
- Handles no site, empty title
- Calls existing `find_candidates()`, `determine_display_text()`, `filter_candidates()`
- **Deliberately calls `track_unreviewed_mention()` for not-found case** — this is a build-time side effect that records which books are mentioned but not reviewed. It writes to `site.data['mention_tracker']`. This must happen regardless of output format, so it stays in `resolve_data()`, not in `render_html_from_data()`. See "Design Decisions" section above.
- Raises `FatalException` for ambiguous titles (same as current — this is a build error)
- Returns `canonical_title` from `book_data['title']` alongside `display_text`
- Returns `cite` flag
- Returns frozen hash (`.freeze`)

The `filter_candidates()` method returns either a book data hash (success) or a log string (failure). This behavior is preserved — `resolve_data()` checks `result.is_a?(String)` the same way `resolve()` does.

#### 2. Utils Module
**File**: `_plugins/src/content/books/core/book_link_util.rb`

Add:
```ruby
def self.find_book_link_data(book_title_raw, context, link_text_override_raw = nil,
                             author_filter_raw = nil, date_filter_raw = nil, cite: true)
  Jekyll::Books::Core::BookLinkResolver.new(context).resolve_data(
    book_title_raw, link_text_override_raw, author_filter_raw, date_filter_raw, cite: cite
  )
end
```

#### 3. Resolver Tests
**File**: `_tests/src/content/books/core/test_book_link_resolver.rb`

New test cases (~14):

Basic status coverage:
- `test_resolve_data_found` — `{ status: :found, url: ..., display_text: ..., canonical_title: ..., cite: true }`
- `test_resolve_data_found_cite_false` — `{ ..., cite: false }`
- `test_resolve_data_not_found` — all keys present, `url: nil`, `canonical_title: nil`
- `test_resolve_data_empty_title` — all keys present, all nil except status
- `test_resolve_data_no_site` — all keys present, `display_text` is raw input
- `test_resolve_data_with_text_override` — `display_text` uses override, `canonical_title` still from cache
- `test_resolve_data_ambiguous_raises` — still raises `FatalException`
- `test_resolve_data_frozen` — returned hash is frozen

Filter-specific data verification:
- `test_resolve_data_date_filter_match` — `:found` with correct URL for the dated review
- `test_resolve_data_date_filter_mismatch` — `:not_found` when date doesn't match any candidate
- `test_resolve_data_author_filter_match` — `:found` with correct URL for the filtered author
- `test_resolve_data_author_filter_mismatch` — `:not_found` when author doesn't match
- `test_resolve_data_date_and_author_combined` — `:found` with correct URL when both filters applied
- `test_resolve_data_canonical_vs_archived` — `:found` returns the non-archived URL

#### 4. Utils Tests
**File**: `_tests/src/content/books/core/test_book_link_util.rb`

- `test_find_book_link_data_delegates` — returns data hash

---

## Testing Strategy

### Approach: TDD per resolver

1. Write `resolve_data()` test cases (data contract shape assertions)
2. Implement `resolve_data()` — green on new tests
3. Implement `render_html_from_data()` and refactor `resolve()` — green on ALL tests (new + existing)
4. Add Utils wrapper + test — green

### What to assert in `resolve_data()` tests:
- `:status` key is correct for each scenario
- `:url` is present when found, `nil` when not
- `:display_text` reflects override, canonical title, or raw input as appropriate
- Hash contains all keys needed by the contract (no missing keys)
- Hash is frozen (`assert data.frozen?`) — at least one test per resolver to verify the contract

### What NOT to duplicate:
- Existing `resolve()` tests already cover every edge case (fuzzy matching, escaping, baseurl, pen names, etc.)
- Those tests serve as the regression safety net after refactoring
- `resolve_data()` tests only need to verify the data contract shape, not re-test every permutation

### Test count estimate:
- AuthorLink: ~7, SeriesLink: ~5, ShortStory: ~6, BookLink: ~14
- ~1 new test per Utils module (4 total)
- **Total: ~36 new test cases across 8 existing test files**
- **0 new test files**

---

## Files Changed Summary

| File | Change |
|---|---|
| `_plugins/src/content/authors/author_link_resolver.rb` | Add `resolve_data()`, `render_html_from_data()`, refactor `resolve()` |
| `_plugins/src/content/authors/author_link_util.rb` | Add `find_author_link_data()` |
| `_plugins/src/content/series/series_link_resolver.rb` | Add `resolve_data()`, `render_html_from_data()`, refactor `resolve()` |
| `_plugins/src/content/series/series_link_util.rb` | Add `find_series_link_data()` |
| `_plugins/src/content/short_stories/short_story_resolver.rb` | Add `resolve_data()`, `render_html_from_data()`, refactor `resolve()` |
| `_plugins/src/content/short_stories/short_story_link_util.rb` | Add `find_short_story_link_data()` |
| `_plugins/src/content/books/core/book_link_resolver.rb` | Add `resolve_data()`, `render_html_from_data()`, refactor `resolve()` |
| `_plugins/src/content/books/core/book_link_util.rb` | Add `find_book_link_data()` |
| `_tests/src/content/authors/test_author_link_resolver.rb` | Add ~7 `resolve_data()` tests |
| `_tests/src/content/authors/test_author_link_util.rb` | Add 1 `find_author_link_data()` test |
| `_tests/src/content/series/test_series_link_resolver.rb` | Add ~5 `resolve_data()` tests |
| `_tests/src/content/series/test_series_link_util.rb` | Add 1 `find_series_link_data()` test |
| `_tests/src/content/short_stories/test_short_story_resolver.rb` | Add ~6 `resolve_data()` tests |
| `_tests/src/content/short_stories/test_short_story_link_util.rb` | Add 1 `find_short_story_link_data()` test |
| `_tests/src/content/books/core/test_book_link_resolver.rb` | Add ~14 `resolve_data()` tests |
| `_tests/src/content/books/core/test_book_link_util.rb` | Add 1 `find_book_link_data()` test |
| **Total** | **16 files modified, 0 new files** |

### Success Criteria:

#### Automated Verification:
- [ ] All tests pass: `make test`
- [ ] Lint passes: `make lint`
- [ ] Build succeeds: `make build`

**Implementation Note**: Each resolver (Steps 1-4) can be implemented and committed independently. After completing all 4, run the full verification.

## References

- Research: `thoughts/shared/research/2026-02-13-rendering-pipeline-dual-output.md`
- Architecture: `_plugins/README.md`
