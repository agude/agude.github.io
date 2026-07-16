# Repo Audit — alexgude.com (2026-07-10)

## Session status (updated 2026-07-11, night)

**Merged to main:** dev-fixups (feed repair, CI guards, hover-preview,
skills sync, §1–§3 + 6.7/6.8 + parts of §5/§7/§8), ruby-3.4 (§4.1),
`plugin-cleanups` (all of §6, 8 commits), `plugin-followups` (§6.9
items 1–5, 5 commits), `drop-pagination` (§4.2, 1 commit). Every
merged branch was verified pre-merge: full suite green, RuboCop clean
(303 files), production build diffed against main with
`_scripts/diagnostics/html_diff.py` (plugin branches: zero diffs;
drop-pagination: exactly the expected diff set — see §4.2). **§6
including follow-ups is fully closed; §4.2 is done.**

**Open branches:**

- `external-link-check` (pushed, unmerged): monthly lychee workflow
  (§2.3). Awaiting user review. Follow-up content work: ~31 genuinely
  dead external URLs found in old posts (dead startups incl. all 8
  gab41.lab41.org links, Insight, SVDS; moved university pages; killed
  publications; hfgudeart.com is down and may be a family site) — user
  will review URL fixes on desktop; archive.org swaps are the default
  fix. First scheduled/manual workflow run will file them as an issue.

**Next up:** `head-html-modernization` merged. §4.5 dark mode is done
on branch `dark-mode` (2 commits), awaiting user review/merge. Then §5
leftovers (README, stale branches, `wt-dev` worktree), §7.1
(code-resident docs, optional).
Loose end from review: add a doc comment to
`TagArgumentUtils.resolve_boolean` (semantics + `default:` kwarg) —
fold into whichever branch touches that file next, or the housekeeping
commit.

Baseline: all checks green. 2221 Ruby tests pass (99.34% line / 90.0% branch
coverage), 196 Python tests pass, RuboCop clean (294 files), Dependabot
configured for bundler + GitHub Actions. The plugin architecture, test
discipline, and build validators are in excellent shape. The real problems
are at the edges: the feed subsystem is broken in production, and there are
a handful of CI/tooling landmines.

---

## 1. Critical — live production bugs

### 1.1 `/feed.xml` serves the raw, unrendered Liquid template — [DONE]

**Verified live:** `curl https://alexgude.com/feed.xml` returns the literal
template — `{% if page.xsl %}`, `{{ post_title }}`, etc. Every feed
subscriber has been getting garbage since commit `b3b97156` ("Add CSS-only
hover previews for book links", 2026-07-07).

**Cause:** the `feed.xml` override at the repo root has **no front matter**,
so Jekyll treats it as a static file and copies it verbatim instead of
rendering it. (jekyll-feed correctly skips generating its own feed because a
file exists at that path — so the broken copy wins.)

**Second, masked bug in the same file:** the explanatory HTML comment sits
_before_ the `<?xml version="1.0"?>` declaration. Even once rendered, the
output would not be well-formed XML (declaration must be the first bytes).
Verified: `xml.etree` rejects the current output; strict feed readers will
too.

**Fix:**

1. Add empty front matter (`---`/`---`) at the top of `feed.xml`.
2. Convert the HTML comment to a `{% comment %}` block (renders to nothing)
   or move it below the XML declaration.
3. `_bin/check_strict.rb` already expects `feed.xml` to be a rendered page
   (it's in `excluded_files`), which confirms front matter was intended.
4. Add a CI guard: after build, assert `_site/feed.xml` parses as XML and
   contains ≥ N `<entry>` elements. The existing "Validate HTML structure"
   step is the natural place; a 3-line `ruby -rrexml` check suffices. This
   class of bug (template deployed verbatim) is invisible to every current
   check because html-proofer only looks at HTML.

### 1.2 Feed limit config key is wrong: `post_limit` vs `posts_limit` — [DONE]

`_config.yml:186` sets `feed: post_limit: 100`, but jekyll-feed's option (and
the override template at `feed.xml:67`) read `site.feed.posts_limit`
(plural). The typo'd key is silently ignored and the default of 10 applies.

**Verified live:** `/feed/books.xml` contains exactly 10 entries out of 129
books. The main feed will hit the same 10-of-105 cap once 1.1 is fixed.

**Fix:** rename to `posts_limit: 100` in `_config.yml`.

### 1.3 Book hover-preview markup leaks into `/feed/books.xml` — [DONE: global post_render hook; feed.xml override kept]

The whole point of the `feed.xml` override was to pipe content through
`strip_link_previews` so hidden preview markup doesn't appear as inline text
in feed readers. But the override only covers the _main_ feed; the books
collection feed is generated from jekyll-feed's bundled template.

**Verified live:** `/feed/books.xml` currently contains 170
`book-preview` fragments.

**Fix options (pick one):**

- Provide an override at `feed/books.xml` too (same template, with front
  matter — see 1.1), or
- Strip previews globally in a `post_render`/generator hook so no template
  override is needed for any current or future feed, and delete the override
  entirely. This is more robust: one mechanism instead of one override per
  feed path.

Note the `hidden` attribute added in `9ebfc12d` does not help feed readers
that strip attributes but keep text.

### 1.4 `/test/` is deployed and listed in the public sitemap — [DONE: sitemap:false + typo fix; no noindex meta]

`test.md` (title: "Test **Papge**" — typo) renders every markdown element as
a QA page. **Verified live:** returns 200 and appears in
`https://alexgude.com/sitemap.xml`, so search engines are invited to index a
lorem-ipsum page.

**Fix:** add `sitemap: false` front matter and a `noindex` robots meta (the
seo pipeline would need a small hook for per-page robots), or exclude it
from production builds entirely (e.g. move to `_drafts/` or gate on
`JEKYLL_ENV`). Fix the title typo if it stays.

---

## 2. High — CI and tooling landmines

### 2.1 Workflow-level concurrency group can silently skip branch tests — [DONE]

`.github/workflows/jekyll.yml` sets `concurrency: group: "pages"` for the
_entire workflow_, on _every push to every branch_, with
`cancel-in-progress: false`. GitHub keeps at most one **pending** run per
group: push branch A (run queues behind an in-progress main deploy), then
push branch B — A's queued run is superseded and **branch A is never
tested**. It also needlessly serializes all test runs behind deploys.

**Fix:** scope the shared lock to deployment only:

- Remove the workflow-level `concurrency`, and
- Add `concurrency: { group: pages, cancel-in-progress: false }` to the
  `deploy` (or `build`+`deploy`) job only; optionally give test runs
  `group: test-${{ github.ref }}`, `cancel-in-progress: true`.

### 2.2 Pre-commit hook silently stages unstaged changes — [DONE: stash --keep-index approach]

`_bin/pre-commit.sh` runs the formatters, then `git add`s each _file_ that
had anything staged. If you partially staged a file (`git add -p`), the hook
stages your leftover hunks and they ride into the commit unreviewed. This
applies to all three stages (RuboCop, Prettier, Ruff).

**Fix:** either fail-don't-fix in the hook (report offenses, exit 1, let the
user re-stage), or stash unstaged changes around the hook
(`git stash -k` … pop), or only re-add when `git diff --name-only` shows the
formatter actually changed the file _and_ the file had no unstaged diff
beforehand. Minor related nits: `xargs` breaks on filenames with spaces;
the stray `"$@"` in the RuboCop invocation passes hook args into rubocop.

