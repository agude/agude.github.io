---
name: jekyll-site-dev
description: >-
  Development reference for the alexgude.com Jekyll site. Use when modifying
  plugins in _plugins/, writing tests in _tests/, working with the markdown
  output pipeline, or debugging build failures.
---

# Jekyll Site Development

## Architecture

Four domains under `_plugins/src/`:

| Domain | Purpose |
|---|---|
| `infrastructure/` | Low-level utilities (logging, URL, text, link cache) |
| `content/` | Domain logic (books, posts, authors, series, markdown output) |
| `seo/` | JSON-LD generators, meta tags, front matter validation |
| `ui/` | Generic components (cards, ratings, citations) |

Tests mirror `_plugins/src/` exactly:
`_plugins/src/content/books/lists/by_year_finder.rb`
`_tests/src/content/books/lists/test_by_year_finder.rb`

## Plugin Navigation Scripts

Find tests, plugins, and coverage gaps. Run from project root:

```bash
.claude/skills/jekyll-site-dev/scripts/test-for-plugin _plugins/src/infrastructure/url_utils.rb
.claude/skills/jekyll-site-dev/scripts/plugin-for-test _tests/src/infrastructure/test_url_utils.rb
.claude/skills/jekyll-site-dev/scripts/coverage-stats [--list-missing [--by-domain]]
.claude/skills/jekyll-site-dev/scripts/orphan-tests
```

Known quirk: some tests in `lists/` test renderers in `lists/renderers/`
(shows as "orphan" but isn't).

## Plugin Patterns

**Tags** are thin wrappers: parse arguments in `initialize`, branch on
`render_mode` in `render`, delegate to a Resolver (HTML) or
MarkdownLinkFormatter (Markdown). No business logic in tags.

**Finder / Renderer separation**: Finders extract and structure data
(return a hash). Renderers convert a data hash to HTML. No data fetching
in renderers, no HTML in finders.

**Render mode**: Tags check `context.registers[:render_mode]`. Simple
tags branch inline. Display tags use the `DisplayTagRenderable` mixin,
which calls `render_markdown(data)` in markdown mode or yields for HTML.

**LinkResolverSupport** (`infrastructure/links/link_resolver_support.rb`):
shared mixin for link resolvers. Provides `find_in_cache`,
`wrap_with_link`, `log_failure`. Resolvers include it and define
`resolve`/`resolve_data`.

**Error handling**: `PluginLoggerUtils.log_liquid_failure` for non-fatal
issues (returns an HTML comment). `Jekyll::Errors::FatalException` for
invariant violations.

**Private constants**: Alias dependencies to avoid namespace pollution:

```ruby
TagArgs = Jekyll::Infrastructure::TagArgumentUtils
private_constant :TagArgs
```

## Gotchas

**Document URL access**: `doc['url']` reads `data['url']` (nil). Use
`doc.url` (method). When passing docs to Finders outside Liquid context:
`item.data.merge('url' => item.url)`. MockDocument masks this --- use
`RealDocLike` in tests.

**Page payload snapshot**: `Page#to_liquid` returns a snapshot Hash, not
a live Drop. Data set in `:pre_render` hooks is invisible to Pages. Fix:
also inject into `payload['page']` directly.

**Cache pollution**: The markdown pipeline uses
`Liquid::Template.parse()` directly (not `site.liquid_renderer`) because
Jekyll caches templates by filename and `render()` mutates `@registers`.

**Strict Liquid**: `render_mode` must always be defined in the payload
(default `'html'` in pre-render hooks) or strict variable mode raises.

**Canonical URL filtering**: Link resolver rejects books where
`canonical_url` starts with `/`, filtering archived re-reviews.
`BookFamilyValidator` enforces that canonical pages never set this field.

**Unreviewed mentions**: `book_link` "not found" in HTML mode tracks an
unreviewed mention. Skipped in markdown mode to avoid double-counting.

**`generate_link_cache` in tests**: `create_site()` calls it
automatically. Manual MockSite construction requires calling
`generate_link_cache` yourself.

**SimpleCov exit 2**: Single-file test runs may exit code 2 (coverage
threshold not met). Normal and harmless.

## References

Deep-dive documents for specific subsystems. Read the relevant file when
working in that area:

- **[Plugin Patterns](references/plugin-patterns.md)** --- Full code
  examples for tag structure, render mode, finder/renderer, resolvers.
- **[Testing](references/testing.md)** --- test_helper.rb API,
  MockDocument vs RealDocLike, factory methods, common test patterns.
- **[Gotchas](references/gotchas.md)** --- Expanded discussion with code
  examples for each gotcha above.
- **[Build Validators](references/build-validators.md)** --- Validators
  that break the build on data errors.
- **[Markdown Output](references/markdown-output.md)** --- Data flow and
  key files for the `.md` / `/llms.txt` pipeline.
- **[Book Families](references/book-families.md)** --- Re-review workflow
  and canonical URL rules.
- **[Content Authoring](references/content-authoring.md)** --- Excerpt
  rules, Liquid tag usage, linking conventions.
- **[CI/CD & Hooks](references/ci-cd-hooks.md)** --- GitHub Actions
  pipeline, pre-commit hook behavior.
