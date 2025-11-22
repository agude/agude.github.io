# frozen_string_literal: true

# _tests/plugins/utils/test_tag_argument_utils.rb
require_relative '../../test_helper'
require 'utils/tag_argument_utils' # Require the new util module

# Tests for TagArgumentUtils module.
#
# Verifies that the utility correctly resolves tag arguments from quoted strings and Liquid variables.
class TestTagArgumentUtils < Minitest::Test
  # --- resolve_value ---
  def test_resolve_value_quoted_string
    ctx = create_context
    assert_equal 'hello', TagArgumentUtils.resolve_value('"hello"', ctx)
    assert_equal 'world', TagArgumentUtils.resolve_value("'world'", ctx)
    assert_equal 'with space', TagArgumentUtils.resolve_value("'with space'", ctx)
    assert_equal '', TagArgumentUtils.resolve_value("''", ctx) # Empty quoted string
  end

  def test_resolve_value_variable_found_string
    ctx = create_context({ 'page' => { 'my_var' => 'found it' } })
    ctx['simple_var'] = 'top level'
    assert_equal 'found it', TagArgumentUtils.resolve_value('page.my_var', ctx)
    assert_equal 'top level', TagArgumentUtils.resolve_value('simple_var', ctx)
  end

  def test_resolve_value_variable_found_non_string
    ctx = create_context({ 'num_var' => 123, 'bool_var' => true })
    assert_equal 123, TagArgumentUtils.resolve_value('num_var', ctx)
    assert_equal true, TagArgumentUtils.resolve_value('bool_var', ctx)
  end

  def test_resolve_value_variable_holds_nil
    ctx = create_context({ 'nil_var' => nil })
    assert_nil TagArgumentUtils.resolve_value('nil_var', ctx)
  end

  def test_resolve_value_variable_holds_false
    ctx = create_context({ 'false_var' => false })
    assert_equal false, TagArgumentUtils.resolve_value('false_var', ctx)
  end

  def test_resolve_value_variable_not_found_returns_nil
    ctx = create_context
    assert_nil TagArgumentUtils.resolve_value('missing_var', ctx)
    assert_nil TagArgumentUtils.resolve_value('page.missing', ctx)
  end

  def test_resolve_value_unquoted_matches_existing_variable
    ctx = create_context({ 'my_literal' => 'variable value' })
    assert_equal 'variable value', TagArgumentUtils.resolve_value('my_literal', ctx)
  end

  def test_resolve_value_unquoted_does_not_match_variable_returns_nil
    ctx = create_context
    assert_nil TagArgumentUtils.resolve_value('some_literal_string', ctx)
  end

  def test_resolve_value_nil_or_empty_markup_input
    ctx = create_context
    assert_nil TagArgumentUtils.resolve_value(nil, ctx)
    assert_nil TagArgumentUtils.resolve_value('', ctx)
    assert_nil TagArgumentUtils.resolve_value('  ', ctx)
  end

  def test_resolve_value_deeply_nested_variable
    ctx = create_context({ 'a' => { 'b' => { 'c' => 'deep value' } } })
    assert_equal 'deep value', TagArgumentUtils.resolve_value('a.b.c', ctx)
  end

  def test_resolve_value_deeply_nested_variable_failure_returns_nil
    ctx = create_context({ 'a' => { 'b' => { 'c' => 'deep value' } } })
    assert_nil TagArgumentUtils.resolve_value('a.b.c.d', ctx)
    assert_nil TagArgumentUtils.resolve_value('a.x.c', ctx)
  end
end
