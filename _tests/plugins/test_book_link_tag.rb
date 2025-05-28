# _tests/plugins/test_book_link_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/book_link_tag' # Load the tag

class TestBookLinkTag < Minitest::Test

  def setup
    @site = create_site
    @context = create_context(
      {
        'page_book_title' => 'Variable Book Title',
        'page_link_text' => 'Variable Link Text for Book',
        'nil_var' => nil,
        'empty_string_var' => ''
      },
      { site: @site, page: create_doc({}, '/current.html') }
    )
  end

  # Helper to parse the tag and capture arguments passed to the utility
  def parse_and_capture_args(markup, context = @context)
    captured_args = nil
    # Stub the utility function
    BookLinkUtils.stub :render_book_link, ->(title, ctx, link_text_override) {
      captured_args = { title: title, context: ctx, link_text_override: link_text_override }
      "<!-- BookLinkUtils called with title: #{title}, link_text: #{link_text_override} -->"
    } do
      template = Liquid::Template.parse("{% book_link #{markup} %}")
      output = template.render!(context)
      return output, captured_args
    end
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_book_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_link %}")
    end
    assert_match "Could not find book title", err.message
  end

  # Similar to AuthorLinkTag, BookLinkTag should parse '' successfully.
  # The utility BookLinkUtils will handle the empty resolved name.
  def test_render_book_title_empty_string_literal_passes_empty_to_util
    _output, captured_args = parse_and_capture_args("''")
    assert_equal "", captured_args[:title], "Tag should resolve '' to an empty string for the utility"
    assert_nil captured_args[:link_text_override]
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_link 'My Book' unknown_arg='test' %}")
    end
    assert_match "Unknown argument 'unknown_arg='test''", err.message
  end

  def test_syntax_error_malformed_link_text
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_link 'My Book' link_text 'bad' %}") # Missing =
    end
    assert_match "Unknown argument 'link_text'", err.message
  end

  # --- Argument Parsing and Delegation Tests (Render) ---
  def test_render_with_literal_title_only
    _output, captured_args = parse_and_capture_args("'The Great Gatsby'")
    assert_equal "The Great Gatsby", captured_args[:title]
    assert_nil captured_args[:link_text_override]
    assert_equal @context, captured_args[:context]
  end

  def test_render_with_variable_title_only
    _output, captured_args = parse_and_capture_args("page_book_title") # 'Variable Book Title'
    assert_equal "Variable Book Title", captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_with_literal_title_and_literal_link_text
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' link_text='Gatsby'")
    assert_equal "The Great Gatsby", captured_args[:title]
    assert_equal "Gatsby", captured_args[:link_text_override]
  end

  def test_render_with_variable_title_and_variable_link_text
    _output, captured_args = parse_and_capture_args("page_book_title link_text=page_link_text")
    assert_equal "Variable Book Title", captured_args[:title]
    assert_equal "Variable Link Text for Book", captured_args[:link_text_override]
  end

  def test_render_link_text_resolves_to_nil_if_variable_is_nil
    _output, captured_args = parse_and_capture_args("'Some Book' link_text=nil_var")
    assert_equal "Some Book", captured_args[:title]
    assert_nil captured_args[:link_text_override] # nil_var is nil
  end

  def test_render_book_title_resolves_to_nil
    _output, captured_args = parse_and_capture_args("nil_var") # nil_var is nil
    assert_nil captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_book_title_resolves_to_empty_string_from_variable
    _output, captured_args = parse_and_capture_args("empty_string_var") # empty_string_var is ''
    assert_equal "", captured_args[:title]
    assert_nil captured_args[:link_text_override]
  end

  def test_render_book_title_unquoted_literal_treated_as_variable
    # 'UnquotedBookTitle' is not in context, so resolve_value returns nil
    _output, captured_args = parse_and_capture_args("UnquotedBookTitle")
    assert_nil captured_args[:title]
  end

  def test_render_multiple_link_text_args_uses_first
    _output, captured_args = parse_and_capture_args("'A Book' link_text='First Text' link_text='Second Text'")
    assert_equal "A Book", captured_args[:title]
    assert_equal "First Text", captured_args[:link_text_override]
  end
end
