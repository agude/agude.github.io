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

The converter protects fenced code blocks using backticks or tildes and
inline code spans with matching delimiter lengths before converting inline HTML.

The figure include emits its image and optional caption in Markdown mode;
the caption then passes through `MarkdownHtmlConverter` so supported inline
HTML is converted.

The video include emits a `[Video](file)` link in Markdown mode while
preserving its video markup in HTML mode.

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