### 2.3 External links are never checked — [DONE: monthly lychee workflow, issue-per-month on failure]

`_bin/check_links.rb` ignores everything matching `/^http/`, so external
link rot is invisible. With ~10 years of posts this is guaranteed to be
accumulating.

**Fix:** add a _scheduled_ (e.g. monthly `schedule:` workflow, not per-push)
external-link check — html-proofer with external checks + cache
(`:cache: { :timeframe: '30d' }`) or lychee — that opens an issue on
failure. Keep the per-push check internal-only as it is now.

---

## 3. Medium — code-level findings in `_plugins`

### 3.1 `BacklinkBuilder#update_capture_tracking` — dead loop — [DONE]

`_plugins/src/infrastructure/link_cache/backlink_builder.rb:132-145`: the
`@capture_defs.each_with_index` loop computes an occurrence-matched index
into `@seen_captures[var_name]`, and then line 144 unconditionally
overwrites it with `cap_idx`. The loop (and `@capture_occurrence_counts`)
has zero observable effect. Either the occurrence-matching was intended to
win (behavioral bug — prose vars between two same-named captures may be
attributed to the wrong def) or the code should be deleted down to
`@seen_captures[var_name] = @capture_defs.length`. Tests pass either way,
which suggests the simple assignment is the real behavior; delete the rest.

### 3.2 `BookLinkResolver` never resets `@log_output` between resolves — [DONE: incl. ShortStoryResolver]

