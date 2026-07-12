# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/links/link_resolver_skeleton'

# Tests for Jekyll::Infrastructure::Links::LinkResolverSkeleton.
#
# Verifies the shared resolve flow (no-site guard, empty-input handling,
# cache lookup, display-text precedence, frozen results) and the
# structural per-resolve state reset, using a dummy resolver.
class TestLinkResolverSkeleton < Minitest::Test
  # Minimal resolver built on the skeleton, mirroring SeriesLinkResolver.
  class WidgetResolver
    include Jekyll::Infrastructure::Links::LinkResolverSkeleton

    self.cache_section = 'widgets'
    self.tag_type = 'RENDER_WIDGET_LINK'
    self.entity_name = 'widget'
    self.empty_input_status = :empty_title
    self.empty_input_reason = 'Input title resolved to empty after normalization.'
    self.empty_input_key = :TitleInput
    self.not_found_key = :Widget

    def resolve_data(title_raw, override_raw, link: true)
      resolve_link_data(title_raw, override_raw, link: link)
    end

    private

    def wrap_element(display_text)
      "<span class=\"widget\">#{CGI.escapeHTML(display_text)}</span>"
    end
  end

  def setup
    @site = create_site
    @site.data['link_cache']['widgets'] = {
      'my widget' => { 'url' => '/widgets/my-widget.html', 'title' => 'My Widget' },
    }
    @page = create_doc({}, '/current.html')
    @ctx = create_context({}, { site: @site, page: @page })
  end

  def resolver
    WidgetResolver.new(@ctx)
  end

  # --- resolve_data flow ---

  def test_found_result
    data = resolver.resolve_data('  my WIDGET ', nil)
    assert_equal :found, data[:status]
    assert_equal '/widgets/my-widget.html', data[:url]
    assert_equal 'My Widget', data[:display_text]
    assert data.frozen?
  end

  def test_not_found_result_keeps_input_text
    data = resolver.resolve_data('Unknown Widget', nil)
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
    assert_equal 'Unknown Widget', data[:display_text]
  end

  def test_override_takes_precedence_over_canonical
    data = resolver.resolve_data('My Widget', '  The Override ')
    assert_equal 'The Override', data[:display_text]
  end

  def test_link_false_nullifies_url
    data = resolver.resolve_data('My Widget', nil, link: false)
    assert_equal :found, data[:status]
    assert_nil data[:url]
  end

  def test_empty_input_result
    data = resolver.resolve_data('   ', nil)
    assert_equal :empty_title, data[:status]
    assert_nil data[:url]
    assert_nil data[:display_text]
  end

  def test_no_site_result
    data = WidgetResolver.new(nil).resolve_data('My Widget', nil)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'My Widget', data[:display_text]
  end

  # --- resolve (HTML rendering) ---

  def test_resolve_found_renders_link
    expected = '<a href="/widgets/my-widget.html"><span class="widget">My Widget</span></a>'
    assert_equal expected, resolver.resolve('My Widget', nil)
  end

  def test_resolve_not_found_renders_bare_element
    assert_equal '<span class="widget">Unknown</span>', resolver.resolve('Unknown', nil)
  end

  def test_resolve_link_false_renders_bare_element
    assert_equal '<span class="widget">My Widget</span>', resolver.resolve('My Widget', nil, link: false)
  end

  def test_resolve_escapes_display_text
    assert_equal '<span class="widget">A &amp; B</span>', resolver.resolve('A & B', nil)
  end

  def test_resolve_empty_input_returns_log_output_only
    assert_equal '', resolver.resolve('', nil)
  end

  def test_resolve_no_site_renders_wrapped_text
    assert_equal '<span class="widget">My Widget</span>', WidgetResolver.new(nil).resolve('My Widget', nil)
  end

  # --- Structural per-resolve state reset ---

  def test_reused_instance_does_not_leak_log_output
    @site.config['plugin_logging']['RENDER_WIDGET_LINK'] = true
    shared = resolver

    Jekyll.stub(:logger, silent_logger) do
      miss_output = shared.resolve('Unknown Widget', nil)
      assert_match(/<!-- \[INFO\] RENDER_WIDGET_LINK_FAILURE:/, miss_output)

      hit_output = shared.resolve('My Widget', nil)
      refute_match(
        /RENDER_WIDGET_LINK_FAILURE/,
        hit_output,
        'a successful resolve must not repeat the previous miss log',
      )
    end
  end

  def test_reused_instance_does_not_leak_override
    shared = resolver
    assert_equal 'The Override', shared.resolve_data('My Widget', 'The Override')[:display_text]
    assert_equal 'My Widget', shared.resolve_data('My Widget', nil)[:display_text]
  end
end
