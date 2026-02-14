# frozen_string_literal: true

# _tests/src/content/series/test_series_link_resolver.rb
require_relative '../../../test_helper'

# Tests for Jekyll::Series::SeriesLinkResolver class.
#
# Verifies that the resolver correctly creates links to book series pages.
class TestSeriesLinkResolver < Minitest::Test
  def test_render_series_link_found_and_linked
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page]) # Add series page to site.pages
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<a href="/series/awesome.html"><span class="book-series">My Awesome Series</span></a>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('My Awesome Series', nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_found_but_current_page
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    # Current page IS the series page
    current_page = create_doc({}, '/series/awesome.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<span class="book-series">My Awesome Series</span>' # No link
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('My Awesome Series', nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_not_found
    site = create_site({}, {}, []) # No pages defined
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect the unlinked span. log_failure is called internally but returns ""
    # because logging is off by default in tests.
    expected_html = '<span class="book-series">NonExistent Series</span>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('NonExistent Series', nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_with_link_text_override_found
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    expected_html = '<a href="/series/awesome.html"><span class="book-series">Display This Instead</span></a>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('My Awesome Series', 'Display This Instead')

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_with_link_text_override_not_found
    site = create_site({}, {}, [])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect the unlinked span with the override text. log_failure returns ""
    expected_html = '<span class="book-series">Display This Instead</span>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('NonExistent Series', 'Display This Instead')

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_empty_input_title
    site = create_site
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # log_failure is called internally and returns "", so the function returns ""
    assert_equal '', Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('', nil)
    assert_equal '', Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('   ', nil) # Whitespace only
    assert_equal '', Jekyll::Series::SeriesLinkResolver.new(ctx).resolve(nil, nil)
  end

  def test_render_series_link_with_baseurl
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    # Site configured with a baseurl
    site = create_site({ 'baseurl' => '/blog' }, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect href to include the baseurl
    expected_html = '<a href="/blog/series/awesome.html"><span class="book-series">My Awesome Series</span></a>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('My Awesome Series', nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_escaping
    series_page = create_doc({ 'title' => 'Series <Title> & Stuff', 'layout' => 'series_page' }, '/series/tricky.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Expect basic HTML entities to be escaped in the display text
    expected_html = '<a href="/series/tricky.html"><span class="book-series">Series &lt;Title&gt; &amp; Stuff</span></a>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve('Series <Title> & Stuff', nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_uses_canonical_title_from_page
    # Page title has different whitespace/casing than input
    series_page = create_doc(
      { 'title' => '  My canonical   SERIES title ', 'layout' => 'series_page' },
      '/series/canonical.html',
    )
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    # Input title is different but should match during lookup
    input_title = 'my canonical series title'
    # Expect the display text to use the canonical title from the page data (stripped)
    expected_html = '<a href="/series/canonical.html"><span class="book-series">My canonical   SERIES title</span></a>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve(input_title, nil)

    assert_equal expected_html, actual_html
  end

  def test_render_series_link_with_nil_site_uses_fallback
    # This tests line 71 and the 'then' branch on line 54
    # When site is nil in context, it should use the fallback method
    ctx_no_site = create_context({}, {}) # No site in registers

    # Should return just a span with the title (fallback behavior)
    expected_html = '<span class="book-series">Fallback Series</span>'
    actual_html = Jekyll::Series::SeriesLinkResolver.new(ctx_no_site).resolve('Fallback Series', nil)

    assert_equal expected_html, actual_html
  end

  # --- resolve() log capture regression tests ---

  def test_resolve_empty_title_includes_log_output_when_logging_enabled
    site_with_logging = create_site
    site_with_logging.config['plugin_logging']['RENDER_SERIES_LINK'] = true
    current_page = create_doc({}, '/current-page.html')
    ctx_logging = create_context({}, { site: site_with_logging, page: current_page })

    silent_logger = Object.new
    def silent_logger.warn(_topic, _message); end
    def silent_logger.info(_topic, _message); end

    output = Jekyll.stub(:logger, silent_logger) do
      Jekyll::Series::SeriesLinkResolver.new(ctx_logging).resolve('', nil)
    end
    assert_match(/<!-- \[WARN\] RENDER_SERIES_LINK_FAILURE:.*?empty after normalization.*?-->/, output)
  end

  # --- resolve_data() tests ---

  def test_resolve_data_found
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    data = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve_data('My Awesome Series', nil)
    assert_equal :found, data[:status]
    assert_equal '/series/awesome.html', data[:url]
    assert_equal 'My Awesome Series', data[:display_text]
  end

  def test_resolve_data_not_found
    site = create_site({}, {}, [])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    data = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve_data('NonExistent Series', nil)
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
    assert_equal 'NonExistent Series', data[:display_text]
  end

  def test_resolve_data_empty_title
    site = create_site
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    data = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve_data('', nil)
    assert_equal :empty_title, data[:status]
    assert_nil data[:url]
    assert_nil data[:display_text]
  end

  def test_resolve_data_no_site
    ctx_no_site = create_context({}, {})
    data = Jekyll::Series::SeriesLinkResolver.new(ctx_no_site).resolve_data('Some Series', nil)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'Some Series', data[:display_text]
  end

  def test_resolve_data_with_override
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    data = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve_data('My Awesome Series', 'Custom Text')
    assert_equal :found, data[:status]
    assert_equal 'Custom Text', data[:display_text]
  end

  def test_resolve_data_frozen
    series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    site = create_site({}, {}, [series_page])
    current_page = create_doc({}, '/current-page.html')
    ctx = create_context({}, { site: site, page: current_page })

    data = Jekyll::Series::SeriesLinkResolver.new(ctx).resolve_data('My Awesome Series', nil)
    assert data.frozen?, 'resolve_data() should return a frozen hash'
  end
end
