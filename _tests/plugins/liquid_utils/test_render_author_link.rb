require_relative '../../test_helper'

class TestLiquidUtils < Minitest::Test

  # --- render_author_link ---
  def test_render_author_link_found_and_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page]) # Add to pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span></a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx)
  end

  def test_render_author_link_possessive_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span>’s</a>" # Possessive inside link
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, nil, true)
  end

  def test_render_author_link_possessive_unlinked
    site = create_site({}, {}, []) # No author pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<span class=\"author-name\">Jane Doe</span>’s" # Possessive outside span
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, nil, true)
  end
end
