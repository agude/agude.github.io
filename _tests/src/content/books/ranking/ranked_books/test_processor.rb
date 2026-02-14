# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Ranking::RankedBooks::Processor
#
# Verifies that ranked book lists are correctly processed into rating groups.
class TestRankedBooksProcessor < Minitest::Test
  def setup
    @book_5star = create_doc(
      { 'title' => 'Five Star Book', 'published' => true, 'rating' => 5 },
      '/books/five.html',
    )
    @book_4star = create_doc(
      { 'title' => 'Four Star Book', 'published' => true, 'rating' => 4 },
      '/books/four.html',
    )
    @book_3star = create_doc(
      { 'title' => 'Three Star Book', 'published' => true, 'rating' => 3 },
      '/books/three.html',
    )
  end

  def test_returns_empty_groups_for_empty_list
    site = create_site({}, { 'books' => [@book_5star] })
    context = create_context({ 'my_list' => [] }, { site: site, page: @book_5star })

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')
    result = processor.process

    assert_empty result[:rating_groups]
  end

  def test_groups_books_by_rating
    site = create_site({}, { 'books' => [@book_5star, @book_4star] })
    context = create_context(
      { 'my_list' => ['Five Star Book', 'Four Star Book'] },
      { site: site, page: @book_5star },
    )

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')
    result = processor.process

    assert_equal 2, result[:rating_groups].length
    assert_equal 5, result[:rating_groups][0][:rating]
    assert_equal 4, result[:rating_groups][1][:rating]
  end

  def test_combines_books_with_same_rating
    book_5star_b = create_doc(
      { 'title' => 'Another Five Star', 'published' => true, 'rating' => 5 },
      '/books/five-b.html',
    )
    site = create_site({}, { 'books' => [@book_5star, book_5star_b] })
    context = create_context(
      { 'my_list' => ['Five Star Book', 'Another Five Star'] },
      { site: site, page: @book_5star },
    )

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')
    result = processor.process

    assert_equal 1, result[:rating_groups].length
    assert_equal 2, result[:rating_groups][0][:books].length
  end

  def test_raises_when_list_not_array
    site = create_site({}, { 'books' => [@book_5star] })
    context = create_context({ 'my_list' => 'not an array' }, { site: site, page: @book_5star })

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')

    error = assert_raises(RuntimeError) { processor.process }
    assert_includes error.message, 'not a valid list'
  end

  def test_raises_when_books_collection_missing
    site = create_site({}, {})
    context = create_context({ 'my_list' => ['Book'] }, { site: site, page: @book_5star })

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')

    error = assert_raises(RuntimeError) { processor.process }
    assert_includes error.message, "Collection 'books' not found"
  end

  def test_skips_unpublished_books
    unpublished = create_doc(
      { 'title' => 'Unpublished', 'published' => false, 'rating' => 5 },
      '/books/unpub.html',
    )
    site = create_site({}, { 'books' => [unpublished] })
    context = create_context({ 'my_list' => ['Unpublished'] }, { site: site, page: unpublished })

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')

    # In non-production mode, should raise because book not found
    error = assert_raises(RuntimeError) { processor.process }
    assert_includes error.message, 'not found'
  end

  def test_validates_monotonicity_in_development
    site = create_site({ 'environment' => 'development' }, { 'books' => [@book_4star, @book_5star] })
    context = create_context(
      { 'my_list' => ['Four Star Book', 'Five Star Book'] },
      { site: site, page: @book_4star },
    )

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')

    # 5 after 4 violates monotonicity
    error = assert_raises(RuntimeError) { processor.process }
    assert_includes error.message, 'Monotonicity violation'
  end

  def test_skips_validation_in_production
    site = create_site({ 'environment' => 'production' }, { 'books' => [@book_5star] })
    context = create_context(
      { 'my_list' => ['Missing Book'] },
      { site: site, page: @book_5star },
    )

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')
    result = processor.process

    # Should not raise, just skip the missing book
    assert_empty result[:rating_groups]
  end

  def test_handles_books_with_invalid_rating_in_production
    bad_rating = create_doc(
      { 'title' => 'Bad Rating', 'published' => true, 'rating' => 'not a number' },
      '/books/bad.html',
    )
    site = create_site({ 'environment' => 'production' }, { 'books' => [bad_rating] })
    context = create_context(
      { 'my_list' => ['Bad Rating'] },
      { site: site, page: bad_rating },
    )

    processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, 'my_list')
    result = processor.process

    # Should skip the book with invalid rating
    assert_empty result[:rating_groups]
  end
end
