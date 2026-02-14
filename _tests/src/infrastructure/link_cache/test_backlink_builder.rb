# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::LinkCache::BacklinkBuilder
#
# Verifies that backlinks are correctly built by scanning book content
# for book_link, series_link, and short_story_link tags.
class TestBacklinkBuilder < Minitest::Test
  def setup
    @book_a = create_doc(
      { 'title' => 'Book A', 'published' => true },
      '/books/book-a.html',
      "Review of Book A with {% book_link 'Book B' %} reference.",
    )
    @book_b = create_doc(
      { 'title' => 'Book B', 'published' => true },
      '/books/book-b.html',
      'Book B content with no links.',
    )
    @book_c = create_doc(
      { 'title' => 'Book C', 'published' => true },
      '/books/book-c.html',
      "Book C references {% book_link \"Book A\" %} and {% book_link 'Book B' %}.",
    )
  end

  def test_builds_backlinks_from_book_links
    site = create_site({}, { 'books' => [@book_a, @book_b, @book_c] })
    backlinks = site.data['link_cache']['backlinks']

    # Book B should have backlinks from Book A and Book C
    assert_equal 2, backlinks['/books/book-b.html'].length

    # Book A should have backlink from Book C
    assert_equal 1, backlinks['/books/book-a.html'].length
    assert_equal '/books/book-c.html', backlinks['/books/book-a.html'].first[:source].url
  end

  def test_no_self_referential_backlinks
    self_ref_book = create_doc(
      { 'title' => 'Self Ref', 'published' => true },
      '/books/self-ref.html',
      "This book references itself: {% book_link 'Self Ref' %}.",
    )

    site = create_site({}, { 'books' => [self_ref_book] })
    backlinks = site.data['link_cache']['backlinks']

    # Should not create a backlink to itself
    assert_empty backlinks['/books/self-ref.html'] || []
  end

  def test_handles_empty_content
    empty_book = create_doc(
      { 'title' => 'Empty', 'published' => true },
      '/books/empty.html',
      '',
    )

    site = create_site({}, { 'books' => [empty_book, @book_b] })
    # Should not raise an error
    refute_nil site.data['link_cache']['backlinks']
  end

  def test_handles_nil_content
    nil_book = create_doc(
      { 'title' => 'Nil Content', 'published' => true },
      '/books/nil.html',
      nil,
    )

    site = create_site({}, { 'books' => [nil_book, @book_b] })
    # Should not raise an error
    refute_nil site.data['link_cache']['backlinks']
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks
  end

  def test_handles_empty_books_collection
    site = create_site({}, { 'books' => [] })
    backlinks = site.data['link_cache']['backlinks']

    assert_empty backlinks
  end

  def test_book_link_priority_over_series_link
    # Book that links via both book_link and series_link to same target
    dual_link_book = create_doc(
      { 'title' => 'Dual Linker', 'published' => true },
      '/books/dual.html',
      "{% series_link 'Test Series' %} and {% book_link 'Series Book' %}.",
    )
    series_book = create_doc(
      { 'title' => 'Series Book', 'published' => true, 'series' => 'Test Series' },
      '/books/series-book.html',
      'Part of test series.',
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test-series.html',
    )

    site = create_site(
      {},
      { 'books' => [dual_link_book, series_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # Series book should have only one backlink (deduplicated)
    # and it should be type 'book' (higher priority)
    target_backlinks = backlinks['/books/series-book.html']
    refute_nil target_backlinks
    assert_equal 1, target_backlinks.length
    assert_equal 'book', target_backlinks.first[:type]
  end

  def test_series_link_creates_backlinks_to_all_series_books
    series_book_1 = create_doc(
      { 'title' => 'Foundation', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation.html',
      'First book.',
    )
    series_book_2 = create_doc(
      { 'title' => 'Foundation and Empire', 'published' => true, 'series' => 'Foundation Series' },
      '/books/foundation-empire.html',
      'Second book.',
    )
    referencing_book = create_doc(
      { 'title' => 'Review Collection', 'published' => true },
      '/books/reviews.html',
      "I love the {% series_link 'Foundation Series' %}!",
    )
    series_page = create_doc(
      { 'title' => 'Foundation Series', 'layout' => 'series_page' },
      '/series/foundation.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book_1, series_book_2, referencing_book] },
      [series_page],
    )
    backlinks = site.data['link_cache']['backlinks']

    # Both series books should have backlinks from the referencing book
    assert_equal 1, (backlinks['/books/foundation.html'] || []).length
    assert_equal 1, (backlinks['/books/foundation-empire.html'] || []).length
  end

  def test_short_story_link_without_from_book_resolves_when_unique_url
    story_book = create_doc(
      { 'title' => 'Only Collection', 'published' => true },
      '/books/only.html',
      'Contains short stories.',
    )
    referencing_book = create_doc(
      { 'title' => 'Reviewer', 'published' => true },
      '/books/reviewer.html',
      "I enjoyed {% short_story_link 'Unique Story' %}.",
    )

    # All locations share the same URL, so no from_book is needed
    site = create_site_with_short_stories(
      [story_book, referencing_book],
      { 'unique story' => [{ 'url' => '/books/only.html', 'parent_book_title' => 'Only Collection' }] },
    )
    backlinks = site.data['link_cache']['backlinks']

    target_backlinks = backlinks['/books/only.html'] || []
    assert_equal 1, target_backlinks.length
    assert_equal 'short_story', target_backlinks.first[:type]
  end

  def test_short_story_link_creates_backlinks
    story_book = create_doc(
      { 'title' => 'Story Collection', 'published' => true },
      '/books/collection.html',
      'Contains short stories.',
    )
    referencing_book = create_doc(
      { 'title' => 'Analysis', 'published' => true },
      '/books/analysis.html',
      "Analysis of {% short_story_link 'The Last Question' from_book='Story Collection' %}.",
    )

    # Set up link_cache with short story data
    site = create_site_with_short_stories(
      [story_book, referencing_book],
      { 'the last question' => [{ 'url' => '/books/collection.html', 'parent_book_title' => 'Story Collection' }] },
    )
    backlinks = site.data['link_cache']['backlinks']

    # Story collection should have backlink from analysis
    target_backlinks = backlinks['/books/collection.html'] || []
    assert_equal 1, target_backlinks.length
    assert_equal 'short_story', target_backlinks.first[:type]
  end

  def test_double_quoted_book_links
    double_quoted = create_doc(
      { 'title' => 'Double Quoted', 'published' => true },
      '/books/double.html',
      'Uses {% book_link "Book B" %} with double quotes.',
    )

    site = create_site({}, { 'books' => [double_quoted, @book_b] })
    backlinks = site.data['link_cache']['backlinks']

    assert_equal 1, (backlinks['/books/book-b.html'] || []).length
  end

  def test_multiple_links_to_same_target_deduplicated
    multi_linker = create_doc(
      { 'title' => 'Multi Linker', 'published' => true },
      '/books/multi.html',
      "{% book_link 'Book B' %} is great. Did I mention {% book_link 'Book B' %}?",
    )

    site = create_site({}, { 'books' => [multi_linker, @book_b] })
    backlinks = site.data['link_cache']['backlinks']

    # Should only have one backlink despite two references
    assert_equal 1, (backlinks['/books/book-b.html'] || []).length
  end

  private

  def create_site_with_short_stories(books, short_stories_cache)
    # Create a site and manually inject short stories into the link cache
    site = create_site({}, { 'books' => books })

    # Add short stories to the link cache
    site.data['link_cache']['short_stories'] = short_stories_cache

    # Re-run the backlink builder with the updated cache
    link_cache = site.data['link_cache']
    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
    builder = Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps)
    builder.build

    site
  end
end
