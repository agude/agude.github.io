# frozen_string_literal: true

# _tests/plugins/utils/book_list_utils/test_all_books_by_year_display.rb
require_relative '../../../test_helper'
require 'time'

# Base test class with shared setup and helpers
class TestBookListUtilsAllBooksByYearDisplayBase < Minitest::Test
  def setup
    setup_test_books
    setup_site_and_context
    @silent_logger_stub = create_silent_logger
  end

  def get_all_books_by_year_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_all_books_by_year_display(site: site, context: context)
    end
  end

  private

  def setup_test_books
    @book_mar_2024_setup = create_doc(
      { 'title' => 'Book Mar 2024 Setup', 'date' => Time.utc(2024, 3, 10), 'published' => true },
      '/b2024mar_setup.html'
    )
    @book_jun_2023_setup = create_doc(
      { 'title' => 'Book Jun 2023 Setup', 'date' => Time.utc(2023, 6, 20), 'published' => true },
      '/b2023jun_setup.html'
    )
    @unpublished_2023_setup = create_doc(
      { 'title' => 'Unpublished 2023 Book Setup', 'date' => Time.utc(2023, 7, 7), 'published' => false },
      '/unpub2023_setup.html'
    )
    @book_string_date_2022_setup = create_doc(
      { 'title' => 'Book String Date 2022 Setup', 'date' => '2022-11-11', 'published' => true },
      '/b_str_date_2022_setup.html'
    )

    @books_for_general_year_tests = [
      @book_mar_2024_setup, @book_jun_2023_setup, @unpublished_2023_setup, @book_string_date_2022_setup
    ]
  end

  def setup_site_and_context
    @site = create_site({}, { 'books' => @books_for_general_year_tests })
    @context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') }
    )
  end

  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(_topic, _message); end

      def logger.error(_topic, _message); end

      def logger.info(_topic, _message); end

      def logger.debug(_topic, _message); end
    end
  end
end

