# frozen_string_literal: true

# _tests/plugins/logic/card_lookups/test_book_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lookups/book_finder'

# Tests for Jekyll::Books::Lookups::BookFinder.
#
# Verifies that the BookFinder correctly finds books by normalized title.
class TestBookFinder < Minitest::Test
  def setup
    @book1 = create_doc({ 'title' => 'The First Book', 'published' => true }, '/books/first.html')
    @book2 = create_doc({ 'title' => 'The Second Book', 'published' => true }, '/books/second.html')
    @book3 = create_doc({ 'title' => '  Extra   Whitespace  ', 'published' => true }, '/books/third.html')
    @unpublished_book = create_doc({ 'title' => 'Unpublished Title', 'published' => false }, '/books/unpublished.html')

    # Books with same title but different dates (like multiple reviews)
    @hyperion_review1 = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'date' => Time.new(2023, 10, 17) },
      '/books/hyperion/review-2023-10-17.html'
    )
    @hyperion_review2 = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'date' => Time.new(2025, 9, 20) },
      '/books/hyperion.html'
    )

    @site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [@book1, @book2, @book3, @unpublished_book, @hyperion_review1, @hyperion_review2] }
    )
  end

  def test_returns_error_when_site_is_nil
    finder = Jekyll::Books::Lookups::BookFinder.new(site: nil, title: 'The First Book')
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_returns_error_when_title_is_nil
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: nil)
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_returns_error_when_title_is_empty
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: '   ')
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_finds_book_by_exact_title
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: 'The First Book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_by_case_insensitive_title
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: 'the FIRST book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_by_normalized_whitespace
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: '  The   First    Book  ')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_with_extra_whitespace_in_stored_title
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: 'Extra Whitespace')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book3, result[:book]
  end

  def test_returns_error_when_book_not_found
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: 'NonExistent Book')
    result = finder.find

    assert_nil result[:book]
    assert_equal :not_found, result[:error][:type]
  end

  def test_excludes_unpublished_books
    finder = Jekyll::Books::Lookups::BookFinder.new(site: @site, title: 'Unpublished Title')
    result = finder.find

    assert_nil result[:book]
    assert_equal :not_found, result[:error][:type]
  end

  def test_returns_first_matching_book_if_duplicates_exist
    duplicate_book = create_doc({ 'title' => 'The First Book', 'published' => true }, '/books/duplicate.html')
    site_with_duplicate = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [@book1, duplicate_book, @book2] }
    )

    finder = Jekyll::Books::Lookups::BookFinder.new(site: site_with_duplicate, title: 'The First Book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  # --- Date Parameter Tests ---

  def test_finds_book_by_title_and_date_with_date_object
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: Date.new(2023, 10, 17)
    )
    result = finder.find

    assert_nil result[:error], "Expected no error, got: #{result[:error]}"
    assert_equal @hyperion_review1, result[:book]
  end

  def test_finds_book_by_title_and_date_with_string
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: '2025-09-20'
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @hyperion_review2, result[:book]
  end

  def test_finds_different_review_by_date
    # First review
    finder1 = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: '2023-10-17'
    )
    result1 = finder1.find

    # Second review
    finder2 = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: '2025-09-20'
    )
    result2 = finder2.find

    assert_nil result1[:error]
    assert_nil result2[:error]
    assert_equal @hyperion_review1, result1[:book]
    assert_equal @hyperion_review2, result2[:book]
    refute_equal result1[:book], result2[:book]
  end

  def test_returns_error_when_date_provided_but_no_match
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: '2020-01-01'
    )
    result = finder.find

    assert_nil result[:book]
    assert_equal :date_not_found, result[:error][:type]
  end

  def test_returns_error_when_date_invalid_format
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion',
      date: 'not-a-date'
    )
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_date, result[:error][:type]
  end

  def test_returns_error_when_title_exists_but_date_does_not_match_any
    # The First Book exists but has no date matching 2023-01-01
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'The First Book',
      date: '2023-01-01'
    )
    result = finder.find

    assert_nil result[:book]
    assert_equal :date_not_found, result[:error][:type]
  end

  def test_without_date_returns_first_matching_book
    # Without date parameter, should return first match (existing behavior)
    finder = Jekyll::Books::Lookups::BookFinder.new(
      site: @site,
      title: 'Hyperion'
    )
    result = finder.find

    assert_nil result[:error]
    assert_equal @hyperion_review1, result[:book]
  end
end
