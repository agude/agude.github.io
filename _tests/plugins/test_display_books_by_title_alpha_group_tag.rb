# frozen_string_literal: true

# _tests/plugins/test_display_books_by_title_alpha_group_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_title_alpha_group_tag'
require 'cgi'

class TestDisplayBooksByTitleAlphaGroupTag < Minitest::Test
  def setup
    create_test_books
    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag })
    @context = build_test_context
    @silent_logger_stub = create_silent_logger
  end

  # Helper to render the {% display_books_by_title_alpha_group %} tag.
  # Stubs BookCardUtils.render to simplify assertions, focusing on grouping and headers.
  def render_tag(context = @context)
    output = ''
    stub_card_render = ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" }
    BookCardUtils.stub :render, stub_card_render do
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

  def test_renders_jump_links_navigation
    output = render_tag
    assert_match(/<nav class="alpha-jump-links">/, output)
    assert_jump_links_present(output)
    assert_jump_links_order(output)
  end

  def test_renders_hash_group_correctly
    output = render_tag
    assert_match %r{<h2 class="book-list-headline" id="letter-hash">#</h2>}, output
    expected_hash_cards = build_expected_hash_cards
    pattern = Regexp.new(
      "id=\"letter-hash\">#<\\/h2>\\s*<div class=\"card-grid\">\\s*#{expected_hash_cards}\\s*<\\/div>",
      Regexp::MULTILINE
    )
    assert_match pattern, output
  end

  def test_renders_group_a_correctly
    output = render_tag
    assert_match %r{<h2 class="book-list-headline" id="letter-a">A</h2>}, output
    expected_a_cards = build_expected_a_cards
    assert_match %r{id="letter-a">A</h2>\s*<div class="card-grid">\s*#{expected_a_cards}\s*</div>}m, output
  end

  def test_renders_group_b_correctly
    output = render_tag
    assert_match %r{<h2 class="book-list-headline" id="letter-b">B</h2>}, output
    expected_b_cards = "<!-- Card for: #{@book_a_banana.data['title']} -->"
    assert_match %r{id="letter-b">B</h2>\s*<div class="card-grid">\s*#{expected_b_cards}\s*</div>}m, output
  end

  def test_renders_group_c_correctly
    output = render_tag
    assert_match %r{<h2 class="book-list-headline" id="letter-c">C</h2>}, output
    expected_c_cards = "<!-- Card for: #{@book_the_cherry.data['title']} -->"
    assert_match %r{id="letter-c">C</h2>\s*<div class="card-grid">\s*#{expected_c_cards}\s*</div>}m, output
  end

  def test_renders_group_z_correctly
    output = render_tag
    assert_match %r{<h2 class="book-list-headline" id="letter-z">Z</h2>}, output
    expected_z_cards = "<!-- Card for: #{@book_zebra.data['title']} -->"
    assert_match %r{id="letter-z">Z</h2>\s*<div class="card-grid">\s*#{expected_z_cards}\s*</div>}m, output
  end

  def test_letter_groups_in_correct_order
    output = render_tag
    indices = extract_letter_group_indices(output)
    assert_indices_not_nil(indices)
    assert_indices_in_order(indices)
  end

  def test_renders_log_message_if_books_collection_missing
    context_no_books = build_context_without_books
    output = render_with_logger(context_no_books)
    expected_pattern = /<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; /
    assert_match expected_pattern, output
    refute_match(/<h2 class="book-list-headline">/, output,
                 'No H2 headings should be rendered if collection is missing')
  end

  def test_renders_log_message_if_no_published_books_found
    context_empty_books = build_context_with_empty_books
    output = render_with_logger(context_empty_books)
    expected_pattern = /<!-- \[INFO\] ALL_BOOKS_BY_TITLE_ALPHA_GROUP_FAILURE: /
    assert_match expected_pattern, output
    refute_match(/<h2 class="book-list-headline">/, output,
                 'No H2 headings should be rendered if no books are found')
  end

  private

  def create_test_books
    # Titles are chosen to test sorting (ignoring articles) and grouping by first letter.
    @book_apple = create_doc({ 'title' => 'Apple Pie Adventures' }, '/apa.html')
    @book_a_banana = create_doc({ 'title' => 'A Banana Story' }, '/abs.html')
    @book_the_cherry = create_doc({ 'title' => 'The Cherry Chronicle' }, '/tcc.html')
    @book_another_apple = create_doc({ 'title' => 'Another Apple Tale' }, '/aat.html')
    @book_aardvark = create_doc({ 'title' => 'Aardvark Antics' }, '/aa.html')
    @book_zebra = create_doc({ 'title' => 'Zebra Zoom' }, '/zz.html')
    @book_123go = create_doc({ 'title' => '123 Go!' }, '/123.html')
    @book_empty_title_sort = create_doc({ 'title' => 'The ' }, '/the.html')
    @book_only_an = create_book_only_an

    @all_books_for_tag = [
      @book_apple, @book_a_banana, @book_the_cherry, @book_another_apple,
      @book_aardvark, @book_zebra, @book_123go, @book_empty_title_sort, @book_only_an
    ]
  end

  def create_book_only_an
    MockDocument.new(
      { 'title' => 'An', 'path' => 'an.html', 'date' => Time.now,
        'published' => true, 'layout' => 'test_layout' },
      '/an.html',
      'Content for An',
      Time.now,
      nil,
      nil
    )
  end

  def build_test_context
    page = create_doc({ 'path' => 'current_title_page.md' }, '/current_title_page.html')
    create_context({}, { site: @site, page: page })
  end

  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(topic, message); end
      def logger.error(topic, message); end
      def logger.info(topic, message); end
      def logger.debug(topic, message); end
    end
  end

  def assert_jump_links_present(output)
    assert_match %r{<a href="#letter-hash">#</a>}, output
    assert_match %r{<a href="#letter-a">A</a>}, output
    assert_match %r{<a href="#letter-b">B</a>}, output
    assert_match %r{<a href="#letter-c">C</a>}, output
    assert_match %r{<a href="#letter-z">Z</a>}, output
    assert_match %r{<span>D</span>}, output
    assert_match %r{<span>E</span>}, output
    assert_match %r{<span>F</span>}, output
  end

  def assert_jump_links_order(output)
    assert_match %r{<a href="#letter-hash">#</a> <a href="#letter-a">A</a>}, output
  end

  def build_expected_hash_cards
    # Books: An, The , 123 Go!
    escaped_an = Regexp.escape(@book_only_an.data['title'])
    escaped_empty = Regexp.escape(@book_empty_title_sort.data['title'])
    escaped_123 = Regexp.escape(@book_123go.data['title'])
    "<!-- Card for: #{escaped_an} -->\\s*" \
      "<!-- Card for: #{escaped_empty} -->\\s*" \
      "<!-- Card for: #{escaped_123} -->"
  end

  def build_expected_a_cards
    # Books: Aardvark Antics, Another Apple Tale, Apple Pie Adventures
    "<!-- Card for: #{@book_aardvark.data['title']} -->\\s*" \
      "<!-- Card for: #{@book_another_apple.data['title']} -->\\s*" \
      "<!-- Card for: #{@book_apple.data['title']} -->"
  end

  def extract_letter_group_indices(output)
    {
      hash: output.index('id="letter-hash"'),
      a: output.index('id="letter-a"'),
      b: output.index('id="letter-b"'),
      c: output.index('id="letter-c"'),
      z: output.index('id="letter-z"')
    }
  end

  def assert_indices_not_nil(indices)
    refute_nil indices[:hash], 'Group # heading missing'
    refute_nil indices[:a], 'Group A heading missing'
    refute_nil indices[:b], 'Group B heading missing'
    refute_nil indices[:c], 'Group C heading missing'
    refute_nil indices[:z], 'Group Z heading missing'
  end

  def assert_indices_in_order(indices)
    in_order = indices[:hash] < indices[:a] &&
               indices[:a] < indices[:b] &&
               indices[:b] < indices[:c] &&
               indices[:c] < indices[:z]
    assert in_order, 'Letter groups are not in # then A-Z order'
  end

  def build_context_without_books
    site_no_books = create_site({ 'url' => 'http://example.com' }, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    page = create_doc({ 'path' => 'current_title_page.md' }, '/current_title_page.html')
    create_context({}, { site: site_no_books, page: page })
  end

  def build_context_with_empty_books
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_TITLE_ALPHA_GROUP'] = true
    page = create_doc({ 'path' => 'current_title_page.md' }, '/current_title_page.html')
    create_context({}, { site: site_empty_books, page: page })
  end

  def render_with_logger(context)
    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse('{% display_books_by_title_alpha_group %}').render!(context)
    end
    output
  end
end