`initialize_resolve_state` (book_link_resolver.rb:66) resets title/date/cite
but not `@log_output`. Today this is safe only by accident: the two callers
that reuse one resolver instance across many books
(`books/ranking/renderer.rb:18`, `books/backlinks/renderer.rb:17`) only call
`render_from_data`, which doesn't touch `@log_output`. The first future
caller that calls `resolve` twice on one instance will emit stale log HTML
(a not-found warning from book 1 duplicated into book 2's output).
**Fix:** add `@log_output = ''` to `initialize_resolve_state`. Same pattern
worth auditing in `ShortStoryResolver`, which has the identical
`@log_output = @log_output.to_s + …` accumulation (line 189).

### 3.3 `seo_meta.html` gaps — [DONE: fallback title, twitter:description, image alt tags]

- If a page has no `site.data.seo_meta[page.url]` entry, the page renders
  with **no `<title>` at all** (the whole block is guarded by `{%- if seo -%}`).
  A fallback `<title>{{ page.title | default: site.title }}</title>` in the
  else-branch would make the failure mode graceful; alternatively assert in
  `SeoMetaInjector` that every rendered page got an entry (matches the
  "break, don't fail silently" rule).
- No `twitter:description` (Twitter falls back to `og:description`, but only
  when it's present; explicit is cheap).
- No `og:image:alt` / `twitter:image:alt` — you enforce alt text on `<img>`
  site-wide via html-proofer but social cards get none.

### 3.4 `_config.yml` excludes a file that doesn't exist — [DONE: typo fixed; dummy file kept]

`exclude:` lists `redirects.json`, but the actual file is `redirect.json`
(a dummy with empty front matter, commit `ee00a970`). The dead exclude entry
should be fixed or removed, and it's worth deciding whether the dummy file
is still needed at all given `redirect_from: json: false` already disables
generation.

---

## 4. Modernization

### 4.1 Ruby 3.2 is EOL (since 2026-03-31) — [DONE: 3.4.10; no Gemfile changes needed, only lint autocorrections]

`.ruby-version` pins 3.2; no more security patches. Upgrade to 3.4:

- `.ruby-version` (Makefile and `ruby/setup-ruby` both derive from it —
  single-point change), Dockerfile `ARG RUBY_VERSION` default.
- Expect minor fallout: bundled-gem warnings (you already carry `logger`;
  Ruby 3.5 will want `ostruct`/`fiddle`-class gems declared too), possible
  RuboCop `TargetRubyVersion` bump.
- Rebuild the Docker image (`make image-rebuild`), run tests.

### 4.2 Drop pagination entirely — [DONE, branch `drop-pagination`]

Original idea was jekyll-paginate → jekyll-paginate-v2. Went instead
with: **delete pagination and render all posts on one page**, like
`books.md` already does for 129 books (~105 posts is the same scale;
`render_article_card` entries are text-only, lighter than book cards).
This removes the deprecated dependency without adopting a replacement,
and fixes a real defect: the markdown-output twin of `blog/index.html`
iterated `paginator.posts`, so the generated `.md` only ever contained
page 1's ten posts — the `site.posts` loop makes it complete.

The pagination footprint was four files, all changed:

- `blog/index.html` — swapped `paginator.posts` → `site.posts`,
  deleted the Older/Newer nav block and the "has to be at index.html"
  comment.
- `_config.yml` — removed `paginate:`, `paginate_path:`, and the
  `jekyll-paginate` plugins entry.
- `Gemfile` — removed `jekyll-paginate` (+ the deprecation comment);
  `make lock`.
- `_sass/_posts.scss` — deleted the now-unused `.pagination` /
  `.pagination-item` styles and the stale "pagination" mention in the
  file-header comment.

Reconsidered the "accept the 404s" trade-off: the site already uses
`jekyll-redirect-from` per-page (`redirect_from:` front matter), so
hard-coding the old paginated URLs costs nothing and is the existing
convention. Added a `redirect_from:` list to `blog/index.html`'s front
matter for all ten old paginated URLs (`/blog/page2/` …
`/blog/page11/`, since 105 posts ÷ 10/page = 11 pages, page 1 =
`/blog/`), each 301-ish-redirecting to `/blog/`.

Review note (post-merge): the `make lock` in this commit also picked
up collateral tooling-gem bumps (`async` 2.37→2.42, `io-event`,
`console`, `parallel` 1.28→2.1.0, `rubocop` 1.88.1→1.88.2,
`rubocop-ast`) — all html-proofer/rubocop-side, no site-rendering gems.
Everything green, left as-is; if a tooling regression ever bisects to
the "Drop pagination" commit, this is why. Bonus fix confirmed in
review: main's sitemap listed all ten paginated pages; they're gone
from the sitemap now (redirect stubs are noindex).

Verified with `_scripts/diagnostics/html_diff.py` against main (built
main in a scratch worktree): `blog/page*.md` twins disappear,
`blog/page*/index.html` become redirect stubs (`noindex`, meta-refresh
to `/blog/`), `blog/index.html` grows to all posts, `blog.md` and
`llms.txt` gain the full post list and drop the stale duplicate
per-page "Writings" entries. No other diffs. Full suite green (2282
tests), RuboCop clean (303 files).

### 4.3 Self-host the one remaining Google Font — [DONE, branch `head-html-modernization`; reviewed. Glyph audit: code blocks use 3 arrow chars (→ ↓ ↳) that Ubuntu Mono doesn't contain at all (upstream has zero U+2190–21FF glyphs) — they always fell back to system monospace, before and after; not a regression, nothing to fix]

`head.html` loads only Ubuntu Mono from `fonts.googleapis.com` using the
legacy CSS API, with no `preconnect`. Self-hosting one WOFF2 pair
(`font-display: swap`) removes the only third-party request on the site
(privacy + performance + works offline). While there: delete the
commented-out PT Sans block (dead code since the font was dropped).

### 4.4 Icon/meta modernization in `head.html` — [DONE, branch `head-html-modernization`; reviewed. Third commit on the branch went further than spec'd: `site.theme_color` in `_config.yml` is now the single source for the meta tag, `site.webmanifest` (rendered via empty front matter), and `$sidebar-color` (Sass module config through `main.scss`). Verified: compiled CSS byte-identical, manifest absent from sitemap. §4.5 builds on this]

- `apple-touch-icon-precomposed` (144×144) is the pre-iOS-7 form; modern is
  `<link rel="apple-touch-icon" sizes="180x180">`.
- `rel="shortcut icon"` → `rel="icon"`; consider an SVG favicon +
  `site.webmanifest`.
- `theme-color` is hard-coded `hsl(214, 52%, 42%)`, duplicating
  `$sidebar-color` in `_variables.scss` — a drift hazard; worth a comment
  cross-reference at minimum.

### 4.5 Dark mode — [DONE, branch `dark-mode`; 2 commits. html_diff.py vs main: only diff on every page is the theme-color meta line(s), as expected. Contrast test: dark palette clears AA on all 3 pairs; 2 pre-existing light-mode pairs (--muted-color 3.7:1, --code-color 3.9:1) were already below AA before this branch and are pinned as a regression guard rather than fixed (out of scope; user decision 2026-07-11). Not merged yet.]

**Decision (made): OS-preference only via `prefers-color-scheme`. NO
manual toggle** — a toggle needs JS + localStorage + FOUC handling on a
site that ships zero JS. Do not add any JavaScript.

**Prerequisite:** `head-html-modernization` must be merged first (this
spec references its `site.theme_color` / `@use … with` plumbing and
the web manifest). If it isn't merged yet, branch off it, not main.

Two commits, `make test` + `make lint` green after each.

**Commit 1 — tokens → CSS custom properties (zero visual change):**

- Convert the color tokens in `_sass/_variables.scss` (`$body-bg`,
  `$body-color`, `$muted-color`, `$border-color`, `$code-color`,
  `$sidebar-color`, `$share-button-color`, `$share-hover-color`) to
  CSS custom properties declared on `:root`; keep the Sass variables
  pointing at `var(--…)` so partials don't change.
- Gotcha: `$muted-color` is `color.adjust($body-color, $lightness:
20%)` — Sass can't adjust a `var()`. Materialize it as its own
  custom property (light value: `hsl(0, 0%, 52%)`). No other partial
  applies Sass color functions to these tokens (verified by grep).
- `$sidebar-color` is Liquid-injected from `site.theme_color` via
  `main.scss`'s `@use … with` — keep that plumbing; the custom
  property's light value comes from the (configured) Sass variable.
- Tokenize the hardcoded surfaces that dark mode must flip: the two
  `#f9f9f9` code backgrounds in `_code.scss` (one `--code-bg` token).
  Grep `_sass/` for remaining hex/hsl literals and tokenize only what
  renders wrong on a dark background (e.g. light borders/surfaces);
  do NOT touch the `.highlight .xx` syntax-theme rules (commit 2
  replaces them wholesale in dark mode).
- Acceptance: `html_diff.py` against main = zero HTML diffs; compiled
  light-mode colors unchanged (same values, re-plumbed).

**Commit 2 — the dark palette:**

- Add `color-scheme: light dark;` on `:root` (flips scrollbars/form
  controls automatically).
- One `@media (prefers-color-scheme: dark)` block re-declaring the
  custom properties. Starting values (AA-checked starting points, not
  final taste — user will nudge later; do not iterate on aesthetics):

  | Token             | Light                | Dark                     |
  | ----------------- | -------------------- | ------------------------ |
  | `--body-bg`       | `white`              | `hsl(214, 15%, 12%)`     |
  | `--body-color`    | `hsl(0, 0%, 32%)`    | `hsl(0, 0%, 78%)`        |
  | `--muted-color`   | `hsl(0, 0%, 52%)`    | `hsl(0, 0%, 60%)`        |
  | `--border-color`  | `hsl(0, 0%, 90%)`    | `hsl(214, 10%, 26%)`     |
  | `--code-color`    | `hsl(354, 42%, 56%)` | `hsl(354, 55%, 70%)`     |
  | `--code-bg`       | `#f9f9f9`            | `hsl(214, 12%, 17%)`     |
  | `--sidebar-color` | `site.theme_color`   | unchanged (already dark) |

- Syntax highlighting: do not hand-derive. Generate a tested dark
  theme with `$(DOCKER_RUN) bundle exec rougify style github.dark`
  (or `base16.monokai.dark`) and scope the output inside the dark
  media query; it must override every light rule incl. `.hll` and the
  error/deleted background colors.
- Hover-preview cards (`_previews.scss`): elevated surfaces on dark
  get a _lighter_ background than the page, not shadows — point the
  card bg at a token and give it a dark value ~4–6% lighter than
  `--body-bg`.
- `theme-color` meta: add `theme_color_dark` to `_config.yml` (use the
  dark `--body-bg` value); `head.html` emits two meta tags with
  `media="(prefers-color-scheme: light)"` / `…dark)"`.
  `site.webmanifest` cannot media-switch — keep the light value.
- Images/book covers: leave untouched.
- Add a contrast meta-test (same spirit as the render-mode coverage
  test): parse the light and dark custom-property blocks from
  `_variables.scss` and assert WCAG AA — ≥4.5:1 for
  `--body-color`/`--body-bg`, `--muted-color`/`--body-bg`, and
  `--code-color`/`--code-bg`, in both modes. Pure Ruby test under
  `_tests/`; no new plugin class needed.

**Verification:** commit 1: `html_diff.py` vs main shows zero diffs.
Commit 2: only diff on every page is the theme-color meta line(s) —
the script ignores `*.css`, so also `make build` and confirm the
compiled CSS contains the dark media block. Do not commit plan.md or
prompt.md. Final lightness/saturation tuning is the user's, by eye,
after merge — land the table as-is if it passes the contrast test.

### 4.6 Blocked-on-Jekyll-5 (no action, for awareness)

`bundle outdated`: liquid 4.0.4→5.x, rouge 4→5, terminal-table 3→4
are held back by Jekyll 4.4.1 (current latest). Nothing to do until
Jekyll 5 ships; Dependabot will surface it. (Correction 2026-07-11:
`parallel` 1→2 was listed here but was never actually blocked — the
§4.2 `make lock` updated it to 2.1.0 freely; it's a tooling-side dep
of html-proofer/rubocop, not Jekyll.)

### 4.7 Minor: `Nokogiri::HTML` → `Nokogiri::HTML5`

`TextProcessingUtils.clean_text_from_html` uses the HTML4 parser; `HTML5`
(bundled with nokogiri on CRuby) matches browser parsing for edge cases.
Low priority — inputs are your own kramdown output.

---

## 5. Housekeeping

- [DONE] **`Gemfile.lock` is in `.gitignore` but tracked** (added before the ignore
  rule). It _must_ stay committed — the Dockerfile COPYs it, bundler runs
  frozen, and CI `bundler-cache: true` requires it. Remove the `.gitignore`
  entry; it currently just hides lockfile drift from `git status` tooling
  that respects ignores.
- **No `README.md`.** Even three lines (what the repo is, `make serve`,
  `make test`) helps; `_config.yml` already excludes it.
- **Stale branches:** local `book-mona_lisa`, `bump-rubocop-1.88`, `dev-md`,
  `book-story_of_your_life` (+ their remotes). Delete what's merged.
  Also: a stale `wt-dev` worktree registration (on merged `dev-fixups`)
  points into an old session scratchpad — `git worktree remove --force`
  or `git worktree prune`.
- [DONE: upstream version + URL documented in feed.xml comment] **Feed template drift:** the `feed.xml` override is a fork of jekyll-feed
  0.17's template. The `~> 0.17.0` pin protects you, but add a comment/test
  reminder to re-diff against upstream when the pin ever moves (moot if you
  adopt the hook-based stripping in 1.3 and delete the override).
- **`_site/` artifacts:** stale dev builds sit in the working tree
  (gitignored, harmless) — but note they can mislead greps; the raw-template
  feed bug was visible there since Jul 8.

---

## 6. Plugin architecture — simplification & refactoring

Overall verdict first: the architecture is healthy. The DDD layout, the
Finder/Renderer split, the link cache, the logging discipline, and the
title-tag family (`CiteTitleTag` base + three-line subclasses) are all in
good shape, and the SEO generators' `JsonLdBuilder` DSL is genuinely nice.
The opportunities below are consolidation of parallel code that grew by
copy-paste, not rescue work. Ordered by payoff.

### 6.1 The four link tags are one tag written four times (~490 lines) — [DONE: LinkTagBase; empty-quoted titles now rejected everywhere, uniform error wording]

`book_link_tag.rb`, `author_link_tag.rb`, `series_link_tag.rb`,
`short_story_link_tag.rb` all contain the same hand-rolled StringScanner
loop: positional quoted title → keyword options → unknown-argument error →
empty-title validation → `render` that resolves args, branches on
`render_mode`, and delegates to resolver or `MarkdownLinkFormatter`. They
differ only in which keyword options exist (`author=`, `cite=`, `from_book=`,
`link=`, `possessive`) and which resolver is called.

**Refactor:** extract a `LinkTagBase` (or a shared `TagArgumentParser` in
infrastructure) driven by a declarative option table:

```ruby
class BookLinkTag < LinkTagBase
  self.arg_spec = { link_text: :quoted, author: :quoted, cite: :quoted }
  self.resolver_class = Books::Core::BookLinkResolver
  # subclass hooks: build_resolver_args, markdown_options
end
```

Each tag shrinks to its option spec plus a small adapter. Estimated ~490 →
~200 lines, and the accumulated behavioral drift between the four parsers
disappears (e.g. `series_link` rejects an empty _quoted_ title, `book_link`
accepts one; only `author_link`/`series_text` support `link=false`; error
message wording varies). A fifth link type becomes a 15-line file.

### 6.2 Author/Series resolvers are mirror images; extract the skeleton — [DONE: LinkResolverSkeleton module (declarative class attrs as of `0901e9d5`); structural per-resolve state reset. Data.define: WON'T DO. Book/ShortStory adoption: WON'T DO — see §6.9 preamble]

`AuthorLinkResolver` and `SeriesLinkResolver` share an identical shape:
no-site guard → normalize input → empty-input log+result → cache lookup →
not-found log → display-text precedence (override > canonical > input) →
frozen status hash → `render_html_from_data` case statement. They differ in
cache section, tag_type string, span CSS class, and one extra field
(`possessive` / `link`).

**Refactor:** a template-method base on top of `LinkResolverSupport`
(`cache_section`, `tag_type`, `wrap_element`, `extra_result_fields` hooks).
`BookLinkResolver` and `ShortStoryResolver` keep their real complexity
(disambiguation, previews, mention tracking) but can share the same
skeleton for the common path. Do audit-item 3.2 (`@log_output` reset) as
part of this — the base class is the right place to make per-resolve state
reset structural instead of remembered.

Optional, alongside: the frozen result hashes (`{status:, url:,
display_text:, …}`) are an undocumented protocol spanning resolvers,
`MarkdownLinkFormatter`, and all four tags. Ruby 3.2's `Data.define` would
make the contract explicit (`LinkResolution = Data.define(:status, :url,
…)`) and typo-proof; hashes with string/symbol key conventions are the main
source of friction when touching this code.

### 6.3 List finders: hoist the logging boilerplate into `Shared` — [DONE: incl. mutable-return logger contract, .dups deleted]

Every finder carries a private pair like `log_empty_author_name` /
`log_no_books_for_author` — ten identical lines each, differing only in
tag_type and reason strings (`author_finder.rb`, `series_finder.rb`, and
siblings). Add two parameterized helpers to `Lists::Shared`
(`log_empty_filter(tag_type:, field:, value:)`,
`log_no_results(tag_type:, reason:)`) and delete the per-finder copies.

Related wart: the scattered `.dup` calls after
`PluginLoggerUtils.log_liquid_failure` (finders dup, resolvers don't)
exist because callers sometimes mutate the returned string. Make the
logger's return contract explicit — always return a mutable string (or
always frozen and never mutate) — and delete the defensive `.dup`s.

### 6.4 Inconsistent title normalization in `SeriesFinder` — [DONE: incl. by_year Time.now guard removal]

`series_finder.rb` filters with `series_name.to_s.strip.downcase` while the
link cache, resolvers, and `Shared` all use
`TextProcessingUtils.normalize_title` (which also collapses internal
whitespace/newlines — relevant for YAML folded scalars in front matter). A
series name that differs only in internal whitespace matches via
`series_link` but not via `display_books_for_series`. Unify on
`normalize_title`.

Similar small one: `by_year_finder.rb` silently substitutes `Time.now` for
a non-Time book date when sorting — contrary to the repo's "break, don't
fail silently" rule. Either trust `strict_front_matter` and drop the guard,
or raise.

### 6.5 Duplicate `get_canonical_author` implementations — [DONE: Infrastructure::LinkCache::AuthorLookup]

The same author-canonicalization logic (normalize → look up in
`link_cache['authors']` → fall back to stripped input) exists in
`Lists::Shared#get_canonical_author` and privately in
`BookLinkResolver#get_canonical_author`. Move one copy to infrastructure
(it's a link-cache concern) and delete the other.

### 6.6 Display tags: two structures for the same job — [DONE: flat structure; finder_for/renderer_for/resolve_filter_value hooks in DisplayTagRenderable]

`DisplayBooksByAuthorTag` wraps its logic in a nested
`BooksByAuthorRenderer` class; `DisplayBooksForSeriesTag` puts the same
flow directly on the tag. Both then repeat the same boilerplate: resolve
markup → nil/empty filter dance → construct finder → `find` →
`render_display_tag` with an HTML block + `render_markdown`. Pick the flat
structure, and consider pushing the common flow into
`DisplayTagRenderable` (give it `finder_for(context)` and `renderer_for`
hooks) so each display tag is: arg spec + finder choice + markdown
formatting.

### 6.7 Delete stale path-comment headers — [DONE]

Many files carry a first-line comment with a _pre-reorganization_ path:
`book_link_tag.rb` says `# _plugins/book_link_tag.rb`, `by_year_finder.rb`
says `# _plugins/logic/book_lists/by_year_finder.rb`,
`ranking/renderer.rb` says `# _plugins/logic/ranked_by_backlinks/renderer.rb`.
They're wrong today and will be wrong again after the next move. Delete
them all (one `sed`/RuboCop pass); the filesystem already knows the path.

### 6.8 `BacklinkBuilder#update_capture_tracking` (from §3.1) — [DONE: folded into 3.1]

Once the dead loop is removed, the method is one line
(`@seen_captures[var_name] = @capture_defs.length`) and
`@capture_occurrence_counts` disappears — fold this into the §3.1 fix.

### 6.9 Post-review follow-ups (added 2026-07-11) — [DONE]

Grew out of the multi-agent review of the §6 branch; never plan items
before. Do these on top of `plugin-cleanups` (or on main once merged),
one commit per numbered item, `make test` + `make lint` green each.

**Decisions already made — do NOT do these (recorded 2026-07-11):**

- `Data.define` for the resolver result hashes (§6.2 optional idea):
  WON'T DO. The hash protocol spans all four resolvers,
  `MarkdownLinkFormatter`, all four tags, and the skeleton's
  `**extra_fields` merge; converting churns every consumer and dozens
  of test assertions for typo-proofing the tests already provide. The
  per-family extra fields (`possessive`, `cite`) map badly onto a
  single Data type.
- Moving `BookLinkResolver` / `ShortStoryResolver` onto
  `LinkResolverSkeleton`: WON'T DO. Book diverges at step two
  (multi-candidate lookup, author/date disambiguation,
  canonical-vs-archived, previews, mention tracking). ShortStory would
  save ~20 duplicated prologue lines but needs a multi-candidate
  `find_entry` seam, an `:ambiguous` render status, and preview
  injection — three new extension points on an abstraction whose
  recent improvement was shrinking its surface. Revisit only if a
  third _simple_ link entity (publisher, translator…) ever appears.

**Correctness items (do these first):**

1. **`ShortStoryResolver`: reset `@ambiguous` per resolve.**
   `_plugins/src/content/short_stories/short_story_resolver.rb` —
   `@ambiguous` is set in `log_ambiguous` but only initialized in the
   constructor, so a reused instance that resolves an ambiguous title
   then a merely-missing one returns `:ambiguous` for the second call
   (`build_data_hash`'s `elsif @ambiguous`). Latent today (tags build
   a fresh resolver per render) but it's the §3.2 bug class and
   contradicts the reuse-safety contract LinkResolverSkeleton now
   documents. Fix: reset it at the top of `resolve_data` alongside the
   other per-resolve state. Regression test: mirror the reuse tests in
   `_tests/src/infrastructure/links/test_link_resolver_skeleton.rb`
   (ambiguous resolve, then missing resolve on the same instance; the
   second must not be `:ambiguous`).

2. **`LinkResolverSkeleton#render_html_from_data`: raise on unknown
   status.** `_plugins/src/infrastructure/links/link_resolver_skeleton.rb`
   — the case statement has no `else`, so an unrecognized status
   returns nil and Liquid renders empty string: exactly the rule-5
   failure mode ("break, don't fail silently"). Add
   `else raise Jekyll::Errors::FatalException` naming the class and
   the status. Test by calling `resolve` (or `render_html_from_data`)
   with a stubbed result carrying a bogus status.

**Optional polish (mechanical; only after 1–2 land green):**

3. **Migrate the four display tags still hand-rolling `render`** —
   `display_books_by_year_tag.rb`,
   `display_books_by_title_alpha_group_tag.rb`,
   `display_books_by_author_then_series_tag.rb`,
   `display_all_books_grouped_tag.rb` (all under
   `_plugins/src/content/books/tags/`) — onto `DisplayTagRenderable`'s
   `finder_for` / `renderer_for` hooks. Pattern:
   `display_books_for_series_tag.rb`. Must be behavior-identical;
   their existing tests should pass untouched.

4. **Dedupe the standalone/series-groups markdown loop** repeated in
   `display_books_by_author_tag.rb` (`##` headings),
   `display_all_books_grouped_tag.rb` (`##`), and
   `display_books_by_author_then_series_tag.rb` (`###`) into a helper
   on `Jekyll::UI::Cards::MarkdownCardUtils` (e.g.
   `render_book_groups_md(data, heading_level:)`), with tests.

5. **Hoist the boolean-option check into `TagArgumentUtils`.** Three
   divergent copies: `LinkTagBase#option_enabled?`,
   `series_text_tag.rb` `link_enabled?`, and `display_authors_tag.rb`
   (`!(val_str == 'false' || val == false)`). Add
   `TagArgumentUtils.resolve_boolean(markup, context, default: true)`
   with the LinkTagBase semantics (resolve → `to_s.downcase !=
'false'`) and use it at all three sites. Known behavior change to
   call out in the commit message: `display_authors_tag` currently
   only treats lowercase `'false'` as false; unified semantics make
   `'FALSE'`/`'False'` false too.

**Verification:** after all items, `make build` and run
`_scripts/diagnostics/html_diff.py` against a build of the base
commit (see the worktree recipe: `git worktree add <tmp> <base>`,
`cd <tmp> && make build`) — expect zero semantic diffs. Update
`.claude/skills/jekyll-site-dev/references/plugin-patterns.md` in the
same commit for anything that changes patterns it documents
(AGENTS.md rule 6). Do not commit plan.md or prompt.md.

---

## 7. Repo skills audit (`.claude/skills/`)

Five repo skills: `jekyll-site-dev`, `plugin-navigator`, `stub-book`,
`captures`, `copyedit`. State of each:

**Healthy / verified:**

- `plugin-navigator` — all four scripts run clean; `coverage-stats` reports
  141/141 plugin↔test pairing, `orphan-tests` finds none. Because the
  scripts _derive_ answers from the filesystem, they can't go stale.
- `stub-book` — `scripts/stub_book.py` is a symlink into
  `_scripts/skills/stub_book.py`, so there's a single source of truth and
  the script is covered by `make test-scripts`. Good pattern. (Stray
  `__pycache__/` dir sits in the skill folder; gitignored, harmless, but
  worth deleting.)
- `jekyll-site-dev` references spot-checked accurate: `gotchas.md`,
  `testing.md` (test_helper API names all real), `content-authoring.md`,
  `plugin-patterns.md`, `build-validators.md` (all four validators exist),
  `book-families.md`.

**Stale — fix:** — [DONE: both docs updated; existence test added (mechanism 1); AGENTS.md sync rule added (mechanism 2). §7.1 not done.]

- `references/markdown-output.md` points to
  `content/markdown_output/llms_txt_generator.rb`, which no longer exists —
  the llms.txt stage is now `tags/llms_txt_index_tag.rb` (a Liquid tag used
  by the root `llms.txt` page). The "Data Flow" diagram's third stage
  (`LLMS.TXT … [llms_txt_generator.rb]`) describes the old generator
  architecture.
- `references/ci-cd-hooks.md` predates the Python tooling: it omits the CI
  steps for Python script tests (`setup-python` + `uv run pytest`) and
  Stage 3 of the pre-commit hook (Ruff check + format on staged `.py`
  files). Anyone trusting it gets an incomplete picture of what a commit
  must pass. (Also update it when the §2.2 hook fix changes re-staging
  behavior.)

### How do skills stay in sync? Today: they don't — it's memory-based.

Nothing checks skill docs against the code; the two stale docs above are
exactly the drift you'd predict (both from features added after the docs
were written). Three mechanisms, cheap to expensive:

1. **Automated existence check (do this one).** A small test that scans
   `.claude/skills/**/*.md` for backtick-quoted repo paths
   (`` `_plugins/src/...rb` ``, `` `.github/...yml` ``, etc.) and asserts
   each exists (searching the known roots). It would have caught the
   `llms_txt_generator.rb` staleness the day the file was renamed. Fits
   naturally next to the existing meta-tests (the coverage cross-check
   test in `_tests/` is the same spirit). It can't catch _semantic_ drift
   (ci-cd-hooks.md's missing steps), but it catches the most common kind.
2. **A sync rule where the agent reads it.** Add one line to `AGENTS.md`:
   "When you change plugin architecture, CI workflow, hooks, or the
   markdown-output pipeline, update the matching file in
   `.claude/skills/jekyll-site-dev/references/`." Since edits here are
   made by Claude sessions that load `AGENTS.md` (and the skill itself)
   every time, the instruction is the sync mechanism.
3. **Prefer derivation over description.** The docs that rot are the ones
   that enumerate facts (key-file tables, step lists). The ones that can't
   rot are scripts (`plugin-navigator`) and pattern explanations
   (`gotchas.md` — behaviors change rarely). Where a doc lists an
   inventory, ask if a script or a `grep` recipe could replace the list;
   keep prose for the _why_ and the invariants.

### 7.1 Design: code-resident skill docs (docs live in the code, skills become shims)

The strongest version of "derivation over description": move file-anchored
doc content _into the source files it describes_, and turn the skill into a
thin index plus extraction scripts. The edit that changes the code then
contains the doc block in the same diff — proximity is the sync mechanism.

**The model to copy is the knowledge base.** Its progressive loading is
three tiers, each derived at read time from structure conventions — nothing
is compiled, so nothing drifts:

| Tier                        | KB mechanism                                      | Cost              |
| --------------------------- | ------------------------------------------------- | ----------------- |
| 0. Index, always in context | session hook injects file paths + H1 titles only  | ~KBs              |
| 1. Outline, on demand       | `toc` numbers H2/H3 headings per file             | one tool call     |
| 2. Content, on demand       | `section --file F --number N` streams one section | just that section |

The addressable unit is "H2 section in a markdown file." For code-resident
docs, **don't invent a marker syntax — the doc machinery already exists per
language, and this codebase is already halfway in:**

**Ruby: YARD.** The plugins already contain **195 YARD tags across 30
files** (`@param` ×114, `@return` ×65, `@option`, `@raise`, `@see`) — the
codebase writes YARD; it just never runs it. YARD adds what the invented
`#=` markers would have reinvented, and better:

- **Custom tags** declared once in a `.yardopts` file
  (`--tag gotcha:"Gotcha"`, `--tag pattern:"Pattern"`, …). Docs attach to
  real code objects (class/module/method), so the "topic name" is the
  constant — unique by construction, and move-proof because YARD indexes by
  object, not path.
- **Query engine** for the tier-1 index:
  `yard list --query 'has_tag?(:gotcha)'` → `file.rb:LINE: Full::Class::Name`.
- **Terminal extraction** for tier 2: `yard display Full::Class::Name`
  (or `Class#method`) prints the docstring with Parameters/Returns
  formatted.

_Verified in this repo's Docker image:_ `gem install yard`, a `.yardopts`
with two custom tags, `yard doc -n` to build the registry, then both the
tag query and `yard display` work as described. One caveat found: the
default text template renders the docstring body and standard tags but not
custom-tag _content_ — so use the tag as a categorical marker (`@gotcha`)
and put the prose in the docstring body. For an agent the query result's
`file:line` is arguably better than extraction anyway: Read that location
and you see doc and code together.

**Python: docstrings + `pydoc`.** Nothing to build. Tier 1 already exists
in this repo — `make scripts` / `list_scripts.py` walks modules with `ast`
and prints first docstring lines. Tier 2 is stdlib:
`uv run python -m pydoc metadata.fetch_book_metadata`.

**Shell: header comment + `--help`.** Also already in production here —
the knowledge-base scripts' `show_help "$0"` prints the file's own header
block, and plugin-navigator follows the same convention.

The skill maps onto the same tiers with near-zero custom code:

- **Tier 0 — SKILL.md** stays tiny and _stable_: subsystem overview, the
  three commands above, and the few truly cross-cutting narratives.
- **Tier 1 — index:** `yard list --query …` (wrapped in a `make`
  target or a two-line skill script so the Docker invocation is canned),
  `make scripts`, `script --help`.
- **Tier 2 — content:** `yard display OBJECT`, `python -m pydoc`, or plain
  Read at the `file:line` the query returned.

Setup cost: add `yard` to the Gemfile dev/test group, commit `.yardopts`,
gitignore `.yardoc`. **Execution follows the repo's existing Docker
boundary** (Ruby in the container, Python via host `uv`, shell bare):
YARD runs as `$(DOCKER_RUN) bundle exec yard …` behind `make doc-index` /
`make doc-show OBJ=…` targets — same pattern as `make lint`; adding the
gem means one `make lock` + image rebuild. The `.yardoc` registry lands on
the mounted workspace with host ownership (same as `_coverage`). `pydoc`
and `list_scripts.py` stay on host uv exactly like `make scripts` /
`make test-scripts`; plugin-navigator and `--help` stay bare shell. Any
meta-test (SKILL.md objects resolve via `yard list`) belongs in `_tests/`
so it rides the already-dockerized `make test` locally and the native
bundle in CI — both consume the same `Gemfile.lock`, so no new CI step is
needed. Tier-2 reading needs no container at all when the agent just
Reads the `file:line` from the index. Lookup is by code object, not path,
so files can move freely — the failure mode that broke `markdown-output.md` (renamed
`llms_txt_generator.rb`) becomes structurally impossible. Deleting code
forces its doc into the diff where the reviewer sees it.

**Extract-on-demand beats compile-to-skill.** Compiling docstrings into
`references/*.md` creates a second artifact: stale between compile runs,
and editable by mistake (the wrong copy _will_ get edited). Read-time
context cost is identical — either way the agent reads one section on
demand. The only genuinely context-expensive variant is inlining compiled
content into SKILL.md itself; never do that. The repo already runs the
extraction pattern in production: `make scripts` (`list_scripts.py`)
derives its listing from Python module docstrings via AST.

**What moves into code** (with its natural home):

| Current doc                            | New home                                                                                                                                                                                                     |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `build-validators.md` table            | `@validator`-tagged docstring on each validator class; `yard list --query 'has_tag?(:validator)'` reproduces the table                                                                                       |
| `markdown-output.md` key-files table   | class docstring in each pipeline file                                                                                                                                                                        |
| `markdown-output.md` data-flow diagram | `@pipeline`-tagged docstring on the entry-point class in `markdown_body_hook.rb` (the subsystem's entry point hosts the overview)                                                                            |
| `gotchas.md` entries                   | `@gotcha`-tagged docstring next to the code it warns about (cache pollution → `markdown_body_hook.rb`; canonical-URL filtering → `book_link_resolver.rb`; `generate_link_cache` in tests → `test_helper.rb`) |
| `testing.md` API guide                 | header docs in `test_helper.rb` — it _is_ the API being documented                                                                                                                                           |
| `ci-cd-hooks.md`                       | comment blocks in `jekyll.yml` and `pre-commit.sh` (YAML has no doc tooling; header-comment convention like the shell scripts)                                                                               |
| `plugin-patterns.md`                   | `@pattern`-tagged docstrings in the canonical exemplar files it already points at (`book_link_tag.rb`, `display_tag_renderable.rb`)                                                                          |

**What stays in the skill** (the honest limit): rules about _content_, not
code. `content-authoring.md` (excerpt rules, when to use which tag) and
`book-families.md` (re-review workflow) describe authoring policy with no
single code home — though where a rule has an _enforcement site_, the doc
belongs there (the "never raw-link books" rule can live on `LinkValidator`,
whose error message is what an author actually encounters). What remains in
`.claude/skills` markdown after migration is small, slow-changing policy
prose — the kind that was never the drift problem — and the §7 existence
test covers it.

**Guardrails:** topic uniqueness comes free (Ruby constants); the one
meta-test worth writing asserts every object/tag SKILL.md mentions still
resolves via `yard list`. Known trade-offs: `yard` becomes a dev
dependency and the registry needs a `yard doc -n` parse (seconds on 14k
lines, cached in `.yardoc`); source files carry more comment prose (same
total volume, relocated); no single rendered doc page to browse on GitHub
(acceptable — the audience is the agent, and the tag queries are the
browse view; `yard doc` can emit HTML any time if a human wants it);
semantic drift _within_ a docstring is still possible — proximity is the
mitigation, which is the premise of the whole design.

---

## 8. Book hover-preview review (the recent build)

Overall: a genuinely well-built CSS-only feature. The load-bearing comment
markers as a strip contract, single-line output so kramdown can't split it,
the `_building_lede` re-entrance guard, verified escaping through
`prepare_display_title`, touch/print exclusion via media queries,
`:focus-visible` reveal for keyboard users, `aria-hidden` on duplicate
content, and `@supports`-gated CSS anchor positioning with
`position-try-fallbacks` are all right. Findings, biggest first:

### 8.1 Cover images load eagerly — the CSS comment's claim is false — [DONE]

`_previews.scss:23` says "Browsers do not fetch cover images until the
preview is actually shown." **That is not how browsers work**: `display:
none` (and the `hidden` attribute) do not stop `<img src>` fetches — the
preload scanner grabs them before CSS even applies. Measured in `_site`:
book pages embed up to **29 hidden previews, each with a cover `<img>`**
(`last_stand` 29, `neuromancer` 21, `hyperion` 18, …), so every visitor
downloads dozens of cover images they will likely never see.

**Fix:** add `loading="lazy"` (and `decoding="async"`) to
`BookPreviewRenderer#cover_html`. A lazy image inside a `display: none`
subtree never intersects the viewport, so it is genuinely not fetched
until the preview opens — which makes the comment true instead of wrong.
One-line change plus test updates.

### 8.2 The card cannot be hovered — pointer travel closes it — [DONE: ::before bridge]

Reveal is `a:hover > .book-link-preview`, and the 0.3em gap between link
and card (`margin-top` / `top: calc(anchor(bottom) + 0.3em)`) belongs to
neither element. The instant the pointer leaves the link text toward the
card, hover is lost and the card vanishes — so the card is only readable
while the pointer sits on the link itself. With a multi-line lede inviting
reading, that's a real limitation. **Fix:** make the gap part of the
preview's hover area — transparent `padding-top: 0.3em` on the card (with
the visible box drawn via an inner wrapper or `background-clip:
padding-box`) instead of a margin gap, in both positioning modes.

### 8.3 No hover-intent delay — [DONE: 250ms reveal delay, instant hide]

Pure `display` toggling means cards pop instantly when the mouse crosses
links while scrolling or scanning — several previews can strobe in a
single mouse travel across a link-dense paragraph. Modern CSS can delay
discrete display changes: `transition: display 0s 250ms allow-discrete`
on the reveal (no delay on hide). Old browsers ignore it and keep today's
instant behavior — clean progressive enhancement, and it preserves
`display: none` semantics so it composes with the 8.1 lazy-loading fix
(a `visibility`-based delay would not: hidden-but-laid-out images DO
intersect the viewport and would fetch eagerly again).

### 8.4 Hardcoded colors block theming — [DONE]

`background-color: white; border: 1px solid #e5e5e5` — these are exactly
`$body-bg` and `$border-color` from `_variables.scss`. Use the variables;
as written, the preview is the file that breaks first under the dark-mode
work (§4.5).

### 8.5 Unbounded lede height — [WON'T DO: clamp implemented, then removed by decision — full lede shows]

The lede has no `max-height`/`line-clamp`; a long first paragraph makes a
tall card, and in the anchored mode `position-try-fallbacks` only flips —
it doesn't shrink — so a tall card near mid-viewport can overflow both
ways. Cap it: `line-clamp: 5` (with the `-webkit-box` fallback spelling)
on `.book-link-preview-lede`.

### 8.6 Anchor-name collision (edge case, note only)

Both `a:hover:has(…)` and `a:focus-visible:has(…)` set `anchor-name:
--book-link`. Hover one link while another holds keyboard focus and two
elements carry the same anchor name — both cards show and anchor
resolution picks one element, so one card positions on the wrong link.
Hard to fix in pure CSS; harmless enough to document and accept.

Related, already filed: the preview text leaking into `/feed/books.xml`
is §1.3 — the `hidden` attribute added for no-CSS browsers doesn't help
feed readers that strip attributes but keep text.

---

## Suggested execution order

1. [DONE] **Feed fixes** (1.1 front matter + comment placement, 1.2 `posts_limit`,
   1.3 books-feed stripping) + CI feed-validity guard — one PR, ships the
   user-visible repair.
2. [DONE] **CI concurrency fix** (2.1) — tiny, prevents silently-untested branches.
3. [DONE] **`/test/` de-indexing** (1.4) and config exclude typo (3.4).
4. [DONE] **Ruby 3.4 upgrade** (4.1) — its own PR; everything is containerized so
   risk is low.
5. [DONE] **Pre-commit hook staging fix** (2.2).
6. [DONE] **Plugin cleanups** (3.1, 3.2, 3.3) — mechanical, each with a test.
7. **Modernization batch** (4.2 drop pagination [DONE, branch
   `drop-pagination`], 4.3 fonts, 4.4 icons, 4.5 dark mode) —
   independent, do as interest allows.
8. **Scheduled external link check** (2.3) [DONE] and housekeeping (§5 —
   Gemfile.lock and feed-drift comment done; README, stale branches remain).
   Follow-up: first local run found ~25 genuinely dead URLs in old posts
   (dead startups, moved university pages, killed publications) — fix by
   swapping to archive.org snapshots; the first scheduled run will list
   them in an issue.
9. [DONE] **Hover-preview fixes** (§8): 8.1 lazy covers is a one-liner with
   outsized payoff; 8.2–8.4 done; 8.5 won't do (clamp removed by decision).
10. [DONE] **Skills sync** (§7): fix the two stale reference docs, add the
    path-existence test, add the sync rule to `AGENTS.md` — one small PR.
11. [DONE] **Plugin consolidation** (§6) — all items complete
    (6.1–6.8), one commit each on `plugin-cleanups`, plus two
    review-hardening commits; build verified output-identical to main.
12. [DONE] **§6.9 post-review follow-ups** — correctness items 1–2 first
    (ShortStoryResolver `@ambiguous` reset; skeleton `else raise`),
    polish items 3–5 optional. Suitable for a delegated session; specs
    and guardrails are in §6.9.
