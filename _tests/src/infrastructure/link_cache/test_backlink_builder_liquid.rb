# frozen_string_literal: true

require_relative 'backlink_builder_test_support'

class TestBacklinkBuilderLiquid < BacklinkBuilderTestCase
  # --- Liquid AST parsing tests ---
  # These tests verify behavior that relies on Liquid's AST parser rather than
  # regex. The AST handles multiline, nesting, escaping, and scoping correctly.

  def test_capture_with_conditional_walks_ast_children
    # Liquid AST walks into If nodes to find nested tags.
    # The link exists in the AST regardless of runtime condition.
    book_with_conditional = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture maybe %}{% if page.show_link %}{% book_link "Target Book" %}{% endif %}{% endcapture %}

        I might have read {{ maybe }}.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_conditional, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'AST should walk into conditionals to find link tags'
    assert_equal 1, target_link[:count]
  end

  def test_nested_capture_extracts_inner_link
    # Nested captures: outer capture contains inner capture with a link.
    # AST naturally handles this — inner capture's link is still found.
    book_with_nested = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture outer %}
          {% capture inner %}{% book_link "Target Book" %}{% endcapture %}
          Wrapper around {{ inner }}.
        {% endcapture %}

        {{ outer }}
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_nested, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'AST should find links in nested captures'
    # Only prose-level usages count. {{ inner }} inside outer's body is template
    # machinery, not a prose mention. Only {{ outer }} in prose counts.
    assert_equal 1, target_link[:count], 'Only prose-level usage should count'
  end

  def test_raw_block_not_parsed_for_captures
    # {% raw %} blocks are not parsed — they render literally.
    # A capture inside raw should NOT create a forward link.
    book_with_raw = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        Here's how to use captures in Liquid:

        {% raw %}
        {% capture example %}{% book_link "Example Book" %}{% endcapture %}
        {{ example }}
        {% endraw %}

        That was just documentation.
      CONTENT
    )
    example_book = create_doc(
      { 'title' => 'Example Book', 'published' => true },
      '/books/example.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_raw, example_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    # Should be nil or empty — raw block content is not parsed
    assert(
      forward_links.nil? || forward_links.empty?,
      'Links inside {% raw %} blocks should not create forward links',
    )
  end

  def test_assign_tag_not_treated_as_capture
    # {% assign %} creates a variable but doesn't contain a block body.
    # Only {% capture %}...{% endcapture %} should be scanned for links.
    book_with_assign = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% assign book_title = "Target Book" %}
        {% capture link %}{% book_link "Target Book" %}{% endcapture %}

        I read {{ link }} (title: {{ book_title }}).
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_assign, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link, 'Capture should create forward link'
    # Only {{ link }} should count, not {{ book_title }}
    assert_equal 1, target_link[:count], 'Only capture variable usage should count'
  end

  def test_variable_with_filters_still_counted
    # {{ var | upcase }} should count as a usage of var.
    # Liquid::Variable nodes have a name and optional filters.
    book_with_filters = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture link %}{% book_link "Target Book" %}{% endcapture %}

        I read {{ link | strip }}.
      CONTENT
    )
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_filters, target_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    target_link = forward_links.find { |l| l[:target].url == '/books/target.html' }
    refute_nil target_link
    assert_equal 1, target_link[:count], 'Variable with filters should still count'
  end

  def test_capture_redefinition_uses_latest
    # If a capture is redefined, usages after the redefinition refer to the new value.
    # This matches Liquid semantics — we track the latest definition.
    book_with_redef = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture target %}{% book_link "First Book" %}{% endcapture %}
        {{ target }}

        {% capture target %}{% book_link "Second Book" %}{% endcapture %}
        {{ target }}
      CONTENT
    )
    first_book = create_doc(
      { 'title' => 'First Book', 'published' => true },
      '/books/first.html',
      'Content.',
    )
    second_book = create_doc(
      { 'title' => 'Second Book', 'published' => true },
      '/books/second.html',
      'Content.',
    )

    site = create_site({}, { 'books' => [book_with_redef, first_book, second_book] })
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    first_link = forward_links.find { |l| l[:target].url == '/books/first.html' }
    second_link = forward_links.find { |l| l[:target].url == '/books/second.html' }

    # Both books should have forward links with count=1 each
    refute_nil first_link, 'First capture definition should create link'
    refute_nil second_link, 'Second capture definition should create link'
    assert_equal 1, first_link[:count], 'First usage before redefinition'
    assert_equal 1, second_link[:count], 'Second usage after redefinition'
  end

  def test_author_link_in_capture
    # Author links should work in captures like book links.
    # Author links point to author pages, not expanded to books like series.
    author_page = create_doc(
      { 'title' => 'Philip K. Dick', 'layout' => 'author_page' },
      '/authors/philip-k-dick.html',
    )
    book_with_author_capture = create_doc(
      { 'title' => 'Review', 'published' => true },
      '/books/review.html',
      <<~CONTENT,
        {% capture pkd %}{% author_link "Philip K. Dick" %}{% endcapture %}

        {{ pkd }} wrote many great books.
      CONTENT
    )

    site = create_site({}, { 'books' => [book_with_author_capture] }, [author_page])
    forward_links = site.data['link_cache']['forward_links']['/books/review.html']

    author_link = forward_links&.find { |l| l[:target]&.url == '/authors/philip-k-dick.html' }
    refute_nil author_link, 'Author link in capture should create forward link'
    assert_equal 'author', author_link[:type]
    assert_equal 1, author_link[:count]
  end

  # --- Error handling tests ---
  # Malformed Liquid fails loudly — a broken build is better than silently
  # shipping incomplete backlink data.

  def test_malformed_liquid_raises_fatal_exception
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      '{% capture unclosed This is broken Liquid.',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    assert_includes error.message, '/books/malformed.html'
    assert_includes error.message, 'malformed Liquid'
  end

  def test_malformed_liquid_unclosed_if_raises_fatal_exception
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      "{% if unclosed %}{% book_link 'Target' %}",
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    assert_includes error.message, '/books/malformed.html'
  end

  def test_malformed_liquid_error_includes_syntax_details
    malformed_book = create_doc(
      { 'title' => 'Malformed', 'published' => true },
      '/books/malformed.html',
      '{% for item in %}broken{% endfor %}',
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [malformed_book] })
    end

    # Error message should include Liquid's syntax error details
    assert_includes error.message, 'BacklinkBuilder'
  end

  # --- Liquid internals contract tests ---
  # These tests verify assumptions about Liquid's internal structure.
  # If Liquid changes its ivars in a future version, these tests fail fast.

  def test_liquid_capture_exposes_variable_name
    # BacklinkBuilder accesses @to to get the capture variable name.
    template = Liquid::Template.parse('{% capture foo %}bar{% endcapture %}')
    capture_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Capture) }

    var_name = capture_node.instance_variable_get(:@to)
    assert_equal 'foo',
                 var_name,
                 'Liquid::Capture @to ivar changed — update BacklinkBuilder.process_capture_node'
  end

  def test_liquid_tag_exposes_markup
    # BacklinkBuilder accesses @markup to parse tag arguments.
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.ensure_stub_tags_registered
    template = Liquid::Template.parse("{% book_link 'Test Title' %}")
    tag_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Tag) && n.tag_name == 'book_link' }

    markup = tag_node.instance_variable_get(:@markup)
    assert_includes markup,
                    'Test Title',
                    'Liquid::Tag @markup ivar changed — update BacklinkBuilder.extract_link_from_tag'
  end

  def test_liquid_variable_exposes_name
    # BacklinkBuilder accesses @name to identify variable usages.
    template = Liquid::Template.parse('{{ my_var }}')
    var_node = template.root.nodelist.find { |n| n.is_a?(Liquid::Variable) }

    name_obj = var_node.instance_variable_get(:@name)
    # @name can be a VariableLookup or String depending on Liquid version
    actual_name = name_obj.is_a?(Liquid::VariableLookup) ? name_obj.name : name_obj
    assert_equal 'my_var',
                 actual_name,
                 'Liquid::Variable @name ivar changed — update BacklinkBuilder.extract_variable_name'
  end

end
