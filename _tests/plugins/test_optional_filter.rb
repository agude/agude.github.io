# frozen_string_literal: true

# _tests/plugins/test_optional_filter.rb
require 'test_helper'
require 'optional_filter'

# Tests for OptionalFilter.
#
# Verifies that the filter safely handles missing keys, nil objects,
# and type mismatches (e.g. accessing an Array with a String key)
# to prevent Liquid strict_variables from crashing the build.
class TestOptionalFilter < Minitest::Test
  include Jekyll::OptionalFilter

  # A mock class that behaves like a Jekyll Drop (responds to [])
  class MockDrop
    def [](key)
      return 'DropValue' if key == 'exists'

      nil
    end
  end

  def setup
    @data = {
      'title' => 'My Post',
      'is_true' => true,
      'is_false' => false,
      'nested' => { 'id' => 123 }
    }
    @array = %w[a b c]
    @drop = MockDrop.new
  end

  # --- Happy Paths ---

  def test_returns_value_for_existing_hash_key
    assert_equal 'My Post', optional(@data, 'title')
  end

  def test_returns_value_for_nested_hash_access
    nested = optional(@data, 'nested')
    assert_equal 123, optional(nested, 'id')
  end

  def test_returns_value_for_array_integer_index
    # Arrays support [] with integer
    assert_equal 'a', optional(@array, 0)
  end

  def test_returns_value_for_string_slice
    # Strings support [] (slice)
    assert_equal 'h', optional('hello', 0)
    assert_equal 'e', optional('hello', 'e') # "hello"['e'] -> "e"
  end

  def test_returns_value_for_custom_drop_object
    # Jekyll Drops are objects that implement [], not Hashes.
    assert_equal 'DropValue', optional(@drop, 'exists')
    assert_nil optional(@drop, 'missing')
  end

  # --- Missing/Nil Paths ---

  def test_returns_nil_for_missing_hash_key
    assert_nil optional(@data, 'missing_key')
  end

  def test_returns_nil_when_object_is_nil
    assert_nil optional(nil, 'title')
  end

  def test_returns_nil_when_object_does_not_support_indexing
    # Object.new does not respond to []
    assert_nil optional(Object.new, 'title')
  end

  # --- Edge Cases (Type Mismatches) ---

  def test_returns_nil_when_integer_accessed_by_string
    # Integer responds to [], but 123['title'] raises TypeError.
    # The filter should catch this and return nil.
    assert_nil optional(12_345, 'title')
  end

  def test_returns_nil_when_array_accessed_by_string
    # Array responds to [], but ['a']['key'] raises TypeError.
    assert_nil optional(@array, 'key')
  end

  # --- Liquid Integration Tests ---

  def test_liquid_integration_success
    template = Liquid::Template.parse("{{ data | optional: 'title' }}")
    result = template.render('data' => @data)
    assert_equal 'My Post', result
  end

  def test_liquid_integration_missing_silently
    template = Liquid::Template.parse("Output: {{ data | optional: 'ghost' }}")
    result = template.render('data' => @data)
    assert_equal 'Output: ', result
  end

  def test_liquid_integration_nested_chain
    template = Liquid::Template.parse("{{ data | optional: 'nested' | optional: 'id' }}")
    result = template.render('data' => @data)
    assert_equal '123', result
  end

  def test_liquid_conditional_logic
    # 1. Missing key -> nil -> falsy
    template_missing = Liquid::Template.parse(
      "{% assign val = data | optional: 'missing' %}{% if val %}YES{% else %}NO{% endif %}"
    )
    assert_equal 'NO', template_missing.render('data' => @data)

    # 2. Existing key (true) -> true -> truthy
    template_true = Liquid::Template.parse(
      "{% assign val = data | optional: 'is_true' %}{% if val %}YES{% else %}NO{% endif %}"
    )
    assert_equal 'YES', template_true.render('data' => @data)

    # 3. Existing key (false) -> false -> falsy
    template_false = Liquid::Template.parse(
      "{% assign val = data | optional: 'is_false' %}{% if val %}YES{% else %}NO{% endif %}"
    )
    assert_equal 'NO', template_false.render('data' => @data)
  end
end
