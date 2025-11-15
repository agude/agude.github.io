# _tests/plugins/utils/book_list_utils/test_author_display.rb
require_relative '../../../test_helper'

class TestBookListUtilsAuthorDisplay < Minitest::Test
  def setup
    @author_alpha_name = 'Author Alpha'
    @author_beta_lower_name = 'author beta'
    @author_gamma_name = 'Author Gamma'

    @book_aa_s1_b1 = create_doc(
      { 'title' => 'AA Series1 Book1', 'series' => 'Alpha Series', 'book_number' => 1,
        'book_authors' => [@author_alpha_name], 'published' => true, 'date' => Time.now }, '/aa_s1b1.html'
    )
    @book_aa_s1_b0_5 = create_doc({ 'title' => 'AA Series1 Book0.5', 'series' => 'Alpha Series', 'book_number' => 0.5, 'book_authors' => [@author_alpha_name], 'published' => true, 'date' => Time.now }) # Added for completeness
    @book_aa_standalone = create_doc(
      { 'title' => 'AA Standalone', 'book_authors' => [@author_alpha_name], 'published' => true,
        'date' => Time.now }, '/aa_sa.html'
    )

    @book_ab_s2_b1 = create_doc(
      { 'title' => 'ab Series2 Book1', 'series' => 'Beta Series', 'book_number' => 1,
        'book_authors' => [@author_beta_lower_name], 'published' => true, 'date' => Time.now }, '/ab_s2b1.html'
    )
    @book_ab_standalone = create_doc(
      { 'title' => 'Standalone by ab', 'book_authors' => [@author_beta_lower_name], 'published' => true,
        'date' => Time.now }, '/ab_sa.html'
    )

    @coauthored_aa_ab = create_doc(
      { 'title' => 'Co-authored AA & ab', 'book_authors' => [@author_alpha_name, @author_beta_lower_name],
        'published' => true, 'date' => Time.now }, '/coauth_aa_ab.html'
    )
    @book_gamma_standalone = create_doc(
      { 'title' => 'Gamma Standalone', 'book_authors' => [@author_gamma_name], 'published' => true,
        'date' => Time.now }, '/gamma_sa.html'
    )
    @unpublished_book_by_aa = create_doc(
      { 'title' => 'Unpublished by AA', 'book_authors' => [@author_alpha_name], 'published' => false,
        'date' => Time.now }, '/unpub_aa.html'
    )

    @books_for_author_tests = [
      @book_aa_s1_b1, @book_aa_s1_b0_5, @book_aa_standalone, # Added 0.5
      @book_ab_s2_b1, @book_ab_standalone,
      @coauthored_aa_ab,
      @book_gamma_standalone, @unpublished_book_by_aa
    ].compact
    @site = create_site({}, { 'books' => @books_for_author_tests })
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    @silent_logger_stub = Object.new.tap do |l|
      def l.warn(p, m); end

      def l.error(p, m); end

      def l.info(p, m); end

      def l.debug(p, m); end
    end
  end

  def get_author_data(author_name_filter, site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      BookListUtils.get_data_for_author_display(site: site, author_name_filter: author_name_filter, context: context)
    end
  end

  def test_get_data_for_author_display_found_author_alpha
    data = get_author_data(@author_alpha_name)
    assert_equal 2, data[:standalone_books].size
    # ... (assertions for standalone titles)
    assert_equal 1, data[:series_groups].size
    alpha_series_group = data[:series_groups].find { |g| g[:name] == 'Alpha Series' }
    refute_nil alpha_series_group
    assert_equal 2, alpha_series_group[:books].size # Now 0.5 and 1
    assert_equal @book_aa_s1_b0_5.data['title'], alpha_series_group[:books][0].data['title']
    assert_equal @book_aa_s1_b1.data['title'], alpha_series_group[:books][1].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_found_author_beta_case_insensitive
    data = get_author_data('AUTHOR BETA')
    assert_equal 2, data[:standalone_books].size
    # ... (assertions for standalone titles)
    assert_equal 1, data[:series_groups].size
    beta_series_group = data[:series_groups].find { |g| g[:name] == 'Beta Series' }
    refute_nil beta_series_group
    assert_equal 1, beta_series_group[:books].size
    assert_equal @book_ab_s2_b1.data['title'], beta_series_group[:books][0].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_ignores_unpublished
    data = get_author_data(@author_alpha_name) # Test with Author Alpha who has an unpublished book

    all_rendered_titles = []
    all_rendered_titles.concat(data[:standalone_books].compact.map { |b| b.data['title'] }) if data[:standalone_books]
    data[:series_groups]&.compact&.each do |sg|
      all_rendered_titles.concat(sg[:books].compact.map { |b| b.data['title'] }) if sg && sg[:books]
    end

    refute_includes all_rendered_titles, @unpublished_book_by_aa.data['title']
    # Author Alpha: 2 standalone (apple, zeta), 1 co-authored (AA&ab), 2 series books (0.5, 1)
    # The co-authored book is standalone.
    assert_equal 2, data[:standalone_books].size # AA Standalone, Co-authored AA & ab
    assert_equal 1, data[:series_groups].size
    refute_empty data[:series_groups], 'Series groups for Author Alpha should not be empty'
    assert_equal 2, data[:series_groups][0][:books].size # Books 0.5 and 1
  end

  # ... (other logging tests remain the same) ...
  def test_get_data_for_author_display_author_not_found_logs_info
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('NonExistent Author')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match(/BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='No books found for the specified author\.'/,
                 data[:log_messages])
  end

  def test_get_data_for_author_display_nil_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data(nil)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match(/BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'/,
                 data[:log_messages])
  end

  def test_get_data_for_author_display_empty_filter_logs_warn
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    data = get_author_data('   ')
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match(/BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'/,
                 data[:log_messages])
  end

  def test_get_data_for_author_display_books_collection_missing_logs_error
    site_no_books = create_site({}, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })
    data = get_author_data('Any Author', site_no_books, context_no_books)
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match(/BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'/,
                 data[:log_messages])
  end
end
