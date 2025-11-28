# frozen_string_literal: true

# _tests/plugins/utils/test_book_data_utils.rb
require_relative '../../test_helper'

# Tests for BookDataUtils module
#
# Tests the book data parsing utilities.
class TestBookDataUtils < Minitest::Test
  # --- Tests for parse_book_number ---
  def test_parse_book_number_integer
    assert_equal 1.0, BookDataUtils.parse_book_number(1)
  end

  def test_parse_book_number_string_integer
    assert_equal 10.0, BookDataUtils.parse_book_number('10')
  end

  def test_parse_book_number_float
    assert_equal 2.5, BookDataUtils.parse_book_number(2.5)
  end

  def test_parse_book_number_string_float
    assert_equal 3.75, BookDataUtils.parse_book_number('3.75')
  end

  def test_parse_book_number_nil
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number(nil)
  end

  def test_parse_book_number_empty_string
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number('')
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number('   ')
  end

  def test_parse_book_number_non_numeric_string
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number('Part 1')
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number('One')
    assert_equal Float::INFINITY, BookDataUtils.parse_book_number('1.2.3') # Invalid float format for Float()
  end
end
