# _plugins/tests/test_liquid_utils.rb
require_relative 'test_helper' # Relative path to helper within tests/

# Test class must inherit from Minitest::Test
class TestMinimalLiquidUtils < Minitest::Test

  # Test methods must start with 'test_'
  def test_normalize_title_basic
    assert_equal "hello world", LiquidUtils.normalize_title("  Hello \n World  ")
  end

  def test_normalize_title_strips_leading_the
    assert_equal "test title", LiquidUtils.normalize_title("The Test Title", strip_articles: true)
  end

  # Minimal test for the helper function (assuming it exists)
  # This requires Kramdown, which might add complexity if not already loaded
  # by Jekyll dependency in test_helper.
  def test_prepare_display_title_simple
     # Check if Kramdown is available before running this test
     skip("Kramdown not available") unless defined?(Kramdown)
     assert_equal "Simple Title", LiquidUtils._prepare_display_title("Simple Title")
  end

  def test_prepare_display_title_smart_apostrophe
     skip("Kramdown not available") unless defined?(Kramdown)
     assert_equal "It’s Simple", LiquidUtils._prepare_display_title("It's Simple")
  end

end
