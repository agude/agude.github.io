# frozen_string_literal: true

# _tests/plugins/test_author_link_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/author_link_tag' # Load the tag

# Tests for AuthorLinkTag Liquid tag.
#
# Verifies that the tag correctly renders author links with optional possessive forms.
class TestAuthorLinkTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_author_name' => 'Variable Author',
        'page_link_text' => 'Variable Link Text',
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
    stub_render_author_link = lambda do |name, ctx, link_text_override, possessive|
      captured_args = {
        name: name,
        context: ctx,
        link_text_override: link_text_override,
        possessive: possessive
      }
      "<!-- AuthorLinkUtils called with name: #{name}, link_text: #{link_text_override}, " \
        "possessive: #{possessive} -->"
    end
    AuthorLinkUtils.stub :render_author_link, stub_render_author_link do
      template = Liquid::Template.parse("{% author_link #{markup} %}")
      output = template.render!(context)
      return output, captured_args
    end
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_author_name
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% author_link %}')
    end
    assert_match 'Could not find author name', err.message
  end

  # This test is changed: The tag should parse '' successfully.
  # The utility AuthorLinkUtils will handle the empty resolved name.
  def test_render_author_name_empty_string_literal_passes_empty_to_util
    _output, captured_args = parse_and_capture_args("''")
    assert_equal '', captured_args[:name], "Tag should resolve '' to an empty string for the utility"
    assert_nil captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% author_link 'My Author' unknown_arg='test' %}")
    end
    assert_match "Unknown argument 'unknown_arg='test''", err.message
  end

  def test_syntax_error_malformed_link_text
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% author_link 'My Author' link_text 'bad' %}") # Missing =
    end
    assert_match "Unknown argument 'link_text'", err.message
  end

  # --- Argument Parsing and Delegation Tests (Render) ---
  def test_render_with_literal_name_only
    _output, captured_args = parse_and_capture_args("'Jane Doe'")
    assert_equal 'Jane Doe', captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
    assert_equal @context, captured_args[:context]
  end

  def test_render_with_variable_name_only
    _output, captured_args = parse_and_capture_args('page_author_name') # 'Variable Author'
    assert_equal 'Variable Author', captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_render_with_literal_name_and_literal_link_text
    _output, captured_args = parse_and_capture_args("'Jane Doe' link_text='J. Doe'")
    assert_equal 'Jane Doe', captured_args[:name]
    assert_equal 'J. Doe', captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_render_with_variable_name_and_variable_link_text
    _output, captured_args = parse_and_capture_args('page_author_name link_text=page_link_text')
    assert_equal 'Variable Author', captured_args[:name]
    assert_equal 'Variable Link Text', captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_render_with_literal_name_and_possessive
    _output, captured_args = parse_and_capture_args("'Jane Doe' possessive")
    assert_equal 'Jane Doe', captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal true, captured_args[:possessive]
  end

  def test_render_with_variable_name_and_possessive
    _output, captured_args = parse_and_capture_args('page_author_name possessive')
    assert_equal 'Variable Author', captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal true, captured_args[:possessive]
  end

  def test_render_with_all_args_literal_name
    _output, captured_args = parse_and_capture_args("'Jane Doe' link_text='J.D.' possessive")
    assert_equal 'Jane Doe', captured_args[:name]
    assert_equal 'J.D.', captured_args[:link_text_override]
    assert_equal true, captured_args[:possessive]
  end

  def test_render_with_all_args_variable_name
    _output, captured_args = parse_and_capture_args('page_author_name link_text=page_link_text possessive')
    assert_equal 'Variable Author', captured_args[:name]
    assert_equal 'Variable Link Text', captured_args[:link_text_override]
    assert_equal true, captured_args[:possessive]
  end

  def test_render_arg_order_does_not_matter_for_link_text_and_possessive
    _output, captured_args = parse_and_capture_args("'Jane Doe' possessive link_text='J.D.'")
    assert_equal 'Jane Doe', captured_args[:name]
    assert_equal 'J.D.', captured_args[:link_text_override]
    assert_equal true, captured_args[:possessive]
  end

  def test_render_link_text_resolves_to_nil_if_variable_is_nil
    _output, captured_args = parse_and_capture_args("'Some Author' link_text=nil_var")
    assert_equal 'Some Author', captured_args[:name]
    assert_nil captured_args[:link_text_override] # nil_var is nil
    assert_equal false, captured_args[:possessive]
  end

  def test_render_author_name_resolves_to_nil
    _output, captured_args = parse_and_capture_args('nil_var') # nil_var is nil
    assert_nil captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_render_author_name_resolves_to_empty_string_from_variable
    _output, captured_args = parse_and_capture_args('empty_string_var') # empty_string_var is ''
    assert_equal '', captured_args[:name]
    assert_nil captured_args[:link_text_override]
    assert_equal false, captured_args[:possessive]
  end

  def test_render_author_name_unquoted_literal_treated_as_variable
    # 'UnquotedAuthorName' is not in context, so resolve_value returns nil
    _output, captured_args = parse_and_capture_args('UnquotedAuthorName')
    assert_nil captured_args[:name]
  end

  def test_render_multiple_link_text_args_uses_first
    _output, captured_args = parse_and_capture_args("'An Author' link_text='First Text' link_text='Second Text'")
    assert_equal 'An Author', captured_args[:name]
    assert_equal 'First Text', captured_args[:link_text_override]
  end

  def test_render_multiple_possessive_args_is_still_true
    _output, captured_args = parse_and_capture_args("'An Author' possessive possessive")
    assert_equal 'An Author', captured_args[:name]
    assert_equal true, captured_args[:possessive]
  end
end
