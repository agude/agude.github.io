# frozen_string_literal: true

# _tests/plugins/test_display_books_by_author_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/display_books_by_author_tag'
# BookListUtils, Jekyll::Infrastructure::FrontMatterUtils, etc., are loaded by test_helper

# Tests for Jekyll::Books::Tags::DisplayBooksByAuthorTag Liquid tag.
#
# Verifies that the tag correctly displays books filtered by author.
class TestDisplayBooksByAuthorTag < Minitest::Test
  def setup
    # Define author names
    @author_a = 'Author A'
    @author_b = 'Author B'

    # Create mock documents using 'book_authors' as an array
    @authA_book_s1_n1 = create_doc({
                                     'title' => 'Author A Series One Book 1', 'series' => 'Series One',
                                     'book_number' => 1, 'book_authors' => [@author_a]
                                   }, '/a_s1b1.html')
    @authA_book_s1_n2 = create_doc({
                                     'title' => 'Author A Series One Book 2', 'series' => 'Series One',
                                     'book_number' => 2, 'book_authors' => [@author_a]
                                   }, '/a_s1b2.html')
    @authA_standalone = create_doc({
                                     'title' => 'The Author A Standalone', 'book_authors' => [@author_a]
                                   }, '/a_sa.html')

    # Book co-authored by Author A and Author B, to test if it appears under both
    @co_authored_book = create_doc({
                                     'title' => 'Co-authored Book', 'book_authors' => [@author_a, @author_b]
                                   }, '/coauth.html')

    @authB_book_s2_n1 = create_doc({
                                     'title' => 'Author B Series Two Book 1', 'series' => 'Series Two',
                                     'book_number' => 1, 'book_authors' => [@author_b]
                                   }, '/b_s2b1.html')
    @authB_standalone = create_doc({
                                     'title' => 'Author B Standalone', 'book_authors' => [@author_b]
                                   }, '/b_sb.html')

    @all_books = [
      @authA_book_s1_n1, @authA_book_s1_n2, @authA_standalone, @co_authored_book,
      @authB_book_s2_n1, @authB_standalone
    ]

    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books })
    @context = create_context(
      { 'page_author_var' => @author_a },
      { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') }
    )

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  def render_tag(markup, context = @context)
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      # The tag calls BookListUtils.get_data_for_author_display and then
      # BookListUtils.render_book_groups_html.
      # The internal logic of these utils is tested elsewhere.
      # Here, we are testing the tag's integration.
      output = Liquid::Template.parse("{% display_books_by_author #{markup} %}").render!(context)
    end
    output
  end

  def test_render_books_for_author_A
    output = render_tag("'#{@author_a}'") # Use instance variable for author name

    # Check for Author A's standalone books
    standalone_headline = %r{<h2 class="book-list-headline" id="standalone-books">Standalone Books</h2>}
    assert_match standalone_headline, output
    assert_match %r{<cite class="book-title">The Author A Standalone</cite>}, output
    assert_match %r{<cite class="book-title">Co-authored Book</cite>}, output # Should appear here

    # Check for Author A's series books
    series_headline = %r{<h2 class="series-title" id="series-one">.*<span class="book-series">Series One</span>.*</h2>}
    assert_match series_headline, output
    assert_match %r{<cite class="book-title">Author A Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Author A Series One Book 2</cite>}, output

    # Ensure Author B's specific books (not co-authored) are not present
    refute_match(/Author B Standalone/, output)
    refute_match(/Author B Series Two Book 1/, output)
    refute_match(/<!--.*BOOK_LIST_AUTHOR_DISPLAY_FAILURE.*-->/, output)
  end

  def test_render_books_for_author_B_variable
    @context['page_author_var'] = @author_b # Set context variable to "Author B"
    output = render_tag('page_author_var')

    # Check for Author B's standalone books
    standalone_headline = %r{<h2 class="book-list-headline" id="standalone-books">Standalone Books</h2>}
    assert_match standalone_headline, output
    assert_match %r{<cite class="book-title">Author B Standalone</cite>}, output
    assert_match %r{<cite class="book-title">Co-authored Book</cite>}, output # Should also appear here

    # Check for Author B's series books
    series_headline = %r{<h2 class="series-title" id="series-two">.*<span class="book-series">Series Two</span>.*</h2>}
    assert_match series_headline, output
    assert_match %r{<cite class="book-title">Author B Series Two Book 1</cite>}, output

    # Ensure Author A's specific books (not co-authored) are not present
    refute_match(/The Author A Standalone/, output)
    refute_match(/Author A Series One Book 1/, output)
    refute_match(/<!--.*BOOK_LIST_AUTHOR_DISPLAY_FAILURE.*-->/, output)
  end

  def test_render_empty_for_non_existent_author_logs_info
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    output = render_tag("'NonExistent Author'")
    expected_log_pattern = /<!-- \[INFO\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='No books found for the specified author\.'\s*AuthorFilter='NonExistent Author'\s*SourcePage='current\.html' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_render_logs_for_nil_author_name_variable
    @context['nil_author_var'] = nil
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    output = render_tag('nil_author_var')
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilterInput='N/A'\s*SourcePage='current\.html' -->},
                 output
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_render_logs_for_empty_author_name_literal
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true
    output = render_tag("''")
    expected_log_pattern = /<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilterInput=''\s*SourcePage='current\.html' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_author %}')
    end
    assert_match(/Author name .* is required/, err.message)
  end

  # --- Markdown render mode ---

  def test_markdown_mode_outputs_book_list
    md_context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html'),
        render_mode: :markdown }
    )
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author '#{@author_a}' %}").render!(md_context)
    end
    # Should contain markdown links, not HTML
    assert_includes output, '[Author A Series One Book 1](/a_s1b1.html)'
    assert_includes output, '[Author A Series One Book 2](/a_s1b2.html)'
    assert_includes output, '[The Author A Standalone](/a_sa.html)'
    refute_includes output, '<cite'
    refute_includes output, '<div'
  end

  def test_markdown_mode_groups_by_series
    md_context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html'),
        render_mode: :markdown }
    )
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author '#{@author_a}' %}").render!(md_context)
    end
    assert_includes output, '### Series One'
  end
end
