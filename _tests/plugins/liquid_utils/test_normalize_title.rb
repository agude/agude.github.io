require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- normalize_title ---
  def test_normalize_title_basic
    assert_equal "hello world", LiquidUtils.normalize_title("  Hello \n World  ")
  end

  def test_normalize_title_with_articles
    assert_equal "test title", LiquidUtils.normalize_title("The Test Title", strip_articles: true)
    assert_equal "example", LiquidUtils.normalize_title("an Example", strip_articles: true)
  end

  def test_normalize_title_nil
    assert_equal "", LiquidUtils.normalize_title(nil)
  end
end
