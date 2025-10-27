# _tests/plugins/utils/book_list_utils/test_favorites_lists_display.rb
require_relative '../../../test_helper'

class TestBookListUtilsFavoritesListsDisplay < Minitest::Test
  def setup
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

    # --- Site & Context ---
    @site = create_site(
      {},
      { 'books' => [@book_a, @book_b, @book_z] },
      [],
      [@fav_post_2023, @fav_post_2024, @regular_post]
    )
    # Manually set up the cache that the util will read from
    @site.data['link_cache']['favorites_posts_to_books'] = {
      @fav_post_2024.url => [@book_z, @book_a], # Intentionally unsorted books
      @fav_post_2023.url => [@book_b]
    }
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })

    @silent_logger_stub = Object.new.tap do |l|
      def l.warn(p,m);end; def l.error(p,m);end; def l.info(p,m);end; def l.debug(p,m);end
    end
  end

  def get_favorites_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_favorites_lists(site: site, context: context)
    end
  end

  def test_get_data_for_favorites_lists_correct_structure_and_sorting
    data = get_favorites_data

    assert_empty data[:log_messages].to_s
    assert_equal 2, data[:favorites_lists].size, "Should find two favorites lists"

    # --- Assert Overall List Order (by year descending) ---
    assert_equal @fav_post_2024.url, data[:favorites_lists][0][:post].url
    assert_equal @fav_post_2023.url, data[:favorites_lists][1][:post].url

    # --- Assert 2024 List ---
    list_2024 = data[:favorites_lists][0]
    assert_equal 2, list_2024[:books].size
    # Books should be sorted alphabetically by title
    assert_equal @book_a.data['title'], list_2024[:books][0].data['title']
    assert_equal @book_z.data['title'], list_2024[:books][1].data['title']

    # --- Assert 2023 List ---
    list_2023 = data[:favorites_lists][1]
    assert_equal 1, list_2023[:books].size
    assert_equal @book_b.data['title'], list_2023[:books][0].data['title']
  end

  def test_get_data_for_favorites_lists_no_favorites_posts_logs_info
    site_no_favs = create_site({}, { 'books' => [@book_a] }, [], [@regular_post])
    site_no_favs.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context_no_favs = create_context({}, { site: site_no_favs, page: @context.registers[:page] })

    data = get_favorites_data(site_no_favs, context_no_favs)
    assert_empty data[:favorites_lists]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_FAVORITES_FAILURE: Reason='No posts with &#39;is_favorites_list&#39; front matter found\.' .*? -->}, data[:log_messages]
  end

  def test_get_data_for_favorites_lists_prerequisites_missing_logs_error
    site_no_cache = create_site({}, {}, [], [@fav_post_2023])
    site_no_cache.data['link_cache'].delete('favorites_posts_to_books')
    site_no_cache.config['plugin_logging']['BOOK_LIST_FAVORITES'] = true
    context_no_cache = create_context({}, { site: site_no_cache, page: @context.registers[:page] })

    data = get_favorites_data(site_no_cache, context_no_cache)
    assert_empty data[:favorites_lists]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_FAVORITES_FAILURE: Reason='Prerequisites missing: site\.posts or favorites_posts_to_books cache\.' .*? -->}, data[:log_messages]
  end
end
