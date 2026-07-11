# Plugin Development Patterns

## Tag Structure: Thin Wrapper + Delegate

Tags parse arguments in `initialize` and delegate in `render`. They do not
contain business logic.

**Link tags** (`book_link`, `author_link`, `series_link`,
`short_story_link`) subclass `LinkTagBase`
(`_plugins/src/infrastructure/links/link_tag_base.rb`) and declare their
grammar instead of hand-rolling a parser:

```ruby
class BookLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
  self.subject = 'book title'          # noun used in error messages
  self.resolver_class = Jekyll::Books::Core::BookLinkResolver
  self.option_spec = { link_text: :value, author: :value, cite: :value }

  private

  # Required hook: [positional_args, keyword_args] for the resolver's
  # resolve / resolve_data pair.
  def resolver_arguments(context)
    [[subject_value(context), option_value(:link_text, context)], {}]
  end
end
```

The base class parses a positional subject (quoted string or variable)
followed by keyword options in any order (`:value` options take
`name=<quoted or variable>`; `:flag` options are bare words), raises
`Liquid::SyntaxError` for unknown arguments and missing/empty subjects,
and branches on `render_mode` (`resolver.resolve` for HTML,
`resolver.resolve_data` + `MarkdownLinkFormatter` for Markdown).
Optional hooks: `markdown_italic?(data)` and `markdown_result(data,
context)`. Helpers: `subject_value`, `option_value`, `flag?`,
`option_enabled?` (true unless the option resolves to `'false'`/`false`).

A new link tag is its option table plus `resolver_arguments`
(~25 lines); add it to the `LinkTagBase` allowlist comment in
`_tests/src/content/markdown_output/test_render_mode_coverage.rb`.

Key files: `_plugins/src/infrastructure/links/link_tag_base.rb`,
`_plugins/src/content/books/tags/book_link_tag.rb`

## Render Mode Branching

Tags check `context.registers[:render_mode]` to emit HTML or Markdown.

**Simple tags** branch inline:

```ruby
if context.registers[:render_mode] == :markdown
  "_#{text}_"
else
  "<cite class=\"#{css}\">#{text}</cite>"
end
```

**Display tags** use the `DisplayTagRenderable` mixin
(`_plugins/src/ui/tags/display_tag_renderable.rb`):

```ruby
include Jekyll::UI::DisplayTagRenderable

def render(context)
  data = finder.find
  render_display_tag(context, data) do |d|
    SomeRenderer.new(context, d).render
  end
end

# The including class must define this:
def render_markdown(data)
  # Return Markdown string using MdCards helpers
end
```

The mixin calls `render_markdown(data)` in markdown mode, or yields for HTML.
It also exposes the `MdCards` constant (`Jekyll::UI::Cards::MarkdownCardUtils`).

## Finder / Renderer Separation

- **Finders** extract and structure data. Return a hash (e.g.,
  `{ year_groups: [...], log_messages: '' }`). No HTML output.
- **Renderers** convert a data hash to HTML. No data fetching.

This allows independent testing. Finders live alongside their domain
(e.g., `content/books/lists/by_year_finder.rb`). Renderers live in
`lists/renderers/` or alongside the finder.

## LinkResolverSupport Mixin

Shared base for link resolvers (`_plugins/src/infrastructure/links/link_resolver_support.rb`).
Provides:

- `initialize(context)` — extracts `@site`, `@context`, initializes `@log_output`
- `find_in_cache(section, normalized_key)` — O(1) lookup in `site.data['link_cache']`
- `wrap_with_link(inner_html, url)` — delegates to `LinkHelperUtils`
- `log_failure(tag_type:, reason:, identifiers:, level:)` — delegates to `PluginLoggerUtils`

Resolvers include this module and define their own `resolve` / `resolve_data`
methods. There are no separate `*_link_util.rb` wrappers — resolvers contain
all logic directly.

## Error Logging

Use `PluginLoggerUtils.log_liquid_failure` for non-fatal issues:

```ruby
Logger.log_liquid_failure(
  context: @context,
  tag_type: 'RENDER_BOOK_LINK',
  reason: 'Could not find book page in cache.',
  identifiers: { Title: @title },
  level: :info,
)
```

- Returns an HTML comment (visible in page source for debugging).
- Respects per-tag `plugin_logging` config and site `plugin_log_level`.
- For fatal invariant violations, raise `Jekyll::Errors::FatalException` instead.

## Private Constants

Tags and modules alias dependencies as private constants to avoid polluting
the namespace:

```ruby
class SomeTag < Liquid::Tag
  TagArgs = Jekyll::Infrastructure::TagArgumentUtils
  Resolver = Jekyll::Books::Core::BookLinkResolver
  private_constant :TagArgs, :Resolver
end
```
