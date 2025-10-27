# _tests/plugins/test_display_books_by_award_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_books_by_award_tag'
require 'cgi'

class TestDisplayBooksByAwardTag < Minitest::Test
  def setup
    @book_hugo_locus = create_doc({ 'title' => 'Book A (Hugo & Locus)', 'awards' => ['Hugo', 'Locus'] }, '/award_a.html')
    @book_nebula = create_doc({ 'title' => 'Book B (Nebula)', 'awards' => ['Nebula'] }, '/award_b.html')
    @book_hugo_lower = create_doc({ 'title' => 'Book C (hugo)', 'awards' => ['hugo'] }, '/award_c.html')
    @book_acc = create_doc({ 'title' => 'Book D (Arthur C. Clarke)', 'awards' => ['arthur c. clarke'] }, '/award_d.html')

    @all_books_for_tag = [@book_hugo_locus, @book_nebula, @book_hugo_lower, @book_acc]
    @site = create_site({ 'url' => 'http://example.com' }, { 'books' => @all_books_for_tag })
    @context = create_context({}, { site: @site, page: create_doc({ 'path' => 'current_award_page.md'}, '/current_award_page.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end; def logger.debug(topic, message); end
    end
  end

  def render_tag(context = @context)
    output = ""
    BookCardUtils.stub :render, ->(book, _ctx) { "<!-- Card for: #{book.data['title']} -->\n" } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse("{% display_books_by_award %}").render!(context)
      end
    end
    output
  end

  def test_syntax_error_if_arguments_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_books_by_award some_arg %}")
    end
    assert_match "This tag does not accept any arguments", err.message
  end

  def test_renders_correct_award_headings_and_book_order
    output = render_tag

    # --- Assert Group for Arthur C. Clarke Award ---
    assert_match %r{<h3 class="book-list-headline" id="arthur-c-clarke-award">Arthur C. Clarke Award</h3>}, output
    expected_acc_cards = "<!-- Card for: #{Regexp.escape(@book_acc.data['title'])} -->"
    assert_match %r{id="arthur-c-clarke-award">Arthur C. Clarke Award</h3>\s*<div class="card-grid">\s*#{expected_acc_cards}\s*</div>}m, output

      # --- Assert Group for Hugo Award ---
      assert_match %r{<h3 class="book-list-headline" id="hugo-award">Hugo Award</h3>}, output
    # Books are sorted by title within the group. Use \s* to be flexible with newlines.
    expected_hugo_cards = "<!-- Card for: #{Regexp.escape(@book_hugo_locus.data['title'])} -->\\s*<!-- Card for: #{Regexp.escape(@book_hugo_lower.data['title'])} -->"
    assert_match %r{id="hugo-award">Hugo Award</h3>\s*<div class="card-grid">\s*#{expected_hugo_cards}\s*</div>}m, output

      # --- Assert Group for Locus Award ---
      assert_match %r{<h3 class="book-list-headline" id="locus-award">Locus Award</h3>}, output
    expected_locus_cards = "<!-- Card for: #{Regexp.escape(@book_hugo_locus.data['title'])} -->"
    assert_match %r{id="locus-award">Locus Award</h3>\s*<div class="card-grid">\s*#{expected_locus_cards}\s*</div>}m, output

      # --- Assert Group for Nebula Award ---
      assert_match %r{<h3 class="book-list-headline" id="nebula-award">Nebula Award</h3>}, output
    expected_nebula_cards = "<!-- Card for: #{Regexp.escape(@book_nebula.data['title'])} -->"
    assert_match %r{id="nebula-award">Nebula Award</h3>\s*<div class="card-grid">\s*#{expected_nebula_cards}\s*</div>}m, output

      # --- Assert Overall Order of Award Groups (Alphabetical) ---
      idx_acc = output.index('id="arthur-c-clarke-award"')
    idx_hugo = output.index('id="hugo-award"')
    idx_locus = output.index('id="locus-award"')
    idx_nebula = output.index('id="nebula-award"')

    refute_nil idx_acc; refute_nil idx_hugo; refute_nil idx_locus; refute_nil idx_nebula
    assert (idx_acc < idx_hugo && idx_hugo < idx_locus && idx_locus < idx_nebula), "Award groups are not in alphabetical order"
  end

  def test_handles_award_names_needing_html_escaping
    book_special_award = create_doc({ 'title' => 'Special Book', 'awards' => ["Science & Fantasy Readers' Choice"] })
    site = create_site({}, { 'books' => [book_special_award] })
    context = create_context({}, { site: site, page: create_doc({ 'path' => 'page.md'}, '/page.html') })

    output = render_tag(context)

    # The slug should be sanitized, removing the '&' and apostrophe.
    assert_match %r{<h3 class="book-list-headline" id="science-fantasy-readers-choice-award">}, output
    # The display name in the H3 tag should have the '&' escaped to '&amp;' and "'" to "&#39;"
    assert_match %r{id="science-fantasy-readers-choice-award">Science &amp; Fantasy Readers&#39; Choice Award</h3>}, output
  end

  def test_renders_log_message_if_books_collection_missing
    site_no_books = create_site({ 'url' => 'http://example.com' }, {})
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books = create_context({}, { site: site_no_books, page: create_doc({ 'path' => 'current_award_page.md'}, '/current_award_page.html') })
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_award %}").render!(context_no_books)
    end
    assert_match %r{<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_award'\s*SourcePage='current_award_page\.md' -->}, output
    refute_match %r{<h3 class="book-list-headline">}, output
  end

  def test_renders_log_message_if_no_books_with_awards_found
    site_no_awards = create_site({ 'url' => 'http://example.com' }, { 'books' => [create_doc({ 'title' => 'No Award Book' })] })
    site_no_awards.config['plugin_logging']['ALL_BOOKS_BY_AWARD_DISPLAY'] = true
    context_no_awards = create_context({}, { site: site_no_awards, page: create_doc({ 'path' => 'current_award_page.md'}, '/current_award_page.html') })
    output = ""
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% display_books_by_award %}").render!(context_no_awards)
    end
    assert_match %r{<!-- \[INFO\] ALL_BOOKS_BY_AWARD_DISPLAY_FAILURE: Reason='No books with awards found\.'\s*SourcePage='current_award_page\.md' -->}, output
    refute_match %r{<h3 class="book-list-headline">}, output
  end
end
