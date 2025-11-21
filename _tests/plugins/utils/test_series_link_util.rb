# frozen_string_literal: true

# _tests/plugins/utils/test_series_link_util.rb
require_relative '../../test_helper'

class TestSeriesLinkUtils < Minitest::Test
  def test_render_series_link_found_and_linked
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page]) # Add series page to site.pages
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<a href="/series/awesome.html"><span class="book-series">My Awesome Series</span></a>'
    actual_html = SeriesLinkUtils.render_series_link('My Awesome Series', ctx)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_found_but_current_page
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    # Current page IS the series page
    current_page = create_doc({}, '/series/awesome.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<span class="book-series">My Awesome Series</span>' # No link
    actual_html = SeriesLinkUtils.render_series_link('My Awesome Series', ctx)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_not_found
    site = create_site({}, {}, []) # No pages defined
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect the unlinked span. log_failure is called internally but returns ""
    # because logging is off by default in tests.
    expected_html = '<span class="book-series">NonExistent Series</span>'
    actual_html = SeriesLinkUtils.render_series_link('NonExistent Series', ctx)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_with_link_text_override_found
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<a href="/series/awesome.html"><span class="book-series">Display This Instead</span></a>'
    actual_html = SeriesLinkUtils.render_series_link('My Awesome Series', ctx, 'Display This Instead')

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_with_link_text_override_not_found
    site = create_site({}, {}, [])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect the unlinked span with the override text. log_failure returns ""
    expected_html = '<span class="book-series">Display This Instead</span>'
    actual_html = SeriesLinkUtils.render_series_link('NonExistent Series', ctx, 'Display This Instead')

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_empty_input_title
    site = create_site
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # log_failure is called internally and returns "", so the function returns ""
    assert_equal '', SeriesLinkUtils.render_series_link('', ctx)
    assert_equal '', SeriesLinkUtils.render_series_link('   ', ctx) # Whitespace only
    assert_equal '', SeriesLinkUtils.render_series_link(nil, ctx)
  end

  def test_render_series_link_with_baseurl
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    # Site configured with a baseurl
    site = create_site({ 'baseurl' => '/blog' }, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect href to include the baseurl
    expected_html = '<a href="/blog/series/awesome.html"><span class="book-series">My Awesome Series</span></a>'
    actual_html = SeriesLinkUtils.render_series_link('My Awesome Series', ctx)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_escaping
    series_page = create_doc({ 'title' => 'Series <Title> & Stuff', 'layout' => 'series_page' }, '/series/tricky.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect basic HTML entities to be escaped in the display text
    expected_html = '<a href="/series/tricky.html"><span class="book-series">Series &lt;Title&gt; &amp; Stuff</span></a>'
    actual_html = SeriesLinkUtils.render_series_link('Series <Title> & Stuff', ctx)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_uses_canonical_title_from_page
    # Page title has different whitespace/casing than input
    series_page = create_doc({ 'title' => '  My canonical   SERIES title ', 'layout' => 'series_page' },
                             '/series/canonical.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Input title is different but should match during lookup
    input_title = 'my canonical series title'
    # Expect the display text to use the canonical title from the page data (stripped)
    expected_html = '<a href="/series/canonical.html"><span class="book-series">My canonical   SERIES title</span></a>'
    actual_html = SeriesLinkUtils.render_series_link(input_title, ctx)

    assert_equal expected_html, actual_html
  end
end
