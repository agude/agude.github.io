# _tests/plugins/test_display_books_by_author_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_author_tag'

class TestDisplayBooksByAuthorTag < Minitest::Test
  def setup
    @authA_book_s1_n1 = create_doc({ 'title' => 'Author A Series One Book 1', 'series' => 'Series One', 'book_number' => 1, 'book_author' => 'Author A' }, '/a_s1b1.html')
    @authA_book_s1_n2 = create_doc({ 'title' => 'Author A Series One Book 2', 'series' => 'Series One', 'book_number' => 2, 'book_author' => 'Author A' }, '/a_s1b2.html')
    @authA_standalone = create_doc({ 'title' => 'The Author A Standalone', 'book_author' => 'Author A' }, '/a_sa.html')

    @authB_book_s2_n1 = create_doc({ 'title' => 'Author B Series Two Book 1', 'series' => 'Series Two', 'book_number' => 1, 'book_author' => 'Author B' }, '/b_s2b1.html')
    @authB_standalone = create_doc({ 'title' => 'Author B Standalone', 'book_author' => 'Author B' }, '/b_sb.html')

    @all_books = [@authA_book_s1_n1, @authA_book_s1_n2, @authA_standalone, @authB_book_s2_n1, @authB_standalone]
    @site = create_site({}, { 'books' => @all_books })
    @context = create_context({ 'page_author_var' => 'Author A' }, { site: @site, page: create_doc({}, '/current.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def render_tag(markup, context = @context)
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_author #{markup} %}").render!(context)
    end
    output
  end

  def test_render_books_for_author_A
    output = render_tag("'Author A'")
    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, output
    assert_match %r{<cite class="book-title">The Author A Standalone</cite>}, output # Sorted: "author a standalone"

    assert_match %r{<h2 class="series-title">.*<span class="book-series">Series One</span>.*</h2>}, output
    assert_match %r{<cite class="book-title">Author A Series One Book 1</cite>}, output
    assert_match %r{<cite class="book-title">Author A Series One Book 2</cite>}, output

    refute_match %r{Author B}, output # Should not include Author B's books
    refute_match %r{<!--.*BOOK_LIST_AUTHOR_DISPLAY_FAILURE.*-->}, output
  end

  def test_render_books_for_author_B_variable
    @context['page_author_var'] = 'Author B' # Change context variable
    output = render_tag("page_author_var")
    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, output
    assert_match %r{<cite class="book-title">Author B Standalone</cite>}, output

    assert_match %r{<h2 class="series-title">.*<span class="book-series">Series Two</span>.*</h2>}, output
    assert_match %r{<cite class="book-title">Author B Series Two Book 1</cite>}, output

    refute_match %r{Author A}, output
    refute_match %r{<!--.*BOOK_LIST_AUTHOR_DISPLAY_FAILURE.*-->}, output
  end

  def test_render_empty_for_non_existent_author
    # Util doesn't log for "author not found but filter was valid", just returns empty data.
    # So, no HTML comment expected here from the util itself.
    output = render_tag("'NonExistent Author'")
    assert_equal "", output.strip # Expect empty output as no books will match
  end

  def test_render_logs_for_nil_author_name_variable
    @context['nil_author_var'] = nil
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true # Enable logging
    output = render_tag("nil_author_var")
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilter='N/A'\s*SourcePage='current\.html' -->}, output
    refute_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, output
    refute_match %r{<h2 class="series-title">}, output
  end

  def test_render_logs_for_empty_author_name_literal
    @site.config['plugin_logging']['BOOK_LIST_AUTHOR_DISPLAY'] = true # Enable logging
    output = render_tag("''")
    assert_match %r{<!-- \[WARN\] BOOK_LIST_AUTHOR_DISPLAY_FAILURE: Reason='Author name filter was empty or nil when fetching data\.'\s*AuthorFilter=''\s*SourcePage='current\.html' -->}, output
    refute_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, output
  end

  def test_syntax_error_missing_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_books_by_author %}")
    end
    assert_match(/Author name .* is required/, err.message)
  end
end
