# frozen_string_literal: true

# _tests/plugins/utils/test_rating_utils.rb
require_relative '../../../test_helper'

# Tests for RatingUtils module.
#
# Verifies that the utility correctly renders star ratings with proper HTML and validation.
class TestRatingUtils < Minitest::Test
  # Helper to check star counts and the exact sequence of star characters.
  def assert_stars(html, full_count, empty_count)
    # --- Total Span Count Check (Sanity Check) ---
    total_stars_found = html.scan(/<span class="book_star (?:full_star|empty_star)"/).count
    assert_equal 5, total_stars_found, 'Structure check failed: Incorrect total number of star spans (expected 5)'

    # --- Extract Actual Star Character Sequence ---
    # Find all star characters (★ or ☆) within the relevant spans
    # This regex looks inside the span tag for the character
    extracted_chars = html.scan(%r{<span class="book_star (?:full_star|empty_star)"[^>]*>([★☆])</span>}).flatten
    extracted_sequence = extracted_chars.join

    # --- Construct Expected Star Character Sequence ---
    expected_sequence = ('★' * full_count) + ('☆' * empty_count)

    # --- Compare Sequences ---
    assert_equal expected_sequence, extracted_sequence,
                 "Sequence check failed: Expected '#{expected_sequence}', but got '#{extracted_sequence}'"
  end

  def test_render_rating_stars_valid_integers
    output5 = RatingUtils.render_rating_stars(5)
    assert_match(/class="book-rating star-rating-5"/, output5)
    assert_match(/role="img"/, output5)
    assert_match(/aria-label="Rating: 5 out of 5 stars"/, output5)
    assert_stars(output5, 5, 0)

    output3 = RatingUtils.render_rating_stars(3)
    assert_match(/class="book-rating star-rating-3"/, output3)
    assert_match(/role="img"/, output3)
    assert_match(/aria-label="Rating: 3 out of 5 stars"/, output3)
    assert_stars(output3, 3, 2)

    output1 = RatingUtils.render_rating_stars(1)
    assert_match(/class="book-rating star-rating-1"/, output1)
    assert_match(/role="img"/, output1)
    assert_match(/aria-label="Rating: 1 out of 5 stars"/, output1)
    assert_stars(output1, 1, 4)
  end

  def test_render_rating_stars_valid_strings
    output4_str = RatingUtils.render_rating_stars('4')
    assert_match(/class="book-rating star-rating-4"/, output4_str)
    assert_match(/role="img"/, output4_str)
    assert_match(/aria-label="Rating: 4 out of 5 stars"/, output4_str)
    assert_stars(output4_str, 4, 1)

    output2_str = RatingUtils.render_rating_stars('2')
    assert_match(/class="book-rating star-rating-2"/, output2_str)
    assert_match(/role="img"/, output2_str)
    assert_match(/aria-label="Rating: 2 out of 5 stars"/, output2_str)
    assert_stars(output2_str, 2, 3)
  end

  def test_render_rating_stars_invalid_range_throws_error
    err0 = assert_raises(ArgumentError) { RatingUtils.render_rating_stars(0) }
    assert_match(/Rating must be between 1 and 5/, err0.message)

    err6 = assert_raises(ArgumentError) { RatingUtils.render_rating_stars(6) }
    assert_match(/Rating must be between 1 and 5/, err6.message)

    # Negative integers will also fail range check
    err_neg = assert_raises(ArgumentError) { RatingUtils.render_rating_stars(-1) }
    assert_match(/Rating must be between 1 and 5/, err_neg.message)
  end

  def test_render_rating_stars_invalid_type_throws_error
    err_str = assert_raises(ArgumentError) { RatingUtils.render_rating_stars('invalid') }
    assert_match(/Invalid rating input type/, err_str.message)

    err_float = assert_raises(ArgumentError) { RatingUtils.render_rating_stars(3.5) }
    assert_match(/Invalid rating input type/, err_float.message)

    err_arr = assert_raises(ArgumentError) { RatingUtils.render_rating_stars([3]) }
    assert_match(/Invalid rating input type/, err_arr.message)

    # Negative integer *string* should fail type check now
    err_neg_str = assert_raises(ArgumentError) { RatingUtils.render_rating_stars('-1') }
    assert_match(/Invalid rating input type/, err_neg_str.message)
  end

  def test_render_rating_stars_nil_input_returns_empty
    assert_equal '', RatingUtils.render_rating_stars(nil), 'Nil input should return empty string'
  end

  def test_render_rating_stars_wrapper_tag_valid
    output_span = RatingUtils.render_rating_stars(4, 'span')
    assert_match(/^<span class="book-rating star-rating-4"/, output_span)
    assert_match(%r{</span>$}, output_span)
    assert_stars(output_span, 4, 1) # Ensure stars are still correct

    output_div = RatingUtils.render_rating_stars(2, 'div')
    assert_match(/^<div class="book-rating star-rating-2"/, output_div)
    assert_match(%r{</div>$}, output_div)
    assert_stars(output_div, 2, 3) # Ensure stars are still correct
  end

  def test_render_rating_stars_wrapper_tag_case_insensitive
    output_span_upper = RatingUtils.render_rating_stars(4, 'SPAN')
    assert_match(/^<span class="book-rating star-rating-4"/, output_span_upper)
    assert_match(%r{</span>$}, output_span_upper)

    output_div_mixed = RatingUtils.render_rating_stars(2, 'DiV')
    assert_match(/^<div class="book-rating star-rating-2"/, output_div_mixed)
    assert_match(%r{</div>$}, output_div_mixed)
  end

  def test_render_rating_stars_wrapper_tag_invalid_defaults_to_div
    output_script = RatingUtils.render_rating_stars(4, 'script')
    assert_match(/^<div class="book-rating star-rating-4"/, output_script, "Invalid tag 'script' should default to div")
    assert_match(%r{</div>$}, output_script)
    assert_stars(output_script, 4, 1)

    output_empty = RatingUtils.render_rating_stars(3, '')
    assert_match(/^<div class="book-rating star-rating-3"/, output_empty, 'Empty tag should default to div')
    assert_match(%r{</div>$}, output_empty)
    assert_stars(output_empty, 3, 2)

    output_nil = RatingUtils.render_rating_stars(5, nil)
    assert_match(/^<div class="book-rating star-rating-5"/, output_nil, 'Nil tag should default to div')
    assert_match(%r{</div>$}, output_nil)
    assert_stars(output_nil, 5, 0)
  end
end
