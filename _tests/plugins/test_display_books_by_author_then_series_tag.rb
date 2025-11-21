# frozen_string_literal: true

# _tests/plugins/test_display_books_by_author_then_series_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_author_then_series_tag'
require 'cgi' # For CGI.escapeHTML

class TestDisplayBooksByAuthorThenSeriesTag < Minitest::Test
  def setup
    @author_a_name = 'Author Alpha'
    @author_b_name = 'Beta Author' # Changed from "author beta"
    @author_c_name = 'Charlie Author' # Added for nav testing

    # Author Alpha books
    @book_aa_s1_b0_5 = create_doc(
      { 'title' => 'AA: Series One, Book 0.5', 'series' => 'Series One', 'book_number' => 0.5,
        'book_authors' => [@author_a_name] }, '/a/s1b0_5.html'
    )
    @book_aa_s1_b1 = create_doc(
      { 'title' => 'AA: Series One, Book 1', 'series' => 'Series One', 'book_number' => 1,
        'book_authors' => [@author_a_name] }, '/a/s1b1.html'
    )
    @book_aa_standalone = create_doc({ 'title' => 'AA: Standalone', 'book_authors' => [@author_a_name] }, '/a/sa.html')

    # Beta Author books
    @book_ab_s2_b1 = create_doc(
      { 'title' => 'ab: Series Two, Book 1', 'series' => 'Series Two', 'book_number' => 1,
        'book_authors' => [@author_b_name] }, '/b/s2b1.html'
    )
    @book_ab_standalone = create_doc({ 'title' => 'ab: Standalone', 'book_authors' => [@author_b_name] }, '/b/sb.html')

    # Charlie Author book
    @book_ac_standalone = create_doc({ 'title' => 'CA: Standalone', 'book_authors' => [@author_c_name] }, '/c/sa.html')

    @coauthored_aa_ab_standalone = create_doc(
      { 'title' => 'Co-authored AA & ab Standalone',
        'book_authors' => [@author_a_name, @author_b_name] }, '/coauth/sa.html'
    )
    @book_no_author = create_doc({ 'title' => 'Book With No Author', 'series' => 'Some Series', 'book_authors' => [] },
                                 '/no_auth.html')

    @all_books_for_tag_test = [
      @book_aa_s1_b0_5, @book_aa_s1_b1, @book_aa_standalone,
      @book_ab_s2_b1, @book_ab_standalone, @book_ac_standalone,
      @coauthored_aa_ab_standalone,
      @book_no_author
    ].compact # Ensure no nils in the array itself

    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag_test })
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_tag_page.md' }, '/current_tag_page.html') })
    @silent_logger_stub = Object.new.tap do |l|
      def l.warn(p, m); end

      def l.error(p, m); end

      def l.info(p, m); end

      def l.debug(p, m); end
    end
  end

  def simple_slugify(text)
    return '' if text.nil?

    text.to_s.downcase.strip.gsub(/\s+/, '-').gsub(/[^\w-]+/, '').gsub(/--+/, '-').gsub(/^-+|-+$/, '')
  end

  def render_tag(context = @context)
    output = +''
    BookListUtils.stub :render_book_groups_html, lambda { |data, _ctx, series_heading_level: 2|
      group_html = +''
      data[:series_groups]&.each do |sg|
        # Ensure sg and sg[:books] are not nil before mapping
        books_titles = if sg && sg[:books]
                         sg[:books].compact.map do |b|
                           b.data['title']
                         end.join(', ')
                       else
                         'NO_BOOKS_IN_SERIES_GROUP_STUB'
                       end
        series_name = sg && sg[:name] ? sg[:name] : 'UNKNOWN_SERIES_STUB'
        group_html << "<!-- Series #{series_name} (H#{series_heading_level}) for author: #{books_titles} -->\n"
      end
      group_html
    } do
      BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Standalone Card: #{book.data['title']} -->\n" } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = Liquid::Template.parse('{% display_books_by_author_then_series %}').render!(context)
        end
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_books_by_author_then_series some_arg %}')
    end
    assert_match 'This tag does not accept any arguments', err.message
  end

  def test_renders_nav_and_correct_author_headings_with_semantic_ids
    output = render_tag

    # --- Calculate expected slugs ---
    author_a_slug = simple_slugify(@author_a_name) # "author-alpha"
    author_b_slug = simple_slugify(@author_b_name) # "beta-author"
    author_c_slug = simple_slugify(@author_c_name) # "charlie-author"

    # --- Assert Jump Links Navigation ---
    assert_match(/<nav class="alpha-jump-links">/, output)
    assert_match %r{<a href="##{author_a_slug}">A</a>}, output
    assert_match %r{<a href="##{author_b_slug}">B</a>}, output
    assert_match %r{<a href="##{author_c_slug}">C</a>}, output
    assert_match %r{<span>D</span>}, output # Unlinked
    assert_match %r{<span>E</span>}, output # Unlinked

    # --- Assert Author Alpha ---
    expected_id_author_a_standalone = "standalone-books-#{author_a_slug}"
    assert_match %r{<h2 class="book-list-headline" id="#{author_a_slug}">#{CGI.escapeHTML(@author_a_name)}</h2>}, output
    expected_h3_author_a = "<h3 class=\"book-list-headline\" id=\"#{expected_id_author_a_standalone}\">Standalone Books</h3>"
    assert_includes output, expected_h3_author_a
    assert_match(/<!-- Standalone Card: #{@book_aa_standalone.data['title']} -->/, output)
    assert_match(/<!-- Standalone Card: #{@coauthored_aa_ab_standalone.data['title']} -->/, output)
    expected_series_one_titles_aa_array = [@book_aa_s1_b0_5.data['title'], @book_aa_s1_b1.data['title']]
    expected_series_one_string_aa = expected_series_one_titles_aa_array.join(', ')
    assert_match(/<!-- Series Series One \(H3\) for author: #{Regexp.escape(expected_series_one_string_aa)} -->/,
                 output)

    # --- Assert Beta Author ---
    expected_id_author_b_standalone = "standalone-books-#{author_b_slug}"
    assert_match %r{<h2 class="book-list-headline" id="#{author_b_slug}">#{CGI.escapeHTML(@author_b_name)}</h2>}, output
    expected_h3_author_b = "<h3 class=\"book-list-headline\" id=\"#{expected_id_author_b_standalone}\">Standalone Books</h3>"
    assert_includes output, expected_h3_author_b
    assert_match(/<!-- Standalone Card: #{@book_ab_standalone.data['title']} -->/, output)
    assert_match(/<!-- Standalone Card: #{@coauthored_aa_ab_standalone.data['title']} -->/, output)
    assert_match(/<!-- Series Series Two \(H3\) for author: #{@book_ab_s2_b1.data['title']} -->/, output)

    # --- Assert Charlie Author ---
    assert_match %r{<h2 class="book-list-headline" id="#{author_c_slug}">#{CGI.escapeHTML(@author_c_name)}</h2>}, output
    assert_match(/<!-- Standalone Card: #{@book_ac_standalone.data['title']} -->/, output)

    # --- Assert Overall Order ---
    author_a_index = output.index("id=\"#{author_a_slug}\"")
    author_b_index = output.index("id=\"#{author_b_slug}\"")
    author_c_index = output.index("id=\"#{author_c_slug}\"")
    refute_nil author_a_index
    refute_nil author_b_index
    refute_nil author_c_index
    assert author_a_index < author_b_index
    assert author_b_index < author_c_index

    # Ensure book with no author is not processed
    refute_match(/Book With No Author/, output)
  end

  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({},
                                      { site: site_no_books,
                                        page: create_doc({ 'path' => 'current_tag_page.md' },
                                                         '/current_tag_page.html') })
    output = ''
    Jekyll.stub(:logger, @silent_logger_stub) { output = Liquid::Template.parse('{% display_books_by_author_then_series %}').render!(context_no_books) }
    assert_match(/<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_author'\s*SourcePage='current_tag_page\.md' -->/,
                 output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_renders_log_message_if_no_books_with_valid_authors_found
    site_no_valid_authors = create_site({ 'url' => 'http://example.com' }, { 'books' => [@book_no_author] })
    site_no_valid_authors.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_no_valid_authors = create_context({},
                                              { site: site_no_valid_authors,
                                                page: create_doc({ 'path' => 'current_tag_page.md' },
                                                                 '/current_tag_page.html') })
    output = ''
    Jekyll.stub(:logger, @silent_logger_stub) { output = Liquid::Template.parse('{% display_books_by_author_then_series %}').render!(context_no_valid_authors) }
    assert_match(/<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_tag_page\.md' -->/,
                 output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end

  def test_renders_empty_if_no_books_at_all_in_collection
    site_empty_books = create_site({ 'url' => 'http://example.com' }, { 'books' => [] })
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_AUTHOR_DISPLAY'] = true
    context_empty_books = create_context({},
                                         { site: site_empty_books,
                                           page: create_doc({ 'path' => 'current_tag_page.md' },
                                                            '/current_tag_page.html') })
    output = ''
    Jekyll.stub(:logger, @silent_logger_stub) { output = Liquid::Template.parse('{% display_books_by_author_then_series %}').render!(context_empty_books) }
    assert_match(/<!-- \[INFO\] ALL_BOOKS_BY_AUTHOR_DISPLAY_FAILURE: Reason='No published books with valid author names found\.'\s*SourcePage='current_tag_page\.md' -->/,
                 output)
    refute_match(/<h2 class="book-list-headline">/, output)
  end
end
