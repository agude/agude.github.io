# frozen_string_literal: true

# _tests/plugins/test_series_link_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/series/tags/series_link_tag' # Load the tag

# Tests for Jekyll::Series::Tags::SeriesLinkTag Liquid tag.
#
# Verifies that the tag correctly creates links to book series pages.
class TestSeriesLinkTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_series_title' => 'Variable Series Title',
        'page_link_text_for_series' => 'Var Link Text for Series',
        'nil_var' => nil,
      },
      { site: @site, page: create_doc({}, '/current.html') },
    )
  end

  # Helper to parse the tag and capture arguments passed to the resolver.
  # Uses Minitest::Mock to verify that resolve is actually called and to
  # capture the arguments for assertion.
  def parse_and_capture_args(markup, context = @context)
    captured_args = nil
    mock_resolver = Minitest::Mock.new
    mock_resolver.expect(:resolve, '<!-- SeriesLinkResolver called -->') do |title, link_text_override, link: true|
      captured_args = { title: title, link_text_override: link_text_override }
      true
    end

    Jekyll::Series::SeriesLinkResolver.stub :new, mock_resolver do
      template = Liquid::Template.parse("{% series_link #{markup} %}")
      output = template.render!(context)
      mock_resolver.verify
      return output, captured_args
    end
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_series_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% series_link %}')
    end
    assert_match 'Could not find series title', err.message
  end

  def test_syntax_error_empty_single_quoted_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% series_link '' %}")
    end
    assert_match 'Title value is missing or empty', err.message
  end

  def test_syntax_error_empty_double_quoted_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% series_link "" %}')
    end
    assert_match 'Title value is missing or empty', err.message
  end

  def test_syntax_error_whitespace_only_quoted_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% series_link '   ' %}")
    end
    assert_match 'Title value is missing or empty', err.message
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% series_link 'My Series' unknown_arg='test' %}")
    end
    assert_match "Unknown argument 'unknown_arg='test''", err.message
  end

  def test_syntax_error_malformed_link_text
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% series_link 'My Series' link_text 'bad' %}") # Missing =
    end
    assert_match "Unknown argument 'link_text'", err.message
  end

  # --- Argument Parsing and Delegation Tests (Render) ---
  def test_render_with_literal_title_only
    _output, captured_args = parse_and_capture_args("'The Foundation Series'")
    assert_equal 'The Foundation Series', captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_with_variable_title_only
    _output, captured_args = parse_and_capture_args('page_series_title') # 'Variable Series Title'
    assert_equal 'Variable Series Title', captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_with_literal_title_and_literal_link_text
    _output, captured_args = parse_and_capture_args("'The Foundation Series' link_text='The Saga'")
    assert_equal 'The Foundation Series', captured_args[:title]
    assert_equal 'The Saga', captured_args[:link_text_override]
  end

  def test_render_with_variable_title_and_variable_link_text
    _output, captured_args = parse_and_capture_args('page_series_title link_text=page_link_text_for_series')
    assert_equal 'Variable Series Title', captured_args[:title]
    assert_equal 'Var Link Text for Series', captured_args[:link_text_override]
  end

  def test_render_link_text_resolves_to_nil_if_variable_is_nil
    _output, captured_args = parse_and_capture_args("'Some Series' link_text=nil_var")
    assert_equal 'Some Series', captured_args[:title]
    assert_nil captured_args[:link_text_override] # nil_var is nil
  end

  def test_render_series_title_resolves_to_nil
    _output, captured_args = parse_and_capture_args('nil_var') # nil_var is nil
    assert_nil captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_series_title_unquoted_literal_treated_as_variable
    # 'UnquotedSeriesTitle' is not in context, so resolve_value returns nil
    _output, captured_args = parse_and_capture_args('UnquotedSeriesTitle')
    assert_nil captured_args[:title]
  end

  def test_render_multiple_link_text_args_uses_first
    _output, captured_args = parse_and_capture_args("'A Series' link_text='First Text' link_text='Second Text'")
    assert_equal 'A Series', captured_args[:title]
    assert_equal 'First Text', captured_args[:link_text_override]
  end

  def test_render_with_trailing_whitespace_after_title
    markup_with_trailing_spaces = "'The Foundation Series'   \t  "
    _output, captured_args = parse_and_capture_args(markup_with_trailing_spaces)
    assert_equal 'The Foundation Series', captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  # --- Markdown Mode Tests ---

  def test_markdown_mode_renders_markdown_link
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/books/series/hyperion-cantos/',
    )
    site = create_site({}, {}, [series_page])
    md_context = create_context(
      {},
      { site: site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse("{% series_link 'Hyperion Cantos' %}")
    output = template.render!(md_context)
    assert_equal '[_Hyperion Cantos_](/books/series/hyperion-cantos/)', output
  end

  def test_markdown_mode_not_found_renders_plain_text
    site = create_site
    md_context = create_context(
      {},
      { site: site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse("{% series_link 'Unknown Series' %}")
    output = template.render!(md_context)
    assert_equal '_Unknown Series_', output
  end

  def test_markdown_mode_self_link_renders_italic_text
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/books/series/hyperion-cantos/',
    )
    site = create_site({}, {}, [series_page])
    md_context = create_context(
      {},
      { site: site, page: series_page, render_mode: :markdown },
    )
    template = Liquid::Template.parse("{% series_link 'Hyperion Cantos' %}")
    output = template.render!(md_context)
    assert_equal '_Hyperion Cantos_', output
  end

  def test_markdown_mode_with_link_text_override
    series_page = create_doc(
      { 'title' => 'Hyperion Cantos', 'layout' => 'series_page' },
      '/books/series/hyperion-cantos/',
    )
    site = create_site({}, {}, [series_page])
    md_context = create_context(
      {},
      { site: site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse("{% series_link 'Hyperion Cantos' link_text='the series' %}")
    output = template.render!(md_context)
    assert_equal '[_the series_](/books/series/hyperion-cantos/)', output
  end

  def test_markdown_mode_escapes_brackets_in_title
    series_page = create_doc(
      { 'title' => 'Foundation [Novels]', 'layout' => 'series_page' },
      '/books/series/foundation-novels/',
    )
    site = create_site({}, {}, [series_page])
    md_context = create_context(
      {},
      { site: site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse("{% series_link 'Foundation [Novels]' %}")
    output = template.render!(md_context)
    assert_equal '[_Foundation \[Novels\]_](/books/series/foundation-novels/)', output
  end
end
