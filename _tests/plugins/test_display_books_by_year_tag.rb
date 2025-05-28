# _tests/plugins/test_display_books_by_year_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_year_tag'
require 'cgi'
require 'time' # For Time.parse

class TestDisplayBooksByYearTag < Minitest::Test
  def setup
    @book_2024_jan = create_doc({ 'title' => 'Book Jan 2024', 'date' => Time.parse("2024-01-15") }, '/b2024a.html')
    @book_2024_mar = create_doc({ 'title' => 'Book Mar 2024', 'date' => Time.parse("2024-03-10") }, '/b2024b.html') # Most recent in 2024
    @book_2023_dec = create_doc({ 'title' => 'Book Dec 2023', 'date' => Time.parse("2023-12-01") }, '/b2023a.html')
    @book_2023_jun = create_doc({ 'title' => 'Book Jun 2023', 'date' => Time.parse("2023-06-20") }, '/b2023b.html')
    @book_no_date = create_doc({ 'title' => 'Book No Date' }, '/bnodate.html') # create_doc assigns Time.now if date is nil

    @all_books_for_tag = [
      @book_2024_jan, @book_2024_mar, @book_2023_dec, @book_2023_jun, @book_no_date
    ]
    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_year_page.md'}, '/current_year_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  def render_tag(context = @context)
    output = ""
    BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} (Date: #{book.date.strftime('%Y-%m-%d')}) -->\n" } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse("{% display_books_by_year %}").render!(context)
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_books_by_year some_arg %}")
    end
    assert_match "This tag does not accept any arguments", err.message
  end

  def test_renders_correct_year_headings_and_book_order
    # Determine year of @book_no_date for assertion
    year_of_no_date_book = @book_no_date.date.year.to_s

    output = render_tag

    # --- Assert Group for current year (if @book_no_date is current year) or 2024 ---
    # Order of year groups: Current Year (if @book_no_date is today), 2024, 2023
    # The actual output order depends on Time.now when tests run for @book_no_date

    # For simplicity, let's check for presence of year groups and internal order.
    # The BookListUtils test will verify the exact order of year groups.

    # Group for @book_no_date's year
    assert_match %r{<h2 class="book-list-headline" id="year-#{year_of_no_date_book}">#{year_of_no_date_book}</h2>}, output
    assert_match %r{id="year-#{year_of_no_date_book}">#{year_of_no_date_book}</h2>\s*<div class="card-grid">\s*<!-- Card for: #{@book_no_date.data['title']} \(Date: #{@book_no_date.date.strftime('%Y-%m-%d')}\) -->\s*</div>}m, output

    # Group 2024
    assert_match %r{<h2 class="book-list-headline" id="year-2024">2024</h2>}, output
    # Books within 2024: Mar (most recent), then Jan
    expected_2024_cards = "<!-- Card for: #{@book_2024_mar.data['title']} \\(Date: 2024-03-10\\) -->\\s*" +
      "<!-- Card for: #{@book_2024_jan.data['title']} \\(Date: 2024-01-15\\) -->"
      assert_match %r{id="year-2024">2024</h2>\s*<div class="card-grid">\s*#{expected_2024_cards}\s*</div>}m, output

        # Group 2023
        assert_match %r{<h2 class="book-list-headline" id="year-2023">2023</h2>}, output
      # Books within 2023: Dec (most recent), then Jun
      expected_2023_cards = "<!-- Card for: #{@book_2023_dec.data['title']} \\(Date: 2023-12-01\\) -->\\s*" +
        "<!-- Card for: #{@book_2023_jun.data['title']} \\(Date: 2023-06-20\\) -->"
        assert_match %r{id="year-2023">2023</h2>\s*<div class="card-grid">\s*#{expected_2023_cards}\s*</div>}m, output

          # Check overall order of year groups (most recent year first)
          # This depends on the year of @book_no_date.
          # If year_of_no_date_book is > "2024", it comes first.
          # If year_of_no_date_book is "2024", it's combined with other 2024 books.
          # If year_of_no_date_book is < "2023", it comes last.
          # The BookListUtils test is better for strict year group ordering.
          # Here, we mainly check that all expected groups are present.
          idx_2024 = output.index('id="year-2024"')
        idx_2023 = output.index('id="year-2023"')
        idx_no_date_year = output.index("id=\"year-#{year_of_no_date_book}\"")

        refute_nil idx_2024
        refute_nil idx_2023
        refute_nil idx_no_date_year

        # Simplified order check: 2024 should come before 2023
        assert idx_2024 < idx_2023, "Year 2024 group should appear before 2023 group"
  end

  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_year_page.md'}, '/current_year_page.html') })
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_year %}").render!(context_no_books)
    end
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_year'\s*SourcePage='current_year_page\.md' -->}, output
    refute_match %r{<h2 class="book-list-headline">}, output
  end

  def test_renders_log_message_if_no_published_books_found
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_YEAR_DISPLAY'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: create_doc({ 'path' => 'current_year_page.md'}, '/current_year_page.html') })
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_year %}").render!(context_empty_books)
    end
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_YEAR_DISPLAY_FAILURE: Reason='No published books found to group by year\.'\s*SourcePage='current_year_page\.md' -->}, output
    refute_match %r{<h2 class="book-list-headline">}, output
  end
end
