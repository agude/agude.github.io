# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/series/series_link_util'

# Tests for Jekyll::Series::SeriesLinkUtils.
#
# Verifies that the utility module correctly uses SeriesLinkFinder + LinkFormatter.
class TestSeriesLinkUtils < Minitest::Test
  Utils = Jekyll::Series::SeriesLinkUtils

  def setup
    @series_entry = {
      'title' => 'Foundation',
      'url' => '/series/foundation/'
    }
    @site = create_site_with_link_cache({
                                          'series' => {
                                            'foundation' => @series_entry
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Format Parameter Tests ---

  def test_render_with_format_html_returns_html
    result = Utils.render_series_link('Foundation', @context, format: :html)
    assert_match %r{<a href="/series/foundation/">}, result
    assert_match %r{<span class="book-series">Foundation</span>}, result
  end

  def test_render_with_format_markdown_returns_markdown
    result = Utils.render_series_link('Foundation', @context, format: :markdown)
    assert_equal '[Foundation](/series/foundation/)', result
  end

  def test_render_without_format_uses_context_mode
    # Default context has no markdown_mode, should return HTML
    result = Utils.render_series_link('Foundation', @context)
    assert_match(/<a href=/, result)
    assert_match(/<span class="book-series">/, result)
  end

  def test_render_with_markdown_context_returns_markdown
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_series_link('Foundation', md_context)
    assert_equal '[Foundation](/series/foundation/)', result
  end

  def test_render_with_format_overrides_context_mode
    # Even with markdown_mode: true, format: :html should return HTML
    md_context = create_context({}, { site: @site, page: @page, markdown_mode: true })
    result = Utils.render_series_link('Foundation', md_context, format: :html)
    assert_match(/<a href=/, result)
    assert_match(/<span class="book-series">/, result)
  end

  # --- Override Tests ---

  def test_render_with_override_uses_override_text
    result = Utils.render_series_link('Foundation', @context, 'The Foundation Trilogy', format: :html)
    assert_match %r{<span class="book-series">The Foundation Trilogy</span>}, result
    assert_match %r{href="/series/foundation/"}, result
  end

  def test_render_with_override_markdown
    result = Utils.render_series_link('Foundation', @context, 'The Trilogy', format: :markdown)
    assert_equal '[The Trilogy](/series/foundation/)', result
  end

  # --- Unknown Series Tests ---

  def test_render_unknown_series_html_returns_span_only
    result = Utils.render_series_link('Unknown Series', @context, format: :html)
    assert_equal '<span class="book-series">Unknown Series</span>', result
    refute_match(/<a href=/, result)
  end

  def test_render_unknown_series_markdown_returns_text_only
    result = Utils.render_series_link('Unknown Series', @context, format: :markdown)
    assert_equal 'Unknown Series', result
  end

  # --- Helper Method Tests ---

  def test_build_series_span_element
    result = Utils._build_series_span_element('Test Series')
    assert_equal '<span class="book-series">Test Series</span>', result
  end

  def test_build_series_span_element_escapes_html
    result = Utils._build_series_span_element('<Script>')
    assert_equal '<span class="book-series">&lt;Script&gt;</span>', result
  end
end
