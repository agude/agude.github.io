# frozen_string_literal: true

# _tests/plugins/utils/test_short_story_title_util.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/src/content/short_stories/short_story_title_util'

# Tests for ShortStoryTitleUtil module.
#
# Verifies that the utility correctly renders short story titles with optional
# Kramdown IDs and proper typography handling.
class TestShortStoryTitleUtil < Minitest::Test
  def setup
    @site = create_site
  end

  # Helper to create a fresh context for each test
  def fresh_context
    context = create_context({}, { site: @site })
    context.registers[:story_title_counts] ||= Hash.new(0)
    context
  end

  # --- Basic Rendering Tests ---

  def test_render_with_default_behavior_includes_id
    context = fresh_context
    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'My Simple Story',
      no_id: false
    )

    slug = TextProcessingUtils.slugify('My Simple Story')
    expected = "<cite class=\"short-story-title\">My Simple Story</cite> {##{slug}}"
    assert_equal expected, output
  end

  def test_render_with_no_id_flag_excludes_id
    context = fresh_context
    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'My Simple Story',
      no_id: true
    )

    expected = '<cite class="short-story-title">My Simple Story</cite>'
    assert_equal expected, output
  end

  # --- Typography Tests ---

  def test_render_applies_typography_utils_with_id
    context = fresh_context
    input_title = %("Don't say 'hello' like that," she said.)
    expected_typography = TypographyUtils.prepare_display_title(input_title)
    slug = TextProcessingUtils.slugify(input_title)

    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: input_title,
      no_id: false
    )

    expected_html = "<cite class=\"short-story-title\">#{expected_typography}</cite> {##{slug}}"
    assert_equal expected_html, output
  end

  def test_render_applies_typography_utils_with_no_id
    context = fresh_context
    input_title = %("Don't say 'hello' like that," she said.)
    expected_typography = TypographyUtils.prepare_display_title(input_title)

    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: input_title,
      no_id: true
    )

    expected_html = "<cite class=\"short-story-title\">#{expected_typography}</cite>"
    assert_equal expected_html, output
  end

  # --- HTML Escaping Tests ---

  def test_render_handles_html_escaping_with_id
    context = fresh_context
    input_title = 'A & B <C>'
    expected_escaped = 'A &amp; B &lt;C&gt;'
    slug = TextProcessingUtils.slugify(input_title)

    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: input_title,
      no_id: false
    )

    expected_html = "<cite class=\"short-story-title\">#{expected_escaped}</cite> {##{slug}}"
    assert_equal expected_html, output
  end

  def test_render_handles_html_escaping_with_no_id
    context = fresh_context
    input_title = 'A & B <C>'
    expected_escaped = 'A &amp; B &lt;C&gt;'

    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: input_title,
      no_id: true
    )

    expected_html = "<cite class=\"short-story-title\">#{expected_escaped}</cite>"
    assert_equal expected_html, output
  end

  # --- Edge Cases: Empty/Nil Input ---

  def test_render_returns_empty_for_nil_title
    context = fresh_context
    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: nil,
      no_id: false
    )

    assert_equal '', output
  end

  def test_render_returns_empty_for_empty_string
    context = fresh_context
    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: '',
      no_id: false
    )

    assert_equal '', output
  end

  def test_render_returns_empty_for_whitespace_only
    context = fresh_context
    output = ShortStoryTitleUtil.render_title(
      context: context,
      title: '   ',
      no_id: false
    )

    assert_equal '', output
  end

  # --- Duplicate ID Handling ---

  def test_render_auto_increments_id_for_duplicate_titles
    context = fresh_context
    slug = TextProcessingUtils.slugify('Duplicate Story')

    # First call should get the base slug
    output1 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Duplicate Story',
      no_id: false
    )
    expected1 = "<cite class=\"short-story-title\">Duplicate Story</cite> {##{slug}}"
    assert_equal expected1, output1

    # Second call should get slug-2
    output2 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Duplicate Story',
      no_id: false
    )
    expected2 = "<cite class=\"short-story-title\">Duplicate Story</cite> {##{slug}-2}"
    assert_equal expected2, output2

    # Third call should get slug-3
    output3 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Duplicate Story',
      no_id: false
    )
    expected3 = "<cite class=\"short-story-title\">Duplicate Story</cite> {##{slug}-3}"
    assert_equal expected3, output3
  end

  def test_render_different_titles_get_independent_counters
    context = fresh_context
    slug_a = TextProcessingUtils.slugify('Story A')
    slug_b = TextProcessingUtils.slugify('Story B')

    # Call with Story A twice
    output_a1 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Story A',
      no_id: false
    )
    expected_a1 = "<cite class=\"short-story-title\">Story A</cite> {##{slug_a}}"
    assert_equal expected_a1, output_a1

    # Call with Story B once
    output_b1 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Story B',
      no_id: false
    )
    expected_b1 = "<cite class=\"short-story-title\">Story B</cite> {##{slug_b}}"
    assert_equal expected_b1, output_b1

    # Call with Story A again - should get slug_a-2
    output_a2 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Story A',
      no_id: false
    )
    expected_a2 = "<cite class=\"short-story-title\">Story A</cite> {##{slug_a}-2}"
    assert_equal expected_a2, output_a2
  end

  def test_render_no_id_flag_does_not_increment_counter
    context = fresh_context
    slug = TextProcessingUtils.slugify('Test Story')

    # First call with no_id=true should not increment counter
    output1 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Test Story',
      no_id: true
    )
    expected1 = '<cite class="short-story-title">Test Story</cite>'
    assert_equal expected1, output1

    # Second call with no_id=false should get the base slug (counter still at 0)
    output2 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Test Story',
      no_id: false
    )
    expected2 = "<cite class=\"short-story-title\">Test Story</cite> {##{slug}}"
    assert_equal expected2, output2

    # Third call with no_id=false should get slug-2
    output3 = ShortStoryTitleUtil.render_title(
      context: context,
      title: 'Test Story',
      no_id: false
    )
    expected3 = "<cite class=\"short-story-title\">Test Story</cite> {##{slug}-2}"
    assert_equal expected3, output3
  end
end
