# frozen_string_literal: true

require_relative '../../../test_helper'

# Exercises shared rendering through a series resolver.
class TestLinkResolverSkeleton < Minitest::Test
  def test_reused_instance_does_not_leak_log_output
    site = create_site
    site.data['link_cache']['series'] = { 'the series' => { 'title' => 'The Series', 'url' => '/series/' } }
    site.config['plugin_logging']['RENDER_SERIES_LINK'] = true
    context = create_context({}, { site: site, page: create_doc({}, '/current.html') })
    resolver = Jekyll::Series::SeriesLinkResolver.new(context)

    Jekyll.stub(:logger, silent_logger) do
      assert_includes resolver.resolve('Unknown Series', nil), '[INFO] RENDER_SERIES_LINK_FAILURE'
      refute_includes resolver.resolve('The Series', nil), 'RENDER_SERIES_LINK_FAILURE'
    end
  end

  # --- Unknown status raises ---

  def test_render_html_from_data_raises_on_unknown_status
    resolver = Jekyll::Series::SeriesLinkResolver.new(nil)
    bogus_data = { status: :bogus, url: nil, display_text: 'x' }
    error = assert_raises(Jekyll::Errors::FatalException) do
      resolver.send(:render_html_from_data, bogus_data)
    end
    assert_match(/unrecognized status :bogus/, error.message)
  end
end
