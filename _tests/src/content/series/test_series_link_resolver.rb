# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Series::SeriesLinkResolver class.
#
# Verifies that the resolver correctly creates links to book series pages.
class TestSeriesLinkResolver < Minitest::Test
  Resolver = Jekyll::Series::SeriesLinkResolver

  def setup
    @series_page = create_doc({ 'title' => 'My Awesome Series', 'layout' => 'series_page' }, '/series/awesome.html')
    @site = create_site({}, {}, [@series_page])
    @context = create_context({}, { site: @site, page: create_doc({}, '/current-page.html') })
    @resolver = Resolver.new(@context)
  end

  def test_resolve_rejects_unknown_keywords
    assert_raises(ArgumentError) { @resolver.resolve('Missing', nil, url: '/wrong/') }
  end

  def test_render_rejects_status_from_another_resolver
    resolver = Jekyll::Series::SeriesLinkResolver.new(nil)
    data = { status: :ambiguous, url: nil, display_text: 'Example' }

    error = assert_raises(Jekyll::Errors::FatalException) { resolver.send(:render_html_from_data, data) }

    assert_includes error.message, 'unrecognized status :ambiguous'
  end

  def test_renders_markdown_link
    context = create_context({}, { site: @site, page: create_doc({}, '/current-page.html'), render_mode: :markdown })
    template = Liquid::Template.parse('{% series_link "My Awesome Series" %}')
    assert_equal '[_My Awesome Series_](/series/awesome.html)', template.render!(context)
  end

  def test_render_series_link_found_but_current_page
    context = create_context({}, { site: @site, page: @series_page })
    assert_equal '<span class="book-series">My Awesome Series</span>', Resolver.new(context).resolve('My Awesome Series', nil)
  end

  def test_render_series_link_not_found
    assert_equal '<span class="book-series">Unknown Series</span>', @resolver.resolve('Unknown Series', nil)
  end

  def test_render_series_link_empty_input_title
    ['', '   ', nil].each { |input| assert_equal '', @resolver.resolve(input, nil) }
  end

  def test_render_series_link_with_baseurl
    @site.config['baseurl'] = '/blog'
    expected = '<a href="/blog/series/awesome.html"><span class="book-series">My Awesome Series</span></a>'
    assert_equal expected, Liquid::Template.parse('{% series_link "My Awesome Series" %}').render!(@context)
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

  def test_resolve_empty_title_includes_log_output_when_logging_enabled
    site_with_logging = create_site
    site_with_logging.config['plugin_logging']['RENDER_SERIES_LINK'] = true
    current_page = create_doc({}, '/current-page.html')
    ctx_logging = create_context({}, { site: site_with_logging, page: current_page })

    output = Jekyll.stub(:logger, silent_logger) do
      Jekyll::Series::SeriesLinkResolver.new(ctx_logging).resolve('', nil)
    end
    assert_match(/<!-- \[WARN\] RENDER_SERIES_LINK_FAILURE:.*?empty after normalization.*?-->/, output)
  end

  def test_resolve_data_found
    data = @resolver.resolve_data('My Awesome Series', nil)
    assert_equal [:found, '/series/awesome.html', 'My Awesome Series'], data.values_at(:status, :url, :display_text)
  end

  def test_resolve_data_not_found
    data = @resolver.resolve_data('NonExistent Series', nil)
    assert_equal [:not_found, nil, 'NonExistent Series'], data.values_at(:status, :url, :display_text)
    @site.data['link_cache'].delete('series')
    data = @resolver.resolve_data('NonExistent Series', 'Display This Instead')
    assert_equal [:not_found, nil, 'Display This Instead'], data.values_at(:status, :url, :display_text)
  end

  def test_resolve_data_empty_title
    assert_equal [:empty_title, nil, nil], @resolver.resolve_data('', nil).values_at(:status, :url, :display_text)
  end

  def test_resolve_data_no_site
    ctx_no_site = create_context({}, {})
    data = Jekyll::Series::SeriesLinkResolver.new(ctx_no_site).resolve_data('Some Series', nil)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'Some Series', data[:display_text]
  end

  def test_resolve_data_with_override
    assert_equal 'Custom Text', @resolver.resolve_data('My Awesome Series', '  Custom Text  ')[:display_text]
    assert_equal 'My Awesome Series', @resolver.resolve_data('My Awesome Series', nil)[:display_text]
  end

  def test_resolve_data_link_false_found_has_nil_url
    data = @resolver.resolve_data('My Awesome Series', nil, link: false)
    assert_equal [:found, nil, 'My Awesome Series'], data.values_at(:status, :url, :display_text)
  end
end
