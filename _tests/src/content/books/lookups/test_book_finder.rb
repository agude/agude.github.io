# frozen_string_literal: true

# _tests/plugins/logic/card_lookups/test_book_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lookups/book_finder'

# Tests for Jekyll::CardLookups::BookFinder.
#
# Verifies that the BookFinder correctly finds books by normalized title.
class TestBookFinder < Minitest::Test
  def setup
    @book1 = create_doc({ 'title' => 'The First Book', 'published' => true }, '/books/first.html')
    @book2 = create_doc({ 'title' => 'The Second Book', 'published' => true }, '/books/second.html')
    @book3 = create_doc({ 'title' => '  Extra   Whitespace  ', 'published' => true }, '/books/third.html')
    @unpublished_book = create_doc({ 'title' => 'Unpublished Title', 'published' => false }, '/books/unpublished.html')

    @site = create_site(
      { 'url' => 'http://example.com' },
      { 'books' => [@book1, @book2, @book3, @unpublished_book] }
    )
  end

  def test_returns_error_when_site_is_nil
    finder = Jekyll::CardLookups::BookFinder.new(site: nil, title: 'The First Book')
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_returns_error_when_title_is_nil
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: nil)
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_returns_error_when_title_is_empty
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: '   ')
    result = finder.find

    assert_nil result[:book]
    assert_equal :invalid_input, result[:error][:type]
  end

  def test_finds_book_by_exact_title
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: 'The First Book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_by_case_insensitive_title
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: 'the FIRST book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_by_normalized_whitespace
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: '  The   First    Book  ')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end

  def test_finds_book_with_extra_whitespace_in_stored_title
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: 'Extra Whitespace')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book3, result[:book]
  end

  def test_returns_error_when_book_not_found
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: 'NonExistent Book')
    result = finder.find

    assert_nil result[:book]
    assert_equal :not_found, result[:error][:type]
  end

  def test_excludes_unpublished_books
    finder = Jekyll::CardLookups::BookFinder.new(site: @site, title: 'Unpublished Title')
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

    finder = Jekyll::CardLookups::BookFinder.new(site: site_with_duplicate, title: 'The First Book')
    result = finder.find

    assert_nil result[:error]
    assert_equal @book1, result[:book]
  end
end
