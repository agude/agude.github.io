# frozen_string_literal: true

# _tests/plugins/test_display_books_by_year_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_year_tag'
require 'cgi'
require 'time' # For Time.parse

class TestDisplayBooksByYearTag < Minitest::Test
  def setup
    @book_2024_jan = create_doc(
      { 'title' => 'Book Jan 2024', 'date' => Time.parse('2024-01-15') },
      '/b2024a.html'
    )
    # Most recent in 2024
    @book_2024_mar = create_doc(
      { 'title' => 'Book Mar 2024', 'date' => Time.parse('2024-03-10') },
      '/b2024b.html'
    )
    @book_2023_dec = create_doc(
      { 'title' => 'Book Dec 2023', 'date' => Time.parse('2023-12-01') },
      '/b2023a.html'
    )
    @book_2023_jun = create_doc(
      { 'title' => 'Book Jun 2023', 'date' => Time.parse('2023-06-20') },
      '/b2023b.html'
    )
    # create_doc assigns Time.now if date is nil
    @book_no_date = create_doc({ 'title' => 'Book No Date' }, '/bnodate.html')

    @all_books_for_tag = [
      @book_2024_jan, @book_2024_mar, @book_2023_dec, @book_2023_jun, @book_no_date
    ]
    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag })
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_year_page.md' }, '/current_year_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  def render_tag(context = @context)
    output = ''
    BookCardUtils.stub :render, lambda { |book, _ctx|
      "<!-- Card for: #{book.data['title']} (Date: #{book.date.strftime('%Y-%m-%d')}) -->\n"
    } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse('{% display_books_by_year %}').render!(context)
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_year some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  def test_renders_correct_year_headings_and_book_order
    # This test now also checks for the navigation bar.
    # Setup specific books for THIS test with clear dates for deterministic results.
    book_2024_mar = create_doc(
      { 'title' => 'Book Mar 2024', 'date' => Time.parse('2024-03-10') },
      '/b2024b.html'
    )
    book_2024_jan = create_doc(
      { 'title' => 'Book Jan 2024', 'date' => Time.parse('2024-01-15') },
      '/b2024a.html'
    )
    book_2023_dec = create_doc(
      { 'title' => 'Book Dec 2023', 'date' => Time.parse('2023-12-01') },
      '/b2023a.html'
    )

    # Create a specific site and context for this test to avoid side effects.
    test_site = create_site({ 'url' => 'http://example.com' },
                            { 'books' => [book_2024_jan, book_2024_mar, book_2023_dec] })
    test_context = create_context({}, { site: test_site, page: @context.registers[:page] })

    output = render_tag(test_context)

    # --- Assert Jump Links Navigation ---
    assert_match(/<nav class="alpha-jump-links">/, output)
    # Check for links in the correct order (most recent year first) with separator
    expected_nav_links = '<a href="#year-2024">2024</a> &middot; <a href="#year-2023">2023</a>'
    assert_match expected_nav_links, output

    # --- Assert Group 2024 ---
    assert_match %r{<h2 class="book-list-headline" id="year-2024">2024</h2>}, output
    # Books within 2024: Mar (most recent), then Jan
    expected_2024_cards = "<!-- Card for: #{book_2024_mar.data['title']} \\(Date: 2024-03-10\\) -->\\s*" \
                          "<!-- Card for: #{book_2024_jan.data['title']} \\(Date: 2024-01-15\\) -->"
    assert_match %r{id="year-2024">2024</h2>\s*<div class="card-grid">\s*#{expected_2024_cards}\s*</div>}m, output

    # --- Assert Group 2023 ---
    assert_match %r{<h2 class="book-list-headline" id="year-2023">2023</h2>}, output
    expected_2023_cards = "<!-- Card for: #{book_2023_dec.data['title']} \\(Date: 2023-12-01\\) -->"
    assert_match %r{id="year-2023">2023</h2>\s*<div class="card-grid">\s*#{expected_2023_cards}\s*</div>}m, output

    # --- Assert Overall Order of Year Groups ---
    idx_2024 = output.index('id="year-2024"')
    idx_2023 = output.index('id="year-2023"')
    refute_nil idx_2024
    refute_nil idx_2023
    assert idx_2024 < idx_2023, 'Year 2024 group should appear before 2023 group'
  end

  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context(
      {},
      {
        site: site_no_books,
        page: create_doc({ 'path' => 'current_year_page.md' }, '/current_year_page.html')
      }
    )
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_books_by_year %}').render!(context_no_books)
    end
    expected_log_pattern = /<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_year'\s*SourcePage='current_year_page\.md' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_renders_log_message_if_no_published_books_found
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_YEAR_DISPLAY'] = true
    context_empty_books = create_context(
      {},
      {
        site: site_empty_books,
        page: create_doc({ 'path' => 'current_year_page.md' }, '/current_year_page.html')
      }
    )
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_books_by_year %}').render!(context_empty_books)
    end
    expected_log_pattern = /<!-- \[INFO\] ALL_BOOKS_BY_YEAR_DISPLAY_FAILURE: Reason='No published books found to group by year\.'\s*SourcePage='current_year_page\.md' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end
end
