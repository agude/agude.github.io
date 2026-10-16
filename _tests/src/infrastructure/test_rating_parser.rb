# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/rating_parser'

# Tests for RatingParser, the one parser for a book's `rating`.
class TestRatingParser < Minitest::Test
  Parser = Jekyll::Infrastructure::RatingParser

  def test_nil_is_no_rating
    assert_nil Parser.parse(nil)
  end

  def test_integers_and_digit_strings_in_range
    (1..5).each do |n|
      assert_equal n, Parser.parse(n)
      assert_equal n, Parser.parse(n.to_s)
    end
  end

  def test_leading_zero_string_is_decimal
    assert_equal 4, Parser.parse('04')
  end

  def test_malformed_values_raise_fatal_by_default
    [4.9, '4.9', '4 stars', '', ' 4', 0, 6, -1, '-1', [4], true].each do |raw|
      assert_raises(Jekyll::Errors::FatalException, raw.inspect) { Parser.parse(raw) }
    end
  end

  def test_error_class_and_source_are_configurable
    error = assert_raises(ArgumentError) { Parser.parse('4 stars', error: ArgumentError, source: 'Dune') }
    assert_includes error.message, 'Dune'
    assert_includes error.message, '"4 stars"'
  end
end
