# frozen_string_literal: true

# _tests/plugins/test_display_ranked_books_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/src/content/books/tags/display_ranked_books_tag'

# Tests for DisplayRankedBooksTag Liquid tag and its components.
#
# This test suite is organized into four sections:
# 1. Validator tests - Test validation logic directly
# 2. Processor tests - Test data processing logic directly
# 3. Renderer tests - Test HTML generation directly
# 4. Tag integration tests - Test the tag orchestration
class TestDisplayRankedBooksTag < Minitest::Test
  def setup
    @site_dev = create_site({ 'environment' => 'development', 'url' => 'http://example.com' })
    @site_prod = create_site({ 'environment' => 'production', 'url' => 'http://example.com' })

    setup_book_documents
    setup_ranked_lists

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
    @silent_logger_stub = create_silent_logger
  end

  # Helper to set up book documents
  def setup_book_documents
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
  end

  # Helper to set up ranked lists
  def setup_ranked_lists
    @valid_ranked_list = ['Book A (5 Stars)', 'Book B (5 Stars)', 'Book C (4 Stars)', 'Book D (1 Star)']
    @non_existent_title_list = ['Book A (5 Stars)', 'Non Existent Book', 'Book C (4 Stars)']
    @invalid_rating_list = ['Book A (5 Stars)', 'Book Invalid Rating', 'Book C (4 Stars)']
    @monotonic_violation_list = ['Book C (4 Stars)', 'Book A (5 Stars)'] # 4 then 5
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

  def render_tag(list_variable_name, context, logger_override = @silent_logger_stub)
    output = ''
    Jekyll.stub :logger, logger_override do
      output = Liquid::Template.parse("{% display_ranked_books #{list_variable_name} %}").render!(context)
    end
    output
  end

  # ========================================================================
  # Validator Tests - Test validation logic directly
  # ========================================================================

  def test_validator_accepts_valid_book_in_dev_mode
    book_map = build_test_book_map(@all_books_for_map)
    validator = Jekyll::DisplayRankedBooks::Validator.new(book_map, 'test_list', false)

    assert_silent do
      validator.validate('Book A (5 Stars)', 0, @book5a)
      validator.validate('Book B (5 Stars)', 1, @book5b)
    end
  end

  def test_validator_raises_error_for_missing_book_in_dev_mode
    book_map = build_test_book_map(@all_books_for_map)
    validator = Jekyll::DisplayRankedBooks::Validator.new(book_map, 'test_list', false)

    err = assert_raises RuntimeError do
      validator.validate('Non Existent Book', 1, nil)
    end
    assert_match "Title 'Non Existent Book' (position 2 in 'test_list') not found", err.message
  end

  def test_validator_raises_error_for_invalid_rating_in_dev_mode
    book_map = build_test_book_map(@all_books_for_map)
    validator = Jekyll::DisplayRankedBooks::Validator.new(book_map, 'test_list', false)

    err = assert_raises RuntimeError do
      validator.validate('Book Invalid Rating', 1, @book_invalid_rating)
    end
    assert_match "Title 'Book Invalid Rating' (position 2 in 'test_list') has invalid non-integer rating", err.message
  end

  def test_validator_raises_error_for_monotonicity_violation_in_dev_mode
    book_map = build_test_book_map(@all_books_for_map)
    validator = Jekyll::DisplayRankedBooks::Validator.new(book_map, 'test_list', false)

    validator.validate('Book C (4 Stars)', 0, @book4a)

    err = assert_raises RuntimeError do
      validator.validate('Book A (5 Stars)', 1, @book5a)
    end
    assert_match 'Monotonicity violation', err.message
    assert_match "Title 'Book A (5 Stars)' (Rating: 5) at position 2", err.message
  end

  def test_validator_skips_validation_in_production_mode
    book_map = build_test_book_map(@all_books_for_map)
    validator = Jekyll::DisplayRankedBooks::Validator.new(book_map, 'test_list', true)

    # Should not raise even with invalid data in production
    assert_silent do
      validator.validate('Non Existent Book', 1, nil)
    end
  end

  # ========================================================================
  # Processor Tests - Test data processing logic directly
  # ========================================================================

  def test_processor_returns_correct_structure
    processor = Jekyll::DisplayRankedBooks::Processor.new(@context_dev, 'page.ranked_list')
    result = processor.process

    assert_kind_of Hash, result
    assert_kind_of Array, result[:rating_groups]
    assert_kind_of String, result[:log_messages]
  end

  def test_processor_groups_books_by_rating_correctly
    processor = Jekyll::DisplayRankedBooks::Processor.new(@context_dev, 'page.ranked_list')
    result = processor.process

    assert_equal 3, result[:rating_groups].length

    # Check 5-star group
    group5 = result[:rating_groups].find { |g| g[:rating] == 5 }
    assert_equal 2, group5[:books].length
    assert_equal(['Book A (5 Stars)', 'Book B (5 Stars)'], group5[:books].map { |b| b.data['title'] })

    # Check 4-star group
    group4 = result[:rating_groups].find { |g| g[:rating] == 4 }
    assert_equal 1, group4[:books].length
    assert_equal 'Book C (4 Stars)', group4[:books][0].data['title']

    # Check 1-star group
    group1 = result[:rating_groups].find { |g| g[:rating] == 1 }
    assert_equal 1, group1[:books].length
    assert_equal 'Book D (1 Star)', group1[:books][0].data['title']
  end

  def test_processor_returns_empty_groups_for_empty_list
    @context_dev['page']['ranked_list'] = []
    processor = Jekyll::DisplayRankedBooks::Processor.new(@context_dev, 'page.ranked_list')
    result = processor.process

    assert_empty result[:rating_groups]
  end

  def test_processor_skips_missing_book_in_production_mode
    @context_prod['page']['ranked_list'] = @non_existent_title_list
    processor = Jekyll::DisplayRankedBooks::Processor.new(@context_prod, 'page.ranked_list')
    result = nil

    mock_jekyll_logger = Minitest::Mock.new
    expected_console_msg_fragment = 'DISPLAY_RANKED_BOOKS_FAILURE'
    mock_jekyll_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?(expected_console_msg_fragment)
    end

    Jekyll.stub :logger, mock_jekyll_logger do
      result = processor.process
    end

    mock_jekyll_logger.verify
    # In production mode, log_messages should be empty (no HTML comments)
    assert_equal '', result[:log_messages]
    # Should have 2 books (skipping the non-existent one)
    assert_equal(2, result[:rating_groups].sum { |g| g[:books].length })
  end

  def test_processor_skips_invalid_rating_in_production_mode
    @context_prod['page']['ranked_list'] = @invalid_rating_list
    processor = Jekyll::DisplayRankedBooks::Processor.new(@context_prod, 'page.ranked_list')
    result = nil

    mock_jekyll_logger = Minitest::Mock.new
    expected_console_msg_fragment = 'DISPLAY_RANKED_BOOKS_FAILURE'
    mock_jekyll_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?(expected_console_msg_fragment)
    end

    Jekyll.stub :logger, mock_jekyll_logger do
      result = processor.process
    end

    mock_jekyll_logger.verify
    # In production mode, log_messages should be empty (no HTML comments)
    assert_equal '', result[:log_messages]
    # Should have 2 books (skipping the invalid rating one)
    assert_equal(2, result[:rating_groups].sum { |g| g[:books].length })
  end

  # ========================================================================
  # Renderer Tests - Test HTML generation directly
  # ========================================================================

  def test_renderer_returns_empty_string_for_empty_groups
    renderer = Jekyll::DisplayRankedBooks::Renderer.new(@context_dev, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_renderer_generates_correct_html_structure
    rating_groups = [
      { rating: 5, books: [@book5a, @book5b] },
      { rating: 4, books: [@book4a] }
    ]

    renderer = Jekyll::DisplayRankedBooks::Renderer.new(@context_dev, rating_groups)
    output = nil

    BookCardUtils.stub :render, @mock_card_html_generic do
      RatingUtils.stub :render_rating_stars, @mock_stars_html_generic do
        output = renderer.render
      end
    end

    assert_match(/<nav class="alpha-jump-links">/, output)
    assert_match(/<h2 class="book-list-headline" id="rating-5">/, output)
    assert_match(/<h2 class="book-list-headline" id="rating-4">/, output)
    assert_match(/<div class="card-grid">/, output)
    assert_equal 3, output.scan('mock-book-card').count
  end

  def test_renderer_calls_book_card_utils_for_each_book
    rating_groups = [{ rating: 5, books: [@book5a, @book5b, @book4a] }]
    card_render_count = 0

    renderer = Jekyll::DisplayRankedBooks::Renderer.new(@context_dev, rating_groups)
    BookCardUtils.stub :render, lambda { |_book_obj, _ctx|
      card_render_count += 1
      @mock_card_html_generic
    } do
      RatingUtils.stub :render_rating_stars, @mock_stars_html_generic do
        renderer.render
      end
    end

    assert_equal 3, card_render_count
  end

  def test_renderer_generates_correct_navigation_links
    rating_groups = [
      { rating: 5, books: [@book5a] },
      { rating: 4, books: [@book4a] },
      { rating: 1, books: [@book1a] }
    ]

    renderer = Jekyll::DisplayRankedBooks::Renderer.new(@context_dev, rating_groups)
    output = nil

    BookCardUtils.stub :render, @mock_card_html_generic do
      RatingUtils.stub :render_rating_stars, @mock_stars_html_generic do
        output = renderer.render
      end
    end

    assert_match('<a href="#rating-5">5&nbsp;Stars</a>', output)
    assert_match('<a href="#rating-4">4&nbsp;Stars</a>', output)
    assert_match('<a href="#rating-1">1&nbsp;Star</a>', output)
  end

  # ========================================================================
  # Tag Integration Tests - Test orchestration
  # ========================================================================

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

    assert_jump_links_navigation(output)
    assert_rating_group(output, rating: 5, expected_titles: ['Book A (5 Stars)', 'Book B (5 Stars)'])
    assert_rating_group(output, rating: 4, expected_titles: ['Book C (4 Stars)'])
    assert_rating_group(output, rating: 1, expected_titles: ['Book D (1 Star)'])

    assert_equal 4, output.scan('mock-book-card').count
  end

  private

  # Helper to build a test book map
  def build_test_book_map(books)
    books.each_with_object({}) do |book, map|
      next if book.data['published'] == false

      title = book.data['title']
      next unless title && !title.to_s.strip.empty?

      normalized = TextProcessingUtils.normalize_title(title, strip_articles: false)
      map[normalized] = book
    end
  end

  # Helper to assert jump links navigation structure
  def assert_jump_links_navigation(output)
    assert_match(/<nav class="alpha-jump-links">/, output)
    expected_nav_links = '<a href="#rating-5">5&nbsp;Stars</a> &middot; <a href="#rating-4">4&nbsp;Stars</a> &middot; <a href="#rating-1">1&nbsp;Star</a>'
    assert_match expected_nav_links, output
  end

  # Helper to assert a rating group's structure and content
  def assert_rating_group(output, rating:, expected_titles:)
    star_label = rating == 1 ? 'Star' : 'Stars'
    # Assert header
    assert_match %r{<h2 class="book-list-headline" id="rating-#{rating}"><span>Rating #{rating} #{star_label}</span></h2>\s*<div class="card-grid">},
                 output

    # Build regex to match all titles in the group
    titles_pattern = expected_titles.map { |title| Regexp.escape(title) }.join('.*?')
    assert_match %r{id="rating-#{rating}">.*?#{titles_pattern}.*?</div>}m, output
  end
end
