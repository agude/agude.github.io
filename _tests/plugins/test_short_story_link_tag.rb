# frozen_string_literal: true

# _tests/plugins/test_short_story_link_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/src/content/short_stories/tags/short_story_link_tag'

# Tests for ShortStoryLinkTag Liquid tag.
#
# Verifies that the tag correctly creates links to short stories within anthology books.
class TestShortStoryLinkTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_story_title' => 'Variable Story Title',
        'page_book_title' => 'Variable Book Title',
        'nil_var' => nil
      },
      { site: @site, page: create_doc({}, '/current.html') }
    )
  end

  # Helper to parse the tag and capture arguments passed to the utility
  def parse_and_capture_args(markup, context = @context)
    captured_args = nil
    ShortStoryLinkUtils.stub :render_short_story_link, lambda { |story_title, ctx, from_book_title|
      captured_args = { story_title: story_title, context: ctx, from_book_title: from_book_title }
      "<!-- Util called with story: #{story_title}, book: #{from_book_title} -->"
    } do
      template = Liquid::Template.parse("{% short_story_link #{markup} %}")
      output = template.render!(context)
      return output, captured_args
    end
  end

  # --- Syntax Error Tests ---
  def test_syntax_error_missing_story_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% short_story_link %}')
    end
    assert_match 'Could not find story title', err.message
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% short_story_link 'My Story' bad_arg='test' %}")
    end
    assert_match "Unknown argument 'bad_arg='test''", err.message
  end

  # --- Argument Parsing and Delegation Tests ---
  def test_render_with_literal_title_only
    _output, captured_args = parse_and_capture_args("'A Good Story'")
    assert_equal 'A Good Story', captured_args[:story_title]
    assert_nil captured_args[:from_book_title]
    assert_equal @context, captured_args[:context]
  end

  def test_render_with_variable_title_only
    _output, captured_args = parse_and_capture_args('page_story_title')
    assert_equal 'Variable Story Title', captured_args[:story_title]
    assert_nil captured_args[:from_book_title]
  end

  def test_render_with_literal_title_and_literal_book
    _output, captured_args = parse_and_capture_args("'Duplicate Story' from_book='Book One'")
    assert_equal 'Duplicate Story', captured_args[:story_title]
    assert_equal 'Book One', captured_args[:from_book_title]
  end

  def test_render_with_variable_title_and_variable_book
    _output, captured_args = parse_and_capture_args('page_story_title from_book=page_book_title')
    assert_equal 'Variable Story Title', captured_args[:story_title]
    assert_equal 'Variable Book Title', captured_args[:from_book_title]
  end

  def test_render_title_resolves_to_nil
    _output, captured_args = parse_and_capture_args('nil_var')
    assert_nil captured_args[:story_title]
    assert_nil captured_args[:from_book_title]
  end

  def test_render_book_title_resolves_to_nil
    _output, captured_args = parse_and_capture_args("'Some Story' from_book=nil_var")
    assert_equal 'Some Story', captured_args[:story_title]
    assert_nil captured_args[:from_book_title]
  end
end
