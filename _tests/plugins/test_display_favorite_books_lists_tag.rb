# _tests/plugins/test_display_favorite_books_lists_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_favorite_books_lists_tag'

class TestDisplayFavoriteBooksListsTag < Minitest::Test
  def setup
    @post_2024 = create_doc({ 'title' => 'Favorites of 2024' }, '/fav24.html')
    @post_2023 = create_doc({ 'title' => 'Favorites of 2023' }, '/fav23.html')
    @book_a = create_doc({ 'title' => 'Book A' }, '/books/a.html')
    @book_b = create_doc({ 'title' => 'Book B' }, '/books/b.html')

    @mock_data_from_util = {
      favorites_lists: [
        { post: @post_2024, books: [@book_a] },
        { post: @post_2023, books: [@book_b] }
      ],
      log_messages: ""
    }

    @site = create_site({ 'url' => 'http://example.com' })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })

    @silent_logger_stub = Object.new.tap do |l|
      def l.warn(p,m);end; def l.error(p,m);end; def l.info(p,m);end; def l.debug(p,m);end
    end
  end

  def render_tag(context = @context, util_return_data = @mock_data_from_util)
    output = ""
    BookListUtils.stub :get_data_for_favorites_lists, ->(args) { util_return_data } do
      BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = Liquid::Template.parse("{% display_favorite_books_lists %}").render!(context)
        end
      end
    end
    output
  end

  def test_renders_correct_html_structure
    output = render_tag

    # Check for 2024 section
    assert_match %r{<h3 class="book-list-headline"><a href="/fav24.html">Favorites of 2024</a></h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Book A -->\s*</div>}m, output

    # Check for 2023 section
    assert_match %r{<h3 class="book-list-headline"><a href="/fav23.html">Favorites of 2023</a></h3>}, output
    assert_match %r{<div class="card-grid">\s*<!-- Card for: Book B -->\s*</div>}m, output

    # Check order
    idx_2024 = output.index('Favorites of 2024')
    idx_2023 = output.index('Favorites of 2023')
    assert idx_2024 < idx_2023, "2024 list should appear before 2023 list"
  end

  def test_renders_log_message_if_util_returns_one
    data_with_log = { favorites_lists: [], log_messages: "<!-- Test Log Message -->" }
    output = render_tag(@context, data_with_log)
    assert_match "<!-- Test Log Message -->", output
    refute_match %r{<h3 class="book-list-headline">}, output
  end

  def test_renders_empty_if_no_lists_found
    data_empty = { favorites_lists: [], log_messages: "" }
    output = render_tag(@context, data_empty)
    assert_equal "", output.strip
  end

  def test_skips_list_if_it_has_no_books
    data_with_empty_list = {
      favorites_lists: [
        { post: @post_2024, books: [] }, # This one should be skipped
        { post: @post_2023, books: [@book_b] }
      ],
      log_messages: ""
    }
    output = render_tag(@context, data_with_empty_list)
    refute_match "Favorites of 2024", output
    assert_match "Favorites of 2023", output
  end

  def test_syntax_error_with_arguments
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_favorite_books_lists some_arg %}")
    end
    assert_match "This tag does not accept any arguments", err.message
  end
end
