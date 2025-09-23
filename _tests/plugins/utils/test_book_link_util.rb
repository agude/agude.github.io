# _tests/plugins/utils/test_book_link_util.rb
require_relative '../../test_helper'

class TestBookLinkUtils < Minitest::Test
  def setup
    # Author pages for smart matching
    @author_a_page = create_doc({ 'title' => 'Author A', 'pen_names' => ['A. A. Penname'], 'layout' => 'author_page' }, '/authors/a.html')
    @author_b_page = create_doc({ 'title' => 'Author B', 'layout' => 'author_page' }, '/authors/b.html')

    # Books for testing
    @unique_book = create_doc({ 'title' => "Unique Book", 'published' => true, 'book_authors' => ['Author A'] }, '/books/unique.html')
    @ambiguous_book_a = create_doc({ 'title' => "Ambiguous Book", 'published' => true, 'book_authors' => ['Author A'] }, '/books/ambiguous-a.html')
    @ambiguous_book_b = create_doc({ 'title' => "Ambiguous Book", 'published' => true, 'book_authors' => ['Author B'] }, '/books/ambiguous-b.html')
    @pen_name_book = create_doc({ 'title' => "Pen Name Book", 'published' => true, 'book_authors' => ['A. A. Penname'] }, '/books/penname.html')

    @site = create_site(
      {},
      { 'books' => [@unique_book, @ambiguous_book_a, @ambiguous_book_b, @pen_name_book] },
      [@author_a_page, @author_b_page]
    )
    # Enable logging for this utility's tag type for all tests in this file.
    @site.config['plugin_logging']['RENDER_BOOK_LINK'] = true

    @page = create_doc({ 'path' => 'current.html' }, '/current.html') # Add path for error message context
    @ctx = create_context({}, { site: @site, page: @page })

    # Silent logger for tests that are expected to produce warnings/info logs
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end; def logger.debug(topic, message); end
    end
  end

  def render_link(title, link_text = nil, author = nil)
    BookLinkUtils.render_book_link(title, @ctx, link_text, author)
  end

  def test_render_unique_book_succeeds
    expected = "<a href=\"/books/unique.html\"><cite class=\"book-title\">Unique Book</cite></a>"
    assert_equal expected, render_link("Unique Book")
  end

  def test_render_ambiguous_book_without_author_fails_build
    err = assert_raises(Jekyll::Errors::FatalException) do
      render_link("Ambiguous Book")
    end
    assert_match "[FATAL] Ambiguous book title", err.message
    assert_match "The book title \"Ambiguous Book\" is used by multiple authors: 'Author A'; 'Author B'", err.message
    assert_match "Fix: Add an author parameter", err.message
  end

  def test_render_ambiguous_book_with_correct_author_succeeds
    expected = "<a href=\"/books/ambiguous-a.html\"><cite class=\"book-title\">Ambiguous Book</cite></a>"
    assert_equal expected, render_link("Ambiguous Book", nil, "Author A")

    expected_b = "<a href=\"/books/ambiguous-b.html\"><cite class=\"book-title\">Ambiguous Book</cite></a>"
    assert_equal expected_b, render_link("Ambiguous Book", nil, "Author B")
  end

  def test_render_ambiguous_book_with_author_pen_name_succeeds
    # "A. A. Penname" is a pen name for "Author A"
    expected = "<a href=\"/books/ambiguous-a.html\"><cite class=\"book-title\">Ambiguous Book</cite></a>"
    assert_equal expected, render_link("Ambiguous Book", nil, "A. A. Penname")
  end

  def test_render_book_by_pen_name_succeeds
    # Link to a book that was published under a pen name
    expected = "<a href=\"/books/penname.html\"><cite class=\"book-title\">Pen Name Book</cite></a>"
    assert_equal expected, render_link("Pen Name Book")
  end

  def test_render_ambiguous_book_with_wrong_author_warns_and_renders_unlinked
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link("Ambiguous Book", nil, "Wrong Author")
    end
    # The log message is now expected to be prepended to the output
    assert_match %r{<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: Reason='Book title exists, but not by the specified author.' .*? --><cite class=\"book-title\">Ambiguous Book</cite>}, output
  end

  def test_render_book_not_found_warns_and_renders_unlinked
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link("Non-existent Book")
    end
    # The log message is now expected to be prepended to the output
    assert_match %r{<!-- \[INFO\] RENDER_BOOK_LINK_FAILURE: Reason='Could not find book page in cache.' .*? --><cite class=\"book-title\">Non-existent Book</cite>}, output
  end

  def test_render_book_link_empty_input_title
    output_nil = nil
    output_empty = nil
    Jekyll.stub :logger, @silent_logger_stub do
      # The utility now returns a log message for empty input, which we should assert.
      output_nil = render_link(nil)
      output_empty = render_link("  ")
    end
    assert_match "<!-- [WARN] RENDER_BOOK_LINK_FAILURE: Reason='Input title resolved to empty after normalization.'", output_nil
    assert_match "<!-- [WARN] RENDER_BOOK_LINK_FAILURE: Reason='Input title resolved to empty after normalization.'", output_empty
  end
end
