---
name: jekyll-site-dev
description: >
  Development reference for the alexgude.com Jekyll site. Use when modifying
  plugins in _plugins/, writing or editing content in _posts/ or _books/,
  working with the markdown output pipeline, book families, build validators,
  CI/CD configuration, or content authoring conventions (excerpts, Liquid
  tags, linking).
---

# Jekyll Site Development Reference

Detailed guides for specific subsystems. Read the relevant file when working
in that area.

## References

- **CI/CD & Hooks** — GitHub Actions pipeline stages are a header comment
  in `.github/workflows/jekyll.yml`; pre-commit hook stages (and the
  `git stash --keep-index` mechanism) are a header comment in
  `_bin/pre-commit.sh`. Read when modifying CI workflows or commit hooks.

- **Build Validators** — Validators that break the build on data errors are
  tagged `@validator` in their class docstring. List them:
  `make doc-index QUERY='has_tag?(:validator)'`. Read the docstring
  (`make doc-show OBJ=Jekyll::...`) for what each one catches. Read when
  adding a validator, debugging a `FatalException`, or understanding why a
  build failed.

- **Markdown Output Pipeline** — Generates `.md` files and `/llms.txt` from
  every page. The full data flow (pre-render -> post-render assembly ->
  llms.txt) lives in the `@pipeline`-tagged docstring on the entry point:
  `make doc-show OBJ=Jekyll::MarkdownOutput::MarkdownBodyHook`. Read when
  modifying `render_mode` behavior, markdown output assembly, or the
  llms.txt index.

- **[Book Families & `canonical_url`](references/book-families.md)** —
  Re-review workflow and canonical URL rules. Read when adding or modifying
  book reviews, especially re-reviews.

- **[Content Authoring](references/content-authoring.md)** — Excerpt rules,
  Liquid tag usage, linking conventions. Read when writing or editing blog
  posts or book reviews.

- **Plugin Patterns** — Tag structure, render mode branching,
  Finder/Renderer separation, LinkResolverSupport, error logging are
  `@pattern`-tagged docstrings on the canonical exemplar for each:
  `make doc-index QUERY='has_tag?(:pattern)'` lists all five
  (LinkTagBase, DisplayTagRenderable, LinkResolverSupport,
  LinkResolverSkeleton, PluginLoggerUtils.log_liquid_failure). Read when
  creating or modifying plugins.

- **Testing** — test structure/naming, the test_helper.rb API
  (MockDocument, MockSite, factory methods), common test patterns, and
  SimpleCov behavior are documented in a header comment at the top of
  `_tests/test_helper.rb`, plus per-method docstrings
  (`make doc-show OBJ=#create_site`, etc.). Read when writing or debugging
  tests.

- **Gotchas** — Non-obvious behaviors that cause subtle bugs live as
  `@gotcha`-tagged docstrings next to the code they warn about:
  `make doc-index QUERY='has_tag?(:gotcha)'` lists all of them (Document
  URL access, page payload snapshot, cache pollution, canonical URL
  filtering, generate_link_cache in tests, ...). Read when debugging
  unexpected behavior.
