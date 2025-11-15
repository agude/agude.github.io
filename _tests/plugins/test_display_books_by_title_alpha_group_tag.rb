# _tests/plugins/test_display_books_by_title_alpha_group_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_title_alpha_group_tag'
require 'cgi' # For CGI.escapeHTML in assertions if needed, though not directly used now

class TestDisplayBooksByTitleAlphaGroupTag < Minitest::Test
  def setup
    # --- Mock Book Data for Alpha Grouping Tests ---
    # Titles are chosen to test sorting (ignoring articles) and grouping by first letter.
    @book_apple = create_doc({ 'title' => 'Apple Pie Adventures' }, '/apa.html') # Sorts under A
    @book_a_banana = create_doc({ 'title' => 'A Banana Story' }, '/abs.html') # Sorts under B (after stripping "A ")
    @book_the_cherry = create_doc({ 'title' => 'The Cherry Chronicle' }, '/tcc.html') # Sorts under C (after stripping "The ")
    @book_another_apple = create_doc({ 'title' => 'Another Apple Tale' }, '/aat.html') # Sorts under A
    @book_aardvark = create_doc({ 'title' => 'Aardvark Antics' }, '/aa.html')         # Sorts under A
    @book_zebra = create_doc({ 'title' => 'Zebra Zoom' }, '/zz.html')                 # Sorts under Z
    @book_123go = create_doc({ 'title' => '123 Go!' }, '/123.html')                   # Sorts under # (non-alphabetic start)
    @book_empty_title_sort = create_doc({ 'title' => 'The ' }, '/the.html')           # Sorts under # (normalized title is empty)
    # Using direct MockDocument instantiation for @book_only_an as it resolved a previous intermittent nil issue.
    # Ensures this specific test data point is reliably created.
    @book_only_an = MockDocument.new({ 'title' => 'An', 'path' => 'an.html', 'date' => Time.now, 'published' => true, 'layout' => 'test_layout' }, '/an.html', 'Content for An', Time.now, nil, nil) # Sorts under #

    # Consolidate books for the site used in these tag tests
    @all_books_for_tag = [
      @book_apple, @book_a_banana, @book_the_cherry, @book_another_apple,
      @book_aardvark, @book_zebra, @book_123go, @book_empty_title_sort, @book_only_an
    ]

    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag })
    # Context for the tag, including a page path for PluginLoggerUtils
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_title_page.md' }, '/current_title_page.html') })

    # Silent logger to suppress console output during tests unless specifically testing logs
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Helper to render the {% display_books_by_title_alpha_group %} tag.
  # Stubs BookCardUtils.render to simplify assertions, focusing on grouping and headers.
  def render_tag(context = @context)
    output = ''
    # The DisplayBooksByTitleAlphaGroupTag directly calls BookCardUtils.render for each book.
    BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" } do
      # BookListUtils.get_data_for_all_books_by_title_alpha_group is called internally by the tag.
      # We stub Jekyll.logger for logs that might originate from BookListUtils.
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(context)
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_title_alpha_group some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  # Tests if the tag correctly renders letter headings (H2) with IDs,
  # and if books are grouped and ordered correctly under these headings.
  def test_renders_correct_letter_headings_and_book_order
    output = render_tag

    # --- Assert Jump Links Navigation ---
    assert_match(/<nav class="alpha-jump-links">/, output)
    # Check for linked letters that should exist (#, A, B, C, Z)
    assert_match %r{<a href="#letter-hash">#</a>}, output
    assert_match %r{<a href="#letter-a">A</a>}, output
    assert_match %r{<a href="#letter-b">B</a>}, output
    assert_match %r{<a href="#letter-c">C</a>}, output
    assert_match %r{<a href="#letter-z">Z</a>}, output
    # Check for unlinked letters that should NOT exist (e.g., D, E, F)
    assert_match %r{<span>D</span>}, output
    assert_match %r{<span>E</span>}, output
    assert_match %r{<span>F</span>}, output
    # Ensure the links are joined by spaces and in the correct order
    assert_match %r{<a href="#letter-hash">#</a> <a href="#letter-a">A</a>}, output

    # --- Assert Group # (Hash) ---
    # Books: An, The , 123 Go! (Order based on secondary sort by original title for empty normalized titles)
    assert_match %r{<h2 class="book-list-headline" id="letter-hash">#</h2>}, output
    expected_hash_cards = "<!-- Card for: #{Regexp.escape(@book_only_an.data['title'])} -->\\s*" + # Title "An"
                          "<!-- Card for: #{Regexp.escape(@book_empty_title_sort.data['title'])} -->\\s*" + # Title "The "
                          "<!-- Card for: #{Regexp.escape(@book_123go.data['title'])} -->" # Title "123 Go!"
    assert_match Regexp.new("id=\"letter-hash\">#<\\/h2>\\s*<div class=\"card-grid\">\\s*#{expected_hash_cards}\\s*<\\/div>", Regexp::MULTILINE),
                 output

    # --- Assert Group A ---
    # Books: Aardvark Antics, Another Apple Tale, Apple Pie Adventures
    assert_match %r{<h2 class="book-list-headline" id="letter-a">A</h2>}, output
    expected_a_cards = "<!-- Card for: #{@book_aardvark.data['title']} -->\\s*" +
                       "<!-- Card for: #{@book_another_apple.data['title']} -->\\s*" +
                       "<!-- Card for: #{@book_apple.data['title']} -->"
    assert_match %r{id="letter-a">A</h2>\s*<div class="card-grid">\s*#{expected_a_cards}\s*</div>}m, output

    # --- Assert Group B ---
    # Book: A Banana Story
    assert_match %r{<h2 class="book-list-headline" id="letter-b">B</h2>}, output
    expected_b_cards = "<!-- Card for: #{@book_a_banana.data['title']} -->"
    assert_match %r{id="letter-b">B</h2>\s*<div class="card-grid">\s*#{expected_b_cards}\s*</div>}m, output

    # --- Assert Group C ---
    # Book: The Cherry Chronicle
    assert_match %r{<h2 class="book-list-headline" id="letter-c">C</h2>}, output
    expected_c_cards = "<!-- Card for: #{@book_the_cherry.data['title']} -->"
    assert_match %r{id="letter-c">C</h2>\s*<div class="card-grid">\s*#{expected_c_cards}\s*</div>}m, output

    # --- Assert Group Z ---
    # Book: Zebra Zoom
    assert_match %r{<h2 class="book-list-headline" id="letter-z">Z</h2>}, output
    expected_z_cards = "<!-- Card for: #{@book_zebra.data['title']} -->"
    assert_match %r{id="letter-z">Z</h2>\s*<div class="card-grid">\s*#{expected_z_cards}\s*</div>}m, output

    # --- Assert Overall Order of Letter Groups ---
    idx_hash = output.index('id="letter-hash"')
    idx_a = output.index('id="letter-a"')
    idx_b = output.index('id="letter-b"')
    idx_c = output.index('id="letter-c"')
    idx_z = output.index('id="letter-z"')

    refute_nil idx_hash, 'Group # heading missing'
    refute_nil idx_a, 'Group A heading missing'
    refute_nil idx_b, 'Group B heading missing'
    refute_nil idx_c, 'Group C heading missing'
    refute_nil idx_z, 'Group Z heading missing'

    assert (idx_hash < idx_a && idx_a < idx_b && idx_b < idx_c && idx_c < idx_z),
           'Letter groups are not in # then A-Z order'
  end

  # Tests logging if the 'books' collection is missing.
  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable logging for the utility
    context_no_books = create_context({},
                                      { site: site_no_books,
                                        page: create_doc({ 'path' => 'current_title_page.md' },
                                                         '/current_title_page.html') })

    output = ''
    # No stubs needed here as BookListUtils will return early with a log message.
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(context_no_books)
    end

    assert_match(/<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_title_alpha_group'\s*SourcePage='current_title_page\.md' -->/,
                 output)
    refute_match(/<h2 class="book-list-headline">/, output,
                 'No H2 headings should be rendered if collection is missing')
  end

  # Tests logging if no published books are found in the collection.
  def test_renders_log_message_if_no_published_books_found
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] }) # Empty 'books' collection
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_TITLE_ALPHA_GROUP'] = true # Enable specific logging
    context_empty_books = create_context({},
                                         { site: site_empty_books,
                                           page: create_doc({ 'path' => 'current_title_page.md' },
                                                            '/current_title_page.html') })

    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(context_empty_books)
    end

    assert_match(/<!-- \[INFO\] ALL_BOOKS_BY_TITLE_ALPHA_GROUP_FAILURE: Reason='No published books found to group by title\.'\s*SourcePage='current_title_page\.md' -->/,
                 output)
    refute_match(/<h2 class="book-list-headline">/, output, 'No H2 headings should be rendered if no books are found')
  end
end
