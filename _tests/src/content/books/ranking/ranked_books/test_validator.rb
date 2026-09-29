# frozen_string_literal: true

require_relative '../../../../../test_helper'

# Tests for Jekyll::Books::Ranking::RankedBooks::Validator
#
# Verifies that ranked book lists are correctly validated.
class TestRankedBooksValidator < Minitest::Test
  def setup
    @book_5star = create_doc(
      { 'title' => 'Five Star Book', 'published' => true, 'rating' => 5 },
      '/books/five.html',
    )
    @book_4star = create_doc(
      { 'title' => 'Four Star Book', 'published' => true, 'rating' => 4 },
      '/books/four.html',
    )
  end

  def test_returns_validated_rating
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    assert_equal 5, validator.validate('Five Star Book', 0, @book_5star)
  end

  def test_raises_when_book_not_found
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Missing Book', 0, nil)
    end

    assert_includes error.message, 'not found'
    assert_includes error.message, 'Missing Book'
    assert_includes error.message, 'position 1'
  end

  def test_validates_rating_is_integer
    bad_rating = create_doc(
      { 'title' => 'Bad', 'published' => true, 'rating' => 'five' },
      '/books/bad.html',
    )
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Bad', 0, bad_rating)
    end

    assert_includes error.message, 'invalid non-integer rating'
  end

  def test_validates_monotonicity
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    # First validate 4-star book
    validator.validate('Four Star Book', 0, @book_4star)

    # Then try to validate 5-star book (higher rating after lower)
    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Five Star Book', 1, @book_5star)
    end

    assert_includes error.message, 'Monotonicity violation'
  end

  def test_allows_equal_ratings
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    book_5star_b = create_doc(
      { 'title' => 'Another Five', 'published' => true, 'rating' => 5 },
      '/books/five-b.html',
    )

    # Should not raise
    validator.validate('Five Star Book', 0, @book_5star)
    validator.validate('Another Five', 1, book_5star_b)
  end

  def test_allows_decreasing_ratings
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    # 5 then 4 is valid (non-increasing)
    validator.validate('Five Star Book', 0, @book_5star)
    validator.validate('Four Star Book', 1, @book_4star)
  end

  def test_error_includes_list_variable_name
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('page.ranked_books')

    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Missing', 0, nil)
    end

    assert_includes error.message, 'page.ranked_books'
  end

  def test_error_includes_position_info
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    validator.validate('Four Star Book', 0, @book_4star)

    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Five Star Book', 1, @book_5star)
    end

    assert_includes error.message, 'position 2'
    assert_includes error.message, 'position 1'
  end

  def test_handles_nil_rating
    nil_rating = create_doc(
      { 'title' => 'Nil Rating', 'published' => true, 'rating' => nil },
      '/books/nil.html',
    )
    validator = Jekyll::Books::Ranking::RankedBooks::Validator.new('list')

    error = assert_raises(Jekyll::Errors::FatalException) do
      validator.validate('Nil Rating', 0, nil_rating)
    end

    assert_includes error.message, 'invalid non-integer rating'
  end
end
