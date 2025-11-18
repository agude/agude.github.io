# _tests/plugins/utils/book_list_utils/test_all_books_display.rb
require_relative '../../../test_helper'
# BookListUtils is loaded by test_helper

# Renamed class
class TestBookListUtilsAllBooksDisplay < Minitest::Test
  def setup
    # --- Book Data for All Books Display Tests ---
    # This setup should include a mix of series books and standalone books
    # to verify overall structuring and sorting.

    # Series One
    @s1_b1 = create_doc(
      { 'title' => 'Series One Book 1', 'series' => 'Series One', 'book_number' => 1, 'published' => true,
        'date' => Time.now }, '/s1b1.html'
    )
    @s1_b0_5 = create_doc(
      { 'title' => 'S1 Book 0.5', 'series' => 'Series One', 'book_number' => 0.5, 'published' => true,
        'date' => Time.now }, '/s1b0_5.html'
    )

    # Series Two
    @s2_b1 = create_doc(
      { 'title' => 'Series Two Book 1', 'series' => 'Series Two', 'book_number' => 1, 'published' => true,
        'date' => Time.now }, '/s2b1.html'
    )

    # Standalone Books
    @st_apple = create_doc({ 'title' => 'Apple Standalone', 'published' => true, 'date' => Time.now }, '/apple.html')
    @st_the_zebra = create_doc({ 'title' => 'The Zebra Standalone', 'published' => true, 'date' => Time.now }, '/zebra.html') # Starts with "The" for sort test
    @st_banana = create_doc({ 'title' => 'Banana Standalone', 'published' => true, 'date' => Time.now }, '/banana.html')

    # Unpublished Book (should be filtered out)
    @unpublished_book = create_doc(
      { 'title' => 'Unpublished Book', 'series' => 'Series One', 'published' => false,
        'date' => Time.now }, '/unpub.html'
    )

    @books_for_all_display_tests = [
      @s1_b1, @s1_b0_5, @s2_b1,
      @st_apple, @st_the_zebra, @st_banana,
      @unpublished_book
    ]

    @site = create_site({}, { 'books' => @books_for_all_display_tests })
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
  def get_all_books_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_all_books_display(site: site, context: context)
    end
  end

  def test_get_data_for_all_books_display_correct_structure_and_sorting
    data = get_all_books_data

    # --- Assert Standalone Books ---
    # Expected order: Apple, Banana, The Zebra (sorts as Zebra)
    assert_equal 3, data[:standalone_books].size, 'Incorrect number of standalone books'
    assert_equal @st_apple.data['title'], data[:standalone_books][0].data['title']
    assert_equal @st_banana.data['title'], data[:standalone_books][1].data['title']
    assert_equal @st_the_zebra.data['title'], data[:standalone_books][2].data['title']

    # --- Assert Series Groups ---
    # Expected series order: Series One, Series Two
    assert_equal 2, data[:series_groups].size, 'Incorrect number of series groups'

    # Series One
    series_one_group = data[:series_groups].find { |g| g[:name] == 'Series One' }
    refute_nil series_one_group, 'Series One group missing'
    assert_equal 2, series_one_group[:books].size, 'Incorrect number of books in Series One'
    assert_equal @s1_b0_5.data['title'], series_one_group[:books][0].data['title'] # Book 0.5
    assert_equal @s1_b1.data['title'], series_one_group[:books][1].data['title']   # Book 1

    # Series Two
    series_two_group = data[:series_groups].find { |g| g[:name] == 'Series Two' }
    refute_nil series_two_group, 'Series Two group missing'
    assert_equal 1, series_two_group[:books].size, 'Incorrect number of books in Series Two'
    assert_equal @s2_b1.data['title'], series_two_group[:books][0].data['title']

    # Ensure overall series group sorting
    assert_equal 'Series One', data[:series_groups][0][:name]
    assert_equal 'Series Two', data[:series_groups][1][:name]

    assert_empty data[:log_messages].to_s, 'Expected no log messages for successful display'
  end

  def test_get_data_for_all_books_display_sorts_series_ignoring_articles
    book_expanse = create_doc({ 'title' => 'Book 1', 'series' => 'The Expanse', 'published' => true }, '/b1.html')
    book_dune = create_doc({ 'title' => 'Book 2', 'series' => 'Dune', 'published' => true }, '/b2.html')
    book_canticle = create_doc({ 'title' => 'Book 3', 'series' => 'A Canticle for Leibowitz', 'published' => true },
                               '/b3.html')

    site_for_series_sort = create_site({}, { 'books' => [book_expanse, book_dune, book_canticle] })
    context_for_series_sort = create_context({}, { site: site_for_series_sort, page: @context.registers[:page] })

    data = get_all_books_data(site_for_series_sort, context_for_series_sort)

    # Expected order: "A Canticle..." (sorts as C), "Dune" (D), "The Expanse" (E)
    expected_series_order = ['A Canticle for Leibowitz', 'Dune', 'The Expanse']
    actual_series_order = data[:series_groups].map { |g| g[:name] }

    assert_equal expected_series_order, actual_series_order, 'Series groups were not sorted correctly ignoring articles'
  end

  def test_get_data_for_all_books_display_ignores_unpublished
    data = get_all_books_data
    all_rendered_titles = data[:standalone_books].map { |b| b.data['title'] } +
                          data[:series_groups].flat_map { |sg| sg[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @unpublished_book.data['title']
  end

  def test_get_data_for_all_books_display_empty_collection_logs_nothing_from_this_method
    # NOTE: _get_all_published_books would return empty.
    # _structure_books_for_display would then process an empty list, returning empty groups
    # and an empty log_messages string. The top-level log for "collection missing" is tested separately.
    site_empty_books = create_site({}, { 'books' => [] })
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })
    data = get_all_books_data(site_empty_books, context_empty_books)

    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_empty data[:log_messages].to_s # This method itself doesn't log for empty, but util might
  end

  def test_get_data_for_all_books_display_books_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_all_books_data(site_no_books, context_no_books)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match(/<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books'\s*SourcePage='current_page\.html' -->/,
                 data[:log_messages])
  end
end
