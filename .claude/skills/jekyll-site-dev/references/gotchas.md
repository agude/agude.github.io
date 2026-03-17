# Gotchas

Non-obvious behaviors that cause subtle bugs if you don't know about them.

## Document URL Access

`Jekyll::Document#['url']` delegates to `data['url']`, which is nil. The
actual URL is `doc.url` (a method). When passing documents to Finders or
assemblers outside Liquid context, merge the URL into data:

```ruby
item.data.merge('url' => item.url)
```

`MockDocument` masks this with special `['url']` handling. Use `RealDocLike`
in tests to catch regressions (see [testing.md](testing.md)).

## Page Payload Snapshot

`Document#to_liquid` returns a live `DocumentDrop` (delegates `[]` to `data`).
`Page#to_liquid` returns a plain `Hash` (snapshot at call time).

In Jekyll's `Renderer#run`, `assign_pages!` calls `to_liquid` **before** the
`:pre_render` hook fires. Data set in `:pre_render` hooks is visible for
Documents (live Drop) but **not** for Pages (stale Hash).

**Fix:** In `:pages` hooks, also inject into `payload['page']` directly.

## Cache Pollution in Markdown Output

The markdown pipeline uses `Liquid::Template.parse()` directly instead of
`site.liquid_renderer`. Jekyll caches templates by filename and `render()`
mutates `@registers` with `merge!()`. Using the site renderer would leak
`render_mode: :markdown` into the HTML rendering pass.

## Strict Liquid Variables

`render_mode` must always be defined in the Liquid payload (set to `'html'`
by default in pre-render hooks). If missing, strict variable mode raises an
error.

## Canonical URL Filtering

The link resolver rejects books where `canonical_url` starts with `/`. This
filters archived re-reviews so `book_link` always points to the current
canonical review. A canonical page must **never** have `canonical_url` set.
`BookFamilyValidator` enforces this.

## Unreviewed Mention Tracking

When a `book_link` resolves to "not found" in HTML mode, the resolver tracks
it as an unreviewed mention. This does **not** happen in markdown mode
(`render_mode: :markdown`), to avoid double-counting.

## generate_link_cache in Tests

`create_site()` calls `generate_link_cache(site)` automatically. All
resolvers and most finders depend on `site.data['link_cache']` being
populated. If you build a MockSite manually without `create_site`, you must
call `generate_link_cache` yourself or tests will fail with nil cache errors.

## SimpleCov Exit Code 2

Running a single test file with `make test TEST=...` may exit with code 2
because SimpleCov's 95% threshold isn't met when only one file's coverage is
measured. This is expected and harmless.
