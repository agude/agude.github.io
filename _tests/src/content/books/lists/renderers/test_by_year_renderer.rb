# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Lists::Renderers::ByYearRenderer
#
# Verifies that books are correctly rendered grouped by year.
class TestByYearRenderer < Minitest::Test
  def setup
    @book_2024 = create_doc(
      { 'title' => 'Book 2024', 'published' => true },
      '/books/2024.html',
    )
    @book_2023 = create_doc(
      { 'title' => 'Book 2023', 'published' => true },
      '/books/2023.html',
    )
    @site = create_site({}, { 'books' => [@book_2024, @book_2023] })
    @context = create_context({}, { site: @site, page: @book_2024 })
  end

  def test_returns_empty_when_no_groups
    data = { year_groups: [] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)

    assert_equal '', renderer.render
  end

  def test_renders_year_heading
    data = { year_groups: [{ year: '2024', books: [@book_2024] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<h2 class="book-list-headline"'
    assert_includes result, '>2024</h2>'
  end

  def test_generates_year_id
    data = { year_groups: [{ year: '2024', books: [@book_2024] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="year-2024"'
  end

  def test_renders_card_grid
    data = { year_groups: [{ year: '2024', books: [@book_2024] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<div class="card-grid">'
  end

  def test_generates_year_navigation
    data = {
      year_groups: [
        { year: '2024', books: [@book_2024] },
        { year: '2023', books: [@book_2023] },
      ],
    }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<nav class="alpha-jump-links">'
    assert_includes result, '<a href="#year-2024">2024</a>'
    assert_includes result, '<a href="#year-2023">2023</a>'
  end

  def test_navigation_uses_middot_separator
    data = {
      year_groups: [
        { year: '2024', books: [@book_2024] },
        { year: '2023', books: [@book_2023] },
      ],
    }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '&middot;'
  end

  def test_renders_multiple_years
    data = {
      year_groups: [
        { year: '2024', books: [@book_2024] },
        { year: '2023', books: [@book_2023] },
      ],
    }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="year-2024"'
    assert_includes result, 'id="year-2023"'
  end

  def test_renders_multiple_books_in_year
    book_2024_b = create_doc(
      { 'title' => 'Another 2024 Book', 'published' => true },
      '/books/2024b.html',
    )
    data = { year_groups: [{ year: '2024', books: [@book_2024, book_2024_b] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    # Should have one grid with multiple cards
    assert_equal 1, result.scan('card-grid').length
  end

  def test_navigation_only_links_present_years
    data = { year_groups: [{ year: '2024', books: [@book_2024] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByYearRenderer.new(@context, data)
    result = renderer.render

    # Navigation only includes years with books
    assert_includes result, '2024'
    refute_includes result, '2023'
  end
end
