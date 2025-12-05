# frozen_string_literal: true

# _tests/plugins/test_link_cache_generator.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/link_cache_generator'

# Base test class with shared setup for Jekyll::Infrastructure::LinkCacheGenerator tests
class TestLinkCacheGeneratorBase < Minitest::Test
  def setup
    setup_mock_pages
    setup_mock_books
    create_default_site
  end

  private

  def setup_mock_pages
    @author_page = create_doc({ 'title' => 'Jane Doe', 'layout' => 'author_page', 'pen_names' => ['J.D.'] },
                              '/authors/jane-doe.html')
    @series_page = create_doc({ 'title' => 'The Foundation', 'layout' => 'series_page' }, '/series/foundation.html')
    @sidebar_page = create_doc({ 'title' => 'About Page', 'sidebar_include' => true }, '/about.html')
    @topbar_page = create_doc(
      { 'title' => 'By Series', 'book_topbar_include' => true, 'short_title' => 'Series' },
      '/books/by-series.html'
    )
    @paginated_page = create_doc({ 'title' => 'Blog Page 2', 'sidebar_include' => true }, '/blog/page2/')
  end

  def setup_mock_books
    @book1 = create_doc({ 'title' => 'Book One', 'published' => true, 'book_authors' => ['Author A'] },
                        '/books/book-one.html')
    @book2_unpublished = create_doc({ 'title' => 'Unpublished Book', 'published' => false },
                                    '/books/unpublished.html')
    @book3_no_title = create_doc({ 'title' => nil, 'published' => true }, '/books/no-title.html')
    @dup_book_a = create_doc({ 'title' => 'Duplicate Title', 'published' => true, 'book_authors' => ['Author A'] },
                             '/books/dup-a.html')
    @dup_book_b = create_doc({ 'title' => 'Duplicate Title', 'published' => true, 'book_authors' => ['Author B'] },
                             '/books/dup-b.html')
  end

  def create_default_site
    @site = create_site(
      {},
      { 'books' => [@book1, @book2_unpublished, @book3_no_title, @dup_book_a, @dup_book_b] },
      [@author_page, @series_page, @sidebar_page, @topbar_page, @paginated_page]
    )
  end
end

# Tests for basic link cache building operations
class TestLinkCacheGeneratorBasicOperations < TestLinkCacheGeneratorBase
  def test_generator_builds_cache_correctly
    cache = @site.data['link_cache']
    refute_nil cache

    assert_author_cache_correct(cache)
    assert_series_cache_correct(cache)
    assert_book_cache_correct(cache)
    assert_nav_caches_correct(cache)
    assert_empty cache['backlinks']
  end

  def test_generator_handles_duplicate_book_titles
    book_cache = @site.data['link_cache']['books']
    assert_equal 2, book_cache['duplicate title'].length
  end

  def test_generator_builds_canonical_and_family_maps
    canonical_book, archived_book, standalone_book = create_canonical_test_books

    site = create_site({}, { 'books' => [canonical_book, archived_book, standalone_book] })
    cache = site.data['link_cache']

    assert_canonical_map_correct(cache, canonical_book, archived_book, standalone_book)
    assert_book_families_correct(cache, canonical_book, archived_book, standalone_book)
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

  private

  def assert_author_cache_correct(cache)
    expected = { 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }
    assert_equal(expected, cache['authors']['jane doe'])
  end

  def assert_series_cache_correct(cache)
    expected = { 'url' => '/series/foundation.html', 'title' => 'The Foundation' }
    assert_equal(expected, cache['series']['the foundation'])
  end

  def assert_book_cache_correct(cache)
    expected = {
      'url' => '/books/book-one.html',
      'title' => 'Book One',
      'authors' => ['Author A'],
      'canonical_url' => nil
    }
    assert_equal(expected, cache['books']['book one'].first)
    assert_nil cache['books']['unpublished book']
  end

  def assert_nav_caches_correct(cache)
    assert_equal 1, cache['sidebar_nav'].size
    assert_equal 1, cache['books_topbar_nav'].size
  end

  def create_canonical_test_books
    canonical_book = create_doc({ 'title' => 'Canonical Book', 'published' => true }, '/books/canonical.html')
    archived_book = create_doc(
      { 'title' => 'Canonical Book', 'published' => true, 'canonical_url' => '/books/canonical.html' },
      '/books/canonical/2023.html'
    )
    standalone_book = create_doc({ 'title' => 'Standalone Book', 'published' => true }, '/books/standalone.html')
    [canonical_book, archived_book, standalone_book]
  end

  def assert_canonical_map_correct(cache, canonical_book, archived_book, standalone_book)
    map = cache['url_to_canonical_map']
    refute_nil map
    assert_equal '/books/canonical.html', map[canonical_book.url]
    assert_equal '/books/canonical.html', map[archived_book.url]
    assert_equal '/books/standalone.html', map[standalone_book.url]
  end

  def assert_book_families_correct(cache, canonical_book, archived_book, standalone_book)
    families = cache['book_families']
    refute_nil families
    assert_equal 2, families[canonical_book.url].length
    assert_includes families[canonical_book.url], canonical_book.url
    assert_includes families[canonical_book.url], archived_book.url
    assert_equal [standalone_book.url], families[standalone_book.url]
  end
