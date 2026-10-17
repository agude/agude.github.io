# Links, Backlinks, and Previews

How cross-references between reviews are discovered, scored, rendered, and
validated. Source of truth is the code; this file records the design
constraints that are not obvious from reading it.

## BacklinkBuilder scans raw Liquid, not rendered output

`_plugins/src/infrastructure/link_cache/backlink_builder.rb` parses each
book's raw template text (`doc.content`) into a Liquid abstract syntax tree
(AST). It walks the tree to find tags listed in `LINK_TAGS`. Malformed Liquid
stops the build. It does not execute Liquid branches.

**Targets come from the tag's own parse, not a second parser.**
`LinkTagTargetResolver` (same directory) reads `link_arguments` from each tag
node: the positional subject, value options, and bare flags that
`LinkTagBase#parse_markup` (or `SeriesTextTag`) already parsed. It then applies
the renderer's lookup rules:

- `book_link`: archived reviews are skipped. `BookCandidateSelector` picks
  among same-titled books by `author=`, through `AuthorLookup`. An author with
  no matching book, or an ambiguous title with no `author=`, links nowhere.
  `book_link` has no date option.
- `author_link`: the name resolves through the `authors` cache, so pen names
  reach the canonical page; `link=false` links nowhere.
- `short_story_link`: `ShortStoryLocationSelector` picks the location. The
  sole canonical location wins, then a story that appears in only one book,
  then `from_book=`. So `from_book=` naming an archived review, or naming no
  book that has the story, still links the canonical location.
  `from_book=` is read as a literal in either quoting style, apostrophes
  included.
- `series_link`, `series_text`: a quoted name or `page.series`, which resolves
  from front matter; `series_text ... link=false` links nowhere. Books use
  `series_text` in 80+ places to reference their own series; scanning only
  `series_link` once left books such as `field_of_dishonor.md` without
  backlinks (#144).
- A variable subject (other than `page.series`) cannot be resolved without
  rendering and produces no edge. Earlier, a quoted option value elsewhere in
  the tag (`link_text="Label"`) was mistaken for the title.
- A variable `author=`, `from_book=`, or `link=` stops the build with the file
  and the tag. Reading `author=` as absent recorded a backlink when the
  variable named an author whose book was not the link's target. Reading
  `link=some_var` as text recorded a backlink when the variable was `false`,
  and reading unquoted `link=FALSE` as false recorded none although the
  renderer links: Liquid literals are case-sensitive, so `FALSE` is an unset
  variable. For `link=`, the unquoted literals `true`, `false`, and `nil` are
  values. Quote any other value.

**The selection rules exist once.** `BookCandidateSelector` and
`ShortStoryLocationSelector` in `infrastructure/link_cache/` are pure: they
return the chosen entry or a reason symbol. `BookLinkResolver` and
`ShortStoryResolver` call them and add logging or the ambiguity error;
`LinkTagTargetResolver` calls them and records no edge. `link=` is false
through `TagArgumentUtils.false_value?` in both the renderer and the builder,
so `link=" false "` and `link="FALSE"` disable both. Before these were
shared, the builder's copies drifted: it stripped `link=` values and the
renderer did not, and it applied `from_book=` before the canonical location.
`TestBacklinkRendererParity` renders each case and builds its backlinks from
the same source.

A tag node without `link_arguments` (a parse-only stub registered by
`ensure_stub_tags_registered`) stops the build: the real tag must be loaded.

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
`Related::Finder`, `Books::Lists::Shared`, `LinkTagTargetResolver`,
and `ShortStoryBuilder` — the last two were missed originally.

## The apostrophe regression

A quoted-string regex once used `/['"]([^'"]+)['"]/`, which truncated
double-quoted titles at the first apostrophe (`"The Detective's Tale"` →
`"The Detective"`), silently breaking ~27 titles (Ender's Game, Childhood's
End, Dragon's Egg, …) for **both** forward links and backlinks. Reading the
tag's own parse removed that regex. Each link type still has an apostrophe
test, and `TestBacklinkRendererParity` compares rendered targets with edges.
Keep them.

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
  marker-delimited blocks. It is used by `strip_tags` and `clean_text_from_html`.
  Previews are stripped from SEO meta descriptions, JSON-LD `reviewBody` and
  `articleBody`, Markdown mirrors, and `llms.txt`. The `feed.xml` override uses
  the registered `strip_link_previews` Liquid filter;
  `strip_feed_previews_hook.rb` handles every other `.xml` page. Apply the
  same stripping to any new output surface.

`JsonLdBuilder` cleans article text once per instance for `articleBody` and
`wordCount`, including empty results. Description field precedence remains
independent of this cache.

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

**`footnote_preview_injector.rb` parses with `Nokogiri::HTML5`, read-only.**
It copies each footnote body out of the parsed tree and injects the preview by
string replacement on the original HTML, so the page is never re-serialized.
Kramdown can emit `<p><figure>…</figure></p>` in a footnote body. The HTML5
parser closes the `<p>` before `<figure>` and makes the figure its sibling.
The preview copies the whole footnote `<li>`, so no content is lost, and the
empty `<p>` left behind becomes an empty `fnp-p` span.
`test_inject_figure_nested_in_paragraph` guards this case. Every other
Nokogiri parse in `_plugins/` also uses `Nokogiri::HTML5`.

## Reference links

`check_reference_links.rb` (`make check-refs`, plus a CI step) fails the
build on three problems in `[text][id]` / `[id]:` markdown reference links:

| Problem                | Why it is fatal                                   |
| ---------------------- | ------------------------------------------------- |
| Undefined `[text][id]` | Kramdown emits the literal source text            |
| Duplicate `[id]:`      | Kramdown keeps the **first** definition silently  |
| Orphaned `[id]:`       | Usually a link that was set up and never attached |

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
  _undefined_ for full-form `[text][id]`; shorthand refs are used solely to
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
