# Content Authoring

## Excerpt and Opening Paragraph

Jekyll's excerpt is the first "block" of content (before the first blank
line). A `{% capture %}` block placed _above_ the opening paragraph becomes
the excerpt instead of the actual paragraph text. Therefore:

- **`{% capture %}` definitions must go _after_ the opening paragraph.**
- **Inline Liquid tags work fine in the opening paragraph** (e.g.
  `{% game_title page.title %}`), because they produce output in-place
  without creating a separate block.
- Opening paragraphs that need title formatting but can't use capture
  variables should use the inline title tags (`movie_title`, `game_title`,
  `tv_show_title`) or raw `<cite>` HTML (which `MarkdownHtmlConverter`
  will handle as a fallback).

## Linking to Books, Authors, and Series

**Never use raw Markdown or HTML links** to book, author, or series URLs.
Always use the custom Liquid tags: `book_link`, `author_link`, `series_link`.
`LinkValidator` breaks the build if it finds raw inline (`[text](url)`) or
reference-style (`[ref]: url`) links to these URLs.

Tags with named options reject unknown or repeated keys and malformed
`key=value` syntax during Liquid parsing. Their shared parser is
`TagArgumentUtils.parse_named_arguments`; tags with positional arguments
parse that part locally.

If you need non-title link text (e.g., linking the word "before" to a book
page), use `book_link` with `cite=false` and `link_text=`:

```liquid
{% book_link "The Triumphant" cite=false link_text="before" %}
```

## Media Title Tags

Simple formatting tags for non-book creative works. Emit
`<cite class="...-title">` in HTML, `_italic_` in Markdown.

| Tag             | CSS class       | Example                          |
| --------------- | --------------- | -------------------------------- |
| `movie_title`   | `movie-title`   | `{% movie_title "The Matrix" %}` |
| `game_title`    | `game-title`    | `{% game_title "Elden Ring" %}`  |
| `tv_show_title` | `tv-show-title` | `{% tv_show_title "The Wire" %}` |

Accepts quoted strings or Liquid variables (`{% game_title page.title %}`).
Base class: `ui/tags/cite_title_tag.rb`.

## Images Get Their Size at Build Time

`ImageDimensionsInjector` (`_plugins/src/infrastructure/`) adds `width` and
`height` to every `<img>` in the HTML output: lead images, figures, cards,
previews, and images written in Markdown or raw HTML. The browser then
reserves each image's box before the file loads. The build stops when an
image cannot be sized. Rules for authors:

- Host every image in the repository and reference it by root-relative
  path (`/files/post/plot.png`) or the site's own absolute URL. A remote,
  `data:`, or relative `src` stops the build.
- Use a raster format FastImage reads (PNG, GIF, JPEG, WebP, AVIF) or SVG.
- An SVG needs an absolute `width` and `height` on its root `<svg>`
  element (px, pt, mm, and so on). Matplotlib and Inkscape exports have
  them. A percentage or missing size stops the build.
- Do not set `width` or `height` on an `<img>`; that stops the build. The
  stylesheet's `img { height: auto; }` keeps every image at its file's
  aspect ratio. Size or crop images with CSS, for example a class with
  `max-width`, or `aspect-ratio` with `object-fit`.

Book covers and post lead images also get `srcset` and `sizes`:
`ImageDerivatives` (`image_derivatives` in `_config.yml`) builds WebP
copies at build time, at the widths set there, and the injector offers them.
An entry names its images one of two ways:

- `source_dir: books/covers`: every file in the directory. Add a new cover
  as a JPEG or PNG with a lowercase extension (`.jpg`, `.jpeg`, `.png`); any
  other file there, `Cover.JPG` included, stops the build.
- `front_matter: posts`: the front-matter `image` of every post. It must be
  a local, root-relative JPEG or PNG with a lowercase extension (`.jpg`,
  `.jpeg`, `.png`); an `.svg` is skipped, and anything else, an uppercase
  extension included, stops the build. Post images share `files/<post>/` with plots and data,
  which is why they are listed by front matter and not by directory.

Copies go to a `derived/` directory next to each source. Two sources in one
directory whose names differ only in extension stop the build (`dune.jpg`
and `dune.png` would share `dune-300.webp`), as does an image in two
entries. Extensions are lowercase because the CI cache key globs
`files/**/*.jpg` and the like, which are case-sensitive. The original stays the `src` and the source of the size. The
configured `sizes` describes the lead slot (lead cover, `#lead-image`); a
template whose slot differs sets its own `sizes`, which the injector keeps:
the book-link preview cover (5rem), and the card images
(`BookCardRenderer::COVER_SIZES`, `ArticleCardRenderer::IMAGE_SIZES`).

