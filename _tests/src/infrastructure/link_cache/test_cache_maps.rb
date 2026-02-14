# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::CacheMaps
#
# Verifies that URL-keyed lookup maps are correctly built from link cache data.
class TestCacheMaps < Minitest::Test
  def test_builds_books_map_keyed_by_url
    link_cache = {
      'books' => {
        'book one' => [{ 'url' => '/books/one.html', 'title' => 'Book One' }],
        'book two' => [{ 'url' => '/books/two.html', 'title' => 'Book Two' }],
      },
      'authors' => {},
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    assert_equal 'Book One', maps.books['/books/one.html']['title']
    assert_equal 'Book Two', maps.books['/books/two.html']['title']
  end

  def test_builds_authors_map_keyed_by_url
    link_cache = {
      'books' => {},
      'authors' => {
        'jane doe' => { 'url' => '/authors/jane.html', 'title' => 'Jane Doe' },
        'john smith' => { 'url' => '/authors/john.html', 'title' => 'John Smith' },
      },
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    assert_equal 'Jane Doe', maps.authors['/authors/jane.html']['title']
    assert_equal 'John Smith', maps.authors['/authors/john.html']['title']
  end

  def test_builds_series_map_keyed_by_url
    link_cache = {
      'books' => {},
      'authors' => {},
      'series' => {
        'foundation' => { 'url' => '/series/foundation.html', 'title' => 'Foundation' },
        'dune' => { 'url' => '/series/dune.html', 'title' => 'Dune' },
      },
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    assert_equal 'Foundation', maps.series['/series/foundation.html']['title']
    assert_equal 'Dune', maps.series['/series/dune.html']['title']
  end

  def test_handles_duplicate_book_titles_with_different_urls
    link_cache = {
      'books' => {
        'duplicate' => [
          { 'url' => '/books/dup-a.html', 'title' => 'Duplicate', 'authors' => ['Author A'] },
          { 'url' => '/books/dup-b.html', 'title' => 'Duplicate', 'authors' => ['Author B'] },
        ],
      },
      'authors' => {},
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    # Both books should be accessible by their URLs
    assert_equal ['Author A'], maps.books['/books/dup-a.html']['authors']
    assert_equal ['Author B'], maps.books['/books/dup-b.html']['authors']
  end

  def test_handles_empty_caches
    link_cache = {
      'books' => {},
      'authors' => {},
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    assert_empty maps.books
    assert_empty maps.authors
    assert_empty maps.series
  end

  def test_flattens_books_from_multiple_title_entries
    link_cache = {
      'books' => {
        'book a' => [{ 'url' => '/books/a.html', 'title' => 'Book A' }],
        'book b' => [{ 'url' => '/books/b.html', 'title' => 'Book B' }],
        'book c' => [{ 'url' => '/books/c.html', 'title' => 'Book C' }],
      },
      'authors' => {},
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    assert_equal 3, maps.books.size
  end

  def test_author_pen_names_share_url
    # When an author has pen names, all normalized names point to same URL
    # CacheMaps just indexes by URL, so duplicates are fine
    link_cache = {
      'books' => {},
      'authors' => {
        'jane doe' => { 'url' => '/authors/jane.html', 'title' => 'Jane Doe' },
        'j.d. writer' => { 'url' => '/authors/jane.html', 'title' => 'Jane Doe' },
      },
      'series' => {},
    }

    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)

    # Only one URL entry since both point to same author
    assert_equal 1, maps.authors.size
    assert_equal 'Jane Doe', maps.authors['/authors/jane.html']['title']
  end
end