end

# Tests for raw link validation
class TestLinkCacheGeneratorValidation < TestLinkCacheGeneratorBase
  def test_validator_raises_fatal_for_raw_book_links
    target_book, source_book_md, source_post_html = create_raw_book_link_docs

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [target_book, source_book_md] }, [], [source_post_html])
    end

    assert_raw_book_link_error(err)
  end

  def test_validator_raises_fatal_for_raw_author_links
    author_page_for_test, source_post = create_raw_author_link_docs

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, {}, [author_page_for_test], [source_post])
    end

    assert_raw_author_link_error(err)
  end

  def test_validator_raises_fatal_for_raw_series_links
    series_page_for_test, source_book = create_raw_series_link_docs

    err = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [source_book] }, [series_page_for_test])
    end

    assert_raw_series_link_error(err)
  end

  private

  def create_raw_book_link_docs
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true, 'book_authors' => ['Author C'], 'path' => '_books/target.md' },
      '/books/target-book.html'
    )
    source_book_md = create_doc(
      { 'title' => 'Source Markdown', 'published' => true, 'path' => '_books/source-md.md' },
      '/books/source-md.html',
      'Link via markdown: [MD Link](/books/target-book.html)'
    )
    source_post_html = create_doc(
      { 'title' => 'Source HTML Post', 'published' => true, 'path' => '_posts/source-html.md' },
      '/posts/source-html.html',
      'Link via HTML: <a href="/books/target-book.html">HTML Link</a>'
    )
    [target_book, source_book_md, source_post_html]
  end

  def create_raw_author_link_docs
    author_page_for_test = create_doc(
      { 'title' => 'Test Author', 'layout' => 'author_page', 'path' => 'authors/test.md' },
      '/authors/test.html'
    )
    source_post = create_doc(
      { 'title' => 'Source Post', 'published' => true, 'path' => '_posts/linking-post.md' },
      '/posts/linking-post.html',
      'Link to an author: [Test Author](/authors/test.html)'
    )
    [author_page_for_test, source_post]
  end

  def create_raw_series_link_docs
    series_page_for_test = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page', 'path' => 'series/test.md' },
      '/series/test.html'
    )
    source_book = create_doc(
      { 'title' => 'Source Book', 'published' => true, 'path' => '_books/linking-book.md' },
      '/books/linking-book.html',
      'Link to a series: <a href="/series/test.html">Test Series</a>'
    )
    [series_page_for_test, source_book]
  end

  def assert_raw_book_link_error(err)
    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_books/source-md.md'", err.message
    assert_match 'Found: Markdown: /books/target-book.html', err.message
    assert_match "In file '_posts/source-html.md'", err.message
    assert_match 'Found: HTML: /books/target-book.html', err.message
  end

  def assert_raw_author_link_error(err)
    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_posts/linking-post.md'", err.message
    assert_match 'Found: Markdown: /authors/test.html', err.message
  end

  def assert_raw_series_link_error(err)
    assert_match 'Found raw Markdown/HTML links', err.message
    assert_match "In file '_books/linking-book.md'", err.message
    assert_match 'Found: HTML: /series/test.html', err.message
  end
end

