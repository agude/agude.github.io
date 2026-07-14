# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/strip_feed_previews_hook'

# Tests for the :pages :post_render hook that strips book-link and
# footnote hover-preview markup from feed XML output.
#
# Fixtures use realistic flush markup (markers directly between tags) —
# PreviewIntegrityValidator also runs on :post_render and rejects markers
# abutting text.
class TestStripFeedPreviewsHook < Minitest::Test
  PREVIEW_HTML =
    '<p>Before <a href="/books/x/"><cite class="book-title">X</cite>' \
    '<!--book-preview--><span class="book-link-preview">text</span><!--/book-preview-->' \
    '</a> After</p>'
  STRIPPED_HTML = '<p>Before <a href="/books/x/"><cite class="book-title">X</cite></a> After</p>'

  FOOTNOTE_HTML =
    '<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a>' \
    '<!--footnote-preview--><span class="footnote-preview">note</span><!--/footnote-preview-->' \
    '</sup>'
  STRIPPED_FOOTNOTE_HTML = '<sup id="fnref:1"><a href="#fn:1" class="footnote">1</a></sup>'

  def test_strips_previews_from_xml_page
    page = build_page('.xml', PREVIEW_HTML)
    run_hook(page)
    assert_equal STRIPPED_HTML, page.output
  end

  def test_strips_footnote_previews_from_xml_page
    page = build_page('.xml', FOOTNOTE_HTML)
    run_hook(page)
    assert_equal STRIPPED_FOOTNOTE_HTML, page.output
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
