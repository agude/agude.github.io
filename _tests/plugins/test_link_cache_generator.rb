# _tests/plugins/test_link_cache_generator.rb
require_relative '../test_helper'
require_relative '../../_plugins/link_cache_generator'

class TestLinkCacheGenerator < Minitest::Test
  def setup
    # --- Mock Pages ---
    @author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page', 'pen_names' => ['J.D.'] },
      '/authors/jane-doe.html'
    )
    @series_page = create_doc(
      { 'title' => 'The Foundation', 'layout' => 'series_page' },
      '/series/foundation.html'
    )
    # Nav-specific pages
    @sidebar_page = create_doc(
      { 'title' => 'About Page', 'sidebar_include' => true },
      '/about.html'
    )
    @topbar_page = create_doc(
      { 'title' => 'By Series', 'book_topbar_include' => true, 'short_title' => 'Series' },
      '/books/by-series.html'
    )
    @paginated_page = create_doc( # Should be excluded from sidebar nav
                                 { 'title' => 'Blog Page 2', 'sidebar_include' => true },
                                 '/blog/page2/'
                                )


    # --- Mock Books ---
    @book1 = create_doc(
      { 'title' => 'Book One', 'published' => true },
      '/books/book-one.html'
    )
    @book2_unpublished = create_doc(
      { 'title' => 'Unpublished Book', 'published' => false },
      '/books/unpublished.html'
    )
    @book3_no_title = create_doc(
      { 'title' => nil, 'published' => true },
      '/books/no-title.html'
    )

    # create_site helper now runs the generator automatically, so we don't need to
    # instantiate it here. The site object will be ready for assertions.
    @site = create_site(
      {}, # config
      { 'books' => [@book1, @book2_unpublished, @book3_no_title] }, # collections
      [@author_page, @series_page, @sidebar_page, @topbar_page, @paginated_page] # pages
    )
  end

  def test_generator_builds_cache_correctly
    # The generator is run inside create_site in the setup method.
    # We just need to assert the results on the @site object.

    # --- Assert Cache Exists ---
    refute_nil @site.data['link_cache'], "link_cache should be added to site.data"
    cache = @site.data['link_cache']

    # --- Assert Author Cache ---
    author_cache = cache['authors']
    refute_nil author_cache
    assert_equal({ 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }, author_cache['jane doe'])
    assert_equal({ 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }, author_cache['j.d.'])

    # --- Assert Series Cache ---
    series_cache = cache['series']
    refute_nil series_cache
    assert_equal({ 'url' => '/series/foundation.html', 'title' => 'The Foundation' }, series_cache['the foundation'])

    # --- Assert Book Cache ---
    book_cache = cache['books']
    refute_nil book_cache
    assert_equal({ 'url' => '/books/book-one.html', 'title' => 'Book One' }, book_cache['book one'])
    assert_nil book_cache['unpublished book']

    # --- Assert Sidebar Nav Cache ---
    sidebar_nav = cache['sidebar_nav']
    refute_nil sidebar_nav
    assert_equal 1, sidebar_nav.size, "Sidebar nav should have 1 item"
    assert_equal 'About Page', sidebar_nav[0].data['title']
    # Ensure paginated page was excluded
    sidebar_nav.each { |p| refute_match(/page/, p.url) }

    # --- Assert Books Topbar Nav Cache ---
    books_topbar_nav = cache['books_topbar_nav']
    refute_nil books_topbar_nav
    assert_equal 1, books_topbar_nav.size, "Books topbar nav should have 1 item"
    assert_equal 'By Series', books_topbar_nav[0].data['title']

    # --- Assert Backlinks Cache ---
    refute_nil cache['backlinks']
    assert_empty cache['backlinks'], "Backlinks should be empty for this simple setup"
  end

  def test_generator_builds_backlinks_cache
    # Setup is specific to this test to keep it isolated
    target_book = create_doc(
      { 'title' => 'Target Book', 'published' => true },
      '/books/target-book.html',
      'I link to myself: <a href="/books/target-book.html">Self</a>'
    )
    source_book_liquid = create_doc(
      { 'title' => 'Source Liquid', 'published' => true },
      '/books/source-liquid.html',
      'Link via liquid: {% book_link "Target Book" %}'
    )
    source_book_md = create_doc(
      { 'title' => 'Source Markdown', 'published' => true },
      '/books/source-md.html',
      'Link via markdown: [MD Link](/books/target-book.html)'
    )
    source_book_html = create_doc(
      { 'title' => 'Source HTML', 'published' => true },
      '/books/source-html.html',
      'Link via HTML: <a href="/books/target-book.html">HTML Link</a>'
    )
    source_book_html_fragment = create_doc(
      { 'title' => 'Source HTML Fragment', 'published' => true },
      '/books/source-html-fragment.html',
      'Link via HTML with fragment: <a href="/books/target-book.html#section">HTML Link</a>'
    )
    source_book_multi_link = create_doc(
      { 'title' => 'Source Multi', 'published' => true },
      '/books/source-multi.html',
      'Two links: {% book_link "Target Book" %} and <a href="/books/target-book.html">HTML Link</a>'
    )
    source_book_no_link = create_doc(
      { 'title' => 'Source No Link', 'published' => true },
      '/books/source-no-link.html',
      'No links here.'
    )

    site = create_site(
      {},
      { 'books' => [
        target_book, source_book_liquid, source_book_md, source_book_html,
        source_book_html_fragment, source_book_multi_link, source_book_no_link
      ]
      },
      [] # No extra pages needed for this test
    )

    cache = site.data['link_cache']
    refute_nil cache['backlinks'], "Backlinks cache should exist"
    backlinks = cache['backlinks']

    # Assertions for the target book
    target_backlinks = backlinks[target_book.url]
    refute_nil target_backlinks, "Backlinks for target book should exist"
    assert_kind_of Array, target_backlinks

    # Check the URLs of the documents that link back
    backlinker_urls = target_backlinks.map(&:url).sort
    expected_urls = [
      source_book_liquid.url,
      source_book_md.url,
      source_book_html.url,
      source_book_html_fragment.url,
      source_book_multi_link.url
    ].sort

    assert_equal expected_urls, backlinker_urls, "Should find all books linking to the target"

    # Check that the multi-link source only appears once
    multi_link_count = target_backlinks.count { |doc| doc.url == source_book_multi_link.url }
    assert_equal 1, multi_link_count, "Source with multiple links should only be listed once"

    # Check that other books don't have backlinks (unless they are linked to)
    assert_empty backlinks[source_book_liquid.url], "Source book should have no backlinks in this test"
    assert_empty backlinks[source_book_no_link.url], "Book with no links should have no backlinks"
  end

  def test_generator_handles_empty_collections_and_pages
    empty_site = create_site({}, { 'books' => [] }, [])
    # Generator is run by create_site, just assert the result
    refute_nil empty_site.data['link_cache']
    assert_empty empty_site.data['link_cache']['authors']
    assert_empty empty_site.data['link_cache']['series']
    assert_empty empty_site.data['link_cache']['books']
    assert_empty empty_site.data['link_cache']['sidebar_nav']
    assert_empty empty_site.data['link_cache']['books_topbar_nav']
    assert_empty empty_site.data['link_cache']['backlinks']
  end

  def test_generator_handles_missing_books_collection
    site_no_books = create_site({}, {}, [@author_page]) # No 'books' collection
    # Generator is run by create_site, just assert the result
    refute_nil site_no_books.data['link_cache']
    assert_empty site_no_books.data['link_cache']['books']
    assert_empty site_no_books.data['link_cache']['backlinks']
    # Authors should still be cached
    refute_empty site_no_books.data['link_cache']['authors']
    assert_equal({ 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }, site_no_books.data['link_cache']['authors']['jane doe'])
  end

  # Test for short story link backlink generation
  def test_generator_builds_backlinks_from_short_story_links
    anthology1 = create_doc(
      { 'title' => 'Anthology One', 'is_anthology' => true, 'published' => true },
      '/books/anthology-one.html',
      '### {% short_story_title "Unique Story" %}'
    )
    anthology2 = create_doc(
      { 'title' => 'Anthology Two', 'is_anthology' => true, 'published' => true },
      '/books/anthology-two.html',
      '### {% short_story_title "Duplicate Story" %}'
    )
    anthology3 = create_doc(
      { 'title' => 'Anthology Three', 'is_anthology' => true, 'published' => true },
      '/books/anthology-three.html',
      '### {% short_story_title "Duplicate Story" %}'
    )
    source_book1 = create_doc(
      { 'title' => 'Source 1', 'published' => true },
      '/books/source1.html',
      'I read {% short_story_link "Unique Story" %}.'
    )
    source_book2 = create_doc(
      { 'title' => 'Source 2', 'published' => true },
      '/books/source2.html',
      'I also read {% short_story_link "Duplicate Story" from_book="Anthology Three" %}.'
    )

    site = create_site({}, { 'books' => [anthology1, anthology2, anthology3, source_book1, source_book2] })
    backlinks = site.data['link_cache']['backlinks']

    # Test backlink for the unique story
    anthology1_backlinks = backlinks[anthology1.url]
    refute_nil anthology1_backlinks
    assert_equal [source_book1.url], anthology1_backlinks.map(&:url)

    # Test backlink for the disambiguated duplicate story
    anthology3_backlinks = backlinks[anthology3.url]
    refute_nil anthology3_backlinks
    assert_equal [source_book2.url], anthology3_backlinks.map(&:url)

    # Test that the other anthology with the duplicate story has no backlinks
    assert_empty backlinks[anthology2.url]
  end
end
