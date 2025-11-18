# frozen_string_literal: true
# _tests/plugins/test_link_cache_generator.rb
require_relative '../test_helper'
require_relative '../../_plugins/link_cache_generator'

class TestLinkCacheGenerator < Minitest::Test
  def setup
    # --- Mock Pages ---
    @author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page', 'pen_names' => ['J.D.'] },
                              '/authors/jane-doe.html')
    @series_page = create_doc({ 'title' => 'The Foundation', 'layout' => 'series_page' }, '/series/foundation.html')
    @sidebar_page = create_doc({ 'title' => 'About Page', 'sidebar_include' => true }, '/about.html')
    @topbar_page = create_doc({ 'title' => 'By Series', 'book_topbar_include' => true, 'short_title' => 'Series' },
                              '/books/by-series.html')
    @paginated_page = create_doc({ 'title' => 'Blog Page 2', 'sidebar_include' => true }, '/blog/page2/')

    # --- Mock Books ---
    @book1 = create_doc({ 'title' => 'Book One', 'published' => true, 'book_authors' => ['Author A'] },
                        '/books/book-one.html')
    @book2_unpublished = create_doc({ 'title' => 'Unpublished Book', 'published' => false }, '/books/unpublished.html')
    @book3_no_title = create_doc({ 'title' => nil, 'published' => true }, '/books/no-title.html')
    @dup_book_a = create_doc({ 'title' => 'Duplicate Title', 'published' => true, 'book_authors' => ['Author A'] },
                             '/books/dup-a.html')
    @dup_book_b = create_doc({ 'title' => 'Duplicate Title', 'published' => true, 'book_authors' => ['Author B'] },
                             '/books/dup-b.html')

    # This site is used for tests that DON'T expect a fatal error during generation.
    @site = create_site({}, { 'books' => [@book1, @book2_unpublished, @book3_no_title, @dup_book_a, @dup_book_b] },
                        [@author_page, @series_page, @sidebar_page, @topbar_page, @paginated_page])
  end

  def test_generator_builds_cache_correctly
    cache = @site.data['link_cache']
    refute_nil cache
    assert_equal({ 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }, cache['authors']['jane doe'])
    assert_equal({ 'url' => '/series/foundation.html', 'title' => 'The Foundation' }, cache['series']['the foundation'])
    assert_equal(
      { 'url' => '/books/book-one.html', 'title' => 'Book One', 'authors' => ['Author A'],
        'canonical_url' => nil }, cache['books']['book one'].first
    )
    assert_nil cache['books']['unpublished book']
    assert_equal 1, cache['sidebar_nav'].size
    assert_equal 1, cache['books_topbar_nav'].size
    assert_empty cache['backlinks']
  end

  def test_generator_handles_duplicate_book_titles
    book_cache = @site.data['link_cache']['books']
    assert_equal 2, book_cache['duplicate title'].length
  end

  def test_generator_builds_canonical_and_family_maps
    canonical_book = create_doc({ 'title' => 'Canonical Book', 'published' => true }, '/books/canonical.html')
    archived_book = create_doc(
      { 'title' => 'Canonical Book', 'published' => true,
        'canonical_url' => '/books/canonical.html' }, '/books/canonical/2023.html'
    )
    standalone_book = create_doc({ 'title' => 'Standalone Book', 'published' => true }, '/books/standalone.html')

    site = create_site({}, { 'books' => [canonical_book, archived_book, standalone_book] })
    cache = site.data['link_cache']

    # Test url_to_canonical_map
    map = cache['url_to_canonical_map']
    refute_nil map
    assert_equal '/books/canonical.html', map['/books/canonical.html']
    assert_equal '/books/canonical.html', map['/books/canonical/2023.html']
    assert_equal '/books/standalone.html', map['/books/standalone.html']

    # Test book_families
    families = cache['book_families']
    refute_nil families
    assert_equal 2, families['/books/canonical.html'].length
    assert_includes families['/books/canonical.html'], '/books/canonical.html'
    assert_includes families['/books/canonical.html'], '/books/canonical/2023.html'
    assert_equal ['/books/standalone.html'], families['/books/standalone.html']
  end

  # REWRITTEN TEST: This now tests that the validator catches raw links and fails the build.
  def test_validator_raises_fatal_for_raw_book_links
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'book_authors' => ['Author C'],
        'path' => '_books/target.md' }, '/books/target-book.html'
    )
    source_book_md = create_doc({ 'title' => 'Source Markdown', 'published' => true, 'path' => '_books/source-md.md' },
                                '/books/source-md.html', 'Link via markdown: [MD Link](/books/target-book.html)')
    source_post_html = create_doc(
      { 'title' => 'Source HTML Post', 'published' => true,
        'path' => '_posts/source-html.md' }, '/posts/source-html.html', 'Link via HTML: <a href="/books/target-book.html">HTML Link</a>'
    )

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [target_book, source_book_md] }, [], [source_post_html])
    end

    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_books/source-md.md'", err.message
    assert_match 'Found: Markdown: /books/target-book.html', err.message
    assert_match "In file '_posts/source-html.md'", err.message
    assert_match 'Found: HTML: /books/target-book.html', err.message
  end

  # NEW TEST: Validator catches raw links to author pages.
  def test_validator_raises_fatal_for_raw_author_links
    author_page_for_test = create_doc(
      { 'title' => 'Test Author', 'layout' => 'author_page', 'path' => 'authors/test.md' }, '/authors/test.html'
    )
    source_post = create_doc({ 'title' => 'Source Post', 'published' => true, 'path' => '_posts/linking-post.md' },
                             '/posts/linking-post.html', 'Link to an author: [Test Author](/authors/test.html)')

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, {}, [author_page_for_test], [source_post])
    end

    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_posts/linking-post.md'", err.message
    assert_match 'Found: Markdown: /authors/test.html', err.message
  end

  # NEW TEST: Validator catches raw links to series pages.
  def test_validator_raises_fatal_for_raw_series_links
    series_page_for_test = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page', 'path' => 'series/test.md' }, '/series/test.html'
    )
    source_book = create_doc({ 'title' => 'Source Book', 'published' => true, 'path' => '_books/linking-book.md' },
                             '/books/linking-book.html', 'Link to a series: <a href="/series/test.html">Test Series</a>')

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [source_book] }, [series_page_for_test])
    end

    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_books/linking-book.md'", err.message
    assert_match 'Found: HTML: /series/test.html', err.message
  end

  def test_generator_handles_empty_collections_and_pages
    empty_site = create_site({}, { 'books' => [] }, [])
    refute_nil empty_site.data['link_cache']
    assert_empty empty_site.data['link_cache']['books']
  end

  def test_generator_handles_missing_books_collection
    site_no_books = create_site({}, {}, [@author_page])
    refute_nil site_no_books.data['link_cache']
    assert_empty site_no_books.data['link_cache']['books']
    refute_empty site_no_books.data['link_cache']['authors']
  end

  def test_generator_builds_backlinks_from_short_story_links
    anthology1 = create_doc({ 'title' => 'Anthology One', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-one.html', '### {% short_story_title "Unique Story" %}')
    anthology2 = create_doc({ 'title' => 'Anthology Two', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-two.html', '### {% short_story_title "Duplicate Story" %}')
    anthology3 = create_doc({ 'title' => 'Anthology Three', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-three.html', '### {% short_story_title "Duplicate Story" %}')
    source_book1 = create_doc({ 'title' => 'Source 1', 'published' => true }, '/books/source1.html',
                              'I read {% short_story_link "Unique Story" %}.')
    source_book2 = create_doc({ 'title' => 'Source 2', 'published' => true }, '/books/source2.html',
                              'I also read {% short_story_link "Duplicate Story" from_book="Anthology Three" %}.')
    site = create_site({}, { 'books' => [anthology1, anthology2, anthology3, source_book1, source_book2] })
    backlinks = site.data['link_cache']['backlinks']
    assert_equal([source_book1.url], backlinks[anthology1.url].map { |e| e[:source].url })
    assert_equal([source_book2.url], backlinks[anthology3.url].map { |e| e[:source].url })
    assert (backlinks[anthology2.url].nil? || backlinks[anthology2.url].empty?), 'Anthology 2 should have no backlinks'
  end

  def test_generator_ignores_ambiguous_short_story_link_without_disambiguation
    anthology2 = create_doc({ 'title' => 'Anthology Two', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-two.html', '### {% short_story_title "Duplicate Story" %}')
    anthology3 = create_doc({ 'title' => 'Anthology Three', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-three.html', '### {% short_story_title "Duplicate Story" %}')

    # This source document creates the failure condition: an ambiguous link with no `from_book`
    source_ambiguous = create_doc(
      { 'title' => 'Source Ambiguous', 'published' => true },
      '/books/source-ambiguous.html',
      'I read {% short_story_link "Duplicate Story" %}.'
    )

    # The generator runs when the site is created.
    site = create_site({}, { 'books' => [anthology2, anthology3, source_ambiguous] })
    backlinks = site.data['link_cache']['backlinks']

    # Assert that NO backlink was created for either potential target.
    assert (backlinks[anthology2.url].nil? || backlinks[anthology2.url].empty?),
           'Ambiguous link should not create a backlink for Anthology 2'
    assert (backlinks[anthology3.url].nil? || backlinks[anthology3.url].empty?),
           'Ambiguous link should not create a backlink for Anthology 3'
  end

  def test_generator_builds_backlinks_from_series_links
    series_book1 = create_doc({ 'title' => 'Series Book 1', 'series' => 'Test Series', 'published' => true },
                              '/books/series1.html')
    series_book2 = create_doc({ 'title' => 'Series Book 2', 'series' => 'Test Series', 'published' => true },
                              '/books/series2.html')
    source_series_link = create_doc({ 'title' => 'Source Series Link', 'published' => true },
                                    '/books/source-series.html', 'A general mention of the series: {% series_link "Test Series" %}')
    source_book_link = create_doc({ 'title' => 'Source Book Link', 'published' => true }, '/books/source-book.html',
                                  'A specific mention of one book: {% book_link "Series Book 1" %}')
    site = create_site({}, { 'books' => [series_book1, series_book2, source_series_link, source_book_link] })
    backlinks = site.data['link_cache']['backlinks']
    book1_backlinks = backlinks[series_book1.url]
    assert_equal 2, book1_backlinks.length
    assert_equal 'series', book1_backlinks.find { |e| e[:source].url == source_series_link.url }[:type]
    assert_equal 'book', book1_backlinks.find { |e| e[:source].url == source_book_link.url }[:type]
    book2_backlinks = backlinks[series_book2.url]
    assert_equal 1, book2_backlinks.length
    assert_equal 'series', book2_backlinks.first[:type]
  end

  def test_backlink_priority_is_enforced
    target_book = create_doc({ 'title' => 'Target Book', 'series' => 'Target Series', 'published' => true },
                             '/books/target.html')

    source_doc = create_doc(
      { 'title' => 'Source Doc', 'published' => true },
      '/books/source.html',
      'I love the {% series_link "Target Series" %}, especially {% book_link "Target Book" %}.'
    )

    site = create_site({}, { 'books' => [target_book, source_doc] })
    backlinks = site.data['link_cache']['backlinks']

    target_backlinks = backlinks[target_book.url]
    refute_nil target_backlinks, 'Backlinks for target book should exist'
    assert_equal 1, target_backlinks.length, 'Should only be one backlink entry from the source doc'

    assert_equal 'book', target_backlinks.first[:type]
  end

  def test_generator_ignores_backlinks_from_non_book_sources
    target_book = create_doc({ 'title' => 'Target Book', 'published' => true }, '/books/target.html')
    source_book = create_doc({ 'title' => 'Source Book', 'published' => true }, '/books/source-book.html',
                             '{% book_link "Target Book" %}')
    source_post = create_doc({ 'title' => 'Source Post', 'published' => true }, '/posts/source-post.html',
                             '{% book_link "Target Book" %}')
    source_page = create_doc({ 'title' => 'Source Page', 'published' => true }, '/source-page.html',
                             '{% book_link "Target Book" %}')

    site = create_site(
      {},
      { 'books' => [target_book, source_book] },
      [source_page],
      [source_post]
    )

    backlinks = site.data['link_cache']['backlinks']
    target_backlinks = backlinks[target_book.url]

    refute_nil target_backlinks, 'Backlinks for target book should exist'
    assert_equal 1, target_backlinks.length, 'Should only be one backlink from the source book'
    assert_equal source_book.url, target_backlinks.first[:source].url
  end
end