# Tests for grouping and sorting functionality
class TestBookListUtilsAllBooksByYearDisplayGrouping < TestBookListUtilsAllBooksByYearDisplayBase
  def test_get_data_for_all_books_by_year_display_correct_grouping_and_sorting
    test_books = create_year_test_books
    temp_site, temp_context = create_temp_site_and_context(test_books)

    data = get_all_books_by_year_data(temp_site, temp_context)

    assert_empty data[:log_messages].to_s
    assert_correct_year_groups(data, test_books)
  end

  def test_get_data_for_all_books_by_year_display_ignores_unpublished
    data = get_all_books_by_year_data(@site, @context)
    all_rendered_titles = data[:year_groups].flat_map { |yg| yg[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @unpublished_2023_setup.data['title']
  end

  private

  def create_year_test_books
    {
      book_mar_2024: create_doc(
        { 'title' => 'Book Mar 2024', 'date' => Time.utc(2024, 3, 10), 'published' => true },
        '/b2024b.html'
      ),
      book_jan_2024: create_doc(
        { 'title' => 'Book Jan 2024', 'date' => Time.utc(2024, 1, 15), 'published' => true },
        '/b2024a.html'
      ),
      book_may_2024_fixed: create_doc(
        { 'title' => 'Book Fixed Now Year (May 2024)', 'date' => Time.utc(2024, 5, 20), 'published' => true },
        '/bnow.html'
      ),
      book_dec_2023: create_doc(
        { 'title' => 'Book Dec 2023', 'date' => Time.utc(2023, 12, 1), 'published' => true },
        '/b2023a.html'
      ),
      book_jun_2023: create_doc(
        { 'title' => 'Book Jun 2023', 'date' => Time.utc(2023, 6, 20), 'published' => true },
        '/b2023b.html'
      ),
      book_oct_2022: create_doc(
        { 'title' => 'Book Oct 2022', 'date' => Time.utc(2022, 10, 5), 'published' => true },
        '/b2022oct.html'
      )
    }
  end

  def create_temp_site_and_context(books)
    current_books_for_year_test = [
      books[:book_jan_2024], books[:book_mar_2024], books[:book_may_2024_fixed],
      books[:book_dec_2023], books[:book_jun_2023],
      books[:book_oct_2022]
    ]
    temp_site = create_site({}, { 'books' => current_books_for_year_test })
    temp_context = create_context({}, { site: temp_site, page: @context.registers[:page] })
    [temp_site, temp_context]
  end

  def assert_correct_year_groups(data, books)
    assert_equal 3, data[:year_groups].size, 'Incorrect number of year groups. Expected 3 based on test data.'

    actual_year_order = data[:year_groups].map { |yg| yg[:year] }
    assert_equal %w[2024 2023 2022], actual_year_order, 'Year groups not sorted correctly'

    assert_group_2024_correct(data, books)
    assert_group_2023_correct(data, books)
    assert_group_2022_correct(data, books)
  end

  def assert_group_2024_correct(data, books)
    group = data[:year_groups].find { |g| g[:year] == '2024' }
    refute_nil group, "Group '2024' missing"
    expected_titles = [
      books[:book_may_2024_fixed].data['title'],
      books[:book_mar_2024].data['title'],
      books[:book_jan_2024].data['title']
    ]
    assert_equal expected_titles, group[:books].map { |b| b.data['title'] },
                 'Books in 2024 group not sorted correctly by date'
  end

  def assert_group_2023_correct(data, books)
    group = data[:year_groups].find { |g| g[:year] == '2023' }
    refute_nil group, "Group '2023' missing"
    expected_titles = [books[:book_dec_2023].data['title'], books[:book_jun_2023].data['title']]
    assert_equal expected_titles, group[:books].map { |b| b.data['title'] },
                 'Books in 2023 group not sorted correctly by date'
  end

  def assert_group_2022_correct(data, books)
    group = data[:year_groups].find { |g| g[:year] == '2022' }
    refute_nil group, "Group '2022' missing"
    expected_titles = [books[:book_oct_2022].data['title']]
    assert_equal expected_titles, group[:books].map { |b| b.data['title'] },
                 'Books in 2022 group not sorted correctly by date'
  end
end

# Tests for archived reviews and date handling
class TestBookListUtilsAllBooksByYearDisplayArchived < TestBookListUtilsAllBooksByYearDisplayBase
  def test_includes_archived_reviews
    canonical, archived = create_archived_test_books
    site = create_site({}, { 'books' => [canonical, archived] })
    context = create_context({}, { site: site, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site, context)

    assert_archived_reviews_included(data, canonical, archived)
  end

  def test_get_data_for_all_books_by_year_display_handles_books_with_non_time_dates_gracefully
    book_current_time, book_specific_string = create_mixed_date_books
    site_with_mixed = create_mixed_dates_site(book_current_time, book_specific_string)
    context_with_mixed = create_context({}, { site: site_with_mixed, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_with_mixed, context_with_mixed)

    assert_mixed_dates_handled_correctly(data, book_current_time, book_specific_string)
  end

  private

  def create_archived_test_books
    canonical = create_doc(
      { 'title' => 'Canonical 2023', 'date' => Time.utc(2023, 8, 1), 'published' => true },
      '/c23.html'
    )
    archived = create_doc(
      { 'title' => 'Archived 2023', 'date' => Time.utc(2023, 4, 1), 'published' => true,
        'canonical_url' => '/c23.html' },
      '/a23.html'
    )
    [canonical, archived]
  end

  def assert_archived_reviews_included(data, canonical, archived)
    assert_equal 1, data[:year_groups].size
    group = data[:year_groups].first
    assert_equal '2023', group[:year]
    assert_equal 2, group[:books].size
    assert_includes group[:books].map { |b| b.data['title'] }, canonical.data['title']
    assert_includes group[:books].map { |b| b.data['title'] }, archived.data['title']
    assert_equal canonical.data['title'], group[:books][0].data['title']
    assert_equal archived.data['title'], group[:books][1].data['title']
  end

  def create_mixed_date_books
    book_current = create_doc({ 'title' => 'Current Time Date Book', 'published' => true },
                              '/current_time_date.html')
    book_specific = create_doc(
      { 'title' => 'Specific String Date Book', 'date' => '2022-07-01', 'published' => true },
      '/specific_string_date.html'
    )
    [book_current, book_specific]
  end

  def create_mixed_dates_site(book_current, book_specific)
    create_site({}, { 'books' => [book_current, book_specific, @book_jun_2023_setup] })
  end

  def assert_mixed_dates_handled_correctly(data, book_current, book_specific)
    current_year_str = Time.now.year.to_s
    expected_years = [current_year_str, '2023', '2022'].uniq.sort.reverse
    actual_years = data[:year_groups].map { |yg| yg[:year] }.sort.reverse
    assert_equal expected_years, actual_years

    current_year_group = data[:year_groups].find { |yg| yg[:year] == current_year_str }
    refute_nil current_year_group, 'Group for current year (fallback or actual) missing'
    assert_includes current_year_group[:books].map { |b| b.data['title'] }, book_current.data['title']

    year_group_2022 = data[:year_groups].find { |yg| yg[:year] == '2022' }
    refute_nil year_group_2022
    assert_includes year_group_2022[:books].map { |b| b.data['title'] }, book_specific.data['title']
  end
end

# Tests for error handling and logging
class TestBookListUtilsAllBooksByYearDisplayErrors < TestBookListUtilsAllBooksByYearDisplayBase
  def test_get_data_for_all_books_by_year_display_no_books_logs_info
    site_empty = create_empty_books_site
    context_empty = create_context({}, { site: site_empty, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_empty, context_empty)

    assert_empty data[:year_groups]
    expected_pattern = /<!-- \[INFO\] ALL_BOOKS_BY_YEAR_DISPLAY_FAILURE: Reason='No published books found to group by year\.'\s*SourcePage='current_page\.html' -->/
    assert_match expected_pattern, data[:log_messages]
  end

  def test_get_data_for_all_books_by_year_display_collection_missing_logs_error
    site_no_collection = create_site_without_books_collection
    context_no_collection = create_context({}, { site: site_no_collection, page: @context.registers[:page] })

    data = get_all_books_by_year_data(site_no_collection, context_no_collection)

    assert_empty data[:year_groups]
    expected_pattern = /<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_year'\s*SourcePage='current_page\.html' -->/
    assert_match expected_pattern, data[:log_messages]
  end

  private

  def create_empty_books_site
    site = create_site({}, { 'books' => [] })
    site.config['plugin_logging']['ALL_BOOKS_BY_YEAR_DISPLAY'] = true
    site
  end

  def create_site_without_books_collection
    site = create_site({}, {})
    site.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    site
  end
end
