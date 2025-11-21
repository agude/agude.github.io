# frozen_string_literal: true

# _tests/plugins/utils/book_list_utils/test_all_books_by_author_display.rb
require_relative '../../../test_helper'
# BookListUtils, FrontMatterUtils are loaded by test_helper

class TestBookListUtilsAllBooksByAuthorDisplay < Minitest::Test
  def setup
    # --- Author Names ---
    @author_a_cap_name = 'Author Alpha'
    @author_b_lower_name = 'author beta' # Lowercase for case-insensitive sort
    @author_c_canonical_name = 'Author Charlie'
    @author_c_pen_name = 'Charles Penotti' # Pen name for Author Charlie

    # --- Author Pages ---
    @page_ac = create_doc(
      { 'title' => @author_c_canonical_name, 'layout' => 'author_page', 'pen_names' => [@author_c_pen_name] },
      '/authors/author-charlie.html'
    )
    # Author Alpha and Beta do not have dedicated pages in this test to ensure the logic
    # falls back to using their given names as canonical when no page is found.

    # --- Book Data ---
    # By Author Alpha (with multiple series and standalone books for sorting tests)
    @book_aa_s1_b1 = create_doc(
      { 'title' => 'AA: Series One, Book 1', 'series' => 'Series One', 'book_number' => 1,
        'book_authors' => [@author_a_cap_name], 'published' => true }, '/aa_s1b1.html'
    )
    @book_aa_s1_b0_5 = create_doc(
      { 'title' => 'AA: Series One, Book 0.5', 'series' => 'Series One', 'book_number' => 0.5,
        'book_authors' => [@author_a_cap_name], 'published' => true }, '/aa_s1b0_5.html'
    )
    @book_aa_standalone_zeta = create_doc(
      { 'title' => 'Zeta Standalone by AA', 'book_authors' => [@author_a_cap_name],
        'published' => true }, '/aa_sa_zeta.html'
    )
    @book_aa_standalone_apple = create_doc(
      { 'title' => 'Apple Standalone by AA', 'book_authors' => [@author_a_cap_name],
        'published' => true }, '/aa_sa_apple.html'
    )

    # By author beta
    @book_ab_standalone = create_doc(
      { 'title' => 'Standalone by ab', 'book_authors' => [@author_b_lower_name], 'published' => true }, '/ab_sa.html'
    )

    # By Author Charlie (canonical and pen name)
    @book_ac_canonical = create_doc(
      { 'title' => 'Book by Author Charlie', 'book_authors' => [@author_c_canonical_name],
        'published' => true }, '/ac_canon.html'
    )
    @book_ac_pen_name = create_doc(
      { 'title' => 'Book by Charles Penotti', 'book_authors' => [@author_c_pen_name],
        'published' => true }, '/ac_pen.html'
    )

    # Co-authored book by Author Alpha and author beta
    @coauthored_aa_ab = create_doc(
      { 'title' => 'Co-authored AA & ab', 'book_authors' => [@author_a_cap_name, @author_b_lower_name],
        'published' => true }, '/coauth_aa_ab.html'
    )

    # Books with malformed or no valid author data
    @book_no_author = create_doc({ 'title' => 'No Author Book', 'book_authors' => [], 'published' => true },
                                 '/no_auth.html')
    @book_nil_author = create_doc({ 'title' => 'Nil Author Book', 'book_authors' => nil, 'published' => true },
                                  '/nil_auth.html')
    @book_empty_author = create_doc({ 'title' => 'Empty Author Book', 'book_authors' => [' '], 'published' => true },
                                    '/empty_auth.html')
    @book_array_empty_author = create_doc(
      { 'title' => 'Array Empty Author Book', 'book_authors' => ['', '  '],
        'published' => true }, '/arr_empty_auth.html'
    )
    @unpublished_book = create_doc(
      { 'title' => 'Unpublished Book by AA', 'book_authors' => [@author_a_cap_name],
        'published' => false }, '/unpub_aa.html'
    )

    @all_books = [
      @book_aa_s1_b1, @book_aa_s1_b0_5, @book_aa_standalone_zeta, @book_aa_standalone_apple,
      @book_ab_standalone, @book_ac_canonical, @book_ac_pen_name, @coauthored_aa_ab,
      @book_no_author, @book_nil_author, @book_empty_author, @book_array_empty_author,
      @unpublished_book
    ]
    @all_pages = [@page_ac]

    @site = create_site({}, { 'books' => @all_books }, @all_pages)
    page_data = { 'path' => 'current_page.html' }
    @context = create_context({}, { site: @site, page: create_doc(page_data, '/current_page.html') })

    @silent_logger_stub = create_silent_logger
  end

  # Helper to create a silent logger stub
  def create_silent_logger
    logger = Object.new
    def logger.warn(_topic, _message); end
    def logger.error(_topic, _message); end
    def logger.info(_topic, _message); end
    def logger.debug(_topic, _message); end
    logger
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
    assert_equal 3, data[:authors_data].size, 'Incorrect number of author groups found'

    # --- Assert Author Order ---
    expected_author_names_ordered = [@author_a_cap_name, @author_b_lower_name, @author_c_canonical_name]
    actual_author_names_ordered = data[:authors_data].map { |ad| ad[:author_name] }
    assert_equal expected_author_names_ordered, actual_author_names_ordered,
                 'Authors not sorted correctly by canonical name'

    # --- Assert Author Alpha's Data ---
    author_a_data = data[:authors_data][0]
    assert_equal @author_a_cap_name, author_a_data[:author_name]
    # Standalone books should be sorted alphabetically
    assert_equal 3, author_a_data[:standalone_books].size, 'Incorrect standalone count for Author Alpha'
    author_a_standalone_titles = author_a_data[:standalone_books].map { |b| b.data['title'] }
    expected_standalone_titles = [
      @book_aa_standalone_apple.data['title'],
      @coauthored_aa_ab.data['title'],
      @book_aa_standalone_zeta.data['title']
    ]
    assert_equal expected_standalone_titles, author_a_standalone_titles,
                 'Standalone books for Author Alpha are not sorted alphabetically'
    # Series books should be sorted by book_number
    assert_equal 1, author_a_data[:series_groups].size, 'Incorrect series group count for Author Alpha'
    series_one_group = author_a_data[:series_groups][0]
    assert_equal 'Series One', series_one_group[:name]
    assert_equal 2, series_one_group[:books].size, 'Incorrect number of books in Series One for Author Alpha'
    assert_equal @book_aa_s1_b0_5.data['title'], series_one_group[:books][0].data['title'],
                 'Series One books not sorted correctly by book_number'
    assert_equal @book_aa_s1_b1.data['title'], series_one_group[:books][1].data['title'],
                 'Series One books not sorted correctly by book_number'

    # --- Assert author beta's Data ---
    author_b_data = data[:authors_data][1]
    assert_equal @author_b_lower_name, author_b_data[:author_name]
    assert_equal 2, author_b_data[:standalone_books].size, 'Incorrect standalone count for author beta'
    author_b_standalone_titles = author_b_data[:standalone_books].map { |b| b.data['title'] }
    assert_includes author_b_standalone_titles, @book_ab_standalone.data['title']
    assert_includes author_b_standalone_titles, @coauthored_aa_ab.data['title']
    assert_empty author_b_data[:series_groups], 'author beta should have no series groups'

    # --- Assert Author Charlie's Data (includes pen name book) ---
    author_c_data = data[:authors_data][2]
    assert_equal @author_c_canonical_name, author_c_data[:author_name]
    assert_equal 2, author_c_data[:standalone_books].size, 'Incorrect standalone count for Author Charlie'
    author_c_standalone_titles = author_c_data[:standalone_books].map { |b| b.data['title'] }
    assert_includes author_c_standalone_titles, @book_ac_canonical.data['title']
    assert_includes author_c_standalone_titles, @book_ac_pen_name.data['title'] # Pen name book
    assert_empty author_c_data[:series_groups], 'Author Charlie should have no series groups'
  end

  def test_get_data_for_all_books_by_author_display_excludes_malformed_and_unpublished
    data = get_all_books_by_author_data

    # Check that no author groups were created for nil or empty string authors
    author_names_present = data[:authors_data].map { |ad| ad[:author_name] }
    refute_includes author_names_present, nil
    refute_includes author_names_present, ''
    refute_includes author_names_present, ' '

    # Check that books with malformed/empty authors or unpublished books are not included anywhere
    all_rendered_book_titles = data[:authors_data].flat_map do |author_data|
      (author_data[:standalone_books] + author_data[:series_groups].flat_map { |sg| sg[:books] })
        .map { |b| b.data['title'] }
    end

    refute_includes all_rendered_book_titles, @book_no_author.data['title']
    refute_includes all_rendered_book_titles, @book_nil_author.data['title']
    refute_includes all_rendered_book_titles, @book_empty_author.data['title']
    refute_includes all_rendered_book_titles, @book_array_empty_author.data['title']
    refute_includes all_rendered_book_titles, @unpublished_book.data['title']
  end

  def test_get_data_for_all_books_by_author_display_logs_if_no_valid_author_books
    site_no_valid_authors = create_site({}, { 'books' => [@book_no_author, @book_nil_author] })
    site_no_valid_authors.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    ctx_page = @context.registers[:page]
    context_no_valid_authors = create_context({}, { site: site_no_valid_authors, page: ctx_page })

    data = get_all_books_by_author_data(site_no_valid_authors, context_no_valid_authors)
    assert_empty data[:authors_data]
    expected_pattern = Regexp.new(
      '<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: ' \
      "Reason='No published books with valid author names found\\.' " \
      "\\s*SourcePage='current_page\\.html' -->"
    )
    assert_match expected_pattern, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_logs_if_books_collection_missing
    site_no_books = create_site({}, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    ctx_page = @context.registers[:page]
    context_no_books = create_context({}, { site: site_no_books, page: ctx_page })

    data = get_all_books_by_author_data(site_no_books, context_no_books)
    assert_empty data[:authors_data]
    expected_pattern = Regexp.new(
      '<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: ' \
      "Reason='Required &#39;books&#39; collection not found in site configuration\\.' " \
      "\\s*filter_type='all_books_by_author'\\s*SourcePage='current_page\\.html' -->"
    )
    assert_match expected_pattern, data[:log_messages]
  end

  def test_get_data_for_all_books_by_author_display_empty_books_collection
    site_empty_books = create_site({}, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    ctx_page = @context.registers[:page]
    context_empty_books = create_context({}, { site: site_empty_books, page: ctx_page })

    data = get_all_books_by_author_data(site_empty_books, context_empty_books)
    assert_empty data[:authors_data]
    expected_pattern = Regexp.new(
      '<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: ' \
      "Reason='No published books with valid author names found\\.' " \
      "\\s*SourcePage='current_page\\.html' -->"
    )
    assert_match expected_pattern, data[:log_messages]
  end
end
