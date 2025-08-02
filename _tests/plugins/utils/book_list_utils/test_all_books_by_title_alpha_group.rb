# _tests/plugins/utils/book_list_utils/test_all_books_by_title_alpha_group.rb
require_relative '../../../test_helper'
# BookListUtils is loaded by test_helper

class TestBookListUtilsAllBooksByTitleAlphaGroup < Minitest::Test # Renamed class

  def setup
    # --- Book Data for Title Alpha Grouping Tests ---
    @book_apple = create_doc({ 'title' => 'Apple Pie Adventures', 'published' => true, 'date' => Time.now }, '/apa.html')
    @book_a_banana = create_doc({ 'title' => 'A Banana Story', 'published' => true, 'date' => Time.now }, '/abs.html')           # Sorts under B
    @book_the_cherry = create_doc({ 'title' => 'The Cherry Chronicle', 'published' => true, 'date' => Time.now }, '/tcc.html') # Sorts under C
    @book_another_apple = create_doc({ 'title' => 'Another Apple Tale', 'published' => true, 'date' => Time.now }, '/aat.html') # Sorts under A
    @book_aardvark = create_doc({ 'title' => 'Aardvark Antics', 'published' => true, 'date' => Time.now }, '/aa.html')         # Sorts under A
    @book_zebra = create_doc({ 'title' => 'Zebra Zoom', 'published' => true, 'date' => Time.now }, '/zz.html')                 # Sorts under Z
    @book_123go = create_doc({ 'title' => '123 Go!', 'published' => true, 'date' => Time.now }, '/123.html')                   # Sorts under #
    @book_empty_title_sort = create_doc({ 'title' => 'The ', 'published' => true, 'date' => Time.now }, '/the.html')           # Sorts under #
    @book_only_an = create_doc({ 'title' => 'An', 'published' => true, 'date' => Time.now }, '/an.html')                       # Sorts under #
    @unpublished_book = create_doc({ 'title' => 'Unpublished Alpha Book', 'published' => false, 'date' => Time.now }, '/unpub_alpha.html')


    @books_for_alpha_tests = [
      @book_apple, @book_a_banana, @book_the_cherry, @book_another_apple,
      @book_aardvark, @book_zebra, @book_123go, @book_empty_title_sort, @book_only_an,
      @unpublished_book
    ]

    @site = create_site({}, { 'books' => @books_for_alpha_tests })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to call the utility method directly
  def get_alpha_group_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_all_books_by_title_alpha_group(site: site, context: context)
    end
  end

  def test_get_data_for_all_books_by_title_alpha_group_correct_grouping_and_sorting
    data = get_alpha_group_data

    assert_empty data[:log_messages].to_s
    # Expected groups: #, A, B, C, Z (based on the published books in setup)
    assert_equal 5, data[:alpha_groups].size, "Incorrect number of alpha groups"

    # --- Assert Group # (Hash) ---
    # Books: "An" (norm: ""), "The " (norm: ""), "123 Go!" (norm: "123 go!")
    # Order within #: empty sort_titles first (sorted by original title), then "123 go!"
    group_hash = data[:alpha_groups].find { |g| g[:letter] == '#' }
    refute_nil group_hash, "Group '#' missing"
    expected_hash_titles = [@book_only_an.data['title'], @book_empty_title_sort.data['title'], @book_123go.data['title']]
    actual_hash_titles = group_hash[:books].map { |b| b.data['title'] }
    assert_equal expected_hash_titles, actual_hash_titles

    # --- Assert Group A ---
    # Books: Aardvark Antics, Another Apple Tale, Apple Pie Adventures (sorted by normalized title)
    group_a = data[:alpha_groups].find { |g| g[:letter] == 'A' }
    refute_nil group_a, "Group 'A' missing"
    expected_a_titles = [@book_aardvark.data['title'], @book_another_apple.data['title'], @book_apple.data['title']]
    assert_equal expected_a_titles, group_a[:books].map { |b| b.data['title'] }

    # --- Assert Group B ---
    # Book: A Banana Story (normalized: "banana story")
    group_b = data[:alpha_groups].find { |g| g[:letter] == 'B' }
    refute_nil group_b, "Group 'B' missing"
    assert_equal [@book_a_banana.data['title']], group_b[:books].map { |b| b.data['title'] }

    # --- Assert Group C ---
    # Book: The Cherry Chronicle (normalized: "cherry chronicle")
    group_c = data[:alpha_groups].find { |g| g[:letter] == 'C' }
    refute_nil group_c, "Group 'C' missing"
    assert_equal [@book_the_cherry.data['title']], group_c[:books].map { |b| b.data['title'] }

    # --- Assert Group Z ---
    # Book: Zebra Zoom
    group_z = data[:alpha_groups].find { |g| g[:letter] == 'Z' }
    refute_nil group_z, "Group 'Z' missing"
    assert_equal [@book_zebra.data['title']], group_z[:books].map { |b| b.data['title'] }

    # --- Assert Overall Order of Letter Groups ---
    letters_ordered = data[:alpha_groups].map { |g| g[:letter] }
    assert_equal ['#', 'A', 'B', 'C', 'Z'], letters_ordered, "Letter groups are not in # then A-Z order"
  end

  def test_get_data_for_all_books_by_title_alpha_group_ignores_unpublished
    data = get_alpha_group_data
    all_rendered_titles = data[:alpha_groups].flat_map { |ag| ag[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @unpublished_book.data['title']
  end

  def test_get_data_for_all_books_by_title_alpha_group_no_books_logs_info
    site_empty_books = create_site({}, { 'books' => [] }) # Empty collection
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_TITLE_ALPHA_GROUP'] = true # Enable specific logging
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })

    data = get_alpha_group_data(site_empty_books, context_empty_books)
    assert_empty data[:alpha_groups]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_TITLE_ALPHA_GROUP_FAILURE: Reason='No published books found to group by title\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_title_alpha_group_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable general util logging
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_alpha_group_data(site_no_books, context_no_books)
    assert_empty data[:alpha_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_title_alpha_group'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end
end
