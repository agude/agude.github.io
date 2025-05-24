# _tests/plugins/test_related_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_books_tag' # Load the tag

class TestRelatedBooksTag < Minitest::Test
  # Use the same constant as the tag for the expected number of books
  DEFAULT_MAX_BOOKS = Jekyll::RelatedBooksTag::DEFAULT_MAX_BOOKS

  def setup
    # Basic site configuration for tests
    @site_config_base = {
      'url' => 'http://example.com', # Required by BookCardUtils -> CardDataExtractorUtils -> UrlUtils
      'plugin_logging' => { 'RELATED_BOOKS' => true }, # Enable logging for this tag for prerequisite tests
      'plugin_log_level' => 'debug' # Set a permissive console log level for tests
    }
    # Use a fixed time for consistent date-based filtering and sorting
    @test_time_now = Time.parse("2024-03-15 10:00:00 EST")

    # Mock collection for books. This will be populated by create_book_obj calls.
    @books_collection_mock = MockCollection.new([], 'books')

    # Helper to create mock book document objects.
    # Assigns them to @books_collection_mock for proper association.
    def create_book_obj(title, series, book_num, author, date_offset_days, url_suffix, published = true)
      create_doc(
        {
          'title' => title, 'series' => series, 'book_number' => book_num,
          'book_author' => author, 'published' => published,
          'date' => @test_time_now - (60 * 60 * 24 * date_offset_days), # Date relative to @test_time_now
          'image' => "/images/book_#{url_suffix}.jpg", # Dummy image for BookCardUtils
          'excerpt_output_override' => "#{title} excerpt."   # Dummy excerpt for BookCardUtils
        },
        "/books/#{url_suffix}.html", # Book's URL
        "Content for #{title}",      # Dummy content attribute
        nil,                         # date_str_param (date is already set in data hash)
        @books_collection_mock       # Associate with the books collection
      )
    end

    # --- Comprehensive Test Books Data Setup ---
    # This data allows testing various scenarios: series matches, author matches, recency, filtering.

    # Series A (Author X) - For testing series priority and book_number sorting
    @sA_b1_ax = create_book_obj('Series A Book 1', 'Series A', 1, 'Author X', 10, 'sa_b1_ax')
    @sA_b2_ax = create_book_obj('Series A Book 2', 'Series A', 2, 'Author X', 5,  'sa_b2_ax') # More recent
    @sA_b3_ax = create_book_obj('Series A Book 3', 'Series A', 3, 'Author X', 1,  'sa_b3_ax') # Most recent in series

    # Series B (Author Y) - For testing with a different series and author
    @sB_b1_ay = create_book_obj('Series B Book 1', 'Series B', 1, 'Author Y', 8,  'sb_b1_ay')
    @sB_b2_ay = create_book_obj('Series B Book 2', 'Series B', 2, 'Author Y', 4,  'sb_b2_ay')

    # Other books by Author X (not in Series A) - For testing author fallback
    @other_ax_recent = create_book_obj('Other AX Recent', 'Old Series', 1, 'Author X', 2, 'other_ax_rec')
    @other_ax_old    = create_book_obj('Other AX Old', nil, nil, 'Author X', 20, 'other_ax_old') # Standalone

    # Other books by Author Y (not in Series B) - For testing author fallback
    @other_ay_standalone = create_book_obj('Other AY Standalone', nil, nil, 'Author Y', 7, 'other_ay_sa')

    # General recent books by other authors - For testing recent fallback
    @recent_other_auth1 = create_book_obj('Recent Other Auth 1', 'Series C', 1, 'Author Z', 0.5, 'rec_oth1') # Very recent
    @recent_other_auth2 = create_book_obj('Recent Other Auth 2', nil, nil, 'Author Q', 3, 'rec_oth2')

    # Special case books for filtering tests
    @unpublished_book = create_book_obj('Unpublished Book', 'Series A', 4, 'Author X', 6, 'unpub', false)
    @future_dated_book = create_book_obj('Future Book', 'Series A', 5, 'Author X', -3, 'future')

    # Consolidate all test books into a list for the site's collection
    @all_test_books_for_site = [
      @sA_b1_ax, @sA_b2_ax, @sA_b3_ax,
      @sB_b1_ay, @sB_b2_ay,
      @other_ax_recent, @other_ax_old,
      @other_ay_standalone,
      @recent_other_auth1, @recent_other_auth2,
      @unpublished_book, @future_dated_book
    ]
    # Populate the mock collection with these documents
    @books_collection_mock.docs = @all_test_books_for_site

    # Create a default site instance for tests, including the populated books collection
    @site = create_site(@site_config_base.dup, { 'books' => @books_collection_mock.docs })

    # Define a default "current page" for many tests.
    # This page is part of Series A and by Author X.
    @current_page_sA_aX = create_doc(
      { 'title' => 'Current Page In Series A', 'url' => '/books/current_sa_ax.html',
        'path' => 'current_sa_ax.md', # Used by PluginLoggerUtils for SourcePage
        'series' => 'Series A', 'book_author' => 'Author X',
        'date' => @test_time_now # Current page's date is "now"
    },
    '/books/current_sa_ax.html', "Current page content", nil, @books_collection_mock
    )
    # Create a default Liquid context
    @context = create_context({}, { site: @site, page: @current_page_sA_aX })

    # Create a silent logger stub to suppress console output during most tests,
    # unless a test specifically mocks Jekyll.logger to check its calls.
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper method to render the {% related_books %} tag.
  # It stubs Time.now for consistent date handling, Jekyll.logger to control console output,
  # and BookCardUtils.render to simplify assertions by focusing on which books are selected.
  def render_tag(context = @context, logger_override = @silent_logger_stub)
    output = ""
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, logger_override do
        # Stub BookCardUtils.render to return a simple comment identifying the book.
        # This avoids needing to assert complex card HTML.
        BookCardUtils.stub :render, ->(book_obj, _ctx) { "<!-- Card for: #{book_obj.data['title']} -->\n" } do
          output = Liquid::Template.parse("{% related_books %}").render!(context)
        end
      end
    end
    output
  end

  # Helper method to extract the titles of rendered books from the HTML comments
  # generated by the stubbed BookCardUtils.render.
  def extract_rendered_titles(output_html)
    output_html.scan(/<!-- Card for: (.*?) -->/).flatten
  end

  # --- Prerequisite Failure Tests ---
  # These tests ensure the tag logs errors correctly if essential Jekyll objects are missing.
  def test_logs_error_if_prerequisites_missing
    # Scenario 1: Page object is missing from the context.
    bad_context_no_page = create_context({}, { site: @site }) # Context has site, but no page
    mock_logger_page_missing = Minitest::Mock.new
    # Expect Jekyll.logger.error to be called by PluginLoggerUtils
    mock_logger_page_missing.expect(:error, nil) do |prefix, msg|
      prefix == "PluginLiquid:" && msg.include?("Missing prerequisites: page object")
    end
    output_page_missing = render_tag(bad_context_no_page, mock_logger_page_missing)
    # Assert that the HTML comment (returned by PluginLoggerUtils) indicates the error.
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: page object.*PageURL='N/A'.* -->}, output_page_missing
    mock_logger_page_missing.verify

    # Scenario 2: 'books' collection is missing from the site.
    site_no_books_collection = create_site(@site_config_base.dup, {}) # Site without a 'books' collection
    bad_context_no_books = create_context({}, { site: site_no_books_collection, page: @current_page_sA_aX })
    mock_logger_coll_missing = Minitest::Mock.new
    # Expect error message to account for HTML escaping of single quotes by PluginLoggerUtils.
    mock_logger_coll_missing.expect(:error, nil) do |prefix, msg|
      prefix == "PluginLiquid:" && msg.include?("Missing prerequisites: site.collections[&#39;books&#39;]")
    end
    output_coll_missing = render_tag(bad_context_no_books, mock_logger_coll_missing)
    assert_match %r{<!-- \[ERROR\] RELATED_BOOKS_FAILURE: Reason='Missing prerequisites: site\.collections\[&#39;books&#39;\]\.'\s*PageURL='\/books\/current_sa_ax\.html'\s*SourcePage='current_sa_ax\.md'\s*-->}, output_coll_missing
    mock_logger_coll_missing.verify
  end

  # --- Selection Logic Tests ---
  # These tests verify the prioritization and filtering logic of the tag.

  # Test Priority 1: Books from the same series.
  def test_priority_1_same_series
    # Current page is part of 'Series A'. Expect books from 'Series A', sorted by book_number.
    # A distinct current page is created for this test to ensure it's not part of the initial book pool.
    current_page_for_test = create_doc(
      { 'title' => 'Test Current Book (Series A)', 'url' => '/books/test_current_sa.html',
        'path' => 'test_current_sa.md', 'series' => 'Series A', 'book_author' => 'Author X',
        'date' => @test_time_now },
        '/books/test_current_sa.html', "Content", nil, @books_collection_mock
    )
    # Site's book collection for this test excludes the current_page_for_test.
    temp_site_books = @all_test_books_for_site.dup.reject { |b| b.url == current_page_for_test.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_for_test })

    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)

    # Expected books from Series A, in order of book_number.
    expected_titles = [@sA_b1_ax.data['title'], @sA_b2_ax.data['title'], @sA_b3_ax.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count, "Should render the default max number of books"
    assert_equal expected_titles, rendered_titles, "Books from the same series are not correctly selected or ordered"
  end

  # Test Priority 2: Books by the same author, after series books are considered.
  def test_priority_2_same_author_after_series
    # Current page is in 'Series B' (by Author Y), which has 2 books.
    # The 3rd slot should be filled by another book by 'Author Y' if available and distinct,
    # before falling back to general recent books.
    current_page_sB_aY = create_doc(
      { 'title' => 'Current Page In Series B', 'url' => '/books/current_sb_ay.html',
        'path' => 'current_sb_ay.md', 'series' => 'Series B', 'book_author' => 'Author Y',
        'date' => @test_time_now },
        '/books/current_sb_ay.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.dup.reject { |b| b.url == current_page_sB_aY.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_sB_aY })

    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)

    # Expected: Two books from Series B, then @other_ay_standalone (by Author Y).
    expected_titles = [@sB_b1_ay.data['title'], @sB_b2_ay.data['title'], @other_ay_standalone.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles, "Author fallback prioritization failed"
  end

  # Test Priority 3: Fallback to general recent books.
  def test_priority_3_recent_books_fallback
    # Current page has no series/author affiliations that would yield 3 books from the test set.
    current_page_no_affiliation = create_doc(
      { 'title' => 'Current Standalone Book', 'url' => '/books/current_standalone.html',
        'path' => 'current_standalone.md', 'series' => 'UniqueSeries', 'book_author' => 'UniqueAuthor',
        'date' => @test_time_now },
        '/books/current_standalone.html', "Content", nil, @books_collection_mock
    )
    temp_site_books = @all_test_books_for_site.dup.reject { |b| b.url == current_page_no_affiliation.url }
    temp_site = create_site(@site_config_base.dup, { 'books' => temp_site_books })
    context_for_test = create_context({}, { site: temp_site, page: current_page_no_affiliation })

    output = render_tag(context_for_test)
    rendered_titles = extract_rendered_titles(output)

    # Expected: The 3 most recent books from the general pool, respecting their dates.
    # Sorted by date: @recent_other_auth1 (0.5 days ago), @sA_b3_ax (1 day ago), @other_ax_recent (2 days ago).
    expected_titles = [@recent_other_auth1.data['title'], @sA_b3_ax.data['title'], @other_ax_recent.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles, "Recent books fallback failed or order incorrect"
  end

  # Test that slots are filled correctly even if series and author pools overlap.
  def test_fills_slots_correctly_when_series_and_author_overlap_partially
    # Uses the default @current_page_sA_aX (Series A, Author X).
    # Series A has 3 books by Author X. These should fill all slots.
    output = render_tag(@context)
    rendered_titles = extract_rendered_titles(output)
    expected_titles = [@sA_b1_ax.data['title'], @sA_b2_ax.data['title'], @sA_b3_ax.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count
    assert_equal expected_titles, rendered_titles, "Overlap handling failed; series books should take precedence"
  end

  # Test the specific "World of Trouble" scenario that highlighted the original bug.
  # Ensures the fix correctly falls back to recent books when series/author pools are insufficient.
  def test_world_of_trouble_scenario_fixed
    tlp_series_name = "The Last Policeman"
    bhw_author_name = "Ben H. Winters"

    # Current page: World of Trouble (Book 3 of TLP series by BHW)
    wot_book = create_book_obj('World of Trouble', tlp_series_name, 3, bhw_author_name, 0, 'wot')
    # Other books in the series (older)
    tlp_book = create_book_obj('The Last Policeman', tlp_series_name, 1, bhw_author_name, 365, 'tlp')
    cc_book  = create_book_obj('Countdown City', tlp_series_name, 2, bhw_author_name, 300, 'cc')
    # Recent unrelated books by other authors
    recent_unrelated1 = create_book_obj('Recent Unrelated 1', 'Other Series', 1, 'Other Author', 10, 'ru1')
    recent_unrelated2 = create_book_obj('Recent Unrelated 2', nil, nil, 'Another Author', 5, 'ru2') # Most recent of these two

    books_for_wot_test = [wot_book, tlp_book, cc_book, recent_unrelated1, recent_unrelated2]

    site_for_wot = create_site(@site_config_base.dup, { 'books' => books_for_wot_test })
    context_for_wot = create_context({}, { site: site_for_wot, page: wot_book })

    output = render_tag(context_for_wot)
    rendered_titles = extract_rendered_titles(output)

    # Expected: tlp_book, cc_book (from series, sorted by book_number),
    # then recent_unrelated2 (most recent distinct book from fallback).
    expected_titles = [tlp_book.data['title'], cc_book.data['title'], recent_unrelated2.data['title']]
    assert_equal DEFAULT_MAX_BOOKS, rendered_titles.count, "Should find 3 books for WoT scenario"
    assert_equal expected_titles, rendered_titles, "WoT scenario fix failed to select correct books or order"
  end

  # Test behavior when no valid related books can be found.
  def test_returns_empty_string_if_no_valid_related_books
    # Current page is the only published, past-dated book.
    current_page_alone = create_book_obj('Alone Again', nil,nil,'Solo Author',0,'alone_again')
    # Site contains only this current page and books that should be filtered out.
    site_alone = create_site(@site_config_base.dup, {
      'books' => [current_page_alone, @unpublished_book, @future_dated_book]
    })
    context_alone = create_context({}, { site: site_alone, page: current_page_alone })

    output = render_tag(context_alone)
    assert_equal "", output.strip, "Should return empty string when no related books are found"
  end

  # Test the basic HTML structure of the output.
  def test_html_structure_is_correct
    # Use a context that guarantees some output (e.g., the default context).
    output = render_tag(@context)
    refute_empty output.strip, "Output should not be empty for a page with related books"
    assert_match %r{<aside class="related">}, output, "Outer aside tag missing or incorrect class"
    assert_match %r{<h2>Related Books</h2>}, output, "Header missing or incorrect text"
    assert_match %r{<div class="card-grid">}, output, "Card grid container missing"
    # Check if the correct number of book cards (stubs) are rendered.
    assert_equal DEFAULT_MAX_BOOKS, output.scan(/<!-- Card for:/).count, "Incorrect number of book cards rendered"
    assert_match %r{</div>\s*</aside>}m, output, "Closing tags for card-grid or aside missing/incorrect"
  end

end
