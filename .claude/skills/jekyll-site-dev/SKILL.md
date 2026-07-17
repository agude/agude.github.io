---
name: jekyll-site-dev
description: >
  Development reference for the alexgude.com Jekyll site. Use when modifying
  plugins in _plugins/, writing or editing content in _posts/ or _books/,
  working with the markdown output pipeline, book families, build validators,
  CI/CD configuration, the AT Protocol / standard.site / Bluesky publishing
  pipeline (_scripts/atproto/), or content authoring conventions (excerpts,
  Liquid tags, linking).
---

# Jekyll Site Development Reference

Most subsystem documentation lives next to the code it describes, not in
this file — proximity is what keeps it from going stale. Look things up in
three tiers:

1. **This file** — stable overview, rarely changes.
2. **`make doc-index`** — lists every code object carrying one of the
   custom doc tags declared in `.yardopts` (`@validator`, `@pipeline`,
   `@pattern`, `@gotcha`). Narrow it with
   `make doc-index QUERY='has_tag?(:<tag>)'`.
3. **`make doc-show OBJ=<full::constant::path>`** — prints that object's
   full docstring. A top-level method is `OBJ='#method_name'`; an instance
   method is `OBJ='Some::Class#method'`. Reading the file at the path the
   index reports works just as well.

`_tests/src/test_skill_docs_yard_objects.rb` asserts every tag/object this
file references still resolves; `_tests/src/test_skill_docs_paths.rb` does
the same for the plain file-path references below.

## Code-resident docs

- **Build Validators** (`@validator`) — classes that raise `FatalException`
  on data errors, and what each one catches. Read when adding a validator,
  debugging a `FatalException`, or understanding why a build failed.

- **Markdown Output Pipeline** (`@pipeline`) — the full pre-render ->
  post-render -> llms.txt data flow lives on the pipeline's entry point,
  `Jekyll::MarkdownOutput::MarkdownBodyHook`. Read when modifying
  `render_mode` behavior, markdown output assembly, or the llms.txt index.

- **Plugin Patterns** (`@pattern`) — tag structure, render-mode branching,
  Finder/Renderer separation, the two link-resolver mixins, and the error-
  logging convention, each on its canonical exemplar (`LinkTagBase`,
  `DisplayTagRenderable`, `LinkResolverSupport`, `LinkResolverSkeleton`,
  `PluginLoggerUtils.log_liquid_failure`). Read when creating or modifying
  plugins.

- **Gotchas** (`@gotcha`) — non-obvious behaviors that cause subtle bugs,
  documented next to the code they warn about (document URL access, page
  payload snapshot, cache pollution, canonical URL filtering,
  `generate_link_cache` in tests, ...). Read when debugging unexpected
  behavior.

- **Testing** — test structure, naming, the test_helper.rb API
  (MockDocument, MockSite, factory methods), common test patterns, and
  SimpleCov behavior are a header comment at the top of
  `_tests/test_helper.rb`; factory methods also carry their own
  `@param`/`@return` docstrings.

- **CI/CD & Hooks** — GitHub Actions pipeline stages are a header comment
  in `.github/workflows/jekyll.yml`; pre-commit hook stages (and the
  `git stash --keep-index` mechanism) are a header comment in
  `_bin/pre-commit.sh`. Read when modifying CI workflows or commit hooks.

## Policy docs (no single code home)

These describe authoring conventions, not code behavior, so they stay as
plain skill markdown:

- **[Book Families & `canonical_url`](references/book-families.md)** —
  Re-review workflow and canonical URL rules. Read when adding or modifying
  book reviews, especially re-reviews.

- **[Content Authoring](references/content-authoring.md)** — Excerpt rules,
  Liquid tag usage, linking conventions, front-matter rules enforced by the
  AT Protocol pipeline. Read when writing or editing blog posts or book
  reviews.

- **[AT Protocol / standard.site](references/atproto-standard-site.md)** —
  How the site publishes to Bluesky's network: the domain-as-handle DNS
  wiring, the publish script, well-known generator, link tags, CI flow,
  and the operational runbook (orphans, outages, secret rotation). Read
  when touching `_scripts/atproto/`, the standard.site plugin, or the
  publish steps in CI. Full design history: `bluesky.md` at the repo root.
