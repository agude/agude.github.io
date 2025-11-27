# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_shared.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/logic/book_lists/shared'

# Tests for Jekyll::BookLists::Shared module
#
# Tests the private helper methods that are shared across all BookList finder classes.
class TestBookListsShared < Minitest::Test
  # Helper class to test private methods from the Shared module
  class SharedTester
    include Jekyll::BookLists::Shared

    def initialize(site: nil, context: nil)
      @site = site
      @context = context
    end

    # Expose private methods for testing
    def test_parse_book_number(value)
      parse_book_number(value)
    end
  end

  def setup
    @tester = SharedTester.new
  end

  # --- Tests for parse_book_number (private method) ---
  def test_parse_book_number_integer
    assert_equal 1.0, @tester.test_parse_book_number(1)
  end

  def test_parse_book_number_string_integer
    assert_equal 10.0, @tester.test_parse_book_number('10')
  end

  def test_parse_book_number_float
    assert_equal 2.5, @tester.test_parse_book_number(2.5)
  end

  def test_parse_book_number_string_float
    assert_equal 3.75, @tester.test_parse_book_number('3.75')
  end

  def test_parse_book_number_nil
    assert_equal Float::INFINITY, @tester.test_parse_book_number(nil)
  end

  def test_parse_book_number_empty_string
    assert_equal Float::INFINITY, @tester.test_parse_book_number('')
    assert_equal Float::INFINITY, @tester.test_parse_book_number('   ')
  end

  def test_parse_book_number_non_numeric_string
    assert_equal Float::INFINITY, @tester.test_parse_book_number('Part 1')
    assert_equal Float::INFINITY, @tester.test_parse_book_number('One')
    assert_equal Float::INFINITY, @tester.test_parse_book_number('1.2.3') # Invalid float format for Float()
  end
end
