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
