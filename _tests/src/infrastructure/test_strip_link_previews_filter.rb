# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/strip_link_previews_filter'

# Tests for Jekyll::Infrastructure::StripLinkPreviewsFilter.
#
# Verifies that the filter removes hidden book-link hover-preview markup
# (see BookPreviewRenderer) from HTML, leaves other HTML untouched, and
# handles nil/empty input safely.
class TestStripLinkPreviewsFilter < Minitest::Test
  include Jekyll::Infrastructure::StripLinkPreviewsFilter

  # --- Happy Paths ---

  def test_removes_preview_span_and_content
    html = 'Before<!--book-preview--><span class="book-link-preview">by Frank Herbert</span><!--/book-preview-->After'
    assert_equal 'BeforeAfter', strip_link_previews(html)
  end

  def test_leaves_other_html_alone
    html = '<p>Some <a href="/books/dune.html"><cite>Dune</cite></a> text.</p>'
    assert_equal html, strip_link_previews(html)
  end

  # --- Nil/Empty Paths ---

  def test_nil_input
    assert_equal '', strip_link_previews(nil)
  end

  def test_empty_input
    assert_equal '', strip_link_previews('')
  end

  # --- Liquid Integration Tests ---

  def test_liquid_integration_removes_preview_markup
    template = Liquid::Template.parse('{{ content | strip_link_previews }}')
    content = 'Before<!--book-preview--><span class="book-link-preview">by Frank Herbert</span><!--/book-preview-->After'
    result = template.render('content' => content)
    assert_equal 'BeforeAfter', result
  end

  def test_liquid_integration_leaves_other_html_alone
    template = Liquid::Template.parse('{{ content | strip_link_previews }}')
    content = '<p>Plain content, no preview here.</p>'
    result = template.render('content' => content)
    assert_equal content, result
  end
end
