# _tests/plugins/liquid_utils/test_render_author_link.rb
require_relative '../../test_helper'

class TestLiquidUtilsRenderAuthorLink < Minitest::Test

  # --- Existing Tests (Keep, some may pass now without changes) ---
  def test_render_author_link_found_and_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page]) # Add to pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span></a>"
    # Use normalized input for lookup, but expect canonical display
    assert_equal expected, LiquidUtils.render_author_link("  jane DOE ", ctx)
  end

  def test_render_author_link_possessive_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span>’s</a>" # Possessive inside link
    assert_equal expected, LiquidUtils.render_author_link("jane doe", ctx, nil, true)
  end

  def test_render_author_link_possessive_unlinked
    site = create_site({}, {}, []) # No author pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect unlinked span + possessive. log_failure returns ""
    expected = "<span class=\"author-name\">Jane Doe</span>’s" # Possessive outside span
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, nil, true)
  end

  def test_render_author_link_not_found
    site = create_site({}, {}, []) # No author pages
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect unlinked span. log_failure returns ""
    expected = "<span class=\"author-name\">John Smith</span>"
    assert_equal expected, LiquidUtils.render_author_link("John Smith", ctx)
  end

  def test_render_author_link_found_but_current_page
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    # Current page IS the author page
    page = create_doc({}, '/authors/jane-doe.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect unlinked span
    expected = "<span class=\"author-name\">Jane Doe</span>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx)
  end

  def test_render_author_link_with_link_text_override_found
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">JD</span></a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, "JD")
  end

  def test_render_author_link_with_link_text_override_not_found
    site = create_site({}, {}, [])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect unlinked span with override text. log_failure returns ""
    expected = "<span class=\"author-name\">JD</span>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, "JD")
  end

  def test_render_author_link_possessive_with_override_linked
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Possessive inside link, uses override text
    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">JD</span>’s</a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, "JD", true)
  end

  def test_render_author_link_possessive_with_override_unlinked
    site = create_site({}, {}, [])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Possessive outside span, uses override text. log_failure returns ""
    expected = "<span class=\"author-name\">JD</span>’s"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, "JD", true)
  end

  def test_render_author_link_empty_input_name
    site = create_site
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # log_failure called internally, returns ""
    assert_equal "", LiquidUtils.render_author_link("", ctx)
    assert_equal "", LiquidUtils.render_author_link("   ", ctx)
    assert_equal "", LiquidUtils.render_author_link(nil, ctx)
  end

  def test_render_author_link_with_baseurl
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({ 'baseurl' => '/myblog' }, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    expected = "<a href=\"/myblog/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span></a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx)
  end

  def test_render_author_link_escaping_name
    # Author page title needs escaping
    author_page = create_doc({ 'title' => 'A & B <Company>', 'layout' => 'author_page' }, '/authors/a-b.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect canonical title to be escaped
    expected = "<a href=\"/authors/a-b.html\"><span class=\"author-name\">A &amp; B &lt;Company&gt;</span></a>"
    # Use matching input name for lookup (normalization handles it)
    assert_equal expected, LiquidUtils.render_author_link("a & b <company>", ctx)
  end

  def test_render_author_link_escaping_override
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expect override text to be escaped
    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">J &amp; D &lt;Inc&gt;</span></a>"
    assert_equal expected, LiquidUtils.render_author_link("Jane Doe", ctx, "J & D <Inc>")
  end

  def test_render_author_link_uses_canonical_title_from_page
    # Page title has different whitespace/casing than input
    author_page = create_doc({ 'title' => '  Jane   DOE ', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Input name is different but should match via normalization
    input_name = "jane doe"
    # Expect the display text to use the canonical title from the page data (stripped)
    expected = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane   DOE</span></a>"
    actual_html = LiquidUtils.render_author_link(input_name, ctx)

    assert_equal expected, actual_html
  end

  def test_render_author_link_lookup_is_case_insensitive_and_whitespace_normalized
    # Page title is 'Jane Doe'
    author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page' }, '/authors/jane-doe.html')
    site = create_site({}, {}, [author_page])
    page = create_doc({}, '/current.html')
    ctx = create_context({}, { site: site, page: page })

    # Expected linked output using canonical title
    expected_linked = "<a href=\"/authors/jane-doe.html\"><span class=\"author-name\">Jane Doe</span></a>"

    # Test lowercase input - should match and link
    input_name_lower = "jane doe"
    assert_equal expected_linked, LiquidUtils.render_author_link(input_name_lower, ctx)

    # Test input with extra internal space - should match and link
    input_name_space = "Jane  Doe"
    assert_equal expected_linked, LiquidUtils.render_author_link(input_name_space, ctx)

    # Test input with leading/trailing space and different case - should match and link
    input_name_mixed = "  jAnE dOe   "
    assert_equal expected_linked, LiquidUtils.render_author_link(input_name_mixed, ctx)
  end

end
