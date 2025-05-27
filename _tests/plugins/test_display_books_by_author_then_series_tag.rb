# _tests/plugins/test_display_books_by_author_then_series_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_author_then_series_tag'
require 'cgi' # For CGI.escapeHTML

class TestDisplayBooksByAuthorThenSeriesTag < Minitest::Test

  def setup
    # --- Mock Book Data ---
    @author_a_name = "Author A"
    @author_b_name = "Author B: The Sequel" # Author name with colon and space for slug testing

    # Author A
    @book_a_s1_b1 = create_doc({ 'title' => 'Author A: Series One, Book 1', 'series' => 'Series One', 'book_number' => 1, 'book_author' => @author_a_name }, '/a/s1b1.html')
    @book_a_s1_b2 = create_doc({ 'title' => 'Author A: Series One, Book 2', 'series' => 'Series One', 'book_number' => 2, 'book_author' => @author_a_name }, '/a/s1b2.html')
    @book_a_standalone = create_doc({ 'title' => 'Author A: Standalone', 'book_author' => @author_a_name }, '/a/sa.html')

    # Author B
    @book_b_s2_b1 = create_doc({ 'title' => 'Author B: Series Two, Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_author' => @author_b_name }, '/b/s2b1.html')
    @book_b_standalone = create_doc({ 'title' => 'Author B: Standalone', 'book_author' => @author_b_name }, '/b/sb.html')

    # Author C (No books, to test empty author section) - or rather, author with no *published* books if we add that filter
    # For now, assume Author C has no books in the collection.

    # Book with no author (should be filtered out by get_data_for_all_books_by_author_display)
    @book_no_author = create_doc({ 'title' => 'Book With No Author', 'series' => 'Some Series' }, '/no_auth.html')

    @all_books_for_tag_test = [
      @book_a_s1_b1, @book_a_s1_b2, @book_a_standalone,
      @book_b_s2_b1, @book_b_standalone,
      @book_no_author
    ]

    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag_test })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_tag_page.md'}, '/current_tag_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
    end
  end

  # Helper to mimic the tag's slugify for test predictions
  def simple_slugify(text)
    return "" if text.nil?
    text.to_s.downcase.strip
      .gsub(/\s+/, '-')
      .gsub(/[^\w-]+/, '')
      .gsub(/--+/, '-')
      .gsub(/^-+|-+$/, '')
  end

  def render_tag(context = @context)
    output = ""
    BookListUtils.stub :render_book_groups_html, ->(data, _ctx, series_heading_level: 2) {
      group_html = ""
      data[:series_groups]&.each do |sg|
        group_html << "<!-- Series #{sg[:name]} (H#{series_heading_level}) for author: #{sg[:books].map{|b| b.data['title']}.join(', ')} -->\n"
      end
      group_html
    } do
      Jekyll.stub :logger, @silent_logger_stub do # For logs from BookListUtils.get_data_for_all_books_by_author_display
        output = Liquid::Template.parse("{% display_books_by_author_then_series %}").render!(context)
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_books_by_author_then_series some_arg %}")
    end
    assert_match "This tag does not accept any arguments", err.message
  end

  def test_renders_correct_author_headings_and_delegates_to_util_with_ids
    expected_standalone_card_html_author_a = "<!-- Standalone Card: #{@book_a_standalone.data['title']} -->\n"
    expected_standalone_card_html_author_b = "<!-- Standalone Card: #{@book_b_standalone.data['title']} -->\n"

    author_a_slug = simple_slugify(@author_a_name) # "author-a"
    author_b_slug = simple_slugify(@author_b_name) # "author-b-the-sequel"

    expected_id_author_a_standalone = "standalone-books-#{author_a_slug}" # "standalone-books-author-a"
    expected_id_author_b_standalone = "standalone-books-#{author_b_slug}" # "standalone-books-author-b-the-sequel"

    book_card_render_calls = []
    BookCardUtils.stub :render, ->(book, _ctx) {
      book_card_render_calls << book.data['title']
      "<!-- Standalone Card: #{book.data['title']} -->\n"
    } do
      output = render_tag # This render_tag uses the corrected stub for render_book_groups_html

      # Author A Assertions
      assert_match %r{<h2 class="book-list-headline">#{CGI.escapeHTML(@author_a_name)}</h2>}, output
      expected_h3_author_a = "<h3 class=\"book-list-headline\" id=\"#{expected_id_author_a_standalone}\">Standalone Books</h3>"
      assert_includes output, expected_h3_author_a, "Missing or incorrect H3 for Author A Standalone Books"
      assert_includes output, expected_standalone_card_html_author_a
      assert_match %r{<!-- Series Series One \(H3\) for author: #{@book_a_s1_b1.data['title']}, #{@book_a_s1_b2.data['title']} -->}, output

      # Author B Assertions
      assert_match %r{<h2 class="book-list-headline">#{CGI.escapeHTML(@author_b_name)}</h2>}, output
      expected_h3_author_b = "<h3 class=\"book-list-headline\" id=\"#{expected_id_author_b_standalone}\">Standalone Books</h3>"
      assert_includes output, expected_h3_author_b, "Missing or incorrect H3 for Author B Standalone Books"
      assert_includes output, expected_standalone_card_html_author_b
      assert_match %r{<!-- Series Series Two \(H3\) for author: #{@book_b_s2_b1.data['title']} -->}, output

      # Order and general assertions
      author_a_index = output.index("<h2 class=\"book-list-headline\">#{CGI.escapeHTML(@author_a_name)}</h2>")
      author_b_index = output.index("<h2 class=\"book-list-headline\">#{CGI.escapeHTML(@author_b_name)}</h2>")
      refute_nil author_a_index
      refute_nil author_b_index
      # Note: Author B ("Author B: The Sequel") comes after "Author A" alphabetically
      assert author_a_index < author_b_index

      # Ensure book with no author is not processed
      refute_match %r{Book With No Author}, output
      refute_match %r{<h2 class="book-list-headline">\s*</h2>}, output

      # Verify BookCardUtils.render was called for standalone books
      assert_includes book_card_render_calls, @book_a_standalone.data['title']
      assert_includes book_card_render_calls, @book_b_standalone.data['title']
      assert_equal 2, book_card_render_calls.count
    end
  end

  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_tag_page.md'}, '/current_tag_page.html') })

    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author_then_series %}").render!(context_no_books)
    end

    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_author'\s*SourcePage='current_tag_page\.md' -->}, output
    refute_match %r{<h2 class="book-list-headline">}, output
  end

  def test_renders_log_message_if_no_books_with_valid_authors_found
    site_no_valid_authors = create_site({ 'url' => 'http://example.com' }, { 'books' => [@book_no_author] })
    site_no_valid_authors.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_no_valid_authors = create_context({}, { site: site_no_valid_authors, page: create_doc({ 'path' => 'current_tag_page.md'}, '/current_tag_page.html') })

    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author_then_series %}").render!(context_no_valid_authors)
    end
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_tag_page\.md' -->}, output
    refute_match %r{<h2 class="book-list-headline">}, output
  end

  def test_renders_empty_if_no_books_at_all_in_collection
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: create_doc({ 'path' => 'current_tag_page.md'}, '/current_tag_page.html') })

    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author_then_series %}").render!(context_empty_books)
    end
    # Expect the info log from BookListUtils because the collection was empty, leading to no valid authors.
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_tag_page\.md' -->}, output
    refute_match %r{<h2 class="book-list-headline">}, output
  end

end
