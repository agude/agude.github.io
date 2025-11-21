# frozen_string_literal: true

# _tests/plugins/utils/book_list_utils/test_private_helpers.rb
require_relative '../../../test_helper'
# BookListUtils is loaded by test_helper, making its private methods accessible for testing via __send__

# Renamed class
class TestBookListUtilsPrivateHelpers < Minitest::Test
  # No complex setup needed for these direct helper tests,
  # as they don't rely on site or context objects.

  # --- Tests for _parse_book_number (private method) ---
  def test_parse_book_number_integer
    assert_equal 1.0, BookListUtils.__send__(:_parse_book_number, 1)
  end

  def test_parse_book_number_string_integer
    assert_equal 10.0, BookListUtils.__send__(:_parse_book_number, '10')
  end

  def test_parse_book_number_float
    assert_equal 2.5, BookListUtils.__send__(:_parse_book_number, 2.5)
  end

  def test_parse_book_number_string_float
    assert_equal 3.75, BookListUtils.__send__(:_parse_book_number, '3.75')
  end

  def test_parse_book_number_nil
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, nil)
  end

  def test_parse_book_number_empty_string
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, '')
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, '   ')
  end

  def test_parse_book_number_non_numeric_string
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, 'Part 1')
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, 'One')
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, '1.2.3') # Invalid float format for Float()
  end

  # --- Tests for _format_award_display_name (private method) ---
  def test_format_award_display_name_simple
    assert_equal 'Hugo Award', BookListUtils.__send__(:_format_award_display_name, 'hugo')
    assert_equal 'Nebula Award', BookListUtils.__send__(:_format_award_display_name, 'Nebula')
  end

  def test_format_award_display_name_multi_word
    assert_equal 'British Fantasy Award', BookListUtils.__send__(:_format_award_display_name, 'british fantasy')
  end

  def test_format_award_display_name_with_initialism
    assert_equal 'Arthur C. Clarke Award', BookListUtils.__send__(:_format_award_display_name, 'arthur c. clarke')
    assert_equal 'Philip K. Dick Award', BookListUtils.__send__(:_format_award_display_name, 'philip k. dick')
  end

  def test_format_award_display_name_already_contains_award_word_is_titleized_and_appended
    # Current logic always appends " Award" after titleizing the input.
    assert_equal(
      'Locus Award For Best Sf Novel Award',
      BookListUtils.__send__(:_format_award_display_name, 'Locus Award for Best SF Novel')
    )
    assert_equal 'Hugo Award Award', BookListUtils.__send__(:_format_award_display_name, 'hugo award')
  end

  def test_format_award_display_name_empty_or_nil
    assert_equal '', BookListUtils.__send__(:_format_award_display_name, nil)
    assert_equal '', BookListUtils.__send__(:_format_award_display_name, '  ')
  end

  def test_format_award_display_name_mixed_case_input
    # Current logic capitalizes each word.
    assert_equal 'Mixed Case Award Award', BookListUtils.__send__(:_format_award_display_name, 'mIxEd CaSe AwArD')
  end
end
