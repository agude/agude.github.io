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
