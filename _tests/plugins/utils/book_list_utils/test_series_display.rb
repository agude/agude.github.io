# _tests/plugins/utils/book_list_utils/test_series_display.rb
require_relative '../../../test_helper' # Adjusted path
# BookListUtils is loaded by test_helper

class TestBookListUtilsSeriesDisplay < Minitest::Test # Renamed class

  def setup
    # --- Minimal Book Data Setup for Series Display Tests ---
    # Only include books relevant to testing series filtering and sorting.

    # Series One Books
    @s1_b0_5 = create_doc({ 'title' => 'S1 Book 0.5 (Novella)', 'series' => 'Series One', 'book_number' => 0.5, 'published' => true, 'date' => Time.now }, '/s1b0_5.html')
    @s1_b1   = create_doc({ 'title' => 'S1 Book 1',   'series' => 'Series One', 'book_number' => 1, 'published' => true, 'date' => Time.now }, '/s1b1.html')
    @s1_b2   = create_doc({ 'title' => 'S1 Book 2',   'series' => 'Series One', 'book_number' => '2.0', 'published' => true, 'date' => Time.now }, '/s1b2.html')
    @s1_b10  = create_doc({ 'title' => 'S1 Book 10',  'series' => 'Series One', 'book_number' => '10', 'published' => true, 'date' => Time.now }, '/s1b10.html')
    @s1_b_nil_num = create_doc({ 'title' => 'S1 Book NilNum', 'series' => 'Series One', 'book_number' => nil, 'published' => true, 'date' => Time.now }, '/s1b_nil.html')
    @s1_b_str_num = create_doc({ 'title' => 'S1 Book StrNum', 'series' => 'Series One', 'book_number' => 'Part 3', 'published' => true, 'date' => Time.now }, '/s1b_str.html')
    @unpublished_s1 = create_doc({ 'title' => 'Unpublished S1 Book', 'series' => 'Series One', 'published' => false, 'date' => Time.now }, '/s1_unpub.html')

    # Series Two Book (for testing "not found" or different series)
    @s2_b1 = create_doc({ 'title' => 'S2 Book 1', 'series' => 'Series Two', 'book_number' => 1, 'published' => true, 'date' => Time.now }, '/s2b1.html')

    @books_for_series_tests = [
      @s1_b0_5, @s1_b1, @s1_b2, @s1_b10, @s1_b_nil_num, @s1_b_str_num,
      @unpublished_s1, @s2_b1
    ]

    @site = create_site({}, { 'books' => @books_for_series_tests })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility method directly for these focused tests
  def get_series_data(series_name_filter, site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_series_display(site: site, series_name_filter: series_name_filter, context: context)
    end
  end

  def test_get_data_for_series_display_found_and_sorted_numerically_with_floats
    data = get_series_data('Series One')
    assert_equal 'Series One', data[:series_name]
    # Expected order: 0.5, 1, 2.0, 10, NilNum, StrNum (Nil/Str sort last due to Float::INFINITY)
    # Total published in Series One for this test setup: 6
    assert_equal 6, data[:books].size
    assert_equal @s1_b0_5.data['title'], data[:books][0].data['title'] # 0.5
    assert_equal @s1_b1.data['title'],   data[:books][1].data['title'] # 1
    assert_equal @s1_b2.data['title'],   data[:books][2].data['title'] # 2.0
    assert_equal @s1_b10.data['title'],  data[:books][3].data['title'] # 10

    # The order of StrNum and NilNum relative to each other depends on secondary title sort
    last_two_titles = [data[:books][4].data['title'], data[:books][5].data['title']].sort
    expected_last_two = [@s1_b_nil_num.data['title'], @s1_b_str_num.data['title']].sort
    assert_equal expected_last_two, last_two_titles

    assert_empty data[:log_messages].to_s, "Expected no log messages for a successful series lookup"
  end

  def test_get_data_for_series_display_found_case_insensitive
    data = get_series_data('series one') # Lowercase filter
    assert_equal 'series one', data[:series_name] # Util preserves input filter casing for :series_name
    assert_equal 6, data[:books].size # Should still find all 6 published "Series One" books
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_not_found_logs_info
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true # Enable logging for this test
    data = get_series_data('NonExistent Series')
    assert_equal 'NonExistent Series', data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for the specified series\.'\s*SeriesFilter='NonExistent Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_nil_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = get_series_data(nil)
    assert_nil data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='N/A'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_empty_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = get_series_data('   ') # Filter with only whitespace
    assert_equal '   ', data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='   '\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_ignores_unpublished
    data = get_series_data('Series One')
    assert_equal 6, data[:books].size # Should only find the 6 published ones
    refute_includes data[:books].map { |b| b.data['title'] }, @unpublished_s1.data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_books_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable general util logging
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_series_data('Any Series', site_no_books, context_no_books)
    assert_empty data[:books]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='series'\s*series_name='Any Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end
end
