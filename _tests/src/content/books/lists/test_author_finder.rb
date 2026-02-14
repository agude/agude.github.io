# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_author_finder.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/author_finder'

# Tests for Jekyll::Books::Lists::AuthorFinder functionality.
#
# Verifies that the finder correctly displays books for a specific author with series grouping.
class TestBookListAuthorFinder < Minitest::Test
  def setup
    setup_author_names
    setup_test_books
    @site = create_site({}, { 'books' => @books_for_author_tests })
    @context = build_test_context
    @silent_logger_stub = create_silent_logger
  end

  def get_author_data(author_name_filter, site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::Books::Lists::AuthorFinder.new(
        site: site,
        author_name_filter: author_name_filter,
        context: context,
      )
      finder.find
    end
  end

  def test_find_returns_author_alpha_books_correctly_structured
    data = get_author_data(@author_alpha_name)
    assert_author_alpha_structure(data)
  end

  def test_find_is_case_insensitive_for_author_beta
    data = get_author_data('AUTHOR BETA')
    assert_author_beta_structure(data)
  end

  def test_find_ignores_unpublished_books
    data = get_author_data(@author_alpha_name)
    all_rendered_titles = collect_all_rendered_titles(data)
    refute_includes all_rendered_titles, @unpublished_book_by_alpha.data['title']
    assert_expected_alpha_counts(data)
  end

  def test_find_with_nonexistent_author_logs_info
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('NonExistent Author')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    expected_pattern = /BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='No books found for the specified author\.'/
    assert_match expected_pattern, data[:log_messages]
  end

  def test_find_with_nil_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data(nil)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    expected_pattern = /BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil/
    assert_match expected_pattern, data[:log_messages]
  end

  def test_find_with_empty_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('   ')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    expected_pattern = /BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil/
    assert_match expected_pattern, data[:log_messages]
  end

  def test_find_with_missing_books_collection_logs_error
    site_no_books = create_site({}, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })
    data = get_author_data('Any Author', site_no_books, context_no_books)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    expected_pattern = /BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found/
    assert_match expected_pattern, data[:log_messages]
  end

  private

  def setup_author_names
    @author_alpha_name = 'Author Alpha'
    @author_beta_lower_name = 'author beta'
    @author_gamma_name = 'Author Gamma'
  end

  def setup_test_books
    create_alpha_books
    create_beta_books
    create_coauthored_and_other_books
    @books_for_author_tests = [
      @book_alpha_series1_book1,
      @book_alpha_series1_book_half,
      @book_alpha_standalone,
      @book_beta_series2_book1,
      @book_beta_standalone,
      @coauthored_alpha_beta,
      @book_gamma_standalone,
      @unpublished_book_by_alpha,
    ].compact
  end

  def create_alpha_books
    @book_alpha_series1_book1 = create_doc(
      {
        'title' => 'AA Series1 Book1',
        'series' => 'Alpha Series',
        'book_number' => 1,
        'book_authors' => [@author_alpha_name],
        'published' => true,
        'date' => Time.now,
      },
      '/aa_s1b1.html',
    )
    @book_alpha_series1_book_half = create_doc(
      {
        'title' => 'AA Series1 Book0.5',
        'series' => 'Alpha Series',
        'book_number' => 0.5,
        'book_authors' => [@author_alpha_name],
        'published' => true,
        'date' => Time.now,
      },
      '/aa_s1b0_5.html',
    )
    @book_alpha_standalone = create_doc(
      {
        'title' => 'AA Standalone',
        'book_authors' => [@author_alpha_name],
        'published' => true,
        'date' => Time.now,
      },
      '/aa_sa.html',
    )
  end

  def create_beta_books
    @book_beta_series2_book1 = create_doc(
      {
        'title' => 'ab Series2 Book1',
        'series' => 'Beta Series',
        'book_number' => 1,
        'book_authors' => [@author_beta_lower_name],
        'published' => true,
        'date' => Time.now,
      },
      '/ab_s2b1.html',
    )
    @book_beta_standalone = create_doc(
      {
        'title' => 'Standalone by ab',
        'book_authors' => [@author_beta_lower_name],
        'published' => true,
        'date' => Time.now,
      },
      '/ab_sa.html',
    )
  end

  def create_coauthored_and_other_books
    @coauthored_alpha_beta = create_doc(
      {
        'title' => 'Co-authored AA & ab',
        'book_authors' => [@author_alpha_name, @author_beta_lower_name],
        'published' => true,
        'date' => Time.now,
      },
      '/coauth_aa_ab.html',
    )
    @book_gamma_standalone = create_doc(
      {
        'title' => 'Gamma Standalone',
        'book_authors' => [@author_gamma_name],
        'published' => true,
        'date' => Time.now,
      },
      '/gamma_sa.html',
    )
    @unpublished_book_by_alpha = create_doc(
      {
        'title' => 'Unpublished by AA',
        'book_authors' => [@author_alpha_name],
        'published' => false,
        'date' => Time.now,
      },
      '/unpub_aa.html',
    )
  end

  def build_test_context
    page = create_doc({ 'path' => 'current_page.html' }, '/current_page.html')
    create_context({}, { site: @site, page: page })
  end

  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(prefix, msg); end
      def logger.error(prefix, msg); end
      def logger.info(prefix, msg); end
      def logger.debug(prefix, msg); end
    end
  end

  def assert_author_alpha_structure(data)
    assert_equal 2, data[:standalone_books].size
    assert_equal 1, data[:series_groups].size
    alpha_series_group = data[:series_groups].find { |grp| grp[:name] == 'Alpha Series' }
    refute_nil alpha_series_group
    assert_equal 2, alpha_series_group[:books].size
    assert_equal @book_alpha_series1_book_half.data['title'], alpha_series_group[:books][0].data['title']
    assert_equal @book_alpha_series1_book1.data['title'], alpha_series_group[:books][1].data['title']
    assert_empty data[:log_messages].to_s
  end

  def assert_author_beta_structure(data)
    assert_equal 2, data[:standalone_books].size
    assert_equal 1, data[:series_groups].size
    beta_series_group = data[:series_groups].find { |grp| grp[:name] == 'Beta Series' }
    refute_nil beta_series_group
    assert_equal 1, beta_series_group[:books].size
    assert_equal @book_beta_series2_book1.data['title'], beta_series_group[:books][0].data['title']
    assert_empty data[:log_messages].to_s
  end

  def collect_all_rendered_titles(data)
    all_titles = []
    all_titles.concat(data[:standalone_books].compact.map { |book| book.data['title'] }) if data[:standalone_books]
    data[:series_groups]&.compact&.each do |series_group|
      all_titles.concat(series_group[:books].compact.map { |book| book.data['title'] }) if series_group[:books]
    end
    all_titles
  end

  def assert_expected_alpha_counts(data)
    assert_equal 2, data[:standalone_books].size
    assert_equal 1, data[:series_groups].size
    refute_empty data[:series_groups], 'Series groups for Author Alpha should not be empty'
    assert_equal 2, data[:series_groups][0][:books].size
  end
end
