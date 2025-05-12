# _tests/plugins/test_display_all_books_grouped_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_all_books_grouped_tag'

class TestDisplayAllBooksGroupedTag < Minitest::Test
  def setup
    @book_s1_b1 = create_doc({ 'title' => 'S1 Book 1', 'series' => 'Series Alpha', 'book_number' => 1, 'book_author' => 'Author A' }, '/s1b1.html')
    @book_s1_b2 = create_doc({ 'title' => 'S1 Book 2', 'series' => 'Series Alpha', 'book_number' => 2, 'book_author' => 'Author A' }, '/s1b2.html')
    @book_s2_b1 = create_doc({ 'title' => 'S2 Book 1', 'series' => 'Series Beta', 'book_number' => 1, 'book_author' => 'Author B' }, '/s2b1.html')
    @standalone_apple = create_doc({ 'title' => 'Apple Book', 'book_author' => 'Author C' }, '/apple.html')
    @standalone_the_zebra = create_doc({ 'title' => 'The Zebra Book', 'book_author' => 'Author D' }, '/zebra.html')

    @all_books = [@book_s1_b1, @book_s1_b2, @book_s2_b1, @standalone_apple, @standalone_the_zebra]
    @site = create_site({}, { 'books' => @all_books })
    @context = create_context({}, { site: @site, page: create_doc({}, '/current.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  def render_tag(markup = "", context = @context) # Default empty markup
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_all_books_grouped #{markup} %}").render!(context)
    end
    output
  end

  def test_renders_all_books_correctly_grouped_and_sorted
    output = render_tag()

    # Check for Standalone Books section
    assert_match %r{<h2 class="book-list-headline">Standalone Books</h2>}, output
    # Standalone sorted: Apple Book, The Zebra Book (Zebra after Apple)
    assert_match %r{<div class="card-grid">.*<cite class="book-title">Apple Book</cite>.*<cite class="book-title">The Zebra Book</cite>.*</div>}m, output

    # Check for Series Alpha
    assert_match %r{<h2 class="series-title">.*<span class="book-series">Series Alpha</span>.*</h2>}, output
    # Books in Series Alpha sorted by number
    assert_match %r{<div class="card-grid">.*<cite class="book-title">S1 Book 1</cite>.*<cite class="book-title">S1 Book 2</cite>.*</div>}m, output

    # Check for Series Beta
    assert_match %r{<h2 class="series-title">.*<span class="book-series">Series Beta</span>.*</h2>}, output
    assert_match %r{<div class="card-grid">.*<cite class="book-title">S2 Book 1</cite>.*</div>}m, output

    # Ensure order of series groups (Alpha then Beta)
    alpha_index = output.index("Series Alpha")
    beta_index = output.index("Series Beta")
    refute_nil alpha_index, "Series Alpha not found"
    refute_nil beta_index, "Series Beta not found"
    assert alpha_index < beta_index, "Series Alpha should appear before Series Beta"
  end

  def test_renders_empty_when_no_books_exist
    empty_site = create_site({}, { 'books' => [] })
    empty_context = create_context({}, { site: empty_site, page: create_doc({}, '/current.html') })
    output = render_tag("", empty_context)
    assert_equal "", output.strip
  end

  def test_syntax_error_with_arguments
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_all_books_grouped some_arg %}")
    end
    assert_match(/This tag does not accept any arguments/, err.message)
  end
end
