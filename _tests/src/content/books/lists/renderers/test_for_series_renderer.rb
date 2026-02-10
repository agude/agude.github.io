# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Lists::Renderers::ForSeriesRenderer
#
# Verifies that books for a specific series are correctly rendered.
class TestForSeriesRenderer < Minitest::Test
  def setup
    @book1 = create_doc(
      { 'title' => 'Book One', 'published' => true, 'series' => 'Epic Saga' },
      '/books/one.html'
    )
    @book2 = create_doc(
      { 'title' => 'Book Two', 'published' => true, 'series' => 'Epic Saga' },
      '/books/two.html'
    )
    @site = create_site({}, { 'books' => [@book1, @book2] })
    @context = create_context({}, { site: @site, page: @book1 })
  end

  def test_returns_empty_when_no_books
    data = { books: [] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)

    assert_equal '', renderer.render
  end

  def test_renders_card_grid_container
    data = { books: [@book1] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<div class="card-grid">'
    assert_includes result, '</div>'
  end

  def test_renders_single_book
    data = { books: [@book1] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)
    result = renderer.render

    # Should render a book card
    assert_includes result, 'card-grid'
  end

  def test_renders_multiple_books
    data = { books: [@book1, @book2] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)
    result = renderer.render

    # Should have single grid container
    assert_equal 1, result.scan('card-grid').length
  end

  def test_no_navigation_for_series
    data = { books: [@book1, @book2] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)
    result = renderer.render

    # ForSeriesRenderer does not generate navigation
    refute_includes result, 'alpha-jump-links'
    refute_includes result, '<nav'
  end

  def test_no_heading_generated
    data = { books: [@book1] }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)
    result = renderer.render

    # ForSeriesRenderer does not generate headings (series page handles that)
    refute_includes result, '<h2'
    refute_includes result, '<h3'
  end

  def test_handles_nil_books_array
    data = { books: nil }
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)

    assert_equal '', renderer.render
  end

  def test_handles_missing_books_key
    data = {}
    renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer.new(@context, data)

    assert_equal '', renderer.render
  end
end
