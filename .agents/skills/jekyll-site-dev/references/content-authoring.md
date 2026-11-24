# Content Authoring

## Excerpts and Opening Paragraphs

Jekyll's excerpt is the first content block before a blank line. Put
`{% capture %}` definitions after the opening paragraph so they do not become
the excerpt. Inline Liquid tags can appear in the opening paragraph. For title
formatting, use `movie_title`, `game_title`, or `tv_show_title`, or write a
`<cite>` element.

## Links and Media Titles

Link to books, authors, and series with `book_link`, `author_link`, and
`series_link`. Raw Markdown or HTML links to those URLs stop the build. If a
book link needs non-title text, use `cite=false` and `link_text=`:

```liquid
{% book_link "The Triumphant" cite=false link_text="before" %}
```

Named options must use supported keys once each and follow `key=value` syntax;
malformed, unknown, or repeated options stop Liquid parsing.

Use the media title tags for creative works other than books:

| Tag | Example |
| --- | --- |
| `movie_title` | `{% movie_title "The Matrix" %}` |
| `game_title` | `{% game_title "Elden Ring" %}` |
| `tv_show_title` | `{% tv_show_title "The Wire" %}` |

Each accepts a quoted title or a Liquid variable, such as
`{% game_title page.title %}`.

## Images

Host images in the repository. Use a root-relative URL or the site's own
absolute URL. Remote, `data:`, or relative image sources stop the build. Use
PNG, GIF, JPEG, WebP, AVIF, another raster format the site can read, or SVG.

For SVG, give the root `<svg>` an absolute `width` and `height` (for example,
px, pt, or mm). Missing or percentage dimensions stop the build. Do not set
`width` or `height` on an `<img>`; size or crop it with CSS.

Book cover derivative sources must be JPEG or PNG with lowercase `.jpg`,
`.jpeg`, or `.png` extensions. Post front-matter images configured for
derivatives must be local JPEG or PNG; SVG is allowed but gets no WebP copies.
Use lowercase extensions. Unsupported files, missing images, and two sources
that would produce the same derived filename stop the build.

## Code Blocks

Use a supported fence language: `bash`, `cpp`, `html`, `liquid`, `python`,
`shell`, `sql`, `vim`, or `yaml`. An untagged fence, `plaintext`, `text`, or a
raw `<pre>` is labeled “Code block.” An unsupported language stops the build.
Do not set `tabindex`, `role`, or `aria-label` on `<pre>`; that stops the
build.

## Headings, Icons, and External Scripts

- A page needs exactly one `<h1>`, and it must be the first heading. Do not
  skip a heading level while going down. Post and book layouts supply the
  title as `<h1>`, so start sections at `##`.
- An inline decorative `<svg>` needs `aria-hidden="true"`. A meaningful SVG
  needs `role="img"` and a non-empty `aria-label`.
- An external script or stylesheet needs `integrity` and `crossorigin`.

Violations stop the content checks or build.

## Math

Write math as `$$...$$`: inline inside a paragraph, or display math with the
delimiters on their own lines. Use the supported subset: letters, numbers,
basic operators, `_` and `^`, `\frac`, `\sqrt`, `\binom`, `\left`, `\right`,
`\textrm`, `\,`, `\{`, `\}`, and the converter's named symbols and functions.
Unsupported TeX stops the build. Math converts only where kramdown parses
Markdown; a figure caption works, but raw HTML blocks do not. MathJax-style
`\(...\)` delimiters are unsupported.

## Kramdown Abbreviations

Kramdown abbreviation definitions such as `*[CERN]: European Organization...`
must be preceded by `<!-- prettier-ignore -->`; otherwise Prettier changes the
syntax and the abbreviation no longer renders. Keep definitions in one
contiguous block with no blank lines. Put another ignore comment before each
separated block.

## Front Matter for AT Protocol Records

Posts and book reviews are published as AT Protocol document records. The
validator stops the build for invalid required fields:

- `title:` is required and must be non-empty.
- Do not set `slug:` or `permalink:` on a post or book review.
- A book review requires `date:`. A post can use its filename date.
- `published: false` skips the page and its record. A `draft:` key in a post
  or book file is not honored; use `_drafts/` for drafts.
- Future-dated posts and reviews are skipped until their date arrives.
- An archived review with `canonical_url:` does not get a record; its
  canonical review owns the document.
- Post `categories:` become record tags. Book reviews receive the fixed
  `book-reviews` tag.

