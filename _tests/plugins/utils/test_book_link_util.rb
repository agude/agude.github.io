# frozen_string_literal: true

# _tests/plugins/utils/test_book_link_util.rb
require_relative '../../test_helper'

class TestBookLinkUtils < Minitest::Test
  def setup
    # Author pages for smart matching
    author_a_data = { 'title' => 'Author A', 'pen_names' => ['A. A. Penname'], 'layout' => 'author_page' }
    @author_a_page = create_doc(author_a_data, '/authors/a.html')
    @author_b_page = create_doc({ 'title' => 'Author B', 'layout' => 'author_page' }, '/authors/b.html')

    # Books for testing
    unique_book_data = { 'title' => 'Unique Book', 'published' => true, 'book_authors' => ['Author A'] }
    @unique_book = create_doc(unique_book_data, '/books/unique.html')
    amb_a_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author A'] }
    @ambiguous_book_a = create_doc(amb_a_data, '/books/ambiguous-a.html')
    amb_b_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author B'] }
    @ambiguous_book_b = create_doc(amb_b_data, '/books/ambiguous-b.html')
    pen_data = { 'title' => 'Pen Name Book', 'published' => true, 'book_authors' => ['A. A. Penname'] }
    @pen_name_book = create_doc(pen_data, '/books/penname.html')

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
    @silent_logger_stub = create_silent_logger
  end

  def render_link(title, link_text = nil, author = nil)
    BookLinkUtils.render_book_link(title, @ctx, link_text, author)
  end

  # Helper to create a silent logger stub
  def create_silent_logger
    logger = Object.new
    def logger.warn(_topic, _message); end
    def logger.error(_topic, _message); end
    def logger.info(_topic, _message); end
    def logger.debug(_topic, _message); end
    logger
  end

  def test_render_unique_book_succeeds
    expected = '<a href="/books/unique.html"><cite class="book-title">Unique Book</cite></a>'
    assert_equal expected, render_link('Unique Book')
  end

  def test_render_ambiguous_book_without_author_fails_build
    err = assert_raises(Jekyll::Errors::FatalException) do
      render_link('Ambiguous Book')
    end
    assert_match '[FATAL] Ambiguous book title', err.message
    assert_match "The book title \"Ambiguous Book\" is used by multiple authors: 'Author A'; 'Author B'", err.message
    assert_match 'Fix: Add an author parameter', err.message
  end

  def test_render_ambiguous_book_with_correct_author_succeeds
    expected = '<a href="/books/ambiguous-a.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected, render_link('Ambiguous Book', nil, 'Author A')

    expected_b = '<a href="/books/ambiguous-b.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected_b, render_link('Ambiguous Book', nil, 'Author B')
  end

  def test_render_ambiguous_book_with_author_pen_name_succeeds
    # "A. A. Penname" is a pen name for "Author A"
    expected = '<a href="/books/ambiguous-a.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected, render_link('Ambiguous Book', nil, 'A. A. Penname')
  end

  def test_render_book_by_pen_name_succeeds
    # Link to a book that was published under a pen name
    expected = '<a href="/books/penname.html"><cite class="book-title">Pen Name Book</cite></a>'
    assert_equal expected, render_link('Pen Name Book')
  end

  def test_render_ambiguous_book_with_wrong_author_warns_and_renders_unlinked
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link('Ambiguous Book', nil, 'Wrong Author')
    end
    # The log message is now expected to be prepended to the output
    expected_pattern = '<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Book title exists, but not by the specified author.' .*? -->" \
                       '<cite class="book-title">Ambiguous Book</cite>'
    assert_match(/#{expected_pattern}/, output)
  end

  def test_render_book_not_found_warns_and_renders_unlinked
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link('Non-existent Book')
    end
    # The log message is now expected to be prepended to the output
    expected_pattern = '<!-- \[INFO\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Could not find book page in cache.' .*? -->" \
                       '<cite class="book-title">Non-existent Book</cite>'
    assert_match(/#{expected_pattern}/, output)
  end

  def test_render_book_link_empty_input_title
    output_nil = nil
    output_empty = nil
    Jekyll.stub :logger, @silent_logger_stub do
      # The utility now returns a log message for empty input, which we should assert.
      output_nil = render_link(nil)
      output_empty = render_link('  ')
    end
    expected_msg = '<!-- [WARN] RENDER_BOOK_LINK_FAILURE: ' \
                   "Reason='Input title resolved to empty after normalization.'"
    assert_match expected_msg, output_nil
    assert_match expected_msg, output_empty
  end

  def test_unique_book_with_correct_author_param_succeeds
    expected = '<a href="/books/unique.html"><cite class="book-title">Unique Book</cite></a>'
    # This would have passed before, but it's good to have an explicit test.
    assert_equal expected, render_link('Unique Book', nil, 'Author A')
  end

  def test_unique_book_with_incorrect_author_param_renders_unlinked
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link('Unique Book', nil, 'Wrong Author')
    end
    # With the fix, this should correctly fail to find a match and render unlinked cite tag with warning.
    expected_pattern = '<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Book title exists, but not by the specified author.' .*? -->" \
                       '<cite class="book-title">Unique Book</cite>'
    assert_match(/#{expected_pattern}/, output)
  end

  def test_unreviewed_mention_is_tracked
    # Ensure the tracker is empty before the test
    @site.data['mention_tracker'].clear

    unreviewed_title = 'Unreviewed Masterpiece'
    normalized_title = 'unreviewed masterpiece'

    # Call the render function, which will trigger the tracking on failure
    Jekyll.stub :logger, @silent_logger_stub do
      render_link(unreviewed_title)
    end

    # Assert that the tracker was populated correctly
    tracker = @site.data['mention_tracker']
    refute_nil tracker[normalized_title], 'Tracker should have an entry for the normalized title'

    mention_data = tracker[normalized_title]
    msg_count = 'Original title casing should be counted'
    assert_equal 1, mention_data[:original_titles][unreviewed_title], msg_count
    msg_source = 'Source page URL should be in the set of sources'
    assert_includes mention_data[:sources], @page.url, msg_source

    # Call it again from a different page to ensure the count and set grow
    another_page = create_doc({ 'path' => 'another.html' }, '/another.html')
    another_ctx = create_context({}, { site: @site, page: another_page })
    Jekyll.stub :logger, @silent_logger_stub do
      BookLinkUtils.render_book_link(unreviewed_title, another_ctx)
    end

    mention_data = tracker[normalized_title]
    assert_equal 2, mention_data[:original_titles][unreviewed_title]
    assert_equal 2, mention_data[:sources].size
    assert_includes mention_data[:sources], another_page.url
  end

  def test_prefers_canonical_review_over_archived
    canonical_data = { 'title' => 'Same Title', 'published' => true, 'book_authors' => ['Author A'] }
    canonical_book = create_doc(canonical_data, '/books/canonical.html')
    archived_data = {
      'title' => 'Same Title', 'published' => true, 'book_authors' => ['Author A'],
      'canonical_url' => '/books/canonical.html'
    }
    archived_book = create_doc(archived_data, '/books/archived.html')

    site = create_site(
      {},
      { 'books' => [canonical_book, archived_book] },
      [@author_a_page]
    )
    ctx = create_context({}, { site: site, page: @page })

    # This call would be ambiguous without the filtering logic
    output = BookLinkUtils.render_book_link('Same Title', ctx)

    expected = '<a href="/books/canonical.html"><cite class="book-title">Same Title</cite></a>'
    assert_equal expected, output
  end

  def test_handles_combined_ambiguity_of_author_and_archive
    # Setup: "Ambiguous Book" exists for Author A (with an archive) and Author B.
    canon_a_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author A'] }
    canonical_a = create_doc(canon_a_data, '/books/ambiguous-a.html')
    archived_a_data = {
      'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author A'],
      'canonical_url' => '/books/ambiguous-a.html'
    }
    archived_a = create_doc(archived_a_data, '/books/archived-a.html')
    canon_b_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author B'] }
    canonical_b = create_doc(canon_b_data, '/books/ambiguous-b.html')

    site = create_site(
      {},
      { 'books' => [canonical_a, archived_a, canonical_b] },
      [@author_a_page, @author_b_page]
    )
    ctx = create_context({}, { site: site, page: @page })

    # 1. Test that it's still ambiguous without an author filter
    err = assert_raises(Jekyll::Errors::FatalException) do
      BookLinkUtils.render_book_link('Ambiguous Book', ctx)
    end
    # The error message should only list the two canonical authors
    assert_match "used by multiple authors: 'Author A'; 'Author B'", err.message

    # 2. Test that it resolves correctly with an author filter
    output_a = BookLinkUtils.render_book_link('Ambiguous Book', ctx, nil, 'Author A')
    expected_a = '<a href="/books/ambiguous-a.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected_a, output_a

    output_b = BookLinkUtils.render_book_link('Ambiguous Book', ctx, nil, 'Author B')
    expected_b = '<a href="/books/ambiguous-b.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected_b, output_b
  end

  def test_does_not_filter_book_with_external_canonical_url
    # Setup: Two books with the same title, one normal, other points to external canonical URL.
    # This should still be treated as an ambiguity between two distinct books on our site.
    book_a_data = { 'title' => 'External Canon Test', 'published' => true, 'book_authors' => ['Author A'] }
    book_a = create_doc(book_a_data, '/books/ext-a.html')
    book_b_data = {
      'title' => 'External Canon Test', 'published' => true, 'book_authors' => ['Author B'],
      'canonical_url' => 'http://some-other.site/original'
    }
    book_b_external = create_doc(book_b_data, '/books/ext-b.html')

    site = create_site({}, { 'books' => [book_a, book_b_external] }, [@author_a_page, @author_b_page])
    ctx = create_context({}, { site: site, page: @page })

    err = assert_raises(Jekyll::Errors::FatalException) do
      BookLinkUtils.render_book_link('External Canon Test', ctx)
    end
    assert_match "used by multiple authors: 'Author A'; 'Author B'", err.message
  end
end
