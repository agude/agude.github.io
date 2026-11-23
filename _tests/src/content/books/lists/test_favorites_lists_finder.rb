# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/favorites_lists_finder'

# Tests for Jekyll::Books::Lists::FavoritesListsFinder
#
# Verifies that the finder correctly fetches and organizes books by favorites lists,
# sorting lists by year and books within each list alphabetically by normalized title.
class TestBookListFavoritesListsFinder < Minitest::Test
  def setup
    setup_test_documents
    setup_site_and_context
  end

  private

  def stub_silent_logger(&)
    Jekyll.stub(:logger, silent_logger, &)
  end

  def setup_test_documents
    # --- Mock Books ---
    @book_a = create_doc({ 'title' => 'Apple Book' }, '/books/a.html')
    @book_b = create_doc({ 'title' => 'Banana Book' }, '/books/b.html')
    @book_z = create_doc({ 'title' => 'A Zebra Book' }, '/books/z.html')

    # --- Mock Posts ---
    @fav_post_2024 = create_doc(
      { 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 },
      '/posts/fav24.html',
    )
    @fav_post_2023 = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html',
    )
    @regular_post = create_doc({ 'title' => 'Regular Post' }, '/posts/regular.html')
  end

  def setup_site_and_context
    # --- Site & Context ---
    @site = create_site(
      {},
      { 'books' => [@book_a, @book_b, @book_z] },
      [],
      [@fav_post_2023, @fav_post_2024, @regular_post],
    )
    # Manually set up the cache that the finder will read from
    @site.data['link_cache']['favorites_posts_to_books'] = {
      @fav_post_2024.url => [@book_z, @book_a], # Intentionally unsorted books
      @fav_post_2023.url => [@book_b],
    }
    current_page = create_doc({ 'path' => 'current.html' }, '/current.html')
    @context = create_context({}, { site: @site, page: current_page })
  end

  public

  # --- Happy Path Test ---

  def test_find_returns_correctly_structured_and_sorted_data
    assert_equal(
      {
        favorites_lists: [
          { post: @fav_post_2024, books: [@book_a, @book_z] },
          { post: @fav_post_2023, books: [@book_b] },
        ],
        log_messages: '',
      },
      Jekyll::Books::Lists::FavoritesListsFinder.new(site: @site, context: @context).find,
    )
  end

  # --- Error Path Tests ---

  def test_find_logs_error_if_posts_collection_is_nil
    # Create a site where site.posts is nil
    site = create_site({}, { 'books' => [] }, [], [])
    site.posts = nil # Manually set posts to nil
    site.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    result = nil
    stub_silent_logger do
      finder = Jekyll::Books::Lists::FavoritesListsFinder.new(site: site, context: context)
      result = finder.find
    end

    assert_empty result[:favorites_lists]
    assert_match(/Prerequisites missing/, result[:log_messages])
  end

  def test_find_logs_error_if_favorites_cache_is_missing
    # Create a site with posts, but no favorites cache
    site = create_site({}, {}, [], [create_doc({}, '/post.html')])
    site.data['link_cache'].delete('favorites_posts_to_books')
    site.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    result = nil
    stub_silent_logger do
      finder = Jekyll::Books::Lists::FavoritesListsFinder.new(site: site, context: context)
      result = finder.find
    end

    assert_empty result[:favorites_lists]
    assert_match(/Prerequisites missing/, result[:log_messages])
  end

  def test_find_logs_info_if_no_favorites_posts_are_found
    # Create a site with only regular posts (no is_favorites_list front matter)
    site = create_site({}, {}, [], [create_doc({ 'title' => 'Regular' }, '/regular.html')])
    site.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context = create_context({}, { site: site, page: create_doc({}, '/current.html') })

    result = nil
    stub_silent_logger do
      finder = Jekyll::Books::Lists::FavoritesListsFinder.new(site: site, context: context)
      result = finder.find
    end

    assert_empty result[:favorites_lists]
    # Match with HTML entities (&#39; for apostrophes) and any surrounding content
    assert_match(/No posts with.*is_favorites_list.*front matter found/, result[:log_messages])
  end
end
