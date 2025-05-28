# _tests/plugins/utils/test_book_list_utils.rb
require_relative '../../test_helper'
require 'minitest/mock' # Required for Minitest::Mock if creating detailed mocks

class TestBookListUtils < Minitest::Test

  def setup
    # --- Comprehensive Book Data Setup ---
    # This setup provides a diverse set of book objects to test various
    # filtering, sorting, and grouping scenarios within BookListUtils.

    # Series One (Author A) - Includes various book_number formats for sort testing
    @s1_b0_5_authA = create_doc({ 'title' => 'S1 Book 0.5 (Novella)', 'series' => 'Series One', 'book_number' => 0.5, 'book_author' => 'Author A', 'published' => true }, '/s1b0_5.html')
    @s1_b1_authA   = create_doc({ 'title' => 'S1 Book 1',   'series' => 'Series One', 'book_number' => 1, 'book_author' => 'Author A', 'published' => true }, '/s1b1.html')
    @s1_b2_authA   = create_doc({ 'title' => 'S1 Book 2',   'series' => 'Series One', 'book_number' => '2.0', 'book_author' => 'Author A', 'published' => true }, '/s1b2.html') # book_number as string float
    @s1_b2_5_authA = create_doc({ 'title' => 'S1 Book 2.5', 'series' => 'Series One', 'book_number' => 2.5, 'book_author' => 'Author A', 'published' => true }, '/s1b2_5.html')
    @s1_b10_authA  = create_doc({ 'title' => 'S1 Book 10',  'series' => 'Series One', 'book_number' => '10', 'book_author' => 'Author A', 'published' => true }, '/s1b10.html') # book_number as string integer
    @s1_b_nil_num_authA = create_doc({ 'title' => 'S1 Book NilNum', 'series' => 'Series One', 'book_number' => nil, 'book_author' => 'Author A', 'published' => true }, '/s1b_nil.html') # nil book_number
    @s1_b_str_num_authA = create_doc({ 'title' => 'S1 Book StrNum', 'series' => 'Series One', 'book_number' => 'Part 3', 'book_author' => 'Author A', 'published' => true }, '/s1b_str.html') # non-numeric book_number

    # Series Two (Author B)
    @s2_b1_authB = create_doc({ 'title' => 'S2 Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_author' => 'Author B', 'published' => true }, '/s2b1.html')
    @s2_b1_5_authB = create_doc({ 'title' => 'S2 Book 1.5', 'series' => 'Series Two', 'book_number' => 1.5, 'book_author' => 'Author B', 'published' => true }, '/s2b1_5.html')

    # Standalone Books by specific authors
    @st_alpha_authA   = create_doc({ 'title' => 'The Standalone Alpha', 'book_author' => 'Author A', 'published' => true }, '/sa.html')
    @st_beta_authB    = create_doc({ 'title' => 'Standalone Beta',    'book_author' => 'Author B', 'published' => true }, '/sb.html')
    @st_gamma_authA   = create_doc({ 'title' => 'An Earlier Standalone Gamma', 'book_author' => 'Author A', 'published' => true }, '/sg.html')

    # Books with problematic or missing author data (will be standalone if no series)
    @book_nil_author   = create_doc({ 'title' => 'Nil Author Book',   'book_author' => nil, 'published' => true }, '/nil_auth.html')
    @book_empty_author = create_doc({ 'title' => 'Empty Author Book', 'book_author' => ' ', 'published' => true }, '/empty_auth.html')

    # Special case books
    @book_unpublished_s1_authA = create_doc({ 'title' => 'Unpublished S1 Book', 'series' => 'Series One', 'book_author' => 'Author A', 'published' => false }, '/s1_unpub.html')
    @book_no_series_no_author  = create_doc({ 'title' => 'Generic Book', 'published' => true }, '/gb.html') # No series, no author

    # Books for award testing (most do not have series or author specified here for simplicity of award testing)
    @award_book1 = create_doc({ 'title' => 'Book A (Hugo)', 'awards' => ['Hugo', 'Locus'], 'published' => true }, '/award_book_a.html')
    @award_book2 = create_doc({ 'title' => 'Book B (Nebula)', 'awards' => ['Nebula'], 'published' => true }, '/award_book_b.html')
    @award_book3 = create_doc({ 'title' => 'Book C (Hugo)', 'awards' => ['hugo'], 'published' => true }, '/award_book_c.html')
    @award_book4 = create_doc({ 'title' => 'Book D (Arthur C. Clarke)', 'awards' => ['arthur c. clarke'], 'published' => true }, '/award_book_d.html')
    @award_book5 = create_doc({ 'title' => 'Book E (No Awards)', 'published' => true }, '/award_book_e.html')
    @award_book6 = create_doc({ 'title' => 'Book F (Locus)', 'awards' => ['Locus'], 'published' => true }, '/award_book_f.html')
    @award_book7 = create_doc({ 'title' => 'Book G (Mixed Case Award)', 'awards' => ['mIxEd CaSe AwArD'], 'published' => true }, '/award_book_g.html')
    @book_locus_sf = create_doc({ 'title' => 'Locus SF Winner', 'awards' => ['Locus for Best SF Novel'], 'published' => true }, '/locus-sf.html')

    # Collection of all books for site setup
    @all_books = [
      @s1_b0_5_authA, @s1_b1_authA, @s1_b2_authA, @s1_b2_5_authA, @s1_b10_authA, @s1_b_nil_num_authA, @s1_b_str_num_authA,
      @s2_b1_authB, @s2_b1_5_authB,
      @st_alpha_authA, @st_beta_authB, @st_gamma_authA,
      @book_nil_author, @book_empty_author,
      @book_unpublished_s1_authA, # This will be filtered out by _get_all_published_books
      @book_no_series_no_author,
      @award_book1, @award_book2, @award_book3, @award_book4, @award_book5, @award_book6, @award_book7,
      @book_locus_sf
    ]

    @site = create_site({}, { 'books' => @all_books })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    # General silent logger for tests not focused on console output
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
    assert_equal Float::INFINITY, BookListUtils.__send__(:_parse_book_number, "1.2.3") # Invalid float format for Float()
  end

  # --- Tests for _format_award_display_name (private method) ---
  def test_format_award_display_name_simple
    assert_equal "Hugo Award", BookListUtils.__send__(:_format_award_display_name, "hugo")
    assert_equal "Nebula Award", BookListUtils.__send__(:_format_award_display_name, "Nebula")
  end

  def test_format_award_display_name_multi_word
    assert_equal "British Fantasy Award", BookListUtils.__send__(:_format_award_display_name, "british fantasy")
  end

  def test_format_award_display_name_with_initialism
    assert_equal "Arthur C. Clarke Award", BookListUtils.__send__(:_format_award_display_name, "arthur c. clarke")
    assert_equal "Philip K. Dick Award", BookListUtils.__send__(:_format_award_display_name, "philip k. dick")
  end

  def test_format_award_display_name_already_contains_award_word_is_titleized_and_appended
    assert_equal "Locus Award For Best Sf Novel Award", BookListUtils.__send__(:_format_award_display_name, "Locus Award for Best SF Novel")
    assert_equal "Hugo Award Award", BookListUtils.__send__(:_format_award_display_name, "hugo award")
  end

  def test_format_award_display_name_empty_or_nil
    assert_equal "", BookListUtils.__send__(:_format_award_display_name, nil)
    assert_equal "", BookListUtils.__send__(:_format_award_display_name, "  ")
  end

  def test_format_award_display_name_mixed_case_input
    assert_equal "Mixed Case Award Award", BookListUtils.__send__(:_format_award_display_name, "mIxEd CaSe AwArD")
  end


  # --- Tests for get_data_for_all_books_by_award_display ---
  def test_get_data_for_all_books_by_award_display_correct_grouping_and_sorting
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_award_display(site: @site, context: @context)
    end

    assert_empty data[:log_messages].to_s
    # Expected awards (after formatting and sorting):
    # 1. Arthur C. Clarke Award
    # 2. Hugo Award
    # 3. Locus Award
    # 4. Locus For Best Sf Novel Award
    # 5. Mixed Case Award Award (from "mIxEd CaSe AwArD")
    # 6. Nebula Award
    assert_equal 6, data[:awards_data].size

    acc_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Arthur C. Clarke Award" }
    refute_nil acc_award_data, "Arthur C. Clarke Award group missing"
    assert_equal "arthur-c-clarke-award", acc_award_data[:award_slug]
    assert_equal 1, acc_award_data[:books].size
    assert_equal "Book D (Arthur C. Clarke)", acc_award_data[:books][0].data['title']

    hugo_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Hugo Award" }
    refute_nil hugo_award_data, "Hugo Award group missing"
    assert_equal "hugo-award", hugo_award_data[:award_slug]
    assert_equal 2, hugo_award_data[:books].size
    assert_equal ["Book A (Hugo)", "Book C (Hugo)"], hugo_award_data[:books].map { |b| b.data['title'] }.sort

    locus_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Locus Award" }
    refute_nil locus_award_data, "Locus Award group missing"
    assert_equal "locus-award", locus_award_data[:award_slug]
    assert_equal 2, locus_award_data[:books].size
    assert_equal ["Book A (Hugo)", "Book F (Locus)"], locus_award_data[:books].map { |b| b.data['title'] }.sort

    locus_sf_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Locus For Best Sf Novel Award" }
    refute_nil locus_sf_award_data, "\"Locus For Best Sf Novel Award\" group missing"
    assert_equal "locus-for-best-sf-novel-award", locus_sf_award_data[:award_slug]
    assert_equal 1, locus_sf_award_data[:books].size
    assert_equal @book_locus_sf.data['title'], locus_sf_award_data[:books][0].data['title']

    mixed_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Mixed Case Award Award" }
    refute_nil mixed_award_data, "Mixed Case Award Award group missing"
    assert_equal "mixed-case-award-award", mixed_award_data[:award_slug]
    assert_equal 1, mixed_award_data[:books].size
    assert_equal "Book G (Mixed Case Award)", mixed_award_data[:books][0].data['title']

    nebula_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Nebula Award" }
    refute_nil nebula_award_data, "Nebula Award group missing"
    assert_equal "nebula-award", nebula_award_data[:award_slug]
    assert_equal 1, nebula_award_data[:books].size
    assert_equal "Book B (Nebula)", nebula_award_data[:books][0].data['title']

    award_names_in_order = data[:awards_data].map { |ad| ad[:award_name] }
    expected_award_order = [
      "Arthur C. Clarke Award", "Hugo Award", "Locus Award",
      "Locus For Best Sf Novel Award", "Mixed Case Award Award", "Nebula Award"
    ]
    assert_equal expected_award_order, award_names_in_order
  end

  def test_get_data_for_all_books_by_award_display_no_books_with_awards
    site_no_awards = create_site({}, { 'books' => [@book_no_series_no_author, @award_book5] })
    site_no_awards.config['plugin_logging']['ALL_BOOKS_BY_AWARD_DISPLAY'] = true
    context_no_awards = create_context({}, { site: site_no_awards, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_award_display(site: site_no_awards, context: context_no_awards)
    end
    assert_empty data[:awards_data]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AWARD_DISPLAY_FAILURE: Reason='No books with awards found\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_award_display_books_collection_missing
    site_no_books_coll = create_site({}, {})
    site_no_books_coll.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_coll = create_context({}, { site: site_no_books_coll, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_award_display(site: site_no_books_coll, context: context_no_books_coll)
    end
    assert_empty data[:awards_data]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_award'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_award_display_empty_book_collection
    site_empty_books = create_site({}, { 'books' => [] })
    context_empty_books = create_context({}, { site: site_empty_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_award_display(site: site_empty_books, context: context_empty_books)
    end
    assert_empty data[:awards_data]
    assert_empty data[:log_messages].to_s
  end

  # --- Tests for get_data_for_all_books_by_title_alpha_group ---
  def test_get_data_for_all_books_by_title_alpha_group_correct_grouping_and_sorting
    # Setup specific books for this test to ensure clarity and avoid interference from @all_books
    book_apple = create_doc({ 'title' => 'Apple Pie Adventures' }, '/apa.html')
    book_a_banana = create_doc({ 'title' => 'A Banana Story' }, '/abs.html') # Sorts under B
    book_the_cherry = create_doc({ 'title' => 'The Cherry Chronicle' }, '/tcc.html') # Sorts under C
    book_another_apple = create_doc({ 'title' => 'Another Apple Tale' }, '/aat.html') # Sorts under A
    book_aardvark = create_doc({ 'title' => 'Aardvark Antics' }, '/aa.html') # Sorts under A
    book_zebra = create_doc({ 'title' => 'Zebra Zoom' }, '/zz.html') # Sorts under Z
    book_123go = create_doc({ 'title' => '123 Go!' }, '/123.html') # Sorts under #
    book_empty_title_sort = create_doc({ 'title' => 'The ' }, '/the.html') # Sorts under # (empty after normalize)
    book_only_an = create_doc({ 'title' => 'An' }, '/an.html') # Sorts under #

    current_books_for_alpha_test = [
      book_apple, book_a_banana, book_the_cherry, book_another_apple,
      book_aardvark, book_zebra, book_123go, book_empty_title_sort, book_only_an
    ]
    temp_site = create_site({}, { 'books' => current_books_for_alpha_test })
    temp_context = create_context({}, { site: temp_site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_title_alpha_group(site: temp_site, context: temp_context)
    end

    assert_empty data[:log_messages].to_s
    assert_equal 5, data[:alpha_groups].size # A, B, C, Z, #

    group_a = data[:alpha_groups].find { |g| g[:letter] == 'A' }
    refute_nil group_a, "Group 'A' missing"
    assert_equal ['Aardvark Antics', 'Another Apple Tale', 'Apple Pie Adventures'], group_a[:books].map { |b| b.data['title'] }

    group_b = data[:alpha_groups].find { |g| g[:letter] == 'B' }
    refute_nil group_b, "Group 'B' missing"
    assert_equal ['A Banana Story'], group_b[:books].map { |b| b.data['title'] }

    group_c = data[:alpha_groups].find { |g| g[:letter] == 'C' }
    refute_nil group_c, "Group 'C' missing"
    assert_equal ['The Cherry Chronicle'], group_c[:books].map { |b| b.data['title'] }

    group_z = data[:alpha_groups].find { |g| g[:letter] == 'Z' }
    refute_nil group_z, "Group 'Z' missing"
    assert_equal ['Zebra Zoom'], group_z[:books].map { |b| b.data['title'] }

    group_hash = data[:alpha_groups].find { |g| g[:letter] == '#' }
    refute_nil group_hash
    # With secondary sort by original title (lowercase) for identical sort_titles (""):
    # "An" (an) comes before "The " (the )
    # "123 Go!" (123 go!) comes after empty strings.
    expected_hash_titles = [book_only_an.data['title'], book_empty_title_sort.data['title'], book_123go.data['title']]
    actual_hash_titles = group_hash[:books].map { |b| b.data['title'] }
    assert_equal expected_hash_titles, actual_hash_titles

    letters_ordered = data[:alpha_groups].map { |g| g[:letter] }
    assert_equal ['A', 'B', 'C', 'Z', '#'], letters_ordered
  end

  def test_get_data_for_all_books_by_title_alpha_group_no_books
    temp_site = create_site({}, { 'books' => [] })
    temp_site.config['plugin_logging']['ALL_BOOKS_BY_TITLE_ALPHA_GROUP'] = true
    temp_context = create_context({}, { site: temp_site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_title_alpha_group(site: temp_site, context: temp_context)
    end
    assert_empty data[:alpha_groups]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_TITLE_ALPHA_GROUP_FAILURE: Reason='No published books found to group by title\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_title_alpha_group_collection_missing
    temp_site = create_site({}, {}) # No 'books' collection
    temp_site.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    temp_context = create_context({}, { site: temp_site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_title_alpha_group(site: temp_site, context: temp_context)
    end
    assert_empty data[:alpha_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_title_alpha_group'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  # --- Existing Tests for other BookListUtils methods ---
  # These tests use the comprehensive @all_books from setup.

  def test_get_data_for_series_display_numerical_sort_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series One', context: @context)
    end
    assert_equal 'Series One', data[:series_name]
    assert_equal 7, data[:books].size # s1_b0_5, s1_b1, s1_b2, s1_b2_5, s1_b10, s1_b_nil_num, s1_b_str_num
    assert_equal @s1_b0_5_authA.data['title'], data[:books][0].data['title']
    assert_equal @s1_b1_authA.data['title'],   data[:books][1].data['title']
    assert_equal @s1_b2_authA.data['title'],   data[:books][2].data['title']
    assert_equal @s1_b2_5_authA.data['title'], data[:books][3].data['title']
    assert_equal @s1_b10_authA.data['title'],  data[:books][4].data['title']
    last_two_titles = [data[:books][5].data['title'], data[:books][6].data['title']].sort
    expected_last_two = [@s1_b_nil_num_authA.data['title'], @s1_b_str_num_authA.data['title']].sort
    assert_equal expected_last_two, last_two_titles
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_numerical_sort_in_series_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'Author A', context: @context)
    end
    assert_equal 2, data[:standalone_books].size # @st_gamma_authA, @st_alpha_authA
    assert_equal @st_gamma_authA.data['title'], data[:standalone_books][0].data['title']
    assert_equal @st_alpha_authA.data['title'], data[:standalone_books][1].data['title']

    assert_equal 1, data[:series_groups].size
    series_one_group = data[:series_groups].find { |g| g[:name] == 'Series One' }
    refute_nil series_one_group
    assert_equal 7, series_one_group[:books].size # All Series One books by Author A
    # Order already asserted in test_get_data_for_series_display_numerical_sort_with_floats
    assert_equal @s1_b0_5_authA.data['title'], series_one_group[:books][0].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_all_books_display_numerical_sort_in_series_with_floats
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_display(site: @site, context: @context)
    end
    # All published books that don't have a 'series' are standalone.
    # This includes @st_alpha_authA, @st_beta_authB, @st_gamma_authA,
    # @book_nil_author, @book_empty_author, @book_no_series_no_author,
    # and all award books (assuming they don't have series in their test setup).
    assert_equal 14, data[:standalone_books].size

    expected_standalone_objects_ordered = [
      @st_gamma_authA, @award_book4, @award_book1, @award_book2, @award_book3,
      @award_book5, @award_book6, @award_book7, @book_empty_author,
      @book_no_series_no_author, @book_locus_sf, @book_nil_author,
      @st_alpha_authA, @st_beta_authB
    ].sort_by { |b| TextProcessingUtils.normalize_title(b.data['title'], strip_articles: true) }
    actual_standalone_titles_from_data = data[:standalone_books].map { |b| b.data['title'] }
    expected_standalone_titles_from_objects = expected_standalone_objects_ordered.map { |b| b.data['title'] }
    assert_equal expected_standalone_titles_from_objects, actual_standalone_titles_from_data, "Standalone books are not sorted as expected."

    assert_equal 2, data[:series_groups].size # Series One, Series Two
    # Detailed content of series groups already tested elsewhere.
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_all_books_by_author_display_correct_structure_and_float_sort
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_author_display(site: @site, context: @context)
    end
    assert_empty data[:log_messages].to_s
    # Only Author A and Author B have books with author specified in this setup.
    # Award books in @all_books currently don't have 'book_author'.
    assert_equal 2, data[:authors_data].size

    author_a_data = data[:authors_data].find { |ad| ad[:author_name] == 'Author A' }
    refute_nil author_a_data
    assert_equal 2, author_a_data[:standalone_books].size
    assert_equal @st_gamma_authA.data['title'], author_a_data[:standalone_books][0].data['title']
    assert_equal @st_alpha_authA.data['title'], author_a_data[:standalone_books][1].data['title']
    assert_equal 1, author_a_data[:series_groups].size # Series One
    # ... detailed checks for series books under Author A already covered ...

    author_b_data = data[:authors_data].find { |ad| ad[:author_name] == 'Author B' }
    refute_nil author_b_data
    assert_equal 1, author_b_data[:standalone_books].size
    assert_equal @st_beta_authB.data['title'], author_b_data[:standalone_books][0].data['title']
    assert_equal 1, author_b_data[:series_groups].size # Series Two
    # ... detailed checks for series books under Author B ...
  end

  def test_structure_books_for_display_correct_float_sorting
    # This test uses a locally defined books_for_structuring array,
    # so it's isolated from the main @all_books setup.
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
    refute_nil alpha_group
    assert_equal 6, alpha_group[:books].size
    assert_equal 'First Book', alpha_group[:books][0].data['title']
    assert_equal 'Alpha Series Book 1.5', alpha_group[:books][1].data['title']
    assert_equal 'Zenith', alpha_group[:books][2].data['title']
    assert_equal 'Alpha Series Book 10', alpha_group[:books][3].data['title']
    alpha_last_two_titles = [alpha_group[:books][4].data['title'], alpha_group[:books][5].data['title']].sort
    alpha_expected_last_two = ['Alpha Series Book NilNum', 'Alpha Series Book StrNum'].sort
    assert_equal alpha_expected_last_two, alpha_last_two_titles
    # ... (beta_group assertions remain the same)
  end

  # --- Logging and Edge Case Tests (largely unchanged, verify they still make sense) ---
  def test_get_data_for_series_display_found_case_insensitive
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'series one', context: @context)
    end
    assert_equal 'series one', data[:series_name]
    assert_equal 7, data[:books].size
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_not_found
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'NonExistent Series', context: @context)
    end
    assert_empty data[:books]
    assert_match %r{<!-- \[INFO\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='No books found for the specified series\.'\s*SeriesFilter='NonExistent Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_nil_filter
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: nil, context: @context)
    end
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='N/A'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_empty_filter
    @site.config['plugin_logging']['BOOK_LIST_SERIES_DISPLAY'] = true
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: '  ', context: @context)
    end
    assert_empty data[:books]
    assert_match %r{<!-- \[WARN\] BOOK_LIST_SERIES_DISPLAY_FAILURE: Reason='Series name filter was empty or nil\.'\s*SeriesFilterInput='  '\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_series_display_ignores_unpublished
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series One', context: @context)
    end
    assert_equal 7, data[:books].size
    refute_includes data[:books].map { |b| b.data['title'] }, @book_unpublished_s1_authA.data['title']
  end

  def test_get_data_for_series_display_books_collection_missing
    site_no_books = create_site({}, {})
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
    # Site with books that have nil, empty, or no author field.
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
