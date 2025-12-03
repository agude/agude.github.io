# frozen_string_literal: true

# _tests/plugins/test_short_story_title_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/short_stories/tags/short_story_title_tag'

# Tests for ShortStoryTitleTag Liquid tag.
#
# Verifies that the tag correctly parses arguments and delegates to ShortStoryTitleUtil.
class TestShortStoryTitleTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_story_title' => 'My Story Title',
        'nil_var' => nil
      },
      { site: @site }
    )
  end

  # --- Syntax Error Tests ---

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

  # --- Orchestration Tests ---

  def test_calls_util_with_correct_title_from_literal
    captured_args = {}
    mock_output = '<cite class="short-story-title">Test Story</cite> {#test-story}'

    ShortStoryTitleUtil.stub :render_title, lambda { |**args|
      captured_args = args
      mock_output
    } do
      output = Liquid::Template.parse("{% short_story_title 'Test Story' %}").render!(@context)

      assert_equal @context, captured_args[:context]
      assert_equal 'Test Story', captured_args[:title]
      assert_equal false, captured_args[:no_id]
      assert_equal mock_output, output
    end
  end

  def test_calls_util_with_correct_title_from_variable
    captured_args = {}
    mock_output = '<cite class="short-story-title">My Story Title</cite> {#my-story-title}'

    ShortStoryTitleUtil.stub :render_title, lambda { |**args|
      captured_args = args
      mock_output
    } do
      output = Liquid::Template.parse('{% short_story_title page_story_title %}').render!(@context)

      assert_equal @context, captured_args[:context]
      assert_equal 'My Story Title', captured_args[:title]
      assert_equal false, captured_args[:no_id]
      assert_equal mock_output, output
    end
  end

  def test_calls_util_with_no_id_false_by_default
    captured_args = {}

    ShortStoryTitleUtil.stub :render_title, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Liquid::Template.parse("{% short_story_title 'Test' %}").render!(@context)

      assert_equal false, captured_args[:no_id]
    end
  end

  def test_calls_util_with_no_id_true_when_flag_present
    captured_args = {}

    ShortStoryTitleUtil.stub :render_title, lambda { |**args|
      captured_args = args
      '<mock output>'
    } do
      Liquid::Template.parse("{% short_story_title 'Test' no_id %}").render!(@context)

      assert_equal true, captured_args[:no_id]
    end
  end

  def test_calls_util_with_nil_when_variable_is_nil
    captured_args = {}

    ShortStoryTitleUtil.stub :render_title, lambda { |**args|
      captured_args = args
      ''
    } do
      Liquid::Template.parse('{% short_story_title nil_var %}').render!(@context)

      assert_nil captured_args[:title]
    end
  end

  def test_returns_output_from_util
    mock_output = '<div class="custom-story">Custom HTML</div>'

    ShortStoryTitleUtil.stub :render_title, ->(**_args) { mock_output } do
      output = Liquid::Template.parse("{% short_story_title 'Test' %}").render!(@context)

      assert_equal mock_output, output
    end
  end
end
