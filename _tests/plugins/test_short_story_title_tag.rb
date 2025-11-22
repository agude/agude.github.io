# frozen_string_literal: true

# _tests/plugins/test_short_story_title_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/short_story_title_tag'

# Tests for ShortStoryTitleTag Liquid tag.
#
# Verifies that the tag correctly renders short story titles with optional fragment IDs.
class TestShortStoryTitleTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_story_title' => 'A Story From a Variable',
        'complex_story_title' => "\"Don't say 'hello' like that,\" she said.",
        'nil_var' => nil,
        'empty_string_var' => ''
      },
      # The context needs a fresh :story_title_counts register for each render
      { site: @site }
    )
  end

  # Helper to render the tag
  def render_tag(markup, context = @context)
    # Re-initialize the context for each single-tag render to ensure clean registers
    fresh_context = create_context(context.environments.first, context.registers)
    fresh_context.registers[:story_title_counts] ||= Hash.new(0)
    Liquid::Template.parse("{% short_story_title #{markup} %}").render!(fresh_context)
  end

  # --- Syntax Error Tests (Initialize) ---

  def test_syntax_error_if_markup_is_empty
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% short_story_title %}')
    end
    assert_match 'Could not find title', err.message
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% short_story_title 'My Story' bad_arg %}")
    end
    assert_match "Unknown argument 'bad_arg'", err.message
  end

  # --- Rendering Tests ---

  def test_render_default_behavior_with_id
    output = render_tag("'My Simple Story'")
    slug = TextProcessingUtils.slugify('My Simple Story')
    expected = "<cite class=\"short-story-title\">My Simple Story</cite> {##{slug}}"
    assert_equal expected, output
  end

  def test_render_with_variable_and_default_id
    output = render_tag('page_story_title')
    slug = TextProcessingUtils.slugify('A Story From a Variable')
    expected = "<cite class=\"short-story-title\">A Story From a Variable</cite> {##{slug}}"
    assert_equal expected, output
  end

  def test_render_with_no_id_flag
    output = render_tag("'My Simple Story' no_id")
    expected = '<cite class="short-story-title">My Simple Story</cite>'
    assert_equal expected, output
  end

  def test_render_with_variable_and_no_id_flag
    output = render_tag('page_story_title no_id')
    expected = '<cite class="short-story-title">A Story From a Variable</cite>'
    assert_equal expected, output
  end

  def test_render_applies_typography_utils_with_id
    expected_typography = '“Don’t say ‘hello’ like that,” she said.'
    slug = TextProcessingUtils.slugify("\"Don't say 'hello' like that,\" she said.")
    output = render_tag('complex_story_title')
    expected_html = "<cite class=\"short-story-title\">#{expected_typography}</cite> {##{slug}}"
    assert_equal expected_html, output
  end

  def test_render_applies_typography_utils_with_no_id
    expected_typography = '“Don’t say ‘hello’ like that,” she said.'
    output = render_tag('complex_story_title no_id')
    expected_html = "<cite class=\"short-story-title\">#{expected_typography}</cite>"
    assert_equal expected_html, output
  end

  def test_render_handles_html_escaping_with_id
    input_title = 'A & B <C>'
    expected_escaped = 'A &amp; B &lt;C&gt;'
    slug = TextProcessingUtils.slugify(input_title)
    output = render_tag("'#{input_title}'")
    expected_html = "<cite class=\"short-story-title\">#{expected_escaped}</cite> {##{slug}}"
    assert_equal expected_html, output
  end

  def test_render_handles_html_escaping_with_no_id
    input_title = 'A & B <C>'
    expected_escaped = 'A &amp; B &lt;C&gt;'
    output = render_tag("'#{input_title}' no_id")
    expected_html = "<cite class=\"short-story-title\">#{expected_escaped}</cite>"
    assert_equal expected_html, output
  end

  def test_render_returns_empty_for_nil_variable
    output = render_tag('nil_var')
    assert_equal '', output
  end

  def test_render_returns_empty_for_empty_string_variable
    output = render_tag('empty_string_var')
    assert_equal '', output
  end

  def test_render_returns_empty_for_non_existent_variable
    output = render_tag('non_existent_variable')
    assert_equal '', output
  end

  def test_render_returns_empty_for_empty_literal
    output = render_tag("''")
    assert_equal '', output
  end

  def test_render_returns_empty_for_whitespace_literal
    output = render_tag("'   '")
    assert_equal '', output
  end

  def test_render_auto_increments_id_for_duplicate_titles
    # To test the stateful nature of the tag, we must render a single template
    # that contains multiple calls to the tag. This ensures they share the same context.
    template_string = "{% short_story_title 'Duplicate Story' %} and again {% short_story_title 'Duplicate Story' %}"
    template = Liquid::Template.parse(template_string)

    # Initialize a fresh context for this specific render operation
    fresh_context = create_context(@context.environments.first, @context.registers)

    output = template.render!(fresh_context)

    slug = TextProcessingUtils.slugify('Duplicate Story')

    # The first instance should have a clean ID
    first_expected_part = "<cite class=\"short-story-title\">Duplicate Story</cite> {##{slug}}"
    assert_includes output, first_expected_part

    # The second instance should have an incremented ID
    second_expected_part = "<cite class=\"short-story-title\">Duplicate Story</cite> {##{slug}-2}"
    assert_includes output, second_expected_part
  end
end
