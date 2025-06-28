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
  end

  def test_generator_handles_missing_books_collection
    site_no_books = create_site({}, {}, [@author_page]) # No 'books' collection
    # Generator is run by create_site, just assert the result
    refute_nil site_no_books.data['link_cache']
    assert_empty site_no_books.data['link_cache']['books']
    # Authors should still be cached
    refute_empty site_no_books.data['link_cache']['authors']
    assert_equal({ 'url' => '/authors/jane-doe.html', 'title' => 'Jane Doe' }, site_no_books.data['link_cache']['authors']['jane doe'])
  end
end
