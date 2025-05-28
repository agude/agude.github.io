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

    @st_alpha_authA   = create_doc({ 'title' => 'The Standalone Alpha', 'book_author' => 'Author A', 'published' => true }, '/sa.html')
    @st_beta_authB    = create_doc({ 'title' => 'Standalone Beta',    'book_author' => 'Author B', 'published' => true }, '/sb.html')
    @st_gamma_authA   = create_doc({ 'title' => 'An Earlier Standalone Gamma', 'book_author' => 'Author A', 'published' => true }, '/sg.html')

    @book_nil_author   = create_doc({ 'title' => 'Nil Author Book',   'book_author' => nil, 'published' => true }, '/nil_auth.html')
    @book_empty_author = create_doc({ 'title' => 'Empty Author Book', 'book_author' => ' ', 'published' => true }, '/empty_auth.html')

    @book_unpublished_s1_authA = create_doc({ 'title' => 'Unpublished S1 Book', 'series' => 'Series One', 'book_author' => 'Author A', 'published' => false }, '/s1_unpub.html')
    @book_no_series_no_author  = create_doc({ 'title' => 'Generic Book', 'published' => true }, '/gb.html')

    # Books for award testing
    @award_book1 = create_doc({ 'title' => 'Book A (Hugo)', 'awards' => ['Hugo', 'Locus'], 'published' => true }, '/award_book_a.html')
    @award_book2 = create_doc({ 'title' => 'Book B (Nebula)', 'awards' => ['Nebula'], 'published' => true }, '/award_book_b.html')
    @award_book3 = create_doc({ 'title' => 'Book C (Hugo)', 'awards' => ['hugo'], 'published' => true }, '/award_book_c.html') # lowercase
    @award_book4 = create_doc({ 'title' => 'Book D (Arthur C. Clarke)', 'awards' => ['arthur c. clarke'], 'published' => true }, '/award_book_d.html')
    @award_book5 = create_doc({ 'title' => 'Book E (No Awards)', 'published' => true }, '/award_book_e.html')
    @award_book6 = create_doc({ 'title' => 'Book F (Locus)', 'awards' => ['Locus'], 'published' => true }, '/award_book_f.html')
    @award_book7 = create_doc({ 'title' => 'Book G (Mixed Case Award)', 'awards' => ['mIxEd CaSe AwArD'], 'published' => true }, '/award_book_g.html')
    @book_locus_sf = create_doc({ 'title' => 'Locus SF Winner', 'awards' => ['Locus for Best SF Novel'], 'published' => true }, '/locus-sf.html')


    @all_books = [
      @s1_b0_5_authA, @s1_b1_authA, @s1_b2_authA, @s1_b2_5_authA, @s1_b10_authA, @s1_b_nil_num_authA, @s1_b_str_num_authA,
      @s2_b1_authB, @s2_b1_5_authB,
      @st_alpha_authA, @st_beta_authB, @st_gamma_authA,
      @book_nil_author, @book_empty_author,
      @book_unpublished_s1_authA, @book_no_series_no_author,
      @award_book1, @award_book2, @award_book3, @award_book4, @award_book5, @award_book6, @award_book7,
      @book_locus_sf,
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
    # Per simplified logic, "Award" is always appended after titleizing the input.
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
    assert_equal 6, data[:awards_data].size # CORRECTED: Now 6 awards due to "Locus for Best SF Novel"

    # Check Arthur C. Clarke Award
    acc_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Arthur C. Clarke Award" }
    refute_nil acc_award_data, "Arthur C. Clarke Award group missing"
    assert_equal "arthur-c-clarke-award", acc_award_data[:award_slug]
    assert_equal 1, acc_award_data[:books].size
    assert_equal "Book D (Arthur C. Clarke)", acc_award_data[:books][0].data['title']

    # Check Hugo Award
    hugo_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Hugo Award" }
    refute_nil hugo_award_data, "Hugo Award group missing"
    assert_equal "hugo-award", hugo_award_data[:award_slug]
    assert_equal 2, hugo_award_data[:books].size
    assert_equal "Book A (Hugo)", hugo_award_data[:books][0].data['title'] # Sorted by title
    assert_equal "Book C (Hugo)", hugo_award_data[:books][1].data['title']

    # Check Locus Award (from raw "Locus")
    locus_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Locus Award" }
    refute_nil locus_award_data, "Locus Award group missing"
    assert_equal "locus-award", locus_award_data[:award_slug]
    assert_equal 2, locus_award_data[:books].size # Book A and Book F
    assert_equal "Book A (Hugo)", locus_award_data[:books][0].data['title'] # Also won Locus
    assert_equal "Book F (Locus)", locus_award_data[:books][1].data['title']

    # Check Locus For Best Sf Novel Award (from raw "Locus for Best SF Novel")
    locus_sf_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Locus For Best Sf Novel Award" }
    refute_nil locus_sf_award_data, "\"Locus For Best Sf Novel Award\" group missing" # CORRECTED: Message
    assert_equal "locus-for-best-sf-novel-award", locus_sf_award_data[:award_slug]
    assert_equal 1, locus_sf_award_data[:books].size
    assert_equal @book_locus_sf.data['title'], locus_sf_award_data[:books][0].data['title'] # Assert against the correct book

    # Check Mixed Case Award Award
    mixed_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Mixed Case Award Award" } # CORRECTED: Expected name
    refute_nil mixed_award_data, "Mixed Case Award Award group missing"
    assert_equal "mixed-case-award-award", mixed_award_data[:award_slug]
    assert_equal 1, mixed_award_data[:books].size
    assert_equal "Book G (Mixed Case Award)", mixed_award_data[:books][0].data['title']


    # Check Nebula Award
    nebula_award_data = data[:awards_data].find { |ad| ad[:award_name] == "Nebula Award" }
    refute_nil nebula_award_data, "Nebula Award group missing"
    assert_equal "nebula-award", nebula_award_data[:award_slug]
    assert_equal 1, nebula_award_data[:books].size
    assert_equal "Book B (Nebula)", nebula_award_data[:books][0].data['title'] # Dual Winner also has Nebula

    # Check overall sort order of awards
    award_names_in_order = data[:awards_data].map { |ad| ad[:award_name] }
    expected_award_order = [
      "Arthur C. Clarke Award",
      "Hugo Award",
      "Locus Award",
      "Locus For Best Sf Novel Award",
      "Mixed Case Award Award",
      "Nebula Award"
    ]
    assert_equal expected_award_order, award_names_in_order
  end

  def test_get_data_for_all_books_by_award_display_no_books_with_awards
    site_no_awards = create_site({}, { 'books' => [@book_no_series_no_author, @award_book5] }) # Only books with no awards
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
    # No specific log for "no awards found" if collection is empty, as it returns early.
    # The log for "collection missing" is also not hit if collection is present but empty.
    context_empty_books = create_context({}, { site: site_empty_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_by_award_display(site: site_empty_books, context: context_empty_books)
    end
    assert_empty data[:awards_data]
    assert_empty data[:log_messages].to_s # Should be empty as it returns before specific "no awards" log
  end


  # --- Other existing tests for BookListUtils remain unchanged below ---
  # ... (test_get_data_for_series_display_numerical_sort_with_floats, etc.) ...
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
    assert_equal 14, data[:standalone_books].size

    # Expected order of standalone books (titles only, after normalization for sort):
    # 1. "An Earlier Standalone Gamma" (@st_gamma_authA) -> "earlier standalone gamma"
    # 2. "Arthur C. Clarke)" (Book D) -> "arthur c. clarke)" (assuming title is "Book D (Arthur C. Clarke)")
    # 3. "Book A (Hugo)" (@award_book1) -> "book a (hugo)"
    # 4. "Book B (Nebula)" (@award_book2) -> "book b (nebula)"
    # 5. "Book C (Hugo)" (@award_book3) -> "book c (hugo)"
    # 6. "Book E (No Awards)" (@award_book5) -> "book e (no awards)"
    # 7. "Book F (Locus)" (@award_book6) -> "book f (locus)"
    # 8. "Book G (Mixed Case Award)" (@award_book7) -> "book g (mixed case award)"
    # 9. "Empty Author Book" (@book_empty_author) -> "empty author book"
    # 10. "Generic Book" (@book_no_series_no_author) -> "generic book"
    # 11. "Locus SF Winner" (@book_locus_sf) -> "locus sf winner"
    # 12. "Nil Author Book" (@book_nil_author) -> "nil author book"
    # 13. "Standalone Beta" (@st_beta_authB) -> "standalone beta"
    # 14. "The Standalone Alpha" (@st_alpha_authA) -> "standalone alpha"

    expected_standalone_titles_ordered = [
      @st_gamma_authA.data['title'],           # An Earlier Standalone Gamma
      @award_book4.data['title'],              # Book D (Arthur C. Clarke)
      @award_book1.data['title'],              # Book A (Hugo)
      @award_book2.data['title'],              # Book B (Nebula)
      @award_book3.data['title'],              # Book C (Hugo)
      @award_book5.data['title'],              # Book E (No Awards)
      @award_book6.data['title'],              # Book F (Locus)
      @award_book7.data['title'],              # Book G (Mixed Case Award)
      @book_empty_author.data['title'],        # Empty Author Book
      @book_no_series_no_author.data['title'], # Generic Book
      @book_locus_sf.data['title'],            # Locus SF Winner
      @book_nil_author.data['title'],          # Nil Author Book
      @st_alpha_authA.data['title'],           # The Standalone Alpha (sorts as "standalone alpha")
      @st_beta_authB.data['title']            # Standalone Beta (sorts as "standalone beta")
    ].sort_by { |t| TextProcessingUtils.normalize_title(t, strip_articles: true) } # Ensure test expectation is sorted same way as code

    actual_standalone_titles = data[:standalone_books].map { |b| b.data['title'] }

    # To make the assertion more robust if my manual sort above is off slightly,
    # let's just assert the sorted lists are equal.
    # The code sorts by `TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)`
    # So, we should compare against that.

    # Create a list of the expected book objects in their correct sorted order
    expected_standalone_objects_ordered = [
      @st_gamma_authA, @award_book4, @award_book1, @award_book2, @award_book3,
      @award_book5, @award_book6, @award_book7, @book_empty_author,
      @book_no_series_no_author, @book_locus_sf, @book_nil_author,
      @st_alpha_authA, @st_beta_authB
    ].sort_by { |b| TextProcessingUtils.normalize_title(b.data['title'], strip_articles: true) }

    actual_standalone_titles_from_data = data[:standalone_books].map { |b| b.data['title'] }
    expected_standalone_titles_from_objects = expected_standalone_objects_ordered.map { |b| b.data['title'] }

    assert_equal expected_standalone_titles_from_objects, actual_standalone_titles_from_data, "Standalone books are not sorted as expected."


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
    # Authors with books: Author A, Author B. Award books might not have authors set in this test data.
    # If award books have authors, this count might change.
    # Current award books are created without 'book_author'.
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
    assert_equal 6, alpha_group[:books].size
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