The widths and `sizes` come from measurement, not from reading the CSS.
`make check-images` (`_scripts/ci/check_image_sizes.py`) loads one or two
pages per image slot in headless Chromium at each breakpoint in
`_sass/_variables.scss` and at 1x, 2x, and 3x, and records each image's
slot width, its `sizes` width, and the width of the file the browser chose,
decoded from the file rather than read from its `srcset` descriptor. Hover
previews are revealed first, and a slot that is never visible fails the
check.
It prints every slot's width range, which is where a new `srcset` should get
its widths: the narrowest slot at 1x to the widest at 2x. For `srcset`
images it fails when `sizes` is more than 5% under or 10% over the slot,
when the chosen file is too narrow for 2x and the source is wider, or when
it is over twice the slot at the screen's density, or when a `srcset`
descriptor differs from its file's width. A change to cover CSS
that moves a slot fails CI until the widths or `sizes` follow.

Lead images (`#lead-image`, `.book-cover-lead`) also carry
`fetchpriority="high"`: measured in November 2026, they are the Largest
Contentful Paint element on post and book pages.

Card images load lazily, with `sizes="auto, <slot sizes>"`, except the
first two on a card-list page: `EagerCardImages` (a `:post_render` hook in
`_plugins/src/infrastructure/`) removes `loading="lazy"` and the `auto, `
prefix from them. The rule is structural, not by layout: a card-list page is
any page whose first `<img>` is a card image. Today that is the book and
blog indexes and the topic, author, and series pages, and also a post with
`hide_lead_image: true` whose first image is an inline card. A page whose
first image is anything else, such as a lead image, keeps every card lazy.
Measured in November 2026, the Largest Contentful Paint element of a
card-list page is its first or second card, and lazy loading delayed it: a
lazy image waits for layout.

A card that states `sizes` but whose image has no derivatives (an SVG, or a
file outside every entry) loses its `sizes` in the injector: `sizes`
without `srcset` is invalid HTML.
`make check-images` fails when any sampled page's Largest Contentful Paint
element is a lazy image, and when a page gives no reading at all. It
samples two pages per URL directory and first-image slot, and waits for
network idle, because a lazy image does not delay `load`.

## Code Blocks Are Labeled Scroll Regions

`CodeBlockRegionInjector` (`_plugins/src/infrastructure/`) adds
`tabindex="0" role="region" aria-label="..."` to every `<pre>` in the HTML
output, so a keyboard user can focus a code block and scroll it sideways.
It runs at `:post_render` priority `:low`, after `FootnotePreviewInjector`,
so the hidden footnote-preview copy of a code block gets no tab stop.
`_sass/_code.scss` draws the focus ring around the `.highlight` block in
`--accent-color`. Rules for authors:

- Give a fence a language from `LANGUAGE_NAMES` in the injector. The label
  is the language's spoken name plus "code" ("Python code"). A language
  missing from the map stops the build; add it with its spoken name.
- An untagged fence, `plaintext`, `text`, or a raw `<pre>` gets
  "Code block".
- Do not set `tabindex`, `role`, or `aria-label` on a `<pre>`; that stops
  the build.

## Headings, Icons, and External Scripts

Three markup rules are enforced; each fails CI.

- **Heading outline** (`_bin/heading_outline_check.rb`, an html-proofer
  check run by `make check-links`): a page has exactly one `<h1>`, the
  `<h1>` is its first heading, and no heading skips a level going down.
  Going up any number of levels is fine. Post and book layouts render the
  title as the `<h1>`, so sections in Markdown start at `##`, never `#`.
  The Markdown test page (`test/index.html`) is exempt. This runs over
  `_site/` rather than as a build hook because it applies to every page,
  and the plugin tests' fixture sites and fake pages have no outline.
- **Inline SVG** (`InlineSvgValidator`, a `:post_render` build hook): every
  inline `<svg>` has `aria-hidden="true"`, or `role="img"` with an
  `aria-label` if it means something on its own. The icon includes in
  `_includes/icon-*.svg` are decorative and carry `aria-hidden="true"`.
- **Subresource Integrity** (`_bin/subresource_integrity_check.rb`, run by
  `make check-links`): an external `<script src>` or stylesheet needs
  `integrity` and `crossorigin`. html-proofer's own `check_sri` is a no-op
  here, because `check_links.rb` ignores every http(s) URL and html-proofer
  skips ignored URLs before checking SRI. The site loads no external
  scripts today; the check keeps a new one from arriving without a hash.

## Math Is MathML, Converted at Build Time

Write math in `$$...$$`: inline inside a paragraph, display when the
`$$` lines stand alone. `TexToMathml`
(`_plugins/src/infrastructure/tex_to_mathml.rb`) converts it to MathML
during the kramdown pass, and browsers render MathML natively. There is no
MathJax, no script, no CDN, and no front-matter switch.

