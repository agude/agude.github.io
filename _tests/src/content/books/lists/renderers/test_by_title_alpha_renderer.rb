# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer
#
# Verifies that books are correctly rendered grouped by first letter of title.
class TestByTitleAlphaRenderer < Minitest::Test
  def setup
    @book_a = create_doc(
      { 'title' => 'Apple Book', 'published' => true },
      '/books/apple.html',
    )
    @book_z = create_doc(
      { 'title' => 'Zebra Book', 'published' => true },
      '/books/zebra.html',
    )
    @site = create_site({}, { 'books' => [@book_a, @book_z] })
    @context = create_context({}, { site: @site, page: @book_a })
  end

  def test_returns_empty_when_no_groups
    data = { alpha_groups: [] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)

    assert_equal '', renderer.render
  end

  def test_renders_letter_heading
    data = { alpha_groups: [{ letter: 'A', books: [@book_a] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<h2 class="book-list-headline"'
    assert_includes result, '>A</h2>'
  end

  def test_generates_letter_id
    data = { alpha_groups: [{ letter: 'A', books: [@book_a] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="letter-a"'
  end

  def test_renders_card_grid
    data = { alpha_groups: [{ letter: 'A', books: [@book_a] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<div class="card-grid">'
  end

  def test_generates_alpha_navigation
    data = {
      alpha_groups: [
        { letter: 'A', books: [@book_a] },
        { letter: 'Z', books: [@book_z] },
      ],
    }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<nav class="alpha-jump-links">'
    assert_includes result, '<a href="#letter-a">A</a>'
    assert_includes result, '<a href="#letter-z">Z</a>'
  end

  def test_uses_spans_for_missing_letters
    data = { alpha_groups: [{ letter: 'M', books: [@book_a] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, '<span>A</span>'
    assert_includes result, '<a href="#letter-m">M</a>'
    assert_includes result, '<span>Z</span>'
  end

  def test_includes_hash_symbol_in_navigation
    data = { alpha_groups: [{ letter: 'A', books: [@book_a] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    # Hash symbol is for titles starting with numbers
    assert_includes result, '<span>#</span>'
  end

  def test_handles_hash_group_for_numeric_titles
    numeric_book = create_doc(
      { 'title' => '1984', 'published' => true },
      '/books/1984.html',
    )
    data = { alpha_groups: [{ letter: '#', books: [numeric_book] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="letter-hash"'
    assert_includes result, '<a href="#letter-hash">#</a>'
  end

  def test_renders_multiple_groups
    data = {
      alpha_groups: [
        { letter: 'A', books: [@book_a] },
        { letter: 'Z', books: [@book_z] },
      ],
    }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    assert_includes result, 'id="letter-a"'
    assert_includes result, 'id="letter-z"'
  end

  def test_renders_multiple_books_in_group
    book_a2 = create_doc(
      { 'title' => 'Another Book', 'published' => true },
      '/books/another.html',
    )
    data = { alpha_groups: [{ letter: 'A', books: [@book_a, book_a2] }] }
    renderer = Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(@context, data)
    result = renderer.render

    # Should have one grid with multiple cards
    assert_equal 1, result.scan('card-grid').length
  end
end
