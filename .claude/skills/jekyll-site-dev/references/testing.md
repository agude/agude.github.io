# Testing Conventions

## Structure

Tests mirror `_plugins/src/` exactly:

```
_plugins/src/content/books/lists/by_year_finder.rb
_tests/src/content/books/lists/test_by_year_finder.rb
```

Naming: `test_{plugin_name}.rb`. Multi-file matches are allowed:
`test_user.rb` and `test_user_integration.rb` both match `user.rb`.

Run tests: `make test` (all) or `make test TEST=_tests/src/path/to/test.rb`.

## test_helper.rb

All tests require `_tests/test_helper.rb`. It provides:

### Mock Objects

**MockDocument** — `Struct` with `data`, `url`, `content`, `date`, `site`,
`collection`, `relative_path`, `path`. Special `[]` accessor handles `'url'`,
`'content'`, `'date'`, `'title'` by delegating to struct fields, then falls
back to `data[key]`. Also overrides `is_a?` (Document if collection is set,
Page otherwise) and `to_liquid` (returns self).

**MockSite** — Full class with `config`, `collections`, `pages`, `posts`,
`baseurl`, `source`, `converters`, `data`, `categories`, `static_files`.
Provides `documents` (aggregates all collection docs), `in_source_dir`,
`find_converter_instance`, `show_drafts`.

**MockCollection** — `Struct.new(:docs, :label)`.

### Factory Methods

- `create_context(scopes, registers)` — builds a `Liquid::Context`.
- `create_site(config_overrides, collections_data, pages_data, posts_data, categories_data)` — builds a `MockSite` with default config and auto-generates `link_cache`.
- `create_doc(data_overrides, url, content, date_str, collection)` — builds a `MockDocument` with sensible defaults.

### Helpers

- `silent_logger` — no-op logger stub. Use with `Jekyll.stub(:logger, silent_logger) { ... }` when testing code that triggers warnings/errors.
- `generate_link_cache(site)` — runs `LinkCacheGenerator` against a MockSite. Called automatically by `create_site`.

## MockDocument vs RealDocLike

**MockDocument** has special `['url']` handling: `doc['url']` returns
`doc.url` (the struct field). Real `Jekyll::Document#['url']` returns
`data['url']` which is nil.

**RealDocLike** is a test wrapper that mimics real Document behavior:

```ruby
class RealDocLike
  attr_reader :data, :url

  def initialize(mock_doc)
    @data = mock_doc.data.dup
    @data.delete('url')
    @url = mock_doc.url
  end

  def [](key)
    @data[key.to_s]
  end
end
```

Use RealDocLike when testing code that operates on documents outside Liquid
context (e.g., assemblers, generators) to catch `doc['url']` bugs.

## Common Test Patterns

### Stub-and-capture for tags

Mock the resolver to capture arguments passed by the tag:

```ruby
mock_resolver = Minitest::Mock.new
mock_resolver.expect(:resolve, '<a>link</a>') do |title, link_text, author, date, cite:|
  captured = { title: title, cite: cite }
  true
end

ResolverClass.stub :new, mock_resolver do
  output = Liquid::Template.parse("{% some_tag 'Title' %}").render!(context)
  mock_resolver.verify
end
```

### Finder + Renderer orchestration

Stub both finder and renderer, verify the tag wires them together:

```ruby
mock_finder = Minitest::Mock.new
mock_finder.expect :find, { year_groups: [...], log_messages: '' }

mock_renderer = Minitest::Mock.new
mock_renderer.expect :render, '<h1>HTML</h1>'

FinderClass.stub :new, ->(_) { mock_finder } do
  RendererClass.stub :new, ->(ctx, data) { mock_renderer } do
    output = Liquid::Template.parse('{% display_tag %}').render!(context)
  end
end
```

### Render mode testing

Create a context with `render_mode: :markdown` and assert no HTML in output:

```ruby
md_context = create_context({}, { site: site, page: doc, render_mode: :markdown })
output = Liquid::Template.parse('{% display_tag %}').render!(md_context)
assert_match(/^## /, output)
refute_match(/<div/, output)
```

## SimpleCov

- Threshold: 95% line + branch coverage.
- Output: `_coverage/` directory.
- Single-file test runs may exit with code 2 (coverage threshold not met across full suite). This is normal.
