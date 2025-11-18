# _tests/plugins/utils/book_list_utils/test_all_books_by_year_display.rb
require_relative '../../../test_helper'
require 'time' # For Time.parse
# BookListUtils is loaded by test_helper

# Renamed class
class TestBookListUtilsAllBooksByYearDisplay < Minitest::Test
  def setup
    # --- Book Data for Year Display Tests ---
    # Using Time.utc for dates to ensure consistency regardless of test runner's local timezone.
    # These are used by the main test_get_data_for_all_books_by_year_display_correct_grouping_and_sorting
    @book_2024_mar_setup = create_doc(
      { 'title' => 'Book Mar 2024 Setup', 'date' => Time.utc(2024, 3, 10), 'published' => true }, '/b2024mar_setup.html'
    )
    @book_2023_jun_setup = create_doc(
      { 'title' => 'Book Jun 2023 Setup', 'date' => Time.utc(2023, 6, 20), 'published' => true }, '/b2023jun_setup.html'
    )
    @unpublished_2023_setup = create_doc(
      { 'title' => 'Unpublished 2023 Book Setup', 'date' => Time.utc(2023, 7, 7),
        'published' => false }, '/unpub2023_setup.html'
    )
    @book_string_date_2022_setup = create_doc(
      { 'title' => 'Book String Date 2022 Setup', 'date' => '2022-11-11',
        'published' => true }, '/b_str_date_2022_setup.html'
    )

    @books_for_general_year_tests = [ # Used for some edge case tests, not the main sorting one
      @book_2024_mar_setup, @book_2023_jun_setup, @unpublished_2023_setup, @book_string_date_2022_setup
    ]

    @site = create_site({}, { 'books' => @books_for_general_year_tests }) # Default site for some tests
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility method directly
  def get_all_books_by_year_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_all_books_by_year_display(site: site, context: context)
    end
  end

  def test_get_data_for_all_books_by_year_display_correct_grouping_and_sorting
    # Setup specific books for THIS test with clear dates
    book_2024_mar = create_doc({ 'title' => 'Book Mar 2024', 'date' => Time.utc(2024, 3, 10), 'published' => true },
                               '/b2024b.html')
    book_2024_jan = create_doc({ 'title' => 'Book Jan 2024', 'date' => Time.utc(2024, 1, 15), 'published' => true },
                               '/b2024a.html')
    book_2024_may_fixed = create_doc({ 'title' => 'Book Fixed Now Year (May 2024)', 'date' => Time.utc(2024, 5, 20), 'published' => true }, '/bnow.html') # Explicitly 2024

    book_2023_dec = create_doc({ 'title' => 'Book Dec 2023', 'date' => Time.utc(2023, 12, 1), 'published' => true },
                               '/b2023a.html')
    book_2023_jun = create_doc({ 'title' => 'Book Jun 2023', 'date' => Time.utc(2023, 6, 20), 'published' => true },
                               '/b2023b.html')

    book_2022_oct = create_doc({ 'title' => 'Book Oct 2022', 'date' => Time.utc(2022, 10, 5), 'published' => true },
                               '/b2022oct.html')

    current_books_for_year_test = [
      book_2024_jan, book_2024_mar, book_2024_may_fixed, # All 2024
      book_2023_dec, book_2023_jun, # All 2023
      book_2022_oct # All 2022
    ]
    temp_site = create_site({}, { 'books' => current_books_for_year_test })
    # Use the class instance @context for page path in logging, but site from temp_site
    temp_context = create_context({}, { site: temp_site, page: @context.registers[:page] })

    data = get_all_books_by_year_data(temp_site, temp_context)

    assert_empty data[:log_messages].to_s

    # Years present from test data: 2024, 2023, 2022
    assert_equal 3, data[:year_groups].size, 'Incorrect number of year groups. Expected 3 based on test data.'

    # Check overall order of year groups (most recent year first: 2024, then 2023, then 2022)
    actual_year_order = data[:year_groups].map { |yg| yg[:year] }
    assert_equal %w[2024 2023 2022], actual_year_order, 'Year groups not sorted correctly'

    # --- Assert Group 2024 ---
    group_2024 = data[:year_groups].find { |g| g[:year] == '2024' }
    refute_nil group_2024, "Group '2024' missing"
    # Expected order in 2024: May, Mar, Jan (most recent first)
    expected_2024_titles = [book_2024_may_fixed.data['title'], book_2024_mar.data['title'], book_2024_jan.data['title']]
    assert_equal expected_2024_titles, group_2024[:books].map { |b|
      b.data['title']
    }, 'Books in 2024 group not sorted correctly by date'

    # --- Assert Group 2023 ---
    group_2023 = data[:year_groups].find { |g| g[:year] == '2023' }
    refute_nil group_2023, "Group '2023' missing"
    # Expected order in 2023: Dec, Jun
    expected_2023_titles = [book_2023_dec.data['title'], book_2023_jun.data['title']]
    assert_equal expected_2023_titles, group_2023[:books].map { |b|
      b.data['title']
    }, 'Books in 2023 group not sorted correctly by date'

    # --- Assert Group 2022 ---
    group_2022 = data[:year_groups].find { |g| g[:year] == '2022' }
    refute_nil group_2022, "Group '2022' missing"
    expected_2022_titles = [book_2022_oct.data['title']] # Only one book for 2022 in this specific test data
    assert_equal expected_2022_titles, group_2022[:books].map { |b|
      b.data['title']
    }, 'Books in 2022 group not sorted correctly by date'
  end

  def test_get_data_for_all_books_by_year_display_ignores_unpublished
    # This test uses the main @site from setup which includes @unpublished_2023_setup
    data = get_all_books_by_year_data(@site, @context) # Use main site
    all_rendered_titles = data[:year_groups].flat_map { |yg| yg[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @unpublished_2023_setup.data['title']
  end

  def test_includes_archived_reviews
    canonical_2023 = create_doc({ 'title' => 'Canonical 2023', 'date' => Time.utc(2023, 8, 1), 'published' => true },
                                '/c23.html')
    archived_2023 = create_doc(
      { 'title' => 'Archived 2023', 'date' => Time.utc(2023, 4, 1), 'published' => true,
        'canonical_url' => '/c23.html' }, '/a23.html'
    )
    site = create_site({}, { 'books' => [canonical_2023, archived_2023] })
    context = create_context({}, { site: site, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site, context)
    assert_equal 1, data[:year_groups].size
    group_2023 = data[:year_groups].first
    assert_equal '2023', group_2023[:year]
    assert_equal 2, group_2023[:books].size
    assert_includes group_2023[:books].map { |b| b.data['title'] }, 'Canonical 2023'
    assert_includes group_2023[:books].map { |b| b.data['title'] }, 'Archived 2023'
    # Check sort order within the year
    assert_equal 'Canonical 2023', group_2023[:books][0].data['title'] # August
    assert_equal 'Archived 2023', group_2023[:books][1].data['title']  # April
  end

  def test_get_data_for_all_books_by_year_display_handles_books_with_non_time_dates_gracefully
    # create_doc in test_helper converts string dates to Time or defaults to Time.now
    # The BookListUtils sort_by block has a fallback: book.date.is_a?(Time) ? book.date : Time.now
    # This test ensures that if a book somehow ended up with a non-Time date that create_doc didn't catch,
    # it gets grouped into the current year due to the fallback.

    # Book with a date that will be Time.now (current execution time) via create_doc's default
    book_current_time_date = create_doc({ 'title' => 'Current Time Date Book', 'published' => true },
                                        '/current_time_date.html')
    # Book with a string date that create_doc will parse
    book_specific_string_date = create_doc(
      { 'title' => 'Specific String Date Book', 'date' => '2022-07-01',
        'published' => true }, '/specific_string_date.html'
    )

    site_with_mixed_dates = create_site({},
                                        { 'books' => [book_current_time_date, book_specific_string_date,
                                                      @book_2023_jun_setup] })
    context_with_mixed_dates = create_context({}, { site: site_with_mixed_dates, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_with_mixed_dates, context_with_mixed_dates)

    current_year_str = Time.now.year.to_s
    # We expect groups for current_year_str, "2023", and "2022"
    expected_years = [current_year_str, '2023', '2022'].uniq.sort.reverse
    actual_years = data[:year_groups].map { |yg| yg[:year] }.sort.reverse
    assert_equal expected_years, actual_years

    current_year_group = data[:year_groups].find { |yg| yg[:year] == current_year_str }
    refute_nil current_year_group, 'Group for current year (fallback or actual) missing'
    assert_includes current_year_group[:books].map { |b| b.data['title'] }, 'Current Time Date Book'

    year_2022_group = data[:year_groups].find { |yg| yg[:year] == '2022' }
    refute_nil year_2022_group
    assert_includes year_2022_group[:books].map { |b| b.data['title'] }, 'Specific String Date Book'
  end

  def test_get_data_for_all_books_by_year_display_no_books_logs_info
    site_empty_books = create_site({}, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_YEAR_DISPLAY'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_empty_books, context_empty_books)
    assert_empty data[:year_groups]
    assert_match(/<!-- \[INFO\] ALL_BOOKS_BY_YEAR_DISPLAY_FAILURE: Reason='No published books found to group by year\.'\s*SourcePage='current_page\.html' -->/,
                 data[:log_messages])
  end

  def test_get_data_for_all_books_by_year_display_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_no_books, context_no_books)
    assert_empty data[:year_groups]
    assert_match(/<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_year'\s*SourcePage='current_page\.html' -->/,
                 data[:log_messages])
  end
end
