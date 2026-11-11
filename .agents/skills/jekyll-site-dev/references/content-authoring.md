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

Book covers also get `srcset` and `sizes`: `ImageDerivatives`
(`image_derivatives` in `_config.yml`) builds WebP copies, at the widths set
there, of every file in `books/covers/` at build time, and the injector
offers them. Add a new cover as a JPEG or PNG; any other file in that directory
stops the build, as do two covers whose names differ only in extension
(`dune.jpg` and `dune.png` would share `dune-300.webp`). The original stays
the `src` and the source of the size. The configured `sizes` describes the
lead cover; a template whose cover slot differs sets its own `sizes`, which
the injector keeps (the book-link preview cover, 5rem).

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
