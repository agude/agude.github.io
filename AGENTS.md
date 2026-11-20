# AGENTS.md

`GEMINI.md` is a symlink to this file.

## Context

Jekyll-based static site (alexgude.com) running in Docker.
**Crucial:** Always use `make` commands. Never run `jekyll` or `bundle` directly.

## Operations

- **Serve:** `make serve` (Live reload at localhost:4000).
- **Test:** `make test` (Runs all tests in `_tests/`).
- **Test File:** `make test TEST=_tests/src/path/to/test.rb`
- **Ruby properties:** `make test-properties TARGET=html`. Choose `link-cache`,
  `backlinks`, or `markdown` for another suite. Use `PROFILE=discovery` for
  1,000 cases per property. A failure ends with a replay line of the form
  `make test-properties TARGET=<suite> FILTER=<test_method> SEED=<s> CASES=<N+1>`,
  where N is the successful-run count PropCheck reports. Each case depends on
  the cases before it, so `CASES` must exceed N or the replay stops before the
  failing case. A seed stops reproducing a failure once the generator changes,
  so keep each confirmed shrunken input as a literal regression test.
  Add `STATS=1` to print a report for each property: `property-stats` lines
  with the test name, cases run, distinct inputs, and a count for each named
  interaction, zero counts included. Interactions are declared on
  `check_property` with `classify:` (input to interaction names) and
  `interactions:` (every name to report). Stats are off by default and do not
  change inputs, seeds, or results.
- **Ruby mutations:** `make test-mutations TARGET=html` uses the same suite
  names. With `TESTS=all` it passes only when every surviving mutant is listed
  in `_tests/support/mutation_dispositions.yml`. It fails on an unlisted
  survivor (printing its diff and key) and on a stale entry that matches no
  survivor. Timeouts are printed for review and do not fail the run. Each entry
  gives the suite, subject, a 16-digit key (SHA-256 of Mutant's mutated method
  source, so line moves do not change it), a disposition (`equivalent` or
  `out_of_scope`), and a one-sentence reason.
  Only `PROFILE=quick` is accepted and `CASES` is rejected, so every run uses
  the same 100 cases: Mutant's 5 s timeout counts a slow test as a kill.
  Mutant runs in a scratch copy of the checkout (under the temp dir, without
  `.git`, `_site`, `vendor`, caches, or `.mutant`), so a mutant that writes a
  file cannot change the checkout; the session file is copied back into
  `.mutant/results`. Each run sets the Minitest seed to `MUTATION_SEED`
  (default `1`) and prints it in the header, so test order and kills repeat.
  `TESTS=examples` loads only the example files and skips inline property
  tests; it lists the same subjects as the default `TESTS=all`, prints its
  survivors, and does not apply the dispositions or fail.
- **Build:** `make build` (Production build to `_site/`).
- **Deps:** `make lock` (Update Gemfile.lock via Docker).
- **Lint:** `make lint` / `make format-all`.
- **Lint Python:** `make lint-scripts` (Ruff check + format check) /
  `make format-scripts` (Ruff autofix + format).
- **Format MD:** `make prettier <file.md> ...` (Run Prettier on the named
  files). Do not use `make format-md` to format a change: it runs Prettier on
  every Markdown file in the repository and rewrites unrelated files.
- **Scripts:** `make scripts` (List available Python scripts with descriptions).
- **Test Scripts:** `make test-scripts` (Run Python script tests via pytest).
  The sync property tests (`_scripts/tests/test_atproto_publish_properties.py`)
  run 100 examples by default. Set `ATPROTO_HYPOTHESIS_PROFILE=discovery` for
  1,000 examples and `PYTEST_ADDOPTS=--hypothesis-show-statistics` to print
  the per-interaction event counts, e.g.
  `ATPROTO_HYPOTHESIS_PROFILE=discovery PYTEST_ADDOPTS=--hypothesis-show-statistics make test-scripts`.
- **Script mutations:** `make test-mutations-scripts` runs mutmut over
  `_scripts/atproto/` (the AT Protocol publisher). Only
  `tests/test_atproto_publish.py` and `tests/test_atproto_publish_properties.py`
  select tests, under `ATPROTO_HYPOTHESIS_PROFILE=quick`. It creates the
  symlinks `_scripts/_config.yml` and `_scripts/.github` (gitignored) that
  `publish.py` and the workflow test need under `_scripts/mutants/`, runs
  mutmut, then runs `_scripts/ci/check_mutation_dispositions.py`. Narrow it
  with `MUTANTS='atproto.publish.x_sync_documents*'`. Mutant names use the
  `x_<function>__mutmut_<n>` form. The check gates only the functions listed
  under `functions` in `_scripts/tests/mutation_dispositions.yml`: it fails on
  a survivor that is not listed, a listed mutant that no longer survives, a
  function whose source hash changed (mutmut renumbers mutants), or a
  partly run function. A survivor in a function that is not listed also
  fails (untriaged): triage it, list it, and add the function with the hash
  from `mutants/atproto/publish.py.meta`. Lines that
  start with `help=` or `description=` get no mutants
  (`do_not_mutate_patterns` in `_scripts/pyproject.toml`), so put each CLI
  help argument on its own line. `mutants/` and `.mutmut-cache` are
  gitignored.
- **Hooks:** `make hooks-install` (Install pre-commit hook).
- **Code docs:** `make doc-index` (List code objects tagged `@validator`,
  `@pipeline`, `@pattern`, or `@gotcha`) / `make doc-show OBJ=<Class>` or
  `OBJ='<Class>#<method>'` (Print one docstring with its tags). Read the
  tagged docs for a class before changing it.

### Content checks

