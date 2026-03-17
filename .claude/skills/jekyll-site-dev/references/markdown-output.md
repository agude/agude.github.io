# Markdown Output Pipeline

Generates clean `.md` files for every page and a `/llms.txt` index.

## Data Flow

```
PRE-RENDER (:documents/:pages, :pre_render)  [markdown_body_hook.rb]
  │  Eligibility check → Standalone Liquid::Template.parse()
  │  render_mode: :markdown → Tags emit Markdown instead of HTML
  │  Stores data['markdown_body'] + data['markdown_alternate_href']
  ▼
POST-RENDER (:site, :post_render)  [markdown_output_assembler.rb]
  │  For each item with markdown_body:
  │    Header (post/book/generic) + Body + Footer (related content)
  │    → MarkdownWhitespaceNormalizer → GeneratedStaticFile (.md)
  ▼
LLMS.TXT (:site, :post_render)  [llms_txt_generator.rb]
     Indexes all .md files → /llms.txt with absolute URLs
```

## Key Files (`content/markdown_output/`)

| File                           | Purpose                                                                                                               |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `markdown_body_hook.rb`        | Pre-render hooks; re-renders content with `render_mode: :markdown` using standalone template (avoids cache pollution) |
| `markdown_output_assembler.rb` | Post-render hook; assembles header + body + footer into `.md` files                                                   |
| `markdown_card_utils.rb`       | Formats card data hashes as Markdown list items (`- [Title](url) by Author --- stars`)                                |
| `markdown_link_formatter.rb`   | Formats resolved link data as `[text](url)` for link tags                                                             |
| `llms_txt_generator.rb`        | Generates `/llms.txt` index grouped by Blog Posts, Book Reviews, Optional                                             |

## Render Mode Pattern

Tags check `context.registers[:render_mode]` to branch output:

```ruby
def render(context)
  if context.registers[:render_mode] == :markdown
    # Emit Markdown via MarkdownCardUtils / MarkdownLinkFormatter
  else
    # Emit HTML via existing Renderer classes
  end
end
```

Tags with render_mode support: all link tags (`book_link`, `author_link`,
`series_link`, `series_text`, `short_story_link`), all display tags (`display_books_by_year`,
`display_books_by_author_then_series`, `display_books_by_title_alpha_group`,
`display_ranked_books`, `display_awards_page`, `display_books_by_author`,
`display_books_for_series`, `display_category_posts`, `front_page_feed`,
`render_article_card`).

## Gotchas

- **Cache pollution:** The pipeline uses `Liquid::Template.parse()` directly
  (not `site.liquid_renderer`) because Jekyll caches templates by filename and
  `render()` mutates `@registers` with `merge!()`. Using the site renderer
  would leak `render_mode: :markdown` into the HTML pass.
- **Document URL access:** `Jekyll::Document#['url']` reads `data['url']`
  (nil), not `doc.url`. When passing documents to Finders outside Liquid
  context, merge url into data: `item.data.merge('url' => item.url)`.
  `MockDocument` masks this with special `['url']` handling; use `RealDocLike`
  wrapper in tests to catch regressions.
- **Page payload snapshot:** `Page#to_liquid` returns a plain `Hash`
  (snapshot at call time), while `Document#to_liquid` returns a live
  `DocumentDrop`. In `Renderer#run`, `assign_pages!` calls `to_liquid`
  _before_ the `:pre_render` hook fires. Data set in `:pre_render` hooks is
  visible for Documents (live Drop) but **not** for Pages (stale Hash). Fix:
  in `:pages` hooks, also inject into `payload['page']` directly.
- **Strict Liquid:** `render_mode` must always be defined in the payload
  (set to `'html'` by default in pre-render hooks) for strict variable mode.
- **Config:** Feature controlled by `enable_markdown_output` (default: `true`).
  Documents/pages opt out with `markdown_output: false` in front matter.
