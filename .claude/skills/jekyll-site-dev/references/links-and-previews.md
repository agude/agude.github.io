# Links, Backlinks, and Previews

How cross-references between reviews are discovered, scored, rendered, and
validated. Source of truth is the code; this file records the design
constraints that are not obvious from reading it.

## BacklinkBuilder scans raw Liquid, not rendered output

`_plugins/src/infrastructure/link_cache/backlink_builder.rb` reads raw template
text. Consequences:

- `link=false` is invisible unless the scanner filters it explicitly.
  `LINK_FALSE_PATTERN` matches all three quoting styles (`'false'`, `"false"`,
  bare `false`), including mixed quoting like
  `{% series_text 'Honor Harrington' link="false" %}`. When it matches inside a
  tag the scanner skips it — no link rendered means no backlink.
- **Both series tag names must be scanned.** `scan_quoted_series_tags` handles
  `{% series_link "Name" %}` / `{% series_text "Name" %}`;
  `scan_variable_series_tags` handles `{% series_link page.series %}` /
  `{% series_text page.series %}` and resolves `page.series` from front matter.
  `series_text` is used in 80+ places for a book referencing its own series.
  Scanning only `series_link`, and only with quoted arguments, is what left
  books like `field_of_dishonor.md` with no backlinks (#144).
- `scan_book_links` is deliberately narrower — `book_link` is only ever used
  with `page.title` (self-reference, filtered by `add_backlink`) or a quoted
  title, so it needs no variable-path branch.

**Footnote previews never double-count.** BacklinkBuilder scans `doc.content`
in the generator phase; `FootnotePreviewInjector` modifies `item.output` at
`:post_render`. The scan has finished before injection occurs.

## Related-books scoring

The related-books block fills 3 slots via a **waterfall** of tiers: series →
author → mentioned **works** → mentioned **series**.

Books and short stories compete together in the "mentioned works" tier. A
`short_story_link` URL resolves to its **parent book URL**, so book and
short-story mentions of the same work **merge their counts** (a `hyperion`
capture plus a `the_detectives_tale` capture is count 2).

Ranking within a tier: count desc → position asc (earlier in the document
wins) → date desc → title asc.

**Archived re-reviews must be filtered.** Re-reviewed books (only Hyperion and
Fall of Hyperion) have a `canonical_url` starting with `/`, and links must
point at the canonical page rather than the old review. The filter
(`canonical_url&.start_with?('/')`) belongs in `BookLinkResolver`,
`Related::Finder`, `Books::Lists::Shared`, `BacklinkBuilder#extract_book_link`,
and `ShortStoryBuilder` — the last two were missed originally.

## The apostrophe regression

`extract_quoted_string` once used `/['"]([^'"]+)['"]/`, which truncated
double-quoted titles at the first apostrophe (`"The Detective's Tale"` →
`"The Detective"`), silently breaking ~27 titles (Ender's Game, Childhood's
End, Dragon's Egg, …) for **both** forward links and backlinks.

The fix tries the double-quote pattern first, then single-quote
(`/"([^"]+)"/ || /'([^']+)'/`). All four link types share this code path; each
has an apostrophe test. Keep them.

## Hover previews

CSS-only (no JS) hover cards on cross-page book links.

- **Markup.** `BookPreviewRenderer` emits a single-line, span-only mini card
  (cover, bold-italic title, author, stars, series number, plain-text lede) as
  the last child inside the `<a>`, wrapped in
  `<!--book-preview-->…<!--/book-preview-->` markers. **Span-only is a hard
  requirement** — nested `<a>` is invalid HTML and links sit inside `<p>`. The
  span also carries the native `hidden` attribute as a no-CSS fallback (Wayback
  Machine, RSS readers); author CSS `display` overrides `hidden`.
- **Injection.** `wrap_with_link` → `_generate_link_html` adds the preview only
  in the real cross-page-link branch, so self-links and same-page anchors get
  none for free. Short-story links show the **parent book's** card.
- **Lede.** The target book's excerpt stripped to plain text. Jekyll's
  `Excerpt#output` renders lazily so order doesn't matter, but a
  `_building_lede` re-entrancy guard on `site.data` is required to prevent
  infinite mutual recursion between cross-referencing reviews. `url_to_book_doc`
  (a live Document map) is stored on `site.data` directly, **not** in
  `link_cache`, which stays pure serializable data.
- **Leak stripping.** `TextProcessingUtils.strip_link_previews` removes
  marker-delimited blocks; it is applied in `strip_tags`, SEO meta
  descriptions, markdown mirrors/llms.txt, and a `feed.xml` override via the
  registered `strip_link_previews` Liquid filter. Any new output surface needs
  the same treatment.

### Preview CSS positioning

`_sass/_previews.scss`. Hidden by default; revealed on `a:hover` /
`a:focus-visible` under `@media (hover: hover) and (pointer: fine)`;
print-hidden.

Baseline: `.container` has `position: relative` and the preview centers in the
text column via `left: 0; right: 0; margin-inline: auto`. Vertical position
comes free from the static position, since the span sits right after the link
text in the DOM.

Enhancement under `@supports (anchor-name: --a)`: CSS Anchor Positioning with
`position: fixed`, `top: anchor(bottom)`, `left: anchor(left)`, and four
`position-try-fallbacks` (flip-inline/flip-block combos). `anchor-name` is set
only on `:hover`/`:focus-visible` so exactly one anchor exists at a time.

### Footnote previews

Same architecture, one extra constraint: footnote refs live inside `<p>` →
`<sup>`, so the preview must be **phrasing-only** content. Block elements in
footnote bodies (`blockquote`, `figure`, `figcaption`, `div`, `ol`, `ul`, `li`,
`p`) are renamed to `<span class="fnp fnp-<tag>">` and CSS reconstructs block
layout via `display: block`. `assert_phrasing_only` fails the build on
unexpected block elements.

**`footnote_preview_injector.rb` must stay on `Nokogiri::HTML` (HTML4).**
HTML5's stricter `<p>` content model ejects `<figure>` from inside `<p>`, but
kramdown produces `<p><figure>…</figure></p>` in footnote bodies. The HTML4
parser preserves the nesting; HTML5 breaks it.
`test_inject_figure_nested_in_paragraph` guards this. The other four
`Nokogiri::HTML` call sites were migrated to HTML5 safely because they do
`.text` extraction only.

## Reference links

`check_reference_links.rb` (`make check-refs`, plus a CI step) fails the
build on three problems in `[text][id]` / `[id]:` markdown reference links:

| Problem | Why it is fatal |
|---|---|
| Undefined `[text][id]` | Kramdown emits the literal source text |
| Duplicate `[id]:` | Kramdown keeps the **first** definition silently |
| Orphaned `[id]:` | Usually a link that was set up and never attached |

- **No other gate can catch this class.** Worth knowing before reaching for
  one of them, because all three look like "strict mode" and none overlap:
  - **html-proofer is blind to it.** An unresolved reference renders as
    literal bracket text plus a bare URL paragraph. There is no `<a>` tag, so
    there is nothing for it to report — the page is valid HTML that happens
    to be wrong. This is how a bare Wikipedia URL reached production.
  - **`check_strict.rb` is blind to it.** That gate runs documents through
    **Liquid** strict mode. Kramdown parses afterwards, so `[text][id]` is
    plain text as far as Liquid is concerned.
- **Orphans are errors, not warnings.** They look like harmless dead weight,
  but of the ten found when the check was written, five were a definition
  whose reference was never written — the prose rendered as plain text with
  nothing to show for it, which is invisible on the page. The other five were
  deleted. The site sits at zero, so any new orphan is a fresh mistake.
- **Kramdown's own warnings are not usable.** It has no strict/error mode at
  all — it only collects `.warnings` passively, and Jekyll discards them
  unless `show_warnings` is set. Even then they are never fatal, so
  log-scraping was the only path the config offered. They also fire on
  shorthand `[id]` references — indistinguishable from editorial brackets in
  prose (`[sic]`, `[…]`). For the same reason the checker only reports
  *undefined* for full-form `[text][id]`; shorthand refs are used solely to
  keep a definition from counting as orphaned.
- **Scanning logic lives in `_bin/reference_link_scanner.rb`**, a pure module
  with no Jekyll dependency, tested by
  `_tests/bin/test_reference_link_scanner.rb`. `check_reference_links.rb` only
  loads the site and prints. Add regression cases to the test, not to the
  script.
- **Liquid is neutralized, never deleted.** Every `{{ … }}` / `{% … %}` becomes
  a placeholder word that keeps the surrounding markdown structure and the
  line count. Deleting is what produced the original false positives:
  - dropping `{% capture %}` bodies lost the references inside them
    (`{% capture x %}[{% movie_title … %}][soldier]{% endcapture %}` made
    `[soldier]:` look orphaned);
  - truncating a definition line at its first Liquid tag lost references after
    it, which footnote definitions routinely have
    (`[^lampshade]: {{ author }} [lampshades][lampshade] this.`).
- **Line numbers are file lines.** `doc.content` has the front matter
  stripped, so `content_line_offset` locates the body inside the raw file and
  adds the difference. Any transform that changes the line count (comments,
  fenced code, multi-line Liquid tags) must emit the same number of newlines
  it consumed.
- **A definition inside a paragraph splits it.** When fixing an undefined
  reference, put `[id]:` after the whole paragraph, not on the first blank
  line found — a definition block ends the paragraph and the remaining lines
  start a new `<p>`.

## Strict Liquid

`check_strict.rb` runs a full build with strict Liquid and catches
`Liquid::UndefinedVariable`, rendering per-document and skipping `feed/` and
`sitemap/`.

- **`_config.yml` cannot just enable strict mode.** `jekyll-feed` generates
  `feed/books.xml` with an undefined `lang` variable, which crashes the whole
  build. Rendering documents individually and skipping those templates is the
  workaround.
- **It only runs in CI**, not pre-commit or pre-push: it needs a full site
  build. CI catches it on push and the feedback delay is small. A Jekyll plugin
  intercepting the render would work but costs maintenance for seconds of
  latency.
- **A lightweight static check cannot replace it.** A regex pass for
  `{{ undefined_var }}` can't know what is in scope without full site context.
  #142 was closed won't-fix for this reason.

**Include-parameter gotcha.** Under strict Liquid, referencing an unpassed
include parameter throws `undefined variable include` — even
`include.foo | default: false` fails, because the whole `include` object is
undefined when no params were passed. Fix on the **caller** side by passing the
param explicitly (`{% include markdown_alternate_link.html standalone=false %}`).
Do not rely on a `default:` filter inside the include.
