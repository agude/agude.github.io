# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_favorites_lists_finder.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/logic/book_lists/favorites_lists_finder'

# Tests for Jekyll::BookLists::FavoritesListsFinder
#
# Verifies that the finder correctly fetches and organizes books by favorites lists,
# sorting lists by year and books within each list alphabetically by normalized title.
class TestBookListFavoritesListsFinder < Minitest::Test
  def setup
    setup_test_documents
    setup_site_and_context
    setup_silent_logger
  end

  def get_favorites_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::BookLists::FavoritesListsFinder.new(site: site, context: context)
      finder.find
    end
  end

  private

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

  def setup_silent_logger
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(param, msg); end

      def logger.error(param, msg); end

      def logger.info(param, msg); end

      def logger.debug(param, msg); end
    end
  end

  def test_favorites_lists_finder_correct_structure_and_sorting
    result = get_favorites_data

    assert_empty result[:log_messages].to_s
    assert_equal 2, result[:favorites_lists].size, 'Should find two favorites lists'

    assert_correct_list_order(result)
    assert_correct_2024_list_content(result[:favorites_lists][0])
    assert_correct_2023_list_content(result[:favorites_lists][1])
  end

  def test_favorites_lists_finder_no_favorites_posts_logs_info
    site_no_favs = create_site({}, { 'books' => [@book_a] }, [], [@regular_post])
    site_no_favs.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context_no_favs = create_context({}, { site: site_no_favs, page: @context.registers[:page] })

    result = get_favorites_data(site_no_favs, context_no_favs)
    assert_empty result[:favorites_lists]
    expected_info = /<!-- \[INFO\] BOOK_LIST_FAVORITES_FAILURE: Reason='No posts with /
    assert_match(expected_info, result[:log_messages])
  end

  def test_favorites_lists_finder_prerequisites_missing_logs_error
    site_no_cache = create_site({}, {}, [], [@fav_post_2023])
    site_no_cache.data['link_cache'].delete('favorites_posts_to_books')
    site_no_cache.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context_no_cache = create_context({}, { site: site_no_cache, page: @context.registers[:page] })

    result = get_favorites_data(site_no_cache, context_no_cache)
    assert_empty result[:favorites_lists]
    expected_error = /<!-- \[ERROR\] BOOK_LIST_FAVORITES_FAILURE: Reason='Prerequisites missing: /
    assert_match(expected_error, result[:log_messages])
  end

  def assert_correct_list_order(result)
    # Overall list order (by year descending)
    assert_equal @fav_post_2024.url, result[:favorites_lists][0][:post].url
    assert_equal @fav_post_2023.url, result[:favorites_lists][1][:post].url
  end

  def assert_correct_2024_list_content(list_2024)
    assert_equal 2, list_2024[:books].size
    # Books should be sorted alphabetically by title
    assert_equal @book_a.data['title'], list_2024[:books][0].data['title']
    assert_equal @book_z.data['title'], list_2024[:books][1].data['title']
  end

  def assert_correct_2023_list_content(list_2023)
    assert_equal 1, list_2023[:books].size
    assert_equal @book_b.data['title'], list_2023[:books][0].data['title']
  end
end
