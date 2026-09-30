# Markdown output

`MarkdownBodyHook` prepares Markdown for eligible posts, books, and pages in
`:pre_render`. `MarkdownOutputAssembler` writes the `.md` files in
`:post_render`.

The assembler passes document objects directly to related-content finders.
Finders read URLs through `PageUrl.fetch`, which supports document accessors
and Liquid page hashes. Do not copy document data just to add a `url` key.

The pre-render hooks set `render_mode` to `html` for Jekyll's normal render.
The Markdown pass temporarily sets it to `markdown` and restores the prior
value before returning. Pages also copy `markdown_alternate_href` into
`payload['page']` because their Liquid payload is a snapshot.

The figure include emits its image and optional caption in Markdown mode;
the caption then passes through `MarkdownHtmlConverter` so supported inline
HTML is converted. The video include emits a `[Video](file)` link in Markdown
mode while preserving its video markup in HTML mode. The converter protects
fenced code blocks using backticks or tildes and inline code spans with
matching delimiter lengths before converting inline HTML. Fence boundaries are
shared with the whitespace normalizer and include list and blockquote
containers. Inline spans do not cross blank lines. It converts `<em>`
tags to Markdown emphasis and `<strong>` tags to Markdown strong emphasis
before converting enclosing anchors to Markdown links. Horizontal rules become
Markdown thematic breaks with blank-line boundaries. Balanced `low-width-table`
div wrappers and spans whose only inline style is `color` are stripped while
their contents remain. Presentation spans with
`nowrap` or `band-name` classes are stripped while their contents remain, and
`author-name`, `book-series`, `written-by`, `nowrap`, and `band-name` spans are
stripped by a balanced span/div traversal. `written-by` divs become separate
Markdown paragraphs, while the supported ChatGPT wrapper divs are removed and
other div/span wrappers remain intact.

The final Markdown whitespace pass trims prose line endings and collapses
excess blank lines, while preserving hard-break spaces and whitespace inside
fenced or indented code blocks.

The ChatGPT edit include keeps its compact HTML markup for HTML rendering. In
Markdown mode it emits Prompt and Output labels with quoted content indented as
footnote continuation, preserving paragraph breaks, list lines, and fenced
code bytes inside the quote.
Handwritten wrappers with the `chatgpt-edit-block`, `chatgpt-prompt`,
`chatgpt-output`, `chatgpt-prompt-only`, and `chatgpt-output-only` classes are
also removed in Markdown output while preserving their labels and Markdown
content.

`books_topbar.html` emits the cached sort links as Markdown links. The linktree
page keeps its author links and accessible link text while omitting decorative
icons and layout divs from Markdown output; HTML retains its container and
icons. The topics index emits a Markdown list and headings with explicit topic
anchors, then renders each topic's post links.

Disclosure blocks (`<details>` and `<summary>`) are flattened in Markdown
output. The summary and answer body remain in order with paragraph boundaries;
their existing Markdown formatting is preserved, and code fences remain
protected from conversion.

Markdown headers and book/article card links replace `<br>` variants in titles
with a single space before escaping link text. Card data extraction keeps the
document's raw title; the renderer normalizes a local value, so HTML continues
to use the original title.

`DisplayAwardsPageTag` fetches awards and favorites through
`Books::AwardsPage::Finder` once per render pass. It sends the prepared data
to `HtmlRenderer` or `MarkdownRenderer` according to `render_mode`.

Markdown generation errors for eligible items raise
`Jekyll::Errors::FatalException` with the item's URL. Do not log and drop the
Markdown twin: that would publish a successful build with missing output.
`enable_markdown_output: false` and per-item `markdown_output: false` remain
the explicit ways to skip generation.

For changes to this pipeline, run `make test`, `make build`, and the three
content checks: `make check-links`, `make check-refs`, and `make check-liquid`.
