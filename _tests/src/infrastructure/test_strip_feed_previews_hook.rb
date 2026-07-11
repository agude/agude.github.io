# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/strip_feed_previews_hook'

# Tests for the :pages :post_render hook that strips book-link
# hover-preview markup from feed XML output.
class TestStripFeedPreviewsHook < Minitest::Test
  PREVIEW_HTML = 'Before<!--book-preview--><span class="book-link-preview">text</span><!--/book-preview-->After'

  def test_strips_previews_from_xml_page
    page = build_page('.xml', PREVIEW_HTML)
    run_hook(page)
    assert_equal 'BeforeAfter', page.output
  end

  def test_skips_html_pages
    page = build_page('.html', PREVIEW_HTML)
    run_hook(page)
    assert_equal PREVIEW_HTML, page.output
  end

  def test_skips_xml_without_previews
    content = '<feed><entry><title>Hello</title></entry></feed>'
    page = build_page('.xml', content)
    run_hook(page)
    assert_equal content, page.output
  end

  def test_skips_nil_output
    page = build_page('.xml', nil)
    run_hook(page)
    assert_nil page.output
  end

  FakePage = Struct.new(:output_ext, :output)

  private

  def build_page(ext, output)
    FakePage.new(ext, output)
  end

  def run_hook(page)
    hooks = Jekyll::Hooks.instance_variable_get(:@registry)
    page_hooks = hooks.dig(:pages, :post_render) || []
    page_hooks.each { |hook| hook.call(page) }
  end
end
