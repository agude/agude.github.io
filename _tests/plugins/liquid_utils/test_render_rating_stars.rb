require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test
  # --- render_rating_stars ---
  def test_render_rating_stars_valid
    assert_match(/class=".*star-rating-5.*★.*★.*★.*★.*★/, LiquidUtils.render_rating_stars(5))
    assert_match(/class=".*star-rating-3.*★.*★.*★.*☆.*☆/, LiquidUtils.render_rating_stars(3))
    assert_match(/class=".*star-rating-1.*★.*☆.*☆.*☆.*☆/, LiquidUtils.render_rating_stars(1))
  end

  def test_render_rating_stars_invalid
    assert_equal "", LiquidUtils.render_rating_stars(0)
    assert_equal "", LiquidUtils.render_rating_stars(6)
    assert_equal "", LiquidUtils.render_rating_stars("invalid")
    assert_equal "", LiquidUtils.render_rating_stars(nil)
  end

  def test_render_rating_stars_wrapper_tag
    assert_match(/^<span class=.*<\/span>$/, LiquidUtils.render_rating_stars(4, 'span'))
    assert_match(/^<div class=.*<\/div>$/, LiquidUtils.render_rating_stars(4, 'div'))
    # Ensure invalid tags default to div
    assert_match(/^<div class=.*<\/div>$/, LiquidUtils.render_rating_stars(4, 'script'))
  end
end