**No single command runs every check.** `make check` is only an alias for
`check-links`. The suite is three separate commands, and each catches a class
the other two are blind to:

- **`make check-links`** — builds the site, then runs html-proofer over
  `_site/` for broken links, missing images, and empty `alt`, plus two
  custom checks in `_bin/`: heading outline (one `<h1>`, no skipped levels),
  raw TeX left unconverted in page text, and Subresource Integrity on
  external scripts and stylesheets.
- **`make check-refs`** — markdown reference links: undefined `[text][id]`,
  duplicate `[id]:`, orphaned `[id]:`. All three fail the build.
- **`make check-liquid`** — strict-Liquid render of every document.

`make check-images` is a fourth, layout-level check: it builds the site and
measures every image slot in headless Chromium, failing when a `srcset`
image's `sizes` or candidate widths do not fit the slot, or when a page's
Largest Contentful Paint element is a lazy image. CI runs it; run it
locally after changing image CSS, layouts, or `image_derivatives`. It needs
`uv` on the host.

`make check-colors` is a fifth, also browser-based: it loads every page in
the light and dark color schemes and fails when a probed color does not
switch. The color tokens are `light-dark()` values, so a lost or overridden
`color-scheme` silently pins them to light; the Ruby contrast test cannot see
that. CI runs it; run it locally after changing colors or `color-scheme`.

Why they do not overlap:
`.claude/skills/jekyll-site-dev/references/links-and-previews.md`.

## Architecture Map

- **Content:** `_posts/` (Blog), `_books/` (Reviews collection).
- **Layouts:** `_layouts/`, `_includes/`.
- **Plugins:** `_plugins/src/` (Domain-Driven Design).
  - `infrastructure/`: Low-level utils (Logger, Text, URL), **Link Cache**,
    `GeneratedStaticFile`, `MarkdownWhitespaceNormalizer`,
    `MarkdownLinkFormatter`. Post-render hooks that rewrite tags share
    `HtmlScan` (start-tag tokenizer that skips comments and raw text) and
    `HtmlAttributes` (read, add, or remove attributes); image checks share
    `LocalImage` (what counts as a local image and which file it names).
  - `ui/`: Generic components (Cards, Ratings, Citations,
    `MarkdownCardUtils`).
  - `seo/`: Three subsystems all read by (or emitting for) `_includes/head.html`:
    - `JsonLdInjector` populates `site.data['generated_json_ld_scripts']`
      with `<script type="application/ld+json">` tags. Layout-keyed
      dispatch via `LAYOUT_GENERATORS`; unknown layout raises.
    - `SeoMetaInjector` populates `site.data['seo_meta']` with meta tag
      values (title, og_*, twitter_*, description, canonical, robots).
      Layout knowledge limited to title suffixes (`LAYOUT_TITLE_SUFFIX`),
      article classification (`ARTICLE_LAYOUTS`), and indexing
      (`NOINDEX_LAYOUTS`, `NO_CANONICAL_LAYOUTS`). The cross-check test
      `test_every_known_layout_has_article_classification` enforces that
      every layout in `LAYOUT_GENERATORS` is explicitly classified.
    - `StandardSiteWellKnownGenerator` emits
      `.well-known/site.standard.publication` for AT Protocol / Bluesky
      verification; head.html renders the matching link tags from
      `standard_site.publication_uri` (config) and
      `_data/standard_site.json` (CI-generated). See the skill reference
      `atproto-standard-site.md`.
  - `content/`: Domain logic (Books, Posts, Authors, Series, **Markdown Output**).
- **AT Protocol publish:** `_scripts/atproto/publish.py` syncs posts and
  book reviews to `site.standard.document` records in CI (main only); the
  PDS is the state store. Operational runbook:
  `.claude/skills/jekyll-site-dev/references/atproto-standard-site.md`.
- **Tests:** `_tests/` (Mirrors `_plugins/src/` structure).

## Git Conventions

- **`book-*` branches are active.** They mark books the owner is currently
  reading; never delete them during housekeeping.
- **Do not merge a branch straight into `main`.** CI runs the content checks
  on push to any branch, and on `main` the same run deploys the site once they
  pass. A direct `git merge` and push makes `main` the first place the merged
  result is checked: a failure leaves `main` broken, with no deploy, until a
  fix lands. A malformed reference-link definition reached production through
  a direct merge: two `[id]:` definitions got joined onto one line during a
  prose rewrap, kramdown swallowed the second, and the live page rendered a
  bare Wikipedia URL in the middle of a paragraph. Before merging, either push
  the branch and let its CI run pass (a PR shows that run), or run
  `make check-links && make check-refs && make check-liquid` locally.

## Development Rules

1.  **Separation of Concerns:**
    - **Tags** (`tags/`) are thin wrappers; check `render_mode` and delegate.
    - **Utils** (`[domain]/[util].rb`) orchestrate logic.
    - **Finders** fetch data; **Renderers** generate HTML.
2.  **Error Handling:** Use `PluginLoggerUtils.log_liquid_failure`.
3.  **Testing:** Create a matching test file in `_tests/` for every new class.
4.  **Link Cache:** The site relies on `site.data['link_cache']` (built by
    `LinkCacheGenerator`) for O(1) lookups of books/authors.
5.  **Break, don't fail silently.** When an invariant is violated, raise
    `Jekyll::Errors::FatalException` to stop the build. A broken build is
    always better than silently wrong output — wrong output ships to
    production and is discovered much later.
6.  **Skill doc sync:** When you change plugin architecture, CI workflow,
    hooks, or the markdown-output pipeline, update the matching file in
    `.claude/skills/jekyll-site-dev/references/`.
