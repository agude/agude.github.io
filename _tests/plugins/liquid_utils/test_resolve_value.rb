require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- resolve_value ---
  def test_resolve_value_quoted_string
    ctx = create_context
    assert_equal "hello", LiquidUtils.resolve_value('"hello"', ctx)
    assert_equal "world", LiquidUtils.resolve_value("'world'", ctx)
  end

  def test_resolve_value_variable_found
    ctx = create_context({ 'page' => { 'my_var' => 'found it' } })
    assert_equal "found it", LiquidUtils.resolve_value('page.my_var', ctx)
  end

  def test_resolve_value_variable_not_found_returns_markup
    ctx = create_context
    assert_equal "missing_var", LiquidUtils.resolve_value('missing_var', ctx)
  end

  def test_resolve_value_nil_or_empty
    ctx = create_context
    assert_nil LiquidUtils.resolve_value(nil, ctx)
    assert_nil LiquidUtils.resolve_value('', ctx)
    assert_nil LiquidUtils.resolve_value('  ', ctx)
  end
end
