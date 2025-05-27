# _tests/plugins/utils/test_book_list_utils.rb
require_relative '../../test_helper'
require 'minitest/mock' # Required for Minitest::Mock if creating detailed mocks

class TestBookListUtils < Minitest::Test

  def setup
    # --- Books Data ---
    # Series One (Author A) - For numerical sort testing including decimals and multi-digits
    @s1_b0_5_authA = create_doc({ 'title' => 'S1 Book 0.5 (Novella)', 'series' => 'Series One', 'book_number' => 0.5, 'book_author' => 'Author A', 'published' => true }, '/s1b0_5.html')
    @s1_b1_authA   = create_doc({ 'title' => 'S1 Book 1',   'series' => 'Series One', 'book_number' => 1, 'book_author' => 'Author A', 'published' => true }, '/s1b1.html')
    @s1_b2_authA   = create_doc({ 'title' => 'S1 Book 2',   'series' => 'Series One', 'book_number' => '2.0', 'book_author' => 'Author A', 'published' => true }, '/s1b2.html') # String float
    @s1_b2_5_authA = create_doc({ 'title' => 'S1 Book 2.5', 'series' => 'Series One', 'book_number' => 2.5, 'book_author' => 'Author A', 'published' => true }, '/s1b2_5.html')
    @s1_b10_authA  = create_doc({ 'title' => 'S1 Book 10',  'series' => 'Series One', 'book_number' => '10', 'book_author' => 'Author A', 'published' => true }, '/s1b10.html')
    @s1_b_nil_num_authA = create_doc({ 'title' => 'S1 Book NilNum', 'series' => 'Series One', 'book_number' => nil, 'book_author' => 'Author A', 'published' => true }, '/s1b_nil.html')
    @s1_b_str_num_authA = create_doc({ 'title' => 'S1 Book StrNum', 'series' => 'Series One', 'book_number' => 'Part 3', 'book_author' => 'Author A', 'published' => true }, '/s1b_str.html')


    # Series Two (Author B)
    @s2_b1_authB = create_doc({ 'title' => 'S2 Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_author' => 'Author B', 'published' => true }, '/s2b1.html')
    @s2_b1_5_authB = create_doc({ 'title' => 'S2 Book 1.5', 'series' => 'Series Two', 'book_number' => 1.5, 'book_author' => 'Author B', 'published' => true }, '/s2b1_5.html')


    # Standalone Books
    @st_alpha_authA   = create_doc({ 'title' => 'The Standalone Alpha', 'book_author' => 'Author A', 'published' => true }, '/sa.html') # Sorts as "standalone alpha"
    @st_beta_authB    = create_doc({ 'title' => 'Standalone Beta',    'book_author' => 'Author B', 'published' => true }, '/sb.html')    # Sorts as "standalone beta"
    @st_gamma_authA   = create_doc({ 'title' => 'An Earlier Standalone Gamma', 'book_author' => 'Author A', 'published' => true }, '/sg.html') # Sorts as "earlier standalone gamma"

    # Books with problematic author data (but still standalone if no series)
    @book_nil_author   = create_doc({ 'title' => 'Nil Author Book',   'book_author' => nil, 'published' => true }, '/nil_auth.html') # Sorts as "nil author book"
    @book_empty_author = create_doc({ 'title' => 'Empty Author Book', 'book_author' => ' ', 'published' => true }, '/empty_auth.html') # Sorts as "empty author book"

    # Other books
    @book_unpublished_s1_authA = create_doc({ 'title' => 'Unpublished S1 Book', 'series' => 'Series One', 'book_author' => 'Author A', 'published' => false }, '/s1_unpub.html')
    @book_no_series_no_author  = create_doc({ 'title' => 'Generic Book', 'published' => true }, '/gb.html') # Sorts as "generic book"

    @all_books = [
      @s1_b0_5_authA, @s1_b1_authA, @s1_b2_authA, @s1_b2_5_authA, @s1_b10_authA, @s1_b_nil_num_authA, @s1_b_str_num_authA,
      @s2_b1_authB, @s2_b1_5_authB,
      @st_alpha_authA, @st_beta_authB, @st_gamma_authA,
      @book_nil_author, @book_empty_author,
      @book_unpublished_s1_authA, @book_no_series_no_author
    ]

    @site = create_site({}, { 'books' => @all_books })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # --- Tests for _parse_book_number (private method) ---
  def test_parse_book_number_integer
    assert_equal 1.0, BookListUtils.__send__(:_parse_book_number, 1)
  end

  def test_parse_book_number_string_integer
    assert_equal 10.0, BookListUtils.__send__(:_parse_book_number, "10")
  end

  def test_parse_book_number_float
    assert_equal 2.5, BookListUtils.__send__(:_parse_book_number, 2.5)
  end

  def test_parse_book_number_string_float
    assert_equal 3.75, BookListUtils.__send__(:_parse_book_number, "3.75")
  end

  def test_parse_book_number_nil
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, nil)
  end

  def test_parse_book_number_empty_string
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "")
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "   ")
  end

  def test_parse_book_number_non_numeric_string
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "Part 1")
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "One")
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "1.2.3") # Invalid float
  end


  # --- Tests for get_data_for_series_display (Focus on numerical sort with floats) ---
  def test_get_data_for_series_display_numerical_sort_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series One', context: @context)
    end
    assert_equal 'Series One', data[:series_name]
    # Expected order: 0.5, 1, 2.0, 2.5, 10, NilNum, StrNum
    # Total published in Series One: 7
    assert_equal 7, data[:books].size
    assert_equal @s1_b0_5_authA.data['title'], data[:books][0].data['title'] # 0.5
    assert_equal @s1_b1_authA.data['title'],   data[:books][1].data['title'] # 1
    assert_equal @s1_b2_authA.data['title'],   data[:books][2].data['title'] # 2.0
    assert_equal @s1_b2_5_authA.data['title'], data[:books][3].data['title'] # 2.5
    assert_equal @s1_b10_authA.data['title'],  data[:books][4].data['title'] # 10

    last_two_titles = [data[:books][5].data['title'], data[:books][6].data['title']].sort
    expected_last_two = [@s1_b_nil_num_authA.data['title'], @s1_b_str_num_authA.data['title']].sort
    assert_equal expected_last_two, last_two_titles

    assert_empty data[:log_messages].to_s
  end

  # --- Tests for get_data_for_author_display (Focus on numerical sort with floats within series) ---
  def test_get_data_for_author_display_numerical_sort_in_series_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'Author A', context: @context)
    end
    assert_equal 2, data[:standalone_books].size # Order checked in previous test, should be same

    assert_equal 1, data[:series_groups].size
    series_one_group = data[:series_groups].find { |g| g[:name] == 'Series One' }
    refute_nil series_one_group
    assert_equal 7, series_one_group[:books].size
    assert_equal @s1_b0_5_authA.data['title'], series_one_group[:books][0].data['title']
    assert_equal @s1_b1_authA.data['title'],   series_one_group[:books][1].data['title']
    assert_equal @s1_b2_authA.data['title'],   series_one_group[:books][2].data['title']
    assert_equal @s1_b2_5_authA.data['title'], series_one_group[:books][3].data['title']
    assert_equal @s1_b10_authA.data['title'],  series_one_group[:books][4].data['title']
    last_two_in_series = [series_one_group[:books][5].data['title'], series_one_group[:books][6].data['title']].sort
    expected_last_two_in_series = [@s1_b_nil_num_authA.data['title'], @s1_b_str_num_authA.data['title']].sort
    assert_equal expected_last_two_in_series, last_two_in_series

    assert_empty data[:log_messages].to_s
  end

  # --- Tests for get_data_for_all_books_display (Focus on numerical sort with floats within series) ---
  def test_get_data_for_all_books_display_numerical_sort_in_series_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_display(site: @site, context: @context)
    end
    # Standalone books: @st_gamma_authA, @book_empty_author, @book_no_series_no_author, @book_nil_author, @st_alpha_authA, @st_beta_authB
    assert_equal 6, data[:standalone_books].size # Corrected from 4 to 6
    assert_equal @st_gamma_authA.data['title'], data[:standalone_books][0].data['title']           # "An Earlier Standalone Gamma"
    assert_equal @book_empty_author.data['title'], data[:standalone_books][1].data['title']       # "Empty Author Book"
    assert_equal @book_no_series_no_author.data['title'], data[:standalone_books][2].data['title'] # "Generic Book"
    assert_equal @book_nil_author.data['title'], data[:standalone_books][3].data['title']         # "Nil Author Book"
    assert_equal @st_alpha_authA.data['title'], data[:standalone_books][4].data['title']          # "The Standalone Alpha" (sorts as "standalone alpha")
    assert_equal @st_beta_authB.data['title'], data[:standalone_books][5].data['title']           # "Standalone Beta" (sorts as "standalone beta")


    assert_equal 2, data[:series_groups].size
    series_one_group = data[:series_groups].find { |g| g[:name] == 'Series One' }
    series_two_group = data[:series_groups].find { |g| g[:name] == 'Series Two' }

    refute_nil series_one_group
    assert_equal 7, series_one_group[:books].size
    assert_equal @s1_b0_5_authA.data['title'], series_one_group[:books][0].data['title']
    assert_equal @s1_b1_authA.data['title'],   series_one_group[:books][1].data['title']
    assert_equal @s1_b2_authA.data['title'],   series_one_group[:books][2].data['title']
    assert_equal @s1_b2_5_authA.data['title'], series_one_group[:books][3].data['title']
    assert_equal @s1_b10_authA.data['title'],  series_one_group[:books][4].data['title']
    s1_last_two_titles = [series_one_group[:books][5].data['title'], series_one_group[:books][6].data['title']].sort
    s1_expected_last_two = [@s1_b_nil_num_authA.data['title'], @s1_b_str_num_authA.data['title']].sort
    assert_equal s1_expected_last_two, s1_last_two_titles


    refute_nil series_two_group
    assert_equal 2, series_two_group[:books].size
    assert_equal @s2_b1_authB.data['title'], series_two_group[:books][0].data['title'] # 1
    assert_equal @s2_b1_5_authB.data['title'],series_two_group[:books][1].data['title'] # 1.5

    assert_empty data[:log_messages].to_s
  end

  # --- New Tests for get_data_for_all_books_by_author_display (with float sort) ---
  def test_get_data_for_all_books_by_author_display_correct_structure_and_float_sort
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: @site, context: @context)
    end

    assert_empty data[:log_messages].to_s
    assert_equal 2, data[:authors_data].size

    # Author A
    author_a_data = data[:authors_data].find { |ad| ad[:author_name] == 'Author A' }
    refute_nil author_a_data
    assert_equal 2, author_a_data[:standalone_books].size
    assert_equal @st_gamma_authA.data['title'], author_a_data[:standalone_books][0].data['title'] # "An Earlier..."
    assert_equal @st_alpha_authA.data['title'], author_a_data[:standalone_books][1].data['title'] # "The Standalone..."

    assert_equal 1, author_a_data[:series_groups].size
    author_a_series_one = author_a_data[:series_groups].find { |sg| sg[:name] == 'Series One' }
    refute_nil author_a_series_one
    assert_equal 7, author_a_series_one[:books].size
    assert_equal @s1_b0_5_authA.data['title'], author_a_series_one[:books][0].data['title']
    assert_equal @s1_b1_authA.data['title'],   author_a_series_one[:books][1].data['title']
    assert_equal @s1_b2_authA.data['title'],   author_a_series_one[:books][2].data['title']
    assert_equal @s1_b2_5_authA.data['title'], author_a_series_one[:books][3].data['title']
    assert_equal @s1_b10_authA.data['title'],  author_a_series_one[:books][4].data['title']
    author_a_s1_last_two = [author_a_series_one[:books][5].data['title'], author_a_series_one[:books][6].data['title']].sort
    author_a_s1_expected_last_two = [@s1_b_nil_num_authA.data['title'], @s1_b_str_num_authA.data['title']].sort
    assert_equal author_a_s1_expected_last_two, author_a_s1_last_two


    # Author B
    author_b_data = data[:authors_data].find { |ad| ad[:author_name] == 'Author B' }
    refute_nil author_b_data
    assert_equal 1, author_b_data[:standalone_books].size
    assert_equal @st_beta_authB.data['title'], author_b_data[:standalone_books][0].data['title']

    assert_equal 1, author_b_data[:series_groups].size
    author_b_series_two = author_b_data[:series_groups].find { |sg| sg[:name] == 'Series Two' }
    refute_nil author_b_series_two
    assert_equal 2, author_b_series_two[:books].size
    assert_equal @s2_b1_authB.data['title'], author_b_series_two[:books][0].data['title']
    assert_equal @s2_b1_5_authB.data['title'],author_b_series_two[:books][1].data['title']
  end

  # --- Test _structure_books_for_display (Enhanced for float sort) ---
  def test_structure_books_for_display_correct_float_sorting
    books_for_structuring = [
      create_doc({ 'title' => 'Zenith', 'series' => 'Alpha Series', 'book_number' => 2 }, '/z.html'),
      create_doc({ 'title' => 'Apple Standalone', 'published' => true }, '/apple.html'),
      create_doc({ 'title' => 'First Book', 'series' => 'Alpha Series', 'book_number' => 1 }, '/fb.html'),
      create_doc({ 'title' => 'The Banana Standalone', 'published' => true }, '/banana.html'),
      create_doc({ 'title' => 'Beta Book 1', 'series' => 'Beta Series', 'book_number' => 1 }, '/bb1.html'),
      create_doc({ 'title' => 'Alpha Series Book 1.5', 'series' => 'Alpha Series', 'book_number' => '1.5' }, '/asb1_5.html'),
      create_doc({ 'title' => 'Alpha Series Book 10', 'series' => 'Alpha Series', 'book_number' => '10' }, '/asb10.html'),
      create_doc({ 'title' => 'Alpha Series Book NilNum', 'series' => 'Alpha Series', 'book_number' => nil }, '/asb_nil.html'),
      create_doc({ 'title' => 'Alpha Series Book StrNum', 'series' => 'Alpha Series', 'book_number' => 'Chapter IX' }, '/asb_str.html'),
    ]

    structured_data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      structured_data = BookListUtils.__send__(:_structure_books_for_display, books_for_structuring)
    end

    assert_equal 2, structured_data[:standalone_books].size
    assert_equal 'Apple Standalone', structured_data[:standalone_books][0].data['title']
    assert_equal 'The Banana Standalone', structured_data[:standalone_books][1].data['title']


    assert_equal 2, structured_data[:series_groups].size
    alpha_group = structured_data[:series_groups].find { |g| g[:name] == 'Alpha Series' }
    beta_group = structured_data[:series_groups].find { |g| g[:name] == 'Beta Series' }


    refute_nil alpha_group
    assert_equal 'Alpha Series', alpha_group[:name]
    assert_equal 6, alpha_group[:books].size # Corrected from 5 to 6
    assert_equal 'First Book', alpha_group[:books][0].data['title']            # num 1
    assert_equal 'Alpha Series Book 1.5', alpha_group[:books][1].data['title'] # num 1.5
    assert_equal 'Zenith', alpha_group[:books][2].data['title']                # num 2
    assert_equal 'Alpha Series Book 10', alpha_group[:books][3].data['title']  # num 10
    # Order of NilNum and StrNum depends on secondary title sort
    alpha_last_two_titles = [alpha_group[:books][4].data['title'], alpha_group[:books][5].data['title']].sort
    alpha_expected_last_two = ['Alpha Series Book NilNum', 'Alpha Series Book StrNum'].sort
    assert_equal alpha_expected_last_two, alpha_last_two_titles


    refute_nil beta_group # Check Beta group
    assert_equal 'Beta Series', beta_group[:name]
    assert_equal 1, beta_group[:books].size
    assert_equal 'Beta Book 1', beta_group[:books][0].data['title']
  end

  # Keep other tests for logging, empty collections, etc., as they are still relevant.
  def test_get_data_for_series_display_found_case_insensitive
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'series one', context: @context)
    end
    assert_equal 'series one', data[:series_name] # Input filter name is preserved
    assert_equal 7, data[:books].size # All 7 published "Series One" books
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_not_found
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'NonExistent Series', context: @context)
    end
    assert_equal 'NonExistent Series', data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for the specified series\.'\s*SeriesFilter='NonExistent Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_nil_filter
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: nil, context: @context)
    end
    assert_nil data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='N/A'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_empty_filter
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: '  ', context: @context)
    end
    assert_equal '  ', data[:series_name]
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='  '\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_ignores_unpublished
    # @book_unpublished_s1_authA is already in @all_books and part of "Series One"
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series One', context: @context)
    end
    assert_equal 7, data[:books].size # Should only find the 7 published ones
    refute_includes data[:books].map { |b| b.data['title'] }, @book_unpublished_s1_authA.data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_books_collection_missing
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_collection = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: site_no_books, series_name_filter: 'Any Series', context: context_no_books_collection)
    end
    assert_empty data[:books]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='series'\s*series_name='Any Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_author_not_found_logs_info
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'NonExistent Author', context: @context)
    end
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='No books found for the specified author\.'\s*AuthorFilter='NonExistent Author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_nil_filter
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: nil, context: @context)
    end
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilterInput='N/A'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_author_display_books_collection_missing
    site_no_books = create_site({}, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_collection = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: site_no_books, author_name_filter: 'Any Author', context: context_no_books_collection)
    end
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='author'\s*author_name='Any Author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_excludes_nil_empty_authors
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: @site, context: @context)
    end
    all_rendered_book_titles = data[:authors_data].flat_map do |author_data|
      (author_data[:standalone_books] + author_data[:series_groups].flat_map { |sg| sg[:books] }).map { |b| b.data['title'] }
    end
    refute_includes all_rendered_book_titles, @book_nil_author.data['title']
    refute_includes all_rendered_book_titles, @book_empty_author.data['title']
  end

  def test_get_data_for_all_books_by_author_display_logs_if_no_valid_author_books
    site_no_valid_authors = create_site({}, { 'books' => [@book_nil_author, @book_empty_author, @book_no_series_no_author] })
    site_no_valid_authors.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_no_valid_authors = create_context({}, { site: site_no_valid_authors, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: site_no_valid_authors, context: context_no_valid_authors)
    end
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_logs_if_books_collection_missing
    site_no_books_coll = create_site({}, {})
    site_no_books_coll.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_coll = create_context({}, { site: site_no_books_coll, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: site_no_books_coll, context: context_no_books_coll)
    end
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_empty_books_collection
    site_empty_books = create_site({}, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: site_empty_books, context: context_empty_books)
    end
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

end
