# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for forward links built by Jekyll::Infrastructure::LinkCache::BacklinkBuilder
#
# Forward links are the inverse of backlinks: source_url → [targets it links to].
# Both are built during the same scan pass.
class TestForwardLinkBuilder < Minitest::Test
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

  def test_builds_forward_links_from_book_links
    site = create_site({}, { 'books' => [@book_a, @book_b, @book_c] })
    forward_links = site.data['link_cache']['forward_links']

    # Book A links to Book B
    assert_equal 1, forward_links['/books/book-a.html'].length
    assert_equal '/books/book-b.html', forward_links['/books/book-a.html'].first[:target].url

    # Book C links to Book A and Book B
    assert_equal 2, forward_links['/books/book-c.html'].length
    target_urls = forward_links['/books/book-c.html'].map { |e| e[:target].url }
    assert_includes target_urls, '/books/book-a.html'
    assert_includes target_urls, '/books/book-b.html'

    # Book B has no outgoing links
    assert_empty forward_links['/books/book-b.html'] || []
  end

  def test_no_self_referential_forward_links
    self_ref_book = create_doc(
      { 'title' => 'Self Ref', 'published' => true },
      '/books/self-ref.html',
      "This book references itself: {% book_link 'Self Ref' %}.",
    )

    site = create_site({}, { 'books' => [self_ref_book] })
    forward_links = site.data['link_cache']['forward_links']

    assert_empty forward_links['/books/self-ref.html'] || []
  end

  def test_handles_empty_content
    empty_book = create_doc(
      { 'title' => 'Empty', 'published' => true },
      '/books/empty.html',
      '',
    )

    site = create_site({}, { 'books' => [empty_book, @book_b] })
    refute_nil site.data['link_cache']['forward_links']
  end

  def test_handles_nil_content
    nil_book = create_doc(
      { 'title' => 'Nil Content', 'published' => true },
      '/books/nil.html',
      nil,
    )

    site = create_site({}, { 'books' => [nil_book, @book_b] })
    refute_nil site.data['link_cache']['forward_links']
  end

  def test_handles_missing_books_collection
    site = create_site({}, {}, [])
    forward_links = site.data['link_cache']['forward_links']

    assert_empty forward_links
  end

  def test_handles_empty_books_collection
    site = create_site({}, { 'books' => [] })
    forward_links = site.data['link_cache']['forward_links']

    assert_empty forward_links
  end

  def test_forward_link_type_is_book_for_book_links
    site = create_site({}, { 'books' => [@book_a, @book_b] })
    forward_links = site.data['link_cache']['forward_links']

    assert_equal 'book', forward_links['/books/book-a.html'].first[:type]
  end

  def test_book_link_priority_over_series_link
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
    forward_links = site.data['link_cache']['forward_links']

    # Dual linker should have one forward link to series book with type 'book'
    source_links = forward_links['/books/dual.html']
    refute_nil source_links
    series_book_link = source_links.find { |e| e[:target].url == '/books/series-book.html' }
    refute_nil series_book_link
    assert_equal 'book', series_book_link[:type]
  end

  def test_series_link_creates_forward_links_to_all_series_books
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
    forward_links = site.data['link_cache']['forward_links']

    # Referencing book should have forward links to both series books
    source_links = forward_links['/books/reviews.html']
    refute_nil source_links
    target_urls = source_links.map { |e| e[:target].url }
    assert_includes target_urls, '/books/foundation.html'
    assert_includes target_urls, '/books/foundation-empire.html'
  end

  def test_short_story_link_creates_forward_links
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

    site = create_site_with_short_stories(
      [story_book, referencing_book],
      { 'the last question' => [{ 'url' => '/books/collection.html', 'parent_book_title' => 'Story Collection' }] },
    )
    forward_links = site.data['link_cache']['forward_links']

    source_links = forward_links['/books/analysis.html']
    refute_nil source_links
    assert_equal 1, source_links.length
    assert_equal '/books/collection.html', source_links.first[:target].url
    assert_equal 'short_story', source_links.first[:type]
  end

  def test_series_link_with_link_false_skips_forward_links
    series_book = create_doc(
      { 'title' => 'On Basilisk Station', 'published' => true, 'series' => 'Honor Harrington' },
      '/books/basilisk.html',
      'First book.',
    )
    referencing_book = create_doc(
      { 'title' => 'Some Review', 'published' => true },
      '/books/review.html',
      'I read {% series_text "Honor Harrington" link=false %} books.',
    )
    series_page = create_doc(
      { 'title' => 'Honor Harrington', 'layout' => 'series_page' },
      '/series/honor-harrington.html',
    )

    site = create_site(
      {},
      { 'books' => [series_book, referencing_book] },
      [series_page],
    )
    forward_links = site.data['link_cache']['forward_links']

    assert_empty forward_links['/books/review.html'] || []
  end

  def test_multiple_links_to_same_target_deduplicated
    multi_linker = create_doc(
      { 'title' => 'Multi Linker', 'published' => true },
      '/books/multi.html',
      "{% book_link 'Book B' %} is great. Did I mention {% book_link 'Book B' %}?",
    )

    site = create_site({}, { 'books' => [multi_linker, @book_b] })
    forward_links = site.data['link_cache']['forward_links']

    # Should only have one forward link despite two references
    assert_equal 1, (forward_links['/books/multi.html'] || []).length
  end

  def test_forward_and_back_links_are_symmetric
    site = create_site({}, { 'books' => [@book_a, @book_b, @book_c] })
    forward_links = site.data['link_cache']['forward_links']
    backlinks = site.data['link_cache']['backlinks']

    # Book A → Book B (forward) implies Book B ← Book A (backlink)
    forward_a = forward_links['/books/book-a.html'] || []
    assert_equal 1, forward_a.length
    assert_equal '/books/book-b.html', forward_a.first[:target].url

    back_b = backlinks['/books/book-b.html'] || []
    sources = back_b.map { |e| e[:source].url }
    assert_includes sources, '/books/book-a.html'
  end

  def test_priority_upgrade_from_separate_link_types
    # Source links to target via both series_link and book_link.
    # Verifies forward_link stores the higher-priority type.
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'series' => 'Test Series' },
      '/books/target.html',
      'The target.',
    )
    # Links via series first, then direct book_link (tests upgrade path)
    source_book = create_doc(
      { 'title' => 'Source Book', 'published' => true },
      '/books/source.html',
      "I mention {% series_link 'Test Series' %} and {% book_link 'Target Book' %}.",
    )
    series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test-series.html',
    )

    site = create_site(
      {},
      { 'books' => [target_book, source_book] },
      [series_page],
    )
    forward_links = site.data['link_cache']['forward_links']

    source_links = forward_links['/books/source.html']
    refute_nil source_links

    target_link = source_links.find { |e| e[:target].url == '/books/target.html' }
    refute_nil target_link
    assert_equal 'book', target_link[:type], 'book_link should upgrade priority over series_link'
  end

  private

  def rebuild_backlinks(site)
    link_cache = site.data['link_cache']
    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
    Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps).build
  end

  def create_site_with_short_stories(books, short_stories_cache)
    site = create_site({}, { 'books' => books })
    site.data['link_cache']['short_stories'] = short_stories_cache
    rebuild_backlinks(site)
    site
  end
end
