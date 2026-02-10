# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Books::Backlinks::Renderer
#
# Verifies that backlink data is correctly rendered to HTML.
class TestBacklinksRenderer < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Test Book', 'published' => true },
      '/books/test.html'
    )
    @site = create_site({}, { 'books' => [@book] })
    @context = create_context({}, { site: @site, page: @book })
  end

  def test_returns_empty_string_for_no_backlinks
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, [])
    result = renderer.render

    assert_equal '', result
  end

  def test_renders_aside_container
    backlinks = [['Other Book', '/books/other.html', 'book']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, '<aside class="book-backlinks">'
    assert_includes result, '</aside>'
  end

  def test_renders_heading_with_book_title
    backlinks = [['Other Book', '/books/other.html', 'book']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, 'Reviews that mention'
    assert_includes result, '<span class="book-title">Test Book</span>'
  end

  def test_renders_list_items
    backlinks = [['Other Book', '/books/other.html', 'book']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, '<ul class="book-backlink-list">'
    assert_includes result, '<li class="book-backlink-item"'
    assert_includes result, 'data-link-type="book"'
  end

  def test_renders_multiple_backlinks
    backlinks = [
      ['Book A', '/books/a.html', 'book'],
      ['Book B', '/books/b.html', 'book']
    ]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, 'Book A'
    assert_includes result, 'Book B'
  end

  def test_renders_series_indicator_for_series_type
    backlinks = [['Series Book', '/books/series.html', 'series']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, 'data-link-type="series"'
    assert_includes result, '<sup class="series-mention-indicator"'
    assert_includes result, '†'
  end

  def test_includes_series_explanation_when_series_links_present
    backlinks = [['Series Book', '/books/series.html', 'series']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    assert_includes result, '<p class="backlink-explanation">'
    assert_includes result, 'Mentioned via a link to the series'
  end

  def test_no_series_explanation_for_book_links_only
    backlinks = [['Direct Book', '/books/direct.html', 'book']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    refute_includes result, 'backlink-explanation'
    refute_includes result, 'Mentioned via a link to the series'
  end

  def test_escapes_html_in_book_title
    book_with_special = create_doc(
      { 'title' => 'Book <script>alert("xss")</script>', 'published' => true },
      '/books/special.html'
    )
    site = create_site({}, { 'books' => [book_with_special] })
    context = create_context({}, { site: site, page: book_with_special })

    backlinks = [['Other', '/books/other.html', 'book']]
    renderer = Jekyll::Books::Backlinks::Renderer.new(context, book_with_special, backlinks)
    result = renderer.render

    refute_includes result, '<script>'
    assert_includes result, '&lt;script&gt;'
  end

  def test_mixed_book_and_series_links
    backlinks = [
      ['Book Link', '/books/book.html', 'book'],
      ['Series Link', '/books/series.html', 'series']
    ]
    renderer = Jekyll::Books::Backlinks::Renderer.new(@context, @book, backlinks)
    result = renderer.render

    # Should have series explanation
    assert_includes result, 'backlink-explanation'

    # Book link should not have indicator
    # Series link should have indicator
    assert_includes result, 'data-link-type="book"'
    assert_includes result, 'data-link-type="series"'
  end
end
