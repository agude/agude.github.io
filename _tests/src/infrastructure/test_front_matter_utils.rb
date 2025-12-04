# frozen_string_literal: true

# _tests/plugins/utils/test_front_matter_utils.rb
require_relative '../../test_helper'
# Jekyll::Infrastructure::FrontMatterUtils is loaded by test_helper.rb

# Tests for Jekyll::Infrastructure::FrontMatterUtils module.
#
# Verifies that the utility correctly processes and validates front matter data.
class TestFrontMatterUtils < Minitest::Test
  # --- Tests for get_list_from_string_or_array ---

  def test_string_input_single_value
    input = 'Arthur C. Clarke'
    expected = ['Arthur C. Clarke']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_string_input_single_value_with_unicode
    input = 'Hergé'
    expected = ['Hergé']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_string_input_with_whitespace
    input = '  Isaac Asimov  '
    expected = ['Isaac Asimov']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_string_input_empty_after_strip
    input = '   '
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_string_input_actually_empty
    input = ''
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_multiple_values
    input = ['Author One', 'Author Two', 'Author Three']
    expected = ['Author One', 'Author Two', 'Author Three']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_single_value
    input = ['Ursula K. Le Guin']
    expected = ['Ursula K. Le Guin']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_whitespace_in_elements
    input = ['  Frank Herbert  ', ' Robert Heinlein']
    expected = ['Frank Herbert', 'Robert Heinlein']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_empty_strings_and_nil_values
    input = ['Author A', '', '  ', nil, 'Author B', nil]
    expected = ['Author A', 'Author B'] # Empty strings and nils should be removed
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_all_empty_or_nil
    input = [nil, '', '   ', nil]
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_empty_array
    input = []
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_non_string_elements
    # The method converts elements to string with .to_s before stripping
    input = ['Valid String', 123, true, :symbol_value, ' Another Valid ']
    expected = ['Valid String', '123', 'true', 'symbol_value', 'Another Valid']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_non_string_elements_that_become_empty
    obj = Object.new
    input = [123, '', obj, '  ', nil] # Object.new.to_s might be complex, but .strip.empty? should handle it
    expected_predictable = ['123', obj.to_s] # "123" is the only non-empty string after processing
    assert_equal expected_predictable, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_nil_input
    input = nil
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_unsupported_type_input_integer
    input = 12_345 # Not a string or array
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_unsupported_type_input_hash
    input = { key: 'value' } # Not a string or array
    expected = []
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_duplicates
    input = ['Author A', 'Author B', 'Author A', 'Author C', 'Author B']
    expected = ['Author A', 'Author B', 'Author C'] # Order of first appearance is preserved by .uniq
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_with_duplicates_after_stripping
    input = ['  Author A  ', 'Author B', 'Author A  ']
    expected = ['Author A', 'Author B']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_array_input_duplicates_with_different_case_are_kept
    # .uniq is case-sensitive
    input = ['author a', 'Author A', 'author a']
    expected = ['author a', 'Author A']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end

  def test_string_input_no_duplicates_to_remove
    input = 'Single Author'
    expected = ['Single Author']
    assert_equal expected, Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(input)
  end
end
