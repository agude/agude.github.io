# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer
#
# Verifies that books are correctly rendered grouped by author, then by series.
class TestByAuthorThenSeriesRenderer < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Test Book', 'published' => true },
      '/books/test.html'
    )
    @series_book = create_doc(
      { 'title' => 'Series Book', 'published' => true, 'series' => 'Epic Saga' },
      '/books/series.html'
    )
    @site = create_site({}, { 'books' => [@book, @series_book] })
    @context = create_context({}, { site: @site, page: @book })
  end

  def test_returns_empty_when_no_authors
    data = { authors_data: [] }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)

    assert_equal '', renderer.render
  end

  def test_renders_author_heading
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<h2 class="book-list-headline"'
    assert_includes result, 'Jane Doe'
  end

  def test_generates_author_slug_for_id
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="jane-doe"'
  end

  def test_renders_standalone_books_section
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'Standalone Books'
    assert_includes result, 'id="standalone-books-jane-doe"'
    assert_includes result, 'card-grid'
  end

  def test_renders_series_groups
    series_group = { name: 'Epic Saga', books: [@series_book] }
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [], series_groups: [series_group] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'Epic Saga'
  end

  def test_renders_both_standalone_and_series
    series_group = { name: 'Epic Saga', books: [@series_book] }
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [@book], series_groups: [series_group] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'Standalone Books'
    assert_includes result, 'Epic Saga'
  end

  def test_generates_alpha_navigation
    data = {
      authors_data: [
        { author_name: 'Alice', standalone_books: [@book], series_groups: [] },
        { author_name: 'Zack', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<nav class="alpha-jump-links">'
    assert_includes result, '<a href="#alice">A</a>'
    assert_includes result, '<a href="#zack">Z</a>'
  end

  def test_uses_spans_for_missing_letters
    data = {
      authors_data: [
        { author_name: 'Mike', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<span>A</span>'
    assert_includes result, '<a href="#mike">M</a>'
    assert_includes result, '<span>Z</span>'
  end

  def test_renders_multiple_authors
    data = {
      authors_data: [
        { author_name: 'Alice', standalone_books: [@book], series_groups: [] },
        { author_name: 'Bob', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'Alice'
    assert_includes result, 'Bob'
  end

  def test_escapes_html_in_author_name
    data = {
      authors_data: [
        { author_name: 'Jane <script>alert("xss")</script>', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    refute_includes result, '<script>'
    assert_includes result, '&lt;script&gt;'
  end

  def test_skips_standalone_section_when_empty
    series_group = { name: 'Epic Saga', books: [@series_book] }
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [], series_groups: [series_group] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    refute_includes result, 'Standalone Books'
    assert_includes result, 'Epic Saga'
  end

  def test_skips_series_section_when_empty
    data = {
      authors_data: [
        { author_name: 'Jane Doe', standalone_books: [@book], series_groups: [] }
      ]
    }
    renderer = Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'Standalone Books'
    # Series section should not appear
    refute_includes result, 'series-title'
  end
end
