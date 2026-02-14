# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::CacheBuilder
#
# Verifies that caches are correctly built from pages and book documents.
class TestCacheBuilder < Minitest::Test
  def test_caches_sidebar_nav_items
    sidebar_page = create_doc(
      { 'title' => 'About', 'sidebar_include' => true },
      '/about.html',
    )
    non_sidebar_page = create_doc(
      { 'title' => 'Contact', 'sidebar_include' => false },
      '/contact.html',
    )

    site = create_site({}, {}, [sidebar_page, non_sidebar_page])
    sidebar_nav = site.data['link_cache']['sidebar_nav']

    assert_equal 1, sidebar_nav.length
    assert_equal '/about.html', sidebar_nav.first.url
  end

  def test_excludes_paginated_pages_from_sidebar
    paginated_page = create_doc(
      { 'title' => 'Blog Page 2', 'sidebar_include' => true },
      '/blog/page2/',
    )

    site = create_site({}, {}, [paginated_page])
    sidebar_nav = site.data['link_cache']['sidebar_nav']

    assert_empty sidebar_nav
  end

  def test_caches_topbar_nav_items
    topbar_page = create_doc(
      { 'title' => 'By Series', 'book_topbar_include' => true },
      '/books/by-series.html',
    )
    non_topbar_page = create_doc(
      { 'title' => 'Other', 'book_topbar_include' => false },
      '/other.html',
    )

    site = create_site({}, {}, [topbar_page, non_topbar_page])
    topbar_nav = site.data['link_cache']['books_topbar_nav']

    assert_equal 1, topbar_nav.length
    assert_equal '/books/by-series.html', topbar_nav.first.url
  end

  def test_sorts_nav_items_by_title
    page_b = create_doc({ 'title' => 'Zebra', 'sidebar_include' => true }, '/zebra.html')
    page_a = create_doc({ 'title' => 'Apple', 'sidebar_include' => true }, '/apple.html')

    site = create_site({}, {}, [page_b, page_a])
    sidebar_nav = site.data['link_cache']['sidebar_nav']

    assert_equal 'Apple', sidebar_nav.first.data['title']
    assert_equal 'Zebra', sidebar_nav.last.data['title']
  end

  def test_caches_author_pages
    author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html',
    )

    site = create_site({}, {}, [author_page])
    authors = site.data['link_cache']['authors']

    assert_equal '/authors/jane-doe.html', authors['jane doe']['url']
    assert_equal 'Jane Doe', authors['jane doe']['title']
  end

  def test_caches_author_pen_names
    author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page', 'pen_names' => ['J.D. Writer', 'Anonymous'] },
      '/authors/jane-doe.html',
    )

    site = create_site({}, {}, [author_page])
    authors = site.data['link_cache']['authors']

    # Should be findable by pen names too
    assert_equal '/authors/jane-doe.html', authors['j.d. writer']['url']
    assert_equal '/authors/jane-doe.html', authors['anonymous']['url']
  end

  def test_caches_series_pages
    series_page = create_doc(
      { 'title' => 'The Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site({}, {}, [series_page])
    series = site.data['link_cache']['series']

    assert_equal '/series/foundation.html', series['the foundation series']['url']
    assert_equal 'The Foundation Series', series['the foundation series']['title']
  end

  def test_caches_books_with_normalized_titles
    book = create_doc(
      { 'title' => 'The Great Gatsby', 'published' => true, 'book_authors' => ['F. Scott Fitzgerald'] },
      '/books/great-gatsby.html',
    )

    site = create_site({}, { 'books' => [book] })
    books = site.data['link_cache']['books']

    assert_equal 1, books['the great gatsby'].length
    assert_equal '/books/great-gatsby.html', books['the great gatsby'].first['url']
  end

  def test_handles_duplicate_book_titles
    book_a = create_doc(
      { 'title' => 'Duplicate', 'published' => true, 'book_authors' => ['Author A'] },
      '/books/dup-a.html',
    )
    book_b = create_doc(
      { 'title' => 'Duplicate', 'published' => true, 'book_authors' => ['Author B'] },
      '/books/dup-b.html',
    )

    site = create_site({}, { 'books' => [book_a, book_b] })
    books = site.data['link_cache']['books']

    assert_equal 2, books['duplicate'].length
  end

  def test_excludes_unpublished_books_from_cache
    published = create_doc(
      { 'title' => 'Published Book', 'published' => true },
      '/books/published.html',
    )
    unpublished = create_doc(
      { 'title' => 'Draft Book', 'published' => false },
      '/books/draft.html',
    )

    site = create_site({}, { 'books' => [published, unpublished] })
    books = site.data['link_cache']['books']

    assert_equal 1, books['published book'].length
    assert_nil books['draft book']
  end

  def test_builds_series_map
    book1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
    )
    book2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
    )
    standalone = create_doc(
      { 'title' => 'Standalone', 'published' => true },
      '/books/standalone.html',
    )

    site = create_site({}, { 'books' => [book1, book2, standalone] })
    series_map = site.data['link_cache']['series_map']

    assert_equal 2, series_map['foundation series'].length
    assert_nil series_map['standalone']
  end

  def test_builds_book_families_with_canonical_url
    canonical = create_doc(
      { 'title' => 'Original Edition', 'published' => true },
      '/books/original.html',
    )
    reprint = create_doc(
      { 'title' => 'Reprint Edition', 'published' => true, 'canonical_url' => '/books/original.html' },
      '/books/reprint.html',
    )

    site = create_site({}, { 'books' => [canonical, reprint] })
    families = site.data['link_cache']['book_families']
    url_map = site.data['link_cache']['url_to_canonical_map']

    # Both should point to the canonical URL
    assert_equal '/books/original.html', url_map['/books/original.html']
    assert_equal '/books/original.html', url_map['/books/reprint.html']

    # Canonical URL should have both in its family
    assert_includes families['/books/original.html'], '/books/original.html'
    assert_includes families['/books/original.html'], '/books/reprint.html'
  end

  def test_skips_pages_without_title
    no_title_page = create_doc(
      { 'title' => nil, 'sidebar_include' => true },
      '/no-title.html',
    )

    site = create_site({}, {}, [no_title_page])
    sidebar_nav = site.data['link_cache']['sidebar_nav']

    assert_empty sidebar_nav
  end

  def test_skips_books_without_title
    no_title_book = create_doc(
      { 'title' => nil, 'published' => true },
      '/books/no-title.html',
    )

    site = create_site({}, { 'books' => [no_title_book] })
    books = site.data['link_cache']['books']

    assert_empty books
  end

  def test_skips_books_with_empty_title
    empty_title_book = create_doc(
      { 'title' => '   ', 'published' => true },
      '/books/empty-title.html',
    )

    site = create_site({}, { 'books' => [empty_title_book] })
    books = site.data['link_cache']['books']

    assert_empty books
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    books = site.data['link_cache']['books']

    assert_empty books
  end

  def test_book_data_includes_authors
    book = create_doc(
      { 'title' => 'Collaboration', 'published' => true, 'book_authors' => ['Author A', 'Author B'] },
      '/books/collab.html',
    )

    site = create_site({}, { 'books' => [book] })
    book_data = site.data['link_cache']['books']['collaboration'].first

    assert_equal ['Author A', 'Author B'], book_data['authors']
  end

  def test_book_data_includes_date
    book = create_doc(
      { 'title' => 'Dated Book', 'published' => true, 'date' => Time.parse('2024-01-15') },
      '/books/dated.html',
    )

    site = create_site({}, { 'books' => [book] })
    book_data = site.data['link_cache']['books']['dated book'].first

    refute_nil book_data['date']
  end
end
