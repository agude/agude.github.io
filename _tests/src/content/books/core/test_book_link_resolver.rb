# frozen_string_literal: true

# _tests/src/content/books/core/test_book_link_resolver.rb
require_relative '../../../../test_helper'

# Tests for Jekyll::Books::Core::BookLinkResolver.
#
# Verifies that the resolver correctly creates links to book reviews with ambiguity resolution and author filtering.
class TestBookLinkResolver < Minitest::Test
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
    book_with_empty_author_list_data = { 'title' => 'Empty Author Book', 'published' => true, 'book_authors' => [''] }
    @book_with_empty_author_list = create_doc(book_with_empty_author_list_data, '/books/empty-author.html')

    @site = create_site(
      {},
      { 'books' => [@unique_book, @ambiguous_book_a, @ambiguous_book_b, @pen_name_book, @book_with_empty_author_list] },
      [@author_a_page, @author_b_page]
    )
    # Enable logging for this utility's tag type for all tests in this file.
    @site.config['plugin_logging']['RENDER_BOOK_LINK'] = true

    @page = create_doc({ 'path' => 'current.html' }, '/current.html') # Add path for error message context
    @ctx = create_context({}, { site: @site, page: @page })

    # Silent logger for tests that are expected to produce warnings/info logs
    @silent_logger_stub = create_silent_logger
  end

  def render_link(title, link_text = nil, author = nil, context = @ctx)
    Jekyll::Books::Core::BookLinkResolver.new(context).resolve(title, link_text, author)
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

  def test_unique_book_with_link_text_override
    expected = '<a href="/books/unique.html"><cite class="book-title">Display Me</cite></a>'
    assert_equal expected, render_link('Unique Book', 'Display Me')
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
      Jekyll::Books::Core::BookLinkResolver.new(another_ctx).resolve(unreviewed_title, nil, nil)
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
    output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Same Title', nil, nil)

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
      Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Ambiguous Book', nil, nil)
    end
    # The error message should only list the two canonical authors
    assert_match "used by multiple authors: 'Author A'; 'Author B'", err.message

    # 2. Test that it resolves correctly with an author filter
    output_a = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Ambiguous Book', nil, 'Author A')
    expected_a = '<a href="/books/ambiguous-a.html"><cite class="book-title">Ambiguous Book</cite></a>'
    assert_equal expected_a, output_a

    output_b = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Ambiguous Book', nil, 'Author B')
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
      Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('External Canon Test', nil, nil)
    end
    assert_match "used by multiple authors: 'Author A'; 'Author B'", err.message
  end

  def test_resolver_handles_nil_site
    # This covers `context&.registers` when context is valid but registers is nil
    context_nil_registers = Struct.new(:registers).new(nil)
    output = render_link('Unique Book', nil, nil, context_nil_registers)
    expected = '<cite class="book-title">Unique Book</cite>'
    assert_equal expected, output

    # This covers `registers&.[](:site)` when registers is a hash but doesn't contain :site
    context_no_site_in_registers = create_context({}, {}) # No :site in registers
    output_no_site = render_link('Unique Book', nil, nil, context_no_site_in_registers)
    assert_equal expected, output_no_site
  end

  def test_resolver_handles_context_without_registers
    # A context object that doesn't respond to .registers
    context_no_registers = {}
    output = render_link('Unique Book', nil, nil, context_no_registers)
    # It should fallback to an unlinked cite tag because @site will be nil
    expected = '<cite class="book-title">Unique Book</cite>'
    assert_equal expected, output
  end

  def test_resolver_handles_nil_context
    # When context itself is nil, should safely handle and render unlinked cite tag
    output = render_link('Unique Book', nil, nil, nil)
    expected = '<cite class="book-title">Unique Book</cite>'
    assert_equal expected, output
  end

  def test_unreviewed_mention_not_tracked_if_page_url_missing
    @site.data['mention_tracker'].clear
    page_no_url = create_doc({ 'path' => 'no_url.html' }, nil)
    context_no_url = create_context({}, { site: @site, page: page_no_url })
    Jekyll.stub :logger, @silent_logger_stub do
      render_link('An Unreviewed Book', nil, nil, context_no_url)
    end
    assert_empty @site.data['mention_tracker']
  end

  def test_author_filter_with_empty_string_is_ignored
    # An empty author filter should be ignored, and the lookup should proceed as if no filter was given.
    # Since 'Ambiguous Book' is ambiguous without a filter, this should raise a fatal exception.
    err = assert_raises(Jekyll::Errors::FatalException) do
      render_link('Ambiguous Book', nil, '   ') # Whitespace-only author filter
    end
    assert_match '[FATAL] Ambiguous book title', err.message

    # For a unique book, it should succeed.
    expected = '<a href="/books/unique.html"><cite class="book-title">Unique Book</cite></a>'
    assert_equal expected, render_link('Unique Book', nil, '') # Empty string author filter
  end

  def test_author_filter_handles_book_with_empty_author_list
    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = render_link('Empty Author Book', nil, 'Some Author')
    end
    expected_pattern = '<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Book title exists, but not by the specified author.' .*? -->" \
                       '<cite class="book-title">Empty Author Book</cite>'
    assert_match(/#{expected_pattern}/, output)
  end

  def test_legacy_track_unreviewed_mention_works
    @site.data['mention_tracker'].clear
    unreviewed_title = 'Legacy Tracked Book'
    normalized_title = 'legacy tracked book'
    Jekyll.stub :logger, @silent_logger_stub do
      Jekyll::Books::Core::BookLinkResolver.new(@ctx).track_unreviewed_mention_explicit(unreviewed_title)
    end
    tracker = @site.data['mention_tracker']
    refute_nil tracker[normalized_title]
    assert_equal 1, tracker[normalized_title][:original_titles][unreviewed_title]
  end

  # --- Date Filter Tests ---

  def test_render_book_with_date_filter_succeeds
    # Setup: Two reviews of the same book on different dates
    review1_data = { 'title' => 'Multi Review Book', 'published' => true,
                     'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review1 = create_doc(review1_data, '/books/multi-review-1.html')
    review2_data = { 'title' => 'Multi Review Book', 'published' => true,
                     'book_authors' => ['Author A'], 'date' => Time.new(2025, 9, 20) }
    review2 = create_doc(review2_data, '/books/multi-review-2.html')

    site = create_site({}, { 'books' => [review1, review2] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    # Without date filter, this would be ambiguous (same author, same title)
    # With date filter, it should resolve to the correct one
    output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
      'Multi Review Book', nil, nil, '2023-10-17'
    )
    expected = '<a href="/books/multi-review-1.html"><cite class="book-title">Multi Review Book</cite></a>'
    assert_equal expected, output

    output2 = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
      'Multi Review Book', nil, nil, '2025-09-20'
    )
    expected2 = '<a href="/books/multi-review-2.html"><cite class="book-title">Multi Review Book</cite></a>'
    assert_equal expected2, output2
  end

  def test_render_book_with_date_filter_and_author_succeeds
    # Both filters together
    review_data = { 'title' => 'Dated Book', 'published' => true,
                    'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/dated.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
      'Dated Book', nil, 'Author A', '2023-10-17'
    )
    expected = '<a href="/books/dated.html"><cite class="book-title">Dated Book</cite></a>'
    assert_equal expected, output
  end

  def test_render_book_with_wrong_date_filter_warns
    review_data = { 'title' => 'Wrong Date Book', 'published' => true,
                    'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/wrong-date.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
        'Wrong Date Book', nil, nil, '2020-01-01'
      )
    end
    expected_pattern = '<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Book title exists, but not on the specified date.'"
    assert_match(/#{expected_pattern}/, output)
    assert_match('<cite class="book-title">Wrong Date Book</cite>', output)
  end

  def test_date_filter_with_empty_string_is_ignored
    # An empty date filter should be ignored
    expected = '<a href="/books/unique.html"><cite class="book-title">Unique Book</cite></a>'
    assert_equal expected, render_link_with_date('Unique Book', nil, nil, '   ')
    assert_equal expected, render_link_with_date('Unique Book', nil, nil, '')
  end

  def render_link_with_date(title, link_text = nil, author = nil, date = nil, context = @ctx)
    Jekyll::Books::Core::BookLinkResolver.new(context).resolve(title, link_text, author, date)
  end

  def test_render_book_with_date_filter_book_has_no_date
    # This tests line 129: `return false unless book_date` - book without date + date filter provided
    review_no_date_data = { 'title' => 'No Date Book', 'published' => true, 'book_authors' => ['Author A'] }
    # Create doc without setting date
    review_no_date = create_doc(review_no_date_data, '/books/no-date.html')
    # Don't set .date on the doc - it should be nil

    site = create_site({}, { 'books' => [review_no_date] }, [@author_a_page])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      # With a date filter, should fail because book has no date
      output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
        'No Date Book', nil, nil, '2023-10-17'
      )
    end
    expected_pattern = "Reason='Book title exists, but not on the specified date.'"
    assert_match(/#{expected_pattern}/, output)
  end

  def test_render_book_with_date_as_date_object
    # This tests line 138-139: `when Date` branch in normalize_date
    review_data = { 'title' => 'Date Object Book', 'published' => true, 'book_authors' => ['Author A'],
                    'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/date-obj.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    # Stub the book's date method to return a Date object instead of Time
    review.stub :date, Date.new(2023, 10, 17) do
      output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
        'Date Object Book', nil, nil, '2023-10-17'
      )
      expected = '<a href="/books/date-obj.html"><cite class="book-title">Date Object Book</cite></a>'
      assert_equal expected, output
    end
  end

  def test_render_book_with_date_as_string
    # This tests line 142-143: `else Date.parse(date_input.to_s)` branch
    review_data = { 'title' => 'String Date Book', 'published' => true, 'book_authors' => ['Author A'],
                    'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/string-date.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    # Stub the book's date method to return a string
    review.stub :date, '2023-10-17' do
      output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
        'String Date Book', nil, nil, '2023-10-17'
      )
      expected = '<a href="/books/string-date.html"><cite class="book-title">String Date Book</cite></a>'
      assert_equal expected, output
    end
  end

  def test_get_canonical_author_handles_empty_author_name
    # Test that when filtering by an empty author name, it's handled correctly.
    # This is tested indirectly - when a book has an empty author in its list,
    # the canonical author lookup should return nil for that empty author.
    # This is already partially covered by test_author_filter_handles_book_with_empty_author_list,
    # but let's ensure the edge case of comparing nil values works.

    # Create a book with an empty author that matches another book's title
    empty_auth_data = { 'title' => 'Test Title', 'published' => true, 'book_authors' => [''] }
    empty_auth_book = create_doc(empty_auth_data, '/books/empty.html')
    normal_data = { 'title' => 'Test Title', 'published' => true, 'book_authors' => ['Normal Author'] }
    normal_book = create_doc(normal_data, '/books/normal.html')

    site = create_site({}, { 'books' => [empty_auth_book, normal_book] }, [])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    # Since neither book can be disambiguated (one has empty author, one has normal),
    # this should raise an ambiguous error
    err = assert_raises(Jekyll::Errors::FatalException) do
      Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Test Title', nil, nil)
    end
    assert_match '[FATAL] Ambiguous book title', err.message
  end

  # --- resolve_data() tests ---

  def resolve_data_link(title, text = nil, author = nil, date = nil, context = @ctx, cite: true)
    Jekyll::Books::Core::BookLinkResolver.new(context).resolve_data(title, text, author, date, cite: cite)
  end

  def test_resolve_data_found
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Unique Book')
    end
    assert_equal :found, data[:status]
    assert_equal '/books/unique.html', data[:url]
    assert_equal 'Unique Book', data[:display_text]
    assert_equal 'Unique Book', data[:canonical_title]
    assert_equal true, data[:cite]
  end

  def test_resolve_data_found_cite_false
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Unique Book', nil, nil, nil, @ctx, cite: false)
    end
    assert_equal :found, data[:status]
    assert_equal false, data[:cite]
  end

  def test_resolve_data_not_found
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Non-existent Book')
    end
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
    assert_equal 'Non-existent Book', data[:display_text]
    assert_nil data[:canonical_title]
    assert_equal true, data[:cite]
  end

  def test_resolve_data_empty_title
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('')
    end
    assert_equal :empty_title, data[:status]
    assert_nil data[:url]
    assert_nil data[:display_text]
    assert_nil data[:canonical_title]
    assert_nil data[:cite]
  end

  def test_resolve_data_no_site
    context_no_site = create_context({}, {})
    data = resolve_data_link('Unique Book', nil, nil, nil, context_no_site)
    assert_equal :no_site, data[:status]
    assert_nil data[:url]
    assert_equal 'Unique Book', data[:display_text]
    assert_nil data[:canonical_title]
    assert_nil data[:cite]
  end

  def test_resolve_data_with_text_override
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Unique Book', 'Display Me')
    end
    assert_equal :found, data[:status]
    assert_equal 'Display Me', data[:display_text]
    assert_equal 'Unique Book', data[:canonical_title]
  end

  def test_resolve_data_ambiguous_raises
    assert_raises(Jekyll::Errors::FatalException) do
      resolve_data_link('Ambiguous Book')
    end
  end

  def test_resolve_data_found_display_text_uses_canonical_title
    # Raw input differs from canonical title (case/whitespace) — display_text should be canonical
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('  unique BOOK  ')
    end
    assert_equal :found, data[:status]
    assert_equal 'Unique Book', data[:display_text], 'display_text should be the canonical title, not raw input'
    assert_equal 'Unique Book', data[:canonical_title]
  end

  def test_resolve_data_frozen
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Unique Book')
    end
    assert data.frozen?, 'resolve_data() should return a frozen hash'
  end

  def test_resolve_data_date_filter_match
    review1_data = { 'title' => 'Dated Book', 'published' => true,
                     'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review1 = create_doc(review1_data, '/books/dated-1.html')
    review2_data = { 'title' => 'Dated Book', 'published' => true,
                     'book_authors' => ['Author A'], 'date' => Time.new(2025, 9, 20) }
    review2 = create_doc(review2_data, '/books/dated-2.html')

    site = create_site({}, { 'books' => [review1, review2] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data(
      'Dated Book', nil, nil, '2023-10-17'
    )
    assert_equal :found, data[:status]
    assert_equal '/books/dated-1.html', data[:url]
  end

  def test_resolve_data_date_filter_mismatch
    review_data = { 'title' => 'Wrong Date Book', 'published' => true,
                    'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/wrong-date.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data(
        'Wrong Date Book', nil, nil, '2020-01-01'
      )
    end
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
  end

  def test_resolve_data_author_filter_match
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Ambiguous Book', nil, 'Author A')
    end
    assert_equal :found, data[:status]
    assert_equal '/books/ambiguous-a.html', data[:url]
  end

  def test_resolve_data_author_filter_mismatch
    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = resolve_data_link('Ambiguous Book', nil, 'Wrong Author')
    end
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
  end

  def test_resolve_data_date_and_author_combined
    review_data = { 'title' => 'Combined Filter Book', 'published' => true,
                    'book_authors' => ['Author A'], 'date' => Time.new(2023, 10, 17) }
    review = create_doc(review_data, '/books/combined.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data(
      'Combined Filter Book', nil, 'Author A', '2023-10-17'
    )
    assert_equal :found, data[:status]
    assert_equal '/books/combined.html', data[:url]
  end

  def test_resolve_data_canonical_vs_archived
    canonical_data = { 'title' => 'Archive Test', 'published' => true, 'book_authors' => ['Author A'] }
    canonical_book = create_doc(canonical_data, '/books/canonical.html')
    archived_data = {
      'title' => 'Archive Test', 'published' => true, 'book_authors' => ['Author A'],
      'canonical_url' => '/books/canonical.html'
    }
    archived_book = create_doc(archived_data, '/books/archived.html')

    site = create_site({}, { 'books' => [canonical_book, archived_book] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data('Archive Test', nil, nil)
    assert_equal :found, data[:status]
    assert_equal '/books/canonical.html', data[:url]
  end

  def test_get_canonical_author_returns_nil_for_empty_name
    # Tests line 180: `return nil if name.to_s.strip.empty?`
    resolver = Jekyll::Books::Core::BookLinkResolver.new(@ctx)

    # Call private method directly with empty string
    result = resolver.send(:get_canonical_author, '', {})
    assert_nil result

    # Call with whitespace-only string
    result = resolver.send(:get_canonical_author, '   ', {})
    assert_nil result

    # Call with nil
    result = resolver.send(:get_canonical_author, nil, {})
    assert_nil result
  end
end
