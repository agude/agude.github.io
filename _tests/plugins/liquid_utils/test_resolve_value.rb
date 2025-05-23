# _tests/plugins/liquid_utils/test_resolve_value.rb
require_relative '../../test_helper'

class TestLiquidUtilsResolveValue < Minitest::Test

  # --- resolve_value ---
  def test_resolve_value_quoted_string
    ctx = create_context
    assert_equal "hello", LiquidUtils.resolve_value('"hello"', ctx)
    assert_equal "world", LiquidUtils.resolve_value("'world'", ctx)
    assert_equal "with space", LiquidUtils.resolve_value("'with space'", ctx)
    assert_equal "", LiquidUtils.resolve_value("''", ctx) # Empty quoted string
  end

  def test_resolve_value_variable_found_string
    ctx = create_context({ 'page' => { 'my_var' => 'found it' } })
    ctx['simple_var'] = 'top level'
    assert_equal "found it", LiquidUtils.resolve_value('page.my_var', ctx)
    assert_equal "top level", LiquidUtils.resolve_value('simple_var', ctx)
  end

  def test_resolve_value_variable_found_non_string
    ctx = create_context({ 'num_var' => 123, 'bool_var' => true })
    assert_equal 123, LiquidUtils.resolve_value('num_var', ctx)
    assert_equal true, LiquidUtils.resolve_value('bool_var', ctx)
  end

  def test_resolve_value_variable_holds_nil
    ctx = create_context({ 'nil_var' => nil })
    # Should return actual nil
    assert_nil LiquidUtils.resolve_value('nil_var', ctx)
  end

  def test_resolve_value_variable_holds_false
    ctx = create_context({ 'false_var' => false })
    # Should return actual false
    assert_equal false, LiquidUtils.resolve_value('false_var', ctx)
  end

  # --- UPDATED TEST ---
  def test_resolve_value_variable_not_found_returns_nil
    ctx = create_context
    # If 'missing_var' is not quoted and not a key, return nil
    assert_nil LiquidUtils.resolve_value('missing_var', ctx)
    # Also for nested lookups that fail
    assert_nil LiquidUtils.resolve_value('page.missing', ctx)
  end

  def test_resolve_value_unquoted_matches_existing_variable
    # If an unquoted string matches a variable name, the variable's value should be returned
    ctx = create_context({ 'my_literal' => 'variable value' })
    assert_equal 'variable value', LiquidUtils.resolve_value('my_literal', ctx)
  end

  # --- UPDATED TEST ---
  def test_resolve_value_unquoted_does_not_match_variable_returns_nil
    # If an unquoted string does not match a variable, it should return nil
    ctx = create_context
    assert_nil LiquidUtils.resolve_value('some_literal_string', ctx)
  end

  def test_resolve_value_nil_or_empty_markup_input
    ctx = create_context
    assert_nil LiquidUtils.resolve_value(nil, ctx)
    assert_nil LiquidUtils.resolve_value('', ctx)
    assert_nil LiquidUtils.resolve_value('  ', ctx) # Whitespace only markup
  end

  def test_resolve_value_deeply_nested_variable
    ctx = create_context({ 'a' => { 'b' => { 'c' => 'deep value' } } })
    assert_equal 'deep value', LiquidUtils.resolve_value('a.b.c', ctx)
  end

  # --- UPDATED TEST ---
  def test_resolve_value_deeply_nested_variable_failure_returns_nil
    ctx = create_context({ 'a' => { 'b' => { 'c' => 'deep value' } } })
    # 'd' does not exist under 'c' - should return nil
    assert_nil LiquidUtils.resolve_value('a.b.c.d', ctx)
    # 'x' does not exist at top level - should return nil
    assert_nil LiquidUtils.resolve_value('a.x.c', ctx)
  end

end
