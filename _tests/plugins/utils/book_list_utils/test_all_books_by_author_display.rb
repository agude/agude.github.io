# _tests/plugins/utils/book_list_utils/test_all_books_by_author_display.rb
require_relative '../../../test_helper'
# BookListUtils, FrontMatterUtils are loaded by test_helper

class TestBookListUtilsAllBooksByAuthorDisplay < Minitest::Test

  def setup
    # --- Book Data for All Books By Author Display Tests ---
    @author_a_cap_name = "Author Alpha"
    @author_b_lower_name = "author beta" # Lowercase for case-insensitive sort
    @author_c_cap_name = "Author Charlie"

    # Books by Author Alpha
    @book_aa_s1_b1 = create_doc({ 'title' => 'AA: Series One, Book 1', 'series' => 'Series One', 'book_number' => 1, 'book_authors' => [@author_a_cap_name], 'published' => true, 'date' => Time.now }, '/aa_s1b1.html')
    @book_aa_s1_b0_5 = create_doc({ 'title' => 'AA: Series One, Book 0.5', 'series' => 'Series One', 'book_number' => 0.5, 'book_authors' => [@author_a_cap_name], 'published' => true, 'date' => Time.now }, '/aa_s1b0_5.html')
    @book_aa_standalone_zeta = create_doc({ 'title' => 'Zeta Standalone by AA', 'book_authors' => [@author_a_cap_name], 'published' => true, 'date' => Time.now }, '/aa_sa_zeta.html')
    @book_aa_standalone_apple = create_doc({ 'title' => 'Apple Standalone by AA', 'book_authors' => [@author_a_cap_name], 'published' => true, 'date' => Time.now }, '/aa_sa_apple.html')

    # Books by author beta
    @book_ab_s2_b1 = create_doc({ 'title' => 'ab: Series Two, Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_authors' => [@author_b_lower_name], 'published' => true, 'date' => Time.now }, '/ab_s2b1.html')
    @book_ab_standalone = create_doc({ 'title' => 'Standalone by ab', 'book_authors' => [@author_b_lower_name], 'published' => true, 'date' => Time.now }, '/ab_sa.html')

    # Books by Author Charlie
    @book_ac_s3_b1 = create_doc({ 'title' => 'AC: Series Three, Book 1', 'series' => 'Series Three', 'book_number' => 1, 'book_authors' => [@author_c_cap_name], 'published' => true, 'date' => Time.now }, '/ac_s3b1.html')
    @book_ac_standalone = create_doc({ 'title' => 'Standalone by AC', 'book_authors' => [@author_c_cap_name], 'published' => true, 'date' => Time.now }, '/ac_sa.html')

    # Co-authored book by Author Alpha and author beta
    @coauthored_aa_ab = create_doc({ 'title' => 'Co-authored AA & ab', 'book_authors' => [@author_a_cap_name, @author_b_lower_name], 'published' => true, 'date' => Time.now }, '/coauth_aa_ab.html')


    # Books with no author or problematic author data
    @book_nil_author = create_doc({ 'title' => 'Nil Author Book', 'book_authors' => nil, 'published' => true, 'date' => Time.now }, '/nil_auth.html')
    @book_empty_author = create_doc({ 'title' => 'Empty Author Book', 'book_authors' => [' '], 'published' => true, 'date' => Time.now }, '/empty_auth.html') # String with space
    @book_array_empty_author = create_doc({ 'title' => 'Array Empty Author Book', 'book_authors' => ["", "  "], 'published' => true, 'date' => Time.now }, '/arr_empty_auth.html')
    @unpublished_book = create_doc({ 'title' => 'Unpublished Book by AA', 'book_authors' => [@author_a_cap_name], 'published' => false, 'date' => Time.now }, '/unpub_aa.html')


    @books_for_by_author_tests = [
      @book_aa_s1_b1, @book_aa_s1_b0_5, @book_aa_standalone_zeta, @book_aa_standalone_apple,
      @book_ab_s2_b1, @book_ab_standalone,
      @book_ac_s3_b1, @book_ac_standalone,
      @coauthored_aa_ab, # Added co-authored book
      @book_nil_author, @book_empty_author, @book_array_empty_author, @unpublished_book
    ]

    @site = create_site({}, { 'books' => @books_for_by_author_tests })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  def get_all_books_by_author_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_all_books_by_author_display(site: site, context: context)
    end
  end

  def test_get_data_for_all_books_by_author_display_correct_structure_and_sorting
    data = get_all_books_by_author_data

    assert_empty data[:log_messages].to_s
    # Expected authors: Author Alpha, author beta, Author Charlie (sorted case-insensitively)
    assert_equal 3, data[:authors_data].size, "Incorrect number of authors found"

    # --- Assert Author Order ---
    expected_author_names_ordered = [@author_a_cap_name, @author_b_lower_name, @author_c_cap_name]
    actual_author_names_ordered = data[:authors_data].map { |ad| ad[:author_name] }
    assert_equal expected_author_names_ordered, actual_author_names_ordered, "Authors not sorted correctly (case-insensitively)"

    # --- Assert Author Alpha's Data (@author_a_cap_name) ---
    author_a_data = data[:authors_data][0]
    assert_equal @author_a_cap_name, author_a_data[:author_name]
    # Standalone: Apple, Co-authored, Zeta (sorted alphabetically)
    assert_equal 3, author_a_data[:standalone_books].size, "Incorrect standalone count for Author Alpha"
    author_a_standalone_titles = author_a_data[:standalone_books].map { |b| b.data['title'] }
    assert_includes author_a_standalone_titles, @book_aa_standalone_apple.data['title']
    assert_includes author_a_standalone_titles, @book_aa_standalone_zeta.data['title']
    assert_includes author_a_standalone_titles, @coauthored_aa_ab.data['title']
    assert_equal ["Apple Standalone by AA", "Co-authored AA & ab", "Zeta Standalone by AA"], author_a_standalone_titles.sort_by{|t| TextProcessingUtils.normalize_title(t, strip_articles: true)}


    assert_equal 1, author_a_data[:series_groups].size, "Incorrect series group count for Author Alpha"
    series_one_group_aa = author_a_data[:series_groups].find { |sg| sg[:name] == 'Series One' }
    refute_nil series_one_group_aa, "Series One missing for Author Alpha"
    assert_equal 2, series_one_group_aa[:books].size # 0.5, 1
    assert_equal @book_aa_s1_b0_5.data['title'], series_one_group_aa[:books][0].data['title']
    assert_equal @book_aa_s1_b1.data['title'], series_one_group_aa[:books][1].data['title']

    # --- Assert author beta's Data (@author_b_lower_name) ---
    author_b_data = data[:authors_data][1]
    assert_equal @author_b_lower_name, author_b_data[:author_name]
    # Standalone: Co-authored, Standalone by ab (sorted alphabetically)
    assert_equal 2, author_b_data[:standalone_books].size, "Incorrect standalone count for author beta"
    author_b_standalone_titles = author_b_data[:standalone_books].map { |b| b.data['title'] }
    assert_includes author_b_standalone_titles, @book_ab_standalone.data['title']
    assert_includes author_b_standalone_titles, @coauthored_aa_ab.data['title']
    assert_equal ["Co-authored AA & ab", "Standalone by ab"], author_b_standalone_titles.sort_by{|t| TextProcessingUtils.normalize_title(t, strip_articles: true)}


    assert_equal 1, author_b_data[:series_groups].size, "Incorrect series group count for author beta"
    series_two_group_ab = author_b_data[:series_groups].find { |sg| sg[:name] == 'Series Two' }
    refute_nil series_two_group_ab, "Series Two missing for author beta"
    assert_equal 1, series_two_group_ab[:books].size
    assert_equal @book_ab_s2_b1.data['title'], series_two_group_ab[:books][0].data['title']

    # --- Assert Author Charlie's Data (@author_c_cap_name) ---
    author_c_data = data[:authors_data][2]
    assert_equal @author_c_cap_name, author_c_data[:author_name]
    assert_equal 1, author_c_data[:standalone_books].size
    assert_equal @book_ac_standalone.data['title'], author_c_data[:standalone_books][0].data['title']
    assert_equal 1, author_c_data[:series_groups].size
    series_three_group_ac = author_c_data[:series_groups].find { |sg| sg[:name] == 'Series Three' }
    refute_nil series_three_group_ac, "Series Three missing for Author Charlie"
    assert_equal 1, series_three_group_ac[:books].size
    assert_equal @book_ac_s3_b1.data['title'], series_three_group_ac[:books][0].data['title']
  end

  def test_get_data_for_all_books_by_author_display_excludes_nil_empty_and_unpublished_authors
    data = get_all_books_by_author_data # Uses the main @site setup

    # Check that no author groups were created for nil or empty string authors
    author_names_present = data[:authors_data].map { |ad| ad[:author_name] }
    refute_includes author_names_present, nil
    refute_includes author_names_present, ""
    refute_includes author_names_present, " "

    # Check that books with nil/empty authors are not included under any valid author
    all_rendered_book_titles = data[:authors_data].flat_map do |author_data|
      (author_data[:standalone_books] + author_data[:series_groups].flat_map { |sg| sg[:books] })
        .map { |b| b.data['title'] }
    end

    refute_includes all_rendered_book_titles, @book_nil_author.data['title']
    refute_includes all_rendered_book_titles, @book_empty_author.data['title']
    refute_includes all_rendered_book_titles, @book_array_empty_author.data['title']
    refute_includes all_rendered_book_titles, @unpublished_book.data['title']
  end

  def test_get_data_for_all_books_by_author_display_logs_if_no_valid_author_books
    site_no_valid_authors = create_site({}, { 'books' => [@book_nil_author, @book_empty_author, @book_array_empty_author] })
    site_no_valid_authors.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_no_valid_authors = create_context({}, { site: site_no_valid_authors, page: @context.registers[:page] })

    data = get_all_books_by_author_data(site_no_valid_authors, context_no_valid_authors)
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_logs_if_books_collection_missing
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    data = get_all_books_by_author_data(site_no_books, context_no_books)
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_empty_books_collection
    site_empty_books = create_site({}, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })

    data = get_all_books_by_author_data(site_empty_books, context_empty_books)
    assert_empty data[:authors_data]
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end
end
