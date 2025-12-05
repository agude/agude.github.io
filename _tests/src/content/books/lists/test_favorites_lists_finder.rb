# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_favorites_lists_finder.rb
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
    silent_logger = Object.new.tap do |logger|
      def logger.warn(_prefix, _msg); end
      def logger.error(_prefix, _msg); end
      def logger.info(_prefix, _msg); end
      def logger.debug(_prefix, _msg); end
    end

    Jekyll.stub(:logger, silent_logger, &)
  end

  def setup_test_documents
    # --- Mock Books ---
    @book_a = create_doc({ 'title' => 'Apple Book' }, '/books/a.html')
    @book_b = create_doc({ 'title' => 'Banana Book' }, '/books/b.html')
    @book_z = create_doc({ 'title' => 'Zebra Book' }, '/books/z.html')

    # --- Mock Posts ---
    @fav_post_2024 = create_doc(
      { 'title' => 'Favorites 2024', 'is_favorites_list' => 2024 },
      '/posts/fav24.html'
    )
    @fav_post_2023 = create_doc(
      { 'title' => 'Favorites 2023', 'is_favorites_list' => 2023 },
      '/posts/fav23.html'
    )
    @regular_post = create_doc({ 'title' => 'Regular Post' }, '/posts/regular.html')
  end

  def setup_site_and_context
    # --- Site & Context ---
    @site = create_site(
      {},
      { 'books' => [@book_a, @book_b, @book_z] },
      [],
      [@fav_post_2023, @fav_post_2024, @regular_post]
    )
    # Manually set up the cache that the finder will read from
    @site.data['link_cache']['favorites_posts_to_books'] = {
      @fav_post_2024.url => [@book_z, @book_a], # Intentionally unsorted books
      @fav_post_2023.url => [@book_b]
    }
    current_page = create_doc({ 'path' => 'current.html' }, '/current.html')
    @context = create_context({}, { site: @site, page: current_page })
  end

  public

  # --- Happy Path Test ---

  def test_find_returns_correctly_structured_and_sorted_data
    # Instantiate and call the finder directly
    finder = Jekyll::Books::Lists::FavoritesListsFinder.new(site: @site, context: @context)
    result = finder.find

    # Assert no error messages
    assert_empty result[:log_messages].to_s
    assert_equal 2, result[:favorites_lists].size, 'Should find two favorites lists'

    # Assert lists are sorted by year descending (2024, then 2023)
    assert_equal @fav_post_2024.url, result[:favorites_lists][0][:post].url
    assert_equal @fav_post_2023.url, result[:favorites_lists][1][:post].url

    # Assert books within the 2024 list are sorted by title ascending
    list_2024 = result[:favorites_lists][0]
    assert_equal 2, list_2024[:books].size
    assert_equal 'Apple Book', list_2024[:books][0].data['title']
    assert_equal 'Zebra Book', list_2024[:books][1].data['title']

    # Assert books within the 2023 list
    list_2023 = result[:favorites_lists][1]
    assert_equal 1, list_2023[:books].size
    assert_equal 'Banana Book', list_2023[:books][0].data['title']
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
