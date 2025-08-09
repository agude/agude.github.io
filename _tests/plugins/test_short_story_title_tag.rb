# _tests/plugins/test_short_story_title_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/short_story_title_tag'

class TestShortStoryTitleTag < Minitest::Test

  def setup
    @site = create_site
    @context = create_context(
      {
        'page_story_title' => "A Story From a Variable",
        'complex_story_title' => "\"Don't say 'hello' like that,\" she said.",
        'nil_var' => nil,
        'empty_string_var' => ''
      },
      { site: @site }
    )
  end

  # Helper to render the tag
  def render_tag(markup, context = @context)
    Liquid::Template.parse("{% short_story_title #{markup} %}").render!(context)
  end

  # --- Syntax Error Tests (Initialize) ---

  def test_syntax_error_if_markup_is_empty
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% short_story_title %}")
    end
    assert_match "A title (string literal or variable) is required.", err.message
  end

  def test_syntax_error_if_markup_is_whitespace
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% short_story_title    %}")
    end
    assert_match "A title (string literal or variable) is required.", err.message
  end

  # --- Rendering Tests ---

  def test_render_with_literal_string
    output = render_tag("'My Simple Story'")
    expected = "<cite class=\"short-story-title\">My Simple Story</cite>"
    assert_equal expected, output
  end

  def test_render_with_variable
    output = render_tag("page_story_title")
    expected = "<cite class=\"short-story-title\">A Story From a Variable</cite>"
    assert_equal expected, output
  end

  def test_render_applies_typography_utils
    # Test smart quotes, ellipsis, and dashes by resolving a variable.
    # CORRECTED: The expected output now matches the new, cleaner test string.
    expected_typography = "“Don’t say ‘hello’ like that,” she said."
    output = render_tag("complex_story_title")
    expected_html = "<cite class=\"short-story-title\">#{expected_typography}</cite>"
    assert_equal expected_html, output
  end

  def test_render_handles_html_escaping
    input_title = "A & B <C>"
    expected_escaped = "A &amp; B &lt;C&gt;"
    output = render_tag("'#{input_title}'")
    expected_html = "<cite class=\"short-story-title\">#{expected_escaped}</cite>"
    assert_equal expected_html, output
  end

  def test_render_returns_empty_for_nil_variable
    output = render_tag("nil_var")
    assert_equal "", output
  end

  def test_render_returns_empty_for_empty_string_variable
    output = render_tag("empty_string_var")
    assert_equal "", output
  end

  def test_render_returns_empty_for_non_existent_variable
    output = render_tag("non_existent_variable")
    assert_equal "", output
  end

  def test_render_returns_empty_for_empty_literal
    output = render_tag("''")
    assert_equal "", output
  end

  def test_render_returns_empty_for_whitespace_literal
    output = render_tag("'   '")
    assert_equal "", output
  end
end
