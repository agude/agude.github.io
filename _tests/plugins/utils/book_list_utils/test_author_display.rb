# _tests/plugins/utils/book_list_utils/test_author_display.rb
require_relative '../../../test_helper'
# BookListUtils is loaded by test_helper

class TestBookListUtilsAuthorDisplay < Minitest::Test # Renamed class

  def setup
    # --- Minimal Book Data Setup for Author Display Tests ---
    @author_a_name = "Author Alpha"
    @author_b_lower_name = "author beta" # Lowercase for case-insensitivity test

    # Books by Author Alpha
    @book_aa_s1_b1 = create_doc({ 'title' => 'AA Series1 Book1', 'series' => 'Alpha Series', 'book_number' => 1, 'book_author' => @author_a_name, 'published' => true, 'date' => Time.now }, '/aa_s1b1.html')
    @book_aa_s1_b2 = create_doc({ 'title' => 'AA Series1 Book2', 'series' => 'Alpha Series', 'book_number' => 2.0, 'book_author' => @author_a_name, 'published' => true, 'date' => Time.now }, '/aa_s1b2.html')
    @book_aa_s1_b0_5 = create_doc({ 'title' => 'AA Series1 Book0.5', 'series' => 'Alpha Series', 'book_number' => 0.5, 'book_author' => @author_a_name, 'published' => true, 'date' => Time.now }, '/aa_s1b0_5.html')
    @book_aa_standalone_zeta = create_doc({ 'title' => 'Zeta Standalone by AA', 'book_author' => @author_a_name, 'published' => true, 'date' => Time.now }, '/aa_sa_zeta.html')
    @book_aa_standalone_apple = create_doc({ 'title' => 'Apple Standalone by AA', 'book_author' => @author_a_name, 'published' => true, 'date' => Time.now }, '/aa_sa_apple.html')

    # Books by author beta
    @book_ab_s2_b1 = create_doc({ 'title' => 'ab Series2 Book1', 'series' => 'Beta Series', 'book_number' => 1, 'book_author' => @author_b_lower_name, 'published' => true, 'date' => Time.now }, '/ab_s2b1.html')
    @book_ab_standalone = create_doc({ 'title' => 'Standalone by ab', 'book_author' => @author_b_lower_name, 'published' => true, 'date' => Time.now }, '/ab_sa.html')
    @unpublished_ab = create_doc({ 'title' => 'Unpublished by ab', 'book_author' => @author_b_lower_name, 'published' => false, 'date' => Time.now }, '/ab_unpub.html')

    # Book by another author (to ensure filtering works)
    @book_other_author = create_doc({ 'title' => 'Other Author Book', 'book_author' => 'Author Gamma', 'published' => true, 'date' => Time.now }, '/other_auth.html')


    @books_for_author_tests = [
      @book_aa_s1_b1, @book_aa_s1_b2, @book_aa_s1_b0_5, @book_aa_standalone_zeta, @book_aa_standalone_apple,
      @book_ab_s2_b1, @book_ab_standalone, @unpublished_ab,
      @book_other_author
    ]

    @site = create_site({}, { 'books' => @books_for_author_tests })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility method directly
  def get_author_data(author_name_filter, site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do # Stub logger for calls within the util
      BookListUtils.get_data_for_author_display(site: site, author_name_filter: author_name_filter, context: context)
    end
  end

  def test_get_data_for_author_display_found_author_alpha
    data = get_author_data(@author_a_name)

    # Standalone books for Author Alpha (sorted by title)
    assert_equal 2, data[:standalone_books].size
    assert_equal @book_aa_standalone_apple.data['title'], data[:standalone_books][0].data['title'] # Apple
    assert_equal @book_aa_standalone_zeta.data['title'], data[:standalone_books][1].data['title']  # Zeta

    # Series for Author Alpha (Alpha Series)
    assert_equal 1, data[:series_groups].size
    alpha_series_group = data[:series_groups].find { |g| g[:name] == 'Alpha Series' }
    refute_nil alpha_series_group
    assert_equal 3, alpha_series_group[:books].size # 0.5, 1, 2.0
    assert_equal @book_aa_s1_b0_5.data['title'], alpha_series_group[:books][0].data['title']
    assert_equal @book_aa_s1_b1.data['title'], alpha_series_group[:books][1].data['title']
    assert_equal @book_aa_s1_b2.data['title'], alpha_series_group[:books][2].data['title']

    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_found_author_beta_case_insensitive
    data = get_author_data("AUTHOR BETA") # Uppercase filter for lowercase author name

    # Standalone for author beta
    assert_equal 1, data[:standalone_books].size
    assert_equal @book_ab_standalone.data['title'], data[:standalone_books][0].data['title']

    # Series for author beta (Beta Series)
    assert_equal 1, data[:series_groups].size
    beta_series_group = data[:series_groups].find { |g| g[:name] == 'Beta Series' }
    refute_nil beta_series_group
    assert_equal 1, beta_series_group[:books].size
    assert_equal @book_ab_s2_b1.data['title'], beta_series_group[:books][0].data['title']

    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_ignores_unpublished
    data = get_author_data(@author_b_lower_name) # author beta
    # @unpublished_ab should not be included
    assert_equal 1, data[:standalone_books].size
    assert_equal @book_ab_standalone.data['title'], data[:standalone_books][0].data['title']
    assert_equal 1, data[:series_groups].size # Only Beta Series with 1 book
  end

  def test_get_data_for_author_display_author_not_found_logs_info
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('NonExistent Author')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='No books found for the specified author\.'\s*AuthorFilter='NonExistent Author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_nil_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data(nil)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilterInput='N/A'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_empty_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('   ')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilterInput='   '\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_books_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_author_data('Any Author', site_no_books, context_no_books)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='author'\s*author_name='Any Author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end
end