Math converts only where kramdown parses Markdown. Figure captions work
(`figure.html` marks `<figcaption markdown="span">`); raw HTML blocks do
not. `_bin/raw_tex_check.rb`, run by `make check-links`, fails on raw TeX
in page text outside code and MathML: a delimiter (`$$`, `\(`, `\[`) or a
command (`\phi`). MathJax's `\(...\)` form is not supported; kramdown reads
`\(` as an escaped parenthesis.

- It supports a small TeX subset: letters, numbers, basic operators, `_`
  and `^`, `\frac`, `\sqrt`, `\binom`, `\left`/`\right`, `\textrm`, `\,`,
  `\{ \}`, and the names in its `SYMBOLS` and `FUNCTIONS` tables. Anything
  else stops the build, naming the expression and line. Extend the
  converter rather than adding a math library.
- It registers under kramdown's `mathjax` engine name, replacing kramdown's
  built-in engine, because Jekyll requires a `kramdown-math-<name>` gem for
  any other name (`kramdown.math_engine` in `_config.yml`).
- Plain `( ) [ ]` get `stretchy="false"`: TeX stretches only `\left`/`\right`
  delimiters, but MathML stretches fence characters by default, and Firefox
  then grows them to the height of a neighboring fraction.
- An operator that is a whole script (`M_\pm`, `e^-`) gets
  `lspace="0" rspace="0"`; otherwise it keeps its infix spacing and leaves
  a gap after the script.
- A display equation is wrapped in `<div class="math-display">`, which
  scrolls when the equation is wider than the column. Firefox and WebKit do
  not scroll a `<math>` element itself.
- Math renders in "Gude Math", a 32 KB self-hosted subset of Latin Modern
  Math (`assets/fonts/gude-math-latin-modern-subset.woff2`, declared in
  `_sass/_fonts.scss`), so it looks the same on every platform and does not
  depend on a system math font. Browsers download it only on pages with
  `<math>`. `_scripts/fonts/subset_math_font.py` builds it from the CTAN OTF:
  it keeps the MATH table (stretchy radicals and brackets), takes its
  character list from the non-ASCII characters in `tex_to_mathml.rb` plus
  ASCII, the radical sign, and the math-italic letters, and renames the font
  as the GUST Font License asks.
- **License.** The GUST Font License is LPPL 1.3c, whose clause 6 governs
  modified versions. The script writes the required notices into the font's
  name table (original copyright, new name, a description of the changes,
  non-support by the original authors, where the original is), and
  `LICENSE.md` lists both fonts and their licenses.
- **Adding a symbol to the converter means rebuilding the font.**
  `_scripts/tests/test_subset_math_font.py` (`make test-scripts`) fails until
  the committed font covers every character the converter can emit.
- `math { font-size: 1.244em }` in `_sass/_base.scss` matches the size
  MathJax used: math fonts have a smaller x-height than the body font.
- Checked in Chromium, Firefox, and WebKit, light and dark, against MathJax
  renders, at 390 px wide, and with no system math font installed.

## Kramdown Abbreviations Need Prettier Protection

Kramdown abbreviation definitions (`*[CERN]: European Organization...`)
are not CommonMark, and Prettier rewrites `*[` to `_[`, which kramdown
does not recognize — every `<abbr>` silently disappears and the
definitions render as literal text. Both `make format-md` and the
pre-commit hook run Prettier, so any abbreviation block **must** be
preceded by `<!-- prettier-ignore -->`:

```markdown
<!-- prettier-ignore -->
*[CERN]: European Organization for Nuclear Research
*[CMS]: Compact Muon Solenoid
```

The comment protects one contiguous block (a single CommonMark node).
Keep all definitions together with no blank lines between them; a
second block separated by a blank line needs its own comment. The only
current use is `_posts/2018-05-20-my_phd_thesis.md`.

## Front Matter Rules for AT Protocol Records

Every post and book review gets a `site.standard.document` record on
the AT Protocol (see
[AT Protocol / standard.site](atproto-standard-site.md)). CI enforces
these at validate time — violations fail the build:

- `title:` is required and must be non-empty (a bare `title:` parses
  to null and is rejected).
- `slug:` and `permalink:` front matter are **forbidden** on posts and
  books: Jekyll would serve the page away from the filename-derived
  path, leaving the AT record pointing at a 404.
- Books require a `date:` key (posts fall back to the filename date).
- `published: false` skips the page and its record. A `draft:` key is
  **not** honored (Jekyll ignores it outside `_drafts/`).
- Future-dated posts are skipped (matching Jekyll's `future: false`)
  and picked up automatically once their date arrives.
- A book with `canonical_url:` (re-read reviews) gets **no** record —
  the canonical review page owns the document.
- Post `categories:` become record tags; books get a fixed
  `book-reviews` tag.
