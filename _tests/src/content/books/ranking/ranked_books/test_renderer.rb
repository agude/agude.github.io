# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Ranking::RankedBooks::Renderer
#
# Verifies that rating groups are correctly rendered to HTML.
class TestRankedBooksRenderer < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Test Book', 'published' => true, 'rating' => 5 },
      '/books/test.html'
    )
    @site = create_site({}, { 'books' => [@book] })
    @context = create_context({}, { site: @site, page: @book })
  end

  def test_returns_empty_when_no_groups
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, [])

    assert_equal '', renderer.render
  end

  def test_renders_rating_heading
    groups = [{ rating: 5, books: [@book] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '<h2 class="book-list-headline"'
    assert_includes result, 'id="rating-5"'
  end

  def test_renders_star_ratings
    groups = [{ rating: 5, books: [@book] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    # Should use RatingUtils to render stars
    assert_includes result, 'star-rating'
  end

  def test_renders_card_grid
    groups = [{ rating: 5, books: [@book] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '<div class="card-grid">'
  end

  def test_generates_navigation
    groups = [
      { rating: 5, books: [@book] },
      { rating: 4, books: [@book] }
    ]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '<nav class="alpha-jump-links">'
    assert_includes result, '<a href="#rating-5">'
    assert_includes result, '<a href="#rating-4">'
  end

  def test_navigation_uses_singular_for_one_star
    one_star = create_doc(
      { 'title' => 'One Star', 'published' => true, 'rating' => 1 },
      '/books/one.html'
    )
    groups = [{ rating: 1, books: [one_star] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '1&nbsp;Star</a>'
    refute_includes result, '1&nbsp;Stars'
  end

  def test_navigation_uses_plural_for_multiple_stars
    groups = [{ rating: 5, books: [@book] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '5&nbsp;Stars</a>'
  end

  def test_navigation_uses_middot_separator
    groups = [
      { rating: 5, books: [@book] },
      { rating: 4, books: [@book] }
    ]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, '&middot;'
  end

  def test_renders_multiple_rating_groups
    book_4star = create_doc(
      { 'title' => 'Four Star', 'published' => true, 'rating' => 4 },
      '/books/four.html'
    )
    groups = [
      { rating: 5, books: [@book] },
      { rating: 4, books: [book_4star] }
    ]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    assert_includes result, 'id="rating-5"'
    assert_includes result, 'id="rating-4"'
  end

  def test_renders_multiple_books_in_group
    book_b = create_doc(
      { 'title' => 'Second Book', 'published' => true, 'rating' => 5 },
      '/books/second.html'
    )
    groups = [{ rating: 5, books: [@book, book_b] }]
    renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(@context, groups)
    result = renderer.render

    # Should have one grid
    assert_equal 1, result.scan('card-grid').length
  end
end
