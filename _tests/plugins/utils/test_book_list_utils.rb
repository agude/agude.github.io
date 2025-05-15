# _tests/plugins/utils/test_book_list_utils.rb
require_relative '../../test_helper'
require 'minitest/mock' # Required for Minitest::Mock if creating detailed mocks

class TestBookListUtils < Minitest::Test

  def setup
    # --- Books Data ---
    @book1_s1_n1_authA = create_doc({ 'title' => 'Series One Book 1', 'series' => 'Series One', 'book_number' => 1, 'book_author' => 'Author A', 'published' => true }, '/s1b1.html')
    @book2_s1_n2_authA = create_doc({ 'title' => 'Series One Book 2', 'series' => 'Series One', 'book_number' => 2, 'book_author' => 'Author A', 'published' => true }, '/s1b2.html')
    @book3_s2_n1_authB = create_doc({ 'title' => 'Series Two Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_author' => 'Author B', 'published' => true }, '/s2b1.html')
    @book4_s1_n0_authA_unsorted = create_doc({ 'title' => 'A Series One Book 0 (Unsorted Test)', 'series' => 'Series One', 'book_number' => 0, 'book_author' => 'Author A', 'published' => true }, '/s1b0.html') # For testing book_number sort

    @book_standalone1_authA = create_doc({ 'title' => 'The Standalone Alpha', 'book_author' => 'Author A', 'published' => true }, '/sa.html') # No series
    @book_standalone2_authB = create_doc({ 'title' => 'Standalone Beta', 'book_author' => 'Author B', 'published' => true }, '/sb.html')    # No series
    @book_standalone3_authA_late_alpha = create_doc({ 'title' => 'An Earlier Standalone', 'book_author' => 'Author A', 'published' => true }, '/se.html') # For sort-by-title test

    @book_unpublished_s1_authA = create_doc({ 'title' => 'Unpublished Series One Book', 'series' => 'Series One', 'book_author' => 'Author A', 'published' => false }, '/s1_unpub.html')
    @book_no_series_no_author = create_doc({ 'title' => 'Generic Book', 'published' => true }, '/gb.html')

    @all_books = [
      @book1_s1_n1_authA, @book2_s1_n2_authA, @book3_s2_n1_authB, @book4_s1_n0_authA_unsorted,
      @book_standalone1_authA, @book_standalone2_authB, @book_standalone3_authA_late_alpha,
      @book_unpublished_s1_authA, @book_no_series_no_author
    ]

    @site = create_site({}, { 'books' => @all_books })
    # Ensure page has a path for SourcePage identifier
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })


    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  # --- Tests for get_data_for_series_display ---

  def test_get_data_for_series_display_found
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series One', context: @context)
    end
    assert_equal 'Series One', data[:series_name]
    assert_equal 3, data[:books].size
    # Check sorting by book_number (0, 1, 2)
    assert_equal @book4_s1_n0_authA_unsorted.data['title'], data[:books][0].data['title']
    assert_equal @book1_s1_n1_authA.data['title'], data[:books][1].data['title']
    assert_equal @book2_s1_n2_authA.data['title'], data[:books][2].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_found_case_insensitive
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'series one', context: @context)
    end
    assert_equal 'series one', data[:series_name]
    assert_equal 3, data[:books].size
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
    # Add an unpublished book to "Series Two" to ensure it's not picked up
    unpublished_s2 = create_doc({ 'title' => 'Unpublished S2', 'series' => 'Series Two', 'book_number' => 0, 'book_author' => 'Author B', 'published' => false }, '/s2_unpub.html')
    @site.collections['books'].docs << unpublished_s2
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: @site, series_name_filter: 'Series Two', context: @context)
    end
    assert_equal 1, data[:books].size
    assert_equal @book3_s2_n1_authB.data['title'], data[:books][0].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_series_display_books_collection_missing
    site_no_books = create_site({}, {}) # No 'books' collection
    # Enable logging on this specific site instance
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_collection = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_series_display(site: site_no_books, series_name_filter: 'Any Series', context: context_no_books_collection)
    end
    assert_empty data[:books]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='series'\s*series_name='Any Series'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end


  # --- Tests for get_data_for_author_display ---

  def test_get_data_for_author_display_found_author_A
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'Author A', context: @context)
    end
    assert_equal 2, data[:standalone_books].size
    assert_equal @book_standalone3_authA_late_alpha.data['title'], data[:standalone_books][0].data['title']
    assert_equal @book_standalone1_authA.data['title'], data[:standalone_books][1].data['title']

    # Series for Author A (only "Series One")
    assert_equal 1, data[:series_groups].size
    series_one_group = data[:series_groups].find { |g| g[:name] == 'Series One' }
    refute_nil series_one_group
    assert_equal 3, series_one_group[:books].size
    assert_equal @book4_s1_n0_authA_unsorted.data['title'], series_one_group[:books][0].data['title']
    assert_equal @book1_s1_n1_authA.data['title'], series_one_group[:books][1].data['title']
    assert_equal @book2_s1_n2_authA.data['title'], series_one_group[:books][2].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_author_display_found_author_B
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'Author B', context: @context)
    end
    assert_equal 1, data[:standalone_books].size
    assert_equal @book_standalone2_authB.data['title'], data[:standalone_books][0].data['title']

    assert_equal 1, data[:series_groups].size
    series_two_group = data[:series_groups].find { |g| g[:name] == 'Series Two' }
    refute_nil series_two_group
    assert_equal 1, series_two_group[:books].size
    assert_equal @book3_s2_n1_authB.data['title'], series_two_group[:books][0].data['title']
    assert_empty data[:log_messages].to_s
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
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable on this specific site
    context_no_books_collection = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_author_display(site: site_no_books, author_name_filter: 'Any Author', context: context_no_books_collection)
    end
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='author'\s*author_name='Any Author'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end


  # --- Tests for get_data_for_all_books_display ---

  def test_get_data_for_all_books_display
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_display(site: @site, context: @context)
    end

    # Standalone books sort order:
    # 1. "An Earlier Standalone"
    # 2. "Generic Book"
    # 3. "The Standalone Alpha"
    # 4. "Standalone Beta"
    assert_equal 4, data[:standalone_books].size
    assert_equal @book_standalone3_authA_late_alpha.data['title'], data[:standalone_books][0].data['title']
    assert_equal @book_no_series_no_author.data['title'], data[:standalone_books][1].data['title']
    assert_equal @book_standalone1_authA.data['title'], data[:standalone_books][2].data['title']
    assert_equal @book_standalone2_authB.data['title'], data[:standalone_books][3].data['title']

    # Series groups (sorted: "Series One", "Series Two")
    assert_equal 2, data[:series_groups].size
    assert_equal 'Series One', data[:series_groups][0][:name]
    assert_equal 3, data[:series_groups][0][:books].size
    assert_equal @book4_s1_n0_authA_unsorted.data['title'], data[:series_groups][0][:books][0].data['title']
    assert_equal @book1_s1_n1_authA.data['title'], data[:series_groups][0][:books][1].data['title']
    assert_equal @book2_s1_n2_authA.data['title'], data[:series_groups][0][:books][2].data['title']

    assert_equal 'Series Two', data[:series_groups][1][:name]
    assert_equal 1, data[:series_groups][1][:books].size
    assert_equal @book3_s2_n1_authB.data['title'], data[:series_groups][1][:books][0].data['title']
    assert_empty data[:log_messages].to_s
  end

  def test_get_data_for_all_books_display_books_collection_missing
    empty_site = create_site({}, {})
    empty_site.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable on this specific site
    context_no_books_collection = create_context({}, { site: empty_site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = BookListUtils.get_data_for_all_books_display(site: empty_site, context: context_no_books_collection)
    end
    assert_empty data[:standalone_books]
    assert_empty data[:series_groups]
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books'\s*SourcePage='current_page\.html' -->}, data[:log_messages]
  end


  # --- Tests for render_book_groups_html ---

  def test_render_book_groups_html_all_data
    raw_data = nil
    html = ""
    # Stub logger for both data fetching and rendering phases
    Jekyll.stub :logger, @silent_logger_stub do
      raw_data = BookListUtils.get_data_for_author_display(site: @site, author_name_filter: 'Author A', context: @context)
      html = BookListUtils.render_book_groups_html(raw_data, @context)
    end

    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, html
    assert_match %r{<div class="card-grid">.*<cite class="book-title">An Earlier Standalone</cite>.*<cite class="book-title">The Standalone Alpha</cite>.*</div>}m, html, "Standalone books section mismatch or wrong order"

    assert_match %r{<h2 class="series-title">.*<span class="book-series">Series One</span>.*</h2>}, html
    assert_match %r{<div class="card-grid">.*A Series One Book 0 \(Unsorted Test\).*Series One Book 1.*Series One Book 2.*</div>}m, html

    assert_match %r{<div class="book-card">.*<strong><cite class="book-title">An Earlier Standalone</cite></strong>.*</div>}m, html
    assert_match %r{<div class="book-card">.*<strong><cite class="book-title">Series One Book 1</cite></strong>.*</div>}m, html
  end

  def test_render_book_groups_html_only_standalone
    data = {
      standalone_books: [@book_standalone1_authA],
      series_groups: [],
      log_messages: ""
    }
    html = ""
    Jekyll.stub :logger, @silent_logger_stub do
      html = BookListUtils.render_book_groups_html(data, @context)
    end
    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, html
    assert_match %r{The Standalone Alpha}, html
    refute_match %r{<h2 class="series-title">}, html
  end

  def test_render_book_groups_html_only_series
    data = {
      standalone_books: [],
      series_groups: [{ name: 'Series One', books: [@book1_s1_n1_authA] }],
      log_messages: ""
    }
    html = ""
    Jekyll.stub :logger, @silent_logger_stub do
      html = BookListUtils.render_book_groups_html(data, @context)
    end
    refute_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, html
    assert_match %r{<h2 class="series-title">.*Series One.*</h2>}, html
    assert_match %r{Series One Book 1}, html
  end

  def test_render_book_groups_html_empty_data
    data = { standalone_books: [], series_groups: [], log_messages: "" }
    html = ""
    Jekyll.stub :logger, @silent_logger_stub do
      html = BookListUtils.render_book_groups_html(data, @context)
    end
    assert_equal "", html.strip
  end

  def test_render_book_groups_html_with_log_messages
    # Use the main @site and @context for this, and enable logging on @site
    @site.config['plugin_logging']['BOOK_LIST_TEST_LOG'] = true
    log_msg_html = ""
    # Stub logger for the call to LiquidUtils.log_failure
    Jekyll.stub :logger, @silent_logger_stub do
      # Pass the main @context here so PluginLoggerUtils finds the config on @site
      log_msg_html = PluginLoggerUtils.log_liquid_failure(context: @context, tag_type: "BOOK_LIST_TEST_LOG", reason: "Test log", identifiers: {})
    end

    data = {
      standalone_books: [@book_standalone1_authA],
      series_groups: [],
      log_messages: log_msg_html
    }
    html = ""
    # Stub logger for the call to render_book_groups_html (which might call render_book_card, etc.)
    Jekyll.stub :logger, @silent_logger_stub do
      # Pass the main @context here as well for consistency
      html = BookListUtils.render_book_groups_html(data, @context)
    end
    assert_match %r{<!-- \[WARN\] BOOK_LIST_TEST_LOG_FAILURE: Reason='Test log'\s*SourcePage='current_page\.html'.* -->}, html
    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, html
  end

  def test_structure_books_for_display_correct_sorting
    books_for_structuring = [
      create_doc({ 'title' => 'Zenith', 'series' => 'Alpha Series', 'book_number' => 2 }, '/z.html'),
      create_doc({ 'title' => 'Apple Standalone', 'published' => true }, '/apple.html'),
      create_doc({ 'title' => 'First Book', 'series' => 'Alpha Series', 'book_number' => 1 }, '/fb.html'),
      create_doc({ 'title' => 'The Banana Standalone', 'published' => true }, '/banana.html'),
      create_doc({ 'title' => 'Beta Book 1', 'series' => 'Beta Series', 'book_number' => 1 }, '/bb1.html'),
      create_doc({ 'title' => 'Alpha Series Book 3 (No Number)', 'series' => 'Alpha Series' }, '/asb3nn.html'),
    ]

    structured_data = nil
    # _structure_books_for_display might call log_failure if context is passed and an issue occurs
    # However, its primary path doesn't log directly for valid empty inputs.
    # Stubbing here for consistency if any sub-calls within it were to log via Jekyll.logger.
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
    refute_nil beta_group

    assert_equal 'Alpha Series', alpha_group[:name]
    assert_equal 3, alpha_group[:books].size
    assert_equal 'First Book', alpha_group[:books][0].data['title']
    assert_equal 'Zenith', alpha_group[:books][1].data['title']
    assert_equal 'Alpha Series Book 3 (No Number)', alpha_group[:books][2].data['title']

    assert_equal 'Beta Series', beta_group[:name]
    assert_equal 1, beta_group[:books].size
    assert_equal 'Beta Book 1', beta_group[:books][0].data['title']
  end

end
