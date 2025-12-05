# frozen_string_literal: true

# _tests/plugins/test_rating_stars_tag.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/rating_stars_tag'

# Tests for Jekyll::UI::Tags::RatingStarsTag Liquid tag.
#
# Verifies that the tag correctly renders star ratings with proper HTML.
class TestRatingStarsTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({ 'book' => { 'rating' => 4, 'bad_rating' => 6, 'nil_rating' => nil } }, { site: @site })
  end

  def render_tag(markup)
    Liquid::Template.parse("{% rating_stars #{markup} %}").render!(@context)
  end

  def test_render_tag_with_literal_integer
    output = render_tag('3')
    assert_match(/class="book-rating star-rating-3"/, output)
    assert_match(/^<div/, output) # Default wrapper
  end

  def test_render_tag_with_variable
    output = render_tag('book.rating') # book.rating is 4
    assert_match(/class="book-rating star-rating-4"/, output)
    assert_match(/^<div/, output)
  end

  def test_render_tag_with_wrapper_span_literal
    output = render_tag("5 wrapper_tag='span'")
    assert_match(/class="book-rating star-rating-5"/, output)
    assert_match(/^<span/, output)
  end

  def test_render_tag_with_wrapper_span_literal_double_quotes
    output = render_tag('2 wrapper_tag="span"')
    assert_match(/class="book-rating star-rating-2"/, output)
    assert_match(/^<span/, output)
  end

  # Utility function now throws ArgumentError for invalid values
  def test_render_tag_invalid_literal_value_throws
    assert_raises(ArgumentError) { render_tag('0') }
    assert_raises(ArgumentError) { render_tag('6') }
    assert_raises(ArgumentError) { render_tag('3.5') }
    assert_raises(ArgumentError) { render_tag("'abc'") } # Quoted string is invalid type
  end

  def test_render_tag_invalid_variable_value_throws
    assert_raises(ArgumentError) { render_tag('book.bad_rating') } # bad_rating is 6
  end

  def test_render_tag_nil_variable_value_renders_empty
    # render_rating_stars handles nil silently
    assert_equal '', render_tag('book.nil_rating')
  end

  def test_render_tag_nonexistent_variable_renders_empty
    # resolve_value returns nil, render_rating_stars handles nil
    assert_equal '', render_tag('book.no_such_rating')
  end

  def test_render_tag_invalid_wrapper_tag_defaults_to_div
    output = render_tag("4 wrapper_tag='script'")
    assert_match(/class="book-rating star-rating-4"/, output)
    assert_match(/^<div/, output) # Defaults to div
  end

  def test_syntax_error_missing_rating
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse('{% rating_stars %}') }
    assert_match(%r{Rating value/variable is missing}, err.message)
  end

  def test_syntax_error_extra_args
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% rating_stars 3 wrapper_tag='span' extra %}") }
    assert_match(/Unexpected arguments/, err.message)
  end
end