# Tests for backlink generation
class TestLinkCacheGeneratorBacklinks < TestLinkCacheGeneratorBase
  def test_generator_builds_backlinks_from_short_story_links
    anthologies, source_books = create_short_story_test_docs
    site = create_site({}, { 'books' => anthologies + source_books })
    backlinks = site.data['link_cache']['backlinks']

    assert_short_story_backlinks_correct(backlinks, anthologies, source_books)
  end

  def test_generator_ignores_ambiguous_short_story_link_without_disambiguation
    anthologies, source_ambiguous = create_ambiguous_short_story_test_docs
    site = create_site({}, { 'books' => anthologies + [source_ambiguous] })
    backlinks = site.data['link_cache']['backlinks']

    assert_no_ambiguous_backlinks(backlinks, anthologies)
  end

  def test_generator_builds_backlinks_from_series_links
    series_books, source_docs = create_series_backlink_test_docs
    site = create_site({}, { 'books' => series_books + source_docs })
    backlinks = site.data['link_cache']['backlinks']

    assert_series_backlinks_correct(backlinks, series_books, source_docs)
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

    assert_backlink_priority_correct(backlinks, target_book)
  end

  def test_generator_ignores_backlinks_from_non_book_sources
    target_book, source_book, source_post, source_page = create_non_book_source_docs

    site = create_site({}, { 'books' => [target_book, source_book] }, [source_page], [source_post])
    backlinks = site.data['link_cache']['backlinks']

    assert_only_book_backlinks(backlinks, target_book, source_book)
  end

  private

  def create_short_story_test_docs
    anthology1 = create_doc({ 'title' => 'Anthology One', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-one.html', '### {% short_story_title "Unique Story" %}')
    anthology2 = create_doc({ 'title' => 'Anthology Two', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-two.html', '### {% short_story_title "Duplicate Story" %}')
    anthology3 = create_doc({ 'title' => 'Anthology Three', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-three.html', '### {% short_story_title "Duplicate Story" %}')
    source_book1 = create_doc({ 'title' => 'Source 1', 'published' => true }, '/books/source1.html',
                              'I read {% short_story_link "Unique Story" %}.')
    source_book2 = create_doc(
      { 'title' => 'Source 2', 'published' => true },
      '/books/source2.html',
      'I also read {% short_story_link "Duplicate Story" from_book="Anthology Three" %}.'
    )
    [[anthology1, anthology2, anthology3], [source_book1, source_book2]]
  end

  def create_ambiguous_short_story_test_docs
    anthology2 = create_doc({ 'title' => 'Anthology Two', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-two.html', '### {% short_story_title "Duplicate Story" %}')
    anthology3 = create_doc({ 'title' => 'Anthology Three', 'is_anthology' => true, 'published' => true },
                            '/books/anthology-three.html', '### {% short_story_title "Duplicate Story" %}')
    source_ambiguous = create_doc(
      { 'title' => 'Source Ambiguous', 'published' => true },
      '/books/source-ambiguous.html',
      'I read {% short_story_link "Duplicate Story" %}.'
    )
    [[anthology2, anthology3], source_ambiguous]
  end

  def create_series_backlink_test_docs
    series_book1 = create_doc({ 'title' => 'Series Book 1', 'series' => 'Test Series', 'published' => true },
                              '/books/series1.html')
    series_book2 = create_doc({ 'title' => 'Series Book 2', 'series' => 'Test Series', 'published' => true },
                              '/books/series2.html')
    source_series_link = create_doc(
      { 'title' => 'Source Series Link', 'published' => true },
      '/books/source-series.html',
      'A general mention of the series: {% series_link "Test Series" %}'
    )
    source_book_link = create_doc(
      { 'title' => 'Source Book Link', 'published' => true },
      '/books/source-book.html',
      'A specific mention of one book: {% book_link "Series Book 1" %}'
    )
    [[series_book1, series_book2], [source_series_link, source_book_link]]
  end

  def create_non_book_source_docs
    target_book = create_doc({ 'title' => 'Target Book', 'published' => true }, '/books/target.html')
    source_book = create_doc({ 'title' => 'Source Book', 'published' => true }, '/books/source-book.html',
                             '{% book_link "Target Book" %}')
    source_post = create_doc({ 'title' => 'Source Post', 'published' => true }, '/posts/source-post.html',
                             '{% book_link "Target Book" %}')
    source_page = create_doc({ 'title' => 'Source Page', 'published' => true }, '/source-page.html',
                             '{% book_link "Target Book" %}')
    [target_book, source_book, source_post, source_page]
  end

  def assert_short_story_backlinks_correct(backlinks, anthologies, source_books)
    anthology1, anthology2, anthology3 = anthologies
    source_book1, source_book2 = source_books

    assert_equal([source_book1.url], backlinks[anthology1.url].map { |e| e[:source].url })
    assert_equal([source_book2.url], backlinks[anthology3.url].map { |e| e[:source].url })
    assert (backlinks[anthology2.url].nil? || backlinks[anthology2.url].empty?), 'Anthology 2 should have no backlinks'
  end

  def assert_no_ambiguous_backlinks(backlinks, anthologies)
    anthology2, anthology3 = anthologies
    assert (backlinks[anthology2.url].nil? || backlinks[anthology2.url].empty?),
           'Ambiguous link should not create a backlink for Anthology 2'
    assert (backlinks[anthology3.url].nil? || backlinks[anthology3.url].empty?),
           'Ambiguous link should not create a backlink for Anthology 3'
  end

  def assert_series_backlinks_correct(backlinks, series_books, source_docs)
    series_book1, series_book2 = series_books
    source_series_link, source_book_link = source_docs

    book1_backlinks = backlinks[series_book1.url]
    assert_equal 2, book1_backlinks.length
    assert_equal 'series', book1_backlinks.find { |e| e[:source].url == source_series_link.url }[:type]
    assert_equal 'book', book1_backlinks.find { |e| e[:source].url == source_book_link.url }[:type]

    book2_backlinks = backlinks[series_book2.url]
    assert_equal 1, book2_backlinks.length
    assert_equal 'series', book2_backlinks.first[:type]
  end

  def assert_backlink_priority_correct(backlinks, target_book)
    target_backlinks = backlinks[target_book.url]
    refute_nil target_backlinks, 'Backlinks for target book should exist'
    assert_equal 1, target_backlinks.length, 'Should only be one backlink entry from the source doc'
    assert_equal 'book', target_backlinks.first[:type]
  end

  def assert_only_book_backlinks(backlinks, target_book, source_book)
    target_backlinks = backlinks[target_book.url]
    refute_nil target_backlinks, 'Backlinks for target book should exist'
    assert_equal 1, target_backlinks.length, 'Should only be one backlink from the source book'
    assert_equal source_book.url, target_backlinks.first[:source].url
  end
end
