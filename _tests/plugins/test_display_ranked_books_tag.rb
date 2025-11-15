# _tests/plugins/test_display_ranked_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_ranked_books_tag'

class TestDisplayRankedBooksTag < Minitest::Test
  def setup
    @site_dev = create_site({ 'environment' => 'development', 'url' => 'http://example.com' })
    @site_prod = create_site({ 'environment' => 'production', 'url' => 'http://example.com' })

    @book5a = create_doc({ 'title' => 'Book A (5 Stars)', 'rating' => 5, 'published' => true }, '/b5a.html')
    @book5b = create_doc({ 'title' => 'Book B (5 Stars)', 'rating' => '5', 'published' => true }, '/b5b.html') # Rating as string
    @book4a = create_doc({ 'title' => 'Book C (4 Stars)', 'rating' => 4, 'published' => true }, '/b4a.html')
    @book1a = create_doc({ 'title' => 'Book D (1 Star)', 'rating' => 1, 'published' => true }, '/b1a.html') # For singular test
    @book_invalid_rating = create_doc(
      { 'title' => 'Book Invalid Rating', 'rating' => 'five_stars', 'published' => true }, '/bir.html'
    )
    @book_unlisted = create_doc({ 'title' => 'Book Unlisted In Map', 'rating' => 3, 'published' => true }, '/bul.html') # Not in ranked_list

    @all_books_for_map = [@book5a, @book5b, @book4a, @book1a, @book_invalid_rating, @book_unlisted]
    # Ensure collections are hashes for direct key assignment
    @site_dev.collections = { 'books' => MockCollection.new(@all_books_for_map, 'books') }
    @site_prod.collections = { 'books' => MockCollection.new(@all_books_for_map, 'books') }

    @valid_ranked_list = ['Book A (5 Stars)', 'Book B (5 Stars)', 'Book C (4 Stars)', 'Book D (1 Star)']
    @non_existent_title_list = ['Book A (5 Stars)', 'Non Existent Book', 'Book C (4 Stars)']
    @invalid_rating_list = ['Book A (5 Stars)', 'Book Invalid Rating', 'Book C (4 Stars)']
    @monotonic_violation_list = ['Book C (4 Stars)', 'Book A (5 Stars)'] # 4 then 5

    # Initial page data for context
    # Using .dup for lists to prevent modification across tests if context is reused (though we re-assign directly)
    @page_data_dev = { 'ranked_list' => @valid_ranked_list.dup, 'path' => 'test_page.md' }
    @page_data_prod = { 'ranked_list' => @valid_ranked_list.dup, 'path' => 'test_page.md' }

    @context_dev = create_context(
      { 'page' => @page_data_dev },
      # Ensure page in registers also has data and a URL for any internal Jekyll processes
      { site: @site_dev, page: create_doc(@page_data_dev.merge({ 'url' => '/test_page.html' }), '/test_page.html') }
    )
    @context_prod = create_context(
      { 'page' => @page_data_prod },
      { site: @site_prod, page: create_doc(@page_data_prod.merge({ 'url' => '/test_page.html' }), '/test_page.html') }
    )

    # Enable logging for the tag type for production tests that check console output
    @site_prod.config['plugin_logging']['DISPLAY_RANKED_BOOKS'] = true
    # Set a permissive console log level for production site in tests to ensure our :error messages from the tag get through
    @site_prod.config['plugin_log_level'] = 'debug'

    @mock_card_html_generic = "<div class='mock-book-card'>Rendered Book Card</div>\n"
    @mock_stars_html_generic = '<span>Mock Stars</span>'

    # General silent logger for tests NOT focused on Jekyll.logger output
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  def render_tag(list_variable_name, context, logger_override = @silent_logger_stub)
    output = ''
    Jekyll.stub :logger, logger_override do
      output = Liquid::Template.parse("{% display_ranked_books #{list_variable_name} %}").render!(context)
    end
    output
  end

  # --- Syntax and Basic Runtime Errors ---
  def test_syntax_error_missing_list_variable
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_ranked_books %}')
    end
    assert_match 'A variable name holding the list must be provided', err.message
  end

  def test_runtime_error_if_list_variable_not_an_array
    @context_dev['page']['ranked_list'] = 'not_an_array'
    err = assert_raises RuntimeError do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Input 'page.ranked_list' is not a valid list (Array)", err.message
  end

  def test_runtime_error_if_books_collection_missing
    @context_dev.registers[:site].collections.delete('books')
    err = assert_raises RuntimeError do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Collection 'books' not found", err.message
  end

  def test_renders_empty_if_ranked_list_is_empty
    @context_dev['page']['ranked_list'] = []
    output = render_tag('page.ranked_list', @context_dev)
    assert_equal '', output.strip
  end

  # --- Non-Production Validation (Raise Errors) ---
  def test_dev_mode_raises_error_for_non_existent_title_in_list
    @context_dev['page']['ranked_list'] = @non_existent_title_list
    err = assert_raises RuntimeError do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Title 'Non Existent Book' (position 2 in 'page.ranked_list') not found", err.message
  end

  def test_dev_mode_raises_error_for_invalid_rating_in_list
    @context_dev['page']['ranked_list'] = @invalid_rating_list
    err = assert_raises RuntimeError do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Title 'Book Invalid Rating' (position 2 in 'page.ranked_list') has invalid non-integer rating: '\"five_stars\"'",
                 err.message
  end

  def test_dev_mode_raises_error_for_monotonic_violation
    @context_dev['page']['ranked_list'] = @monotonic_violation_list
    err = assert_raises RuntimeError do
      render_tag('page.ranked_list', @context_dev)
    end
    assert_match "Monotonicity violation in 'page.ranked_list'", err.message
    assert_match "Title 'Book A (5 Stars)' (Rating: 5) at position 2", err.message
    assert_match "cannot appear after \n  Title 'Book C (4 Stars)' (Rating: 4) at position 1", err.message
  end

  # --- Production Mode Logging ---
  def test_prod_mode_logs_error_to_console_for_non_existent_title_and_skips
    @context_prod['page']['ranked_list'] = @non_existent_title_list

    mock_jekyll_logger = Minitest::Mock.new
    # NOTE: PluginLoggerUtils escapes HTML in reason/identifiers for console too.
    expected_console_msg_fragment = "DISPLAY_RANKED_BOOKS_FAILURE: Reason='Book title from ranked list not found in lookup map (Production Mode).' Title='Non Existent Book' ListVariable='page.ranked_list' SourcePage='test_page.md'"
    mock_jekyll_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?(expected_console_msg_fragment)
    end

    output = ''
    # Pass the mock_jekyll_logger to render_tag
    BookCardUtils.stub :render, @mock_card_html_generic do
      RatingUtils.stub :render_rating_stars, @mock_stars_html_generic do
        output = render_tag('page.ranked_list', @context_prod, mock_jekyll_logger)
      end
    end

    mock_jekyll_logger.verify
    refute_match(/<!--.*?DISPLAY_RANKED_BOOKS_FAILURE.*?-->/, output,
                 'HTML comment should NOT be present in production')
    assert_equal 2, output.scan('mock-book-card').count
  end

  def test_prod_mode_logs_error_to_console_for_invalid_rating_and_skips
    @context_prod['page']['ranked_list'] = @invalid_rating_list

    mock_jekyll_logger = Minitest::Mock.new
    # CGI.escapeHTML turns " into &quot;
    expected_rating_identifier_val = CGI.escapeHTML('"five_stars"')
    expected_console_msg_fragment = "DISPLAY_RANKED_BOOKS_FAILURE: Reason='Book has invalid non-integer rating (Production Mode).' Title='Book Invalid Rating' Rating='#{expected_rating_identifier_val}' ListVariable='page.ranked_list' SourcePage='test_page.md'"
    mock_jekyll_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?(expected_console_msg_fragment)
    end

    output = ''
    BookCardUtils.stub :render, @mock_card_html_generic do
      RatingUtils.stub :render_rating_stars, @mock_stars_html_generic do
        output = render_tag('page.ranked_list', @context_prod, mock_jekyll_logger)
      end
    end

    mock_jekyll_logger.verify
    refute_match(/<!--.*?DISPLAY_RANKED_BOOKS_FAILURE.*?-->/, output,
                 'HTML comment should NOT be present in production')
    assert_equal 2, output.scan('mock-book-card').count
  end

  # --- Correct HTML Output ---
  def test_correct_html_structure_and_grouping_for_valid_list
    @context_dev['page']['ranked_list'] = @valid_ranked_list.dup # Ensure it's using the valid list
    output = ''
    BookCardUtils.stub :render, lambda { |book_obj, _ctx|
      "<div class='mock-book-card'>#{CGI.escapeHTML(book_obj.data['title'])}</div>\n"
    } do
      RatingUtils.stub :render_rating_stars, lambda { |rating, _wrapper|
        "<span>Rating #{rating} #{rating == 1 ? 'Star' : 'Stars'}</span>"
      } do
        output = render_tag('page.ranked_list', @context_dev)
      end
    end

    # Assert Navigation Bar
    assert_match(/<nav class="alpha-jump-links">/, output)
    expected_nav_links = '<a href="#rating-5">5&nbsp;Stars</a> &middot; <a href="#rating-4">4&nbsp;Stars</a> &middot; <a href="#rating-1">1&nbsp;Star</a>'
    assert_match expected_nav_links, output

    # Assert Headers
    assert_match %r{<h2 class="book-list-headline" id="rating-5"><span>Rating 5 Stars</span></h2>\s*<div class="card-grid">},
                 output
    assert_match %r{<h2 class="book-list-headline" id="rating-4"><span>Rating 4 Stars</span></h2>\s*<div class="card-grid">},
                 output
    assert_match %r{<h2 class="book-list-headline" id="rating-1"><span>Rating 1 Star</span></h2>\s*<div class="card-grid">},
                 output

    assert_equal 4, output.scan('mock-book-card').count

    # Check content of cards within groups
    assert_match %r{id="rating-5">.*?<div class='mock-book-card'>Book A \(5 Stars\)</div>.*?<div class='mock-book-card'>Book B \(5 Stars\)</div>.*?</div>}m,
                 output
    assert_match %r{id="rating-4">.*?<div class='mock-book-card'>Book C \(4 Stars\)</div>.*?</div>}m, output
    assert_match %r{id="rating-1">.*?<div class='mock-book-card'>Book D \(1 Star\)</div>.*?</div>}m, output
  end
end
