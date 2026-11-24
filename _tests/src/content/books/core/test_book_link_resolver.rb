# frozen_string_literal: true

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
    unique_book_data = {
      'title' => 'Unique Book',
      'published' => true,
      'book_authors' => ['Author A'],
      'rating' => 5,
      'image' => '/images/unique.jpg',
    }
    @unique_book = create_doc(unique_book_data, '/books/unique.html')
    series_book_data = {
      'title' => 'Series Book',
      'published' => true,
      'book_authors' => ['Author A'],
      'series' => 'Test Series',
      'book_number' => 2,
    }
    @series_book = create_doc(series_book_data, '/books/series-book.html')
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
      {
        'books' => [
          @unique_book,
          @ambiguous_book_a,
          @ambiguous_book_b,
          @pen_name_book,
          @book_with_empty_author_list,
          @series_book,
        ],
      },
      [@author_a_page, @author_b_page],
    )
    # Enable logging for this utility's tag type for all tests in this file.
    @site.config['plugin_logging']['RENDER_BOOK_LINK'] = true

    @page = create_doc({ 'path' => 'current.html' }, '/current.html') # Add path for error message context
    @ctx = create_context({}, { site: @site, page: @page })

    # Silent logger for tests that are expected to produce warnings/info logs
    @silent_logger_stub = silent_logger
  end

  def render_link(title, link_text = nil, author = nil, context = @ctx)
    Jekyll::Books::Core::BookLinkResolver.new(context).resolve(title, link_text, author)
  end

  # Builds the expected hover-preview markup for a found book, using the real
  # renderer so these tests stay in sync with BookPreviewRenderer's output
  # rather than hand-duplicating its escaping/formatting rules.
  def preview_html(title:, authors:, rating: nil, image: nil, series: nil, book_number: nil)
    Jekyll::Books::Core::BookPreviewRenderer.new(
      @ctx,
      title,
      authors,
      rating,
      image,
      series: series,
      book_number: book_number,
    ).render
  end

  def test_render_rejects_status_from_another_resolver
    resolver = Jekyll::Books::Core::BookLinkResolver.new(nil)
    data = { status: :ambiguous, url: nil, display_text: 'Example' }

    error = assert_raises(Jekyll::Errors::FatalException) { resolver.send(:render_html_from_data, data) }

    assert_includes error.message, 'unrecognized status :ambiguous'
  end

  def test_render_returns_nil_for_an_unknown_status
    resolver = Jekyll::Books::Core::BookLinkResolver.new(nil)

    assert_nil resolver.send(:render_html_from_data, { status: :bogus, url: nil, display_text: 'Example' })
  end

  def test_renders_markdown_link
    context = create_context({}, { site: @site, page: @page, render_mode: :markdown })
    template = Liquid::Template.parse('{% book_link "Unique Book" %}')
    assert_equal '[_Unique Book_](/books/unique.html)', template.render!(context)
  end

  def test_render_series_book_includes_series_preview
    output = Liquid::Template.parse('{% book_link "Series Book" %}').render!(@ctx)
    assert_match(%r{\A<a href="/books/series-book\.html"><cite class="book-title">Series Book</cite><!--book-preview-->}, output)
    assert_includes output, '<span class="book-link-preview-series"><span class="book-series">Test Series</span>&thinsp;#2</span>'
    assert output.end_with?('<!--/book-preview--></a>')
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
    { 'Author A' => '/books/ambiguous-a.html', 'Author B' => '/books/ambiguous-b.html' }.each do |author, url|
      data = resolve_data_link('Ambiguous Book', nil, author)
      assert_equal [:found, url, 'Ambiguous Book'], data.values_at(:status, :url, :display_text)
    end
  end

  def test_render_ambiguous_book_with_author_pen_name_succeeds
    data = resolve_data_link('Ambiguous Book', nil, 'A. A. Penname')
    assert_equal [:found, '/books/ambiguous-a.html', 'Ambiguous Book'], data.values_at(:status, :url, :display_text)
  end

  def test_render_book_by_pen_name_succeeds
    data = resolve_data_link('Pen Name Book')
    assert_equal [:found, '/books/penname.html', 'Pen Name Book'], data.values_at(:status, :url, :display_text)
    assert_equal ['A. A. Penname'], data[:authors]
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
    assert_match(/#{expected_pattern}\z/, output)
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

  def test_handles_combined_ambiguity_of_author_and_archive
    # Setup: "Ambiguous Book" exists for Author A (with an archive) and Author B.
    canon_a_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author A'] }
    canonical_a = create_doc(canon_a_data, '/books/ambiguous-a.html')
    archived_a_data = {
      'title' => 'Ambiguous Book',
      'published' => true,
      'book_authors' => ['Author A'],
      'canonical_url' => '/books/ambiguous-a.html',
    }
    archived_a = create_doc(archived_a_data, '/books/archived-a.html')
    canon_b_data = { 'title' => 'Ambiguous Book', 'published' => true, 'book_authors' => ['Author B'] }
    canonical_b = create_doc(canon_b_data, '/books/ambiguous-b.html')

    site = create_site(
      {},
      { 'books' => [canonical_a, archived_a, canonical_b] },
      [@author_a_page, @author_b_page],
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
    preview_a = preview_html(title: 'Ambiguous Book', authors: ['Author A'])
    expected_a = "<a href=\"/books/ambiguous-a.html\"><cite class=\"book-title\">Ambiguous Book</cite>#{preview_a}</a>"
    assert_equal expected_a, output_a

    output_b = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Ambiguous Book', nil, 'Author B')
    preview_b = preview_html(title: 'Ambiguous Book', authors: ['Author B'])
    expected_b = "<a href=\"/books/ambiguous-b.html\"><cite class=\"book-title\">Ambiguous Book</cite>#{preview_b}</a>"
    assert_equal expected_b, output_b
  end

  def test_resolver_handles_nil_site
    [nil, {}, Struct.new(:registers).new(nil), create_context({}, {})].each do |context|
      assert_equal '<cite class="book-title">Unique Book</cite>', render_link('Unique Book', nil, nil, context)
    end
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
    preview = preview_html(title: 'Unique Book', authors: ['Author A'], rating: 5, image: '/images/unique.jpg')
    expected = "<a href=\"/books/unique.html\"><cite class=\"book-title\">Unique Book</cite>#{preview}</a>"
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

  def test_render_book_with_date_filter_succeeds
    cache = @site.data['link_cache']['books']
    cache['ambiguous book'].zip([Time.new(2023, 10, 17), Time.new(2025, 9, 20)]).each do |book, date|
      book['date'] = date
    end
    early = resolve_data_link('Ambiguous Book', nil, nil, '2023-10-17')
    late = resolve_data_link('Ambiguous Book', nil, nil, '2025-09-20')
    assert_equal [:found, '/books/ambiguous-a.html'], early.values_at(:status, :url)
    assert_equal [:found, '/books/ambiguous-b.html'], late.values_at(:status, :url)
  end

  def test_render_book_with_wrong_date_filter_warns
    review_data = {
      'title' => 'Wrong Date Book',
      'published' => true,
      'book_authors' => ['Author A'],
      'date' => Time.new(2023, 10, 17),
    }
    review = create_doc(review_data, '/books/wrong-date.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    output = nil
    Jekyll.stub :logger, @silent_logger_stub do
      output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve(
        'Wrong Date Book', nil, nil, '2020-01-01',
      )
    end
    expected_pattern = '<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: ' \
                       "Reason='Book title exists, but not on the specified date.'"
    assert_match(/#{expected_pattern}/, output)
    assert_match('<cite class="book-title">Wrong Date Book</cite>', output)
  end

  def test_date_filter_with_empty_string_is_ignored
    ['   ', ''].each do |date|
      data = resolve_data_link('Unique Book', nil, nil, date)
      assert_equal [:found, '/books/unique.html'], data.values_at(:status, :url)
    end
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
        'No Date Book', nil, nil, '2023-10-17',
      )
    end
    expected_pattern = "Reason='Book title exists, but not on the specified date.'"
    assert_match(/#{expected_pattern}/, output)
  end

  def test_render_book_with_date_as_date_object
    @site.data['link_cache']['books']['unique book'].first['date'] = Date.new(2023, 10, 17)
    data = resolve_data_link('Unique Book', nil, nil, '2023-10-17')
    assert_equal [:found, '/books/unique.html'], data.values_at(:status, :url)
  end

  def test_render_book_with_date_as_string
    @site.data['link_cache']['books']['unique book'].first['date'] = '2023-10-17'
    data = resolve_data_link('Unique Book', nil, nil, '2023-10-17')
    assert_equal [:found, '/books/unique.html'], data.values_at(:status, :url)
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

  def resolve_data_link(title, text = nil, author = nil, date = nil, context = @ctx, cite: true)
    Jekyll::Books::Core::BookLinkResolver.new(context).resolve_data(title, text, author, date, cite: cite)
  end

  def test_resolve_data_found
    data = resolve_data_link('Unique Book')
    assert_equal [:found, '/books/unique.html', 'Unique Book'], data.values_at(:status, :url, :display_text)
  end

  def test_resolve_data_found_cite_false
    data = resolve_data_link('Unique Book', cite: false)
    assert_equal [:found, '/books/unique.html', false], data.values_at(:status, :url, :cite)
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

  def test_unpublished_book_has_no_target
    book = create_doc(
      { 'title' => 'Unpublished Book', 'published' => false, 'book_authors' => ['Author A'] },
      '/books/unpublished.html',
    )
    site = create_site({}, { 'books' => [book] }, [@author_a_page])
    context = create_context({}, { site: site, page: @page })
    data = resolve_data_link('Unpublished Book', nil, nil, nil, context)
    assert_equal [:not_found, nil, 'Unpublished Book'], data.values_at(:status, :url, :display_text)
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
    data = resolve_data_link('Unique Book', '  Display Me  ')
    assert_equal [:found, '/books/unique.html', 'Display Me'], data.values_at(:status, :url, :display_text)
  end

  def test_resolve_data_ambiguous_raises
    assert_raises(Jekyll::Errors::FatalException) do
      resolve_data_link('Ambiguous Book')
    end
  end

  def test_resolve_data_found_display_text_uses_canonical_title
    data = resolve_data_link('  unique BOOK  ')
    assert_equal [:found, '/books/unique.html', 'Unique Book'], data.values_at(:status, :url, :display_text)
  end

  def test_resolve_data_date_filter_mismatch
    review_data = {
      'title' => 'Wrong Date Book',
      'published' => true,
      'book_authors' => ['Author A'],
      'date' => Time.new(2023, 10, 17),
    }
    review = create_doc(review_data, '/books/wrong-date.html')

    site = create_site({}, { 'books' => [review] }, [@author_a_page])
    site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    ctx = create_context({}, { site: site, page: @page })

    data = nil
    Jekyll.stub :logger, @silent_logger_stub do
      data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data(
        'Wrong Date Book', nil, nil, '2020-01-01',
      )
    end
    assert_equal :not_found, data[:status]
    assert_nil data[:url]
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
    @site.data['link_cache']['books']['ambiguous book'].first['date'] = Time.new(2023, 10, 17)

    data = resolve_data_link('Ambiguous Book', nil, 'Author A', '2023-10-17')
    assert_equal [:found, '/books/ambiguous-a.html'], data.values_at(:status, :url)

    data = Jekyll.stub(:logger, silent_logger) do
      resolve_data_link('Ambiguous Book', nil, 'Author B', '2023-10-17')
    end
    assert_equal [:not_found, nil], data.values_at(:status, :url)
  end

  def test_resolve_data_canonical_vs_archived
    canonical_data = { 'title' => 'Archive Test', 'published' => true, 'book_authors' => ['Author A'] }
    canonical_book = create_doc(canonical_data, '/books/canonical.html')
    archived_data = {
      'title' => 'Archive Test',
      'published' => true,
      'book_authors' => ['Author A'],
      'canonical_url' => '/books/canonical.html',
    }
    archived_book = create_doc(archived_data, '/books/archived.html')

    site = create_site({}, { 'books' => [canonical_book, archived_book] }, [@author_a_page])
    ctx = create_context({}, { site: site, page: @page })

    data = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve_data('Archive Test', nil, nil)
    assert_equal :found, data[:status]
    assert_equal '/books/canonical.html', data[:url]
  end

  def test_render_from_data_with_cite_true
    resolver = Jekyll::Books::Core::BookLinkResolver.new(@ctx)
    result = resolver.render_from_data("Something's Wrong", '/books/unique.html')
    assert_equal '<a href="/books/unique.html"><cite class="book-title">Something’s Wrong</cite></a>', result
  end

  def test_render_from_data_with_cite_false
    resolver = Jekyll::Books::Core::BookLinkResolver.new(@ctx)
    result = resolver.render_from_data('Unique Book', '/books/unique.html', cite: false)
    assert_equal '<a href="/books/unique.html"><span class="book-text">Unique Book</span></a>', result
  end

  def test_render_from_data_self_link_no_anchor
    # When the current page URL matches the link URL, no <a> wrapper
    page = create_doc({ 'path' => 'self.html' }, '/books/unique.html')
    ctx = create_context({}, { site: @site, page: page })
    resolver = Jekyll::Books::Core::BookLinkResolver.new(ctx)
    result = resolver.render_from_data('Unique Book', '/books/unique.html')
    assert_equal '<cite class="book-title">Unique Book</cite>', result
  end

  def test_resolve_self_link_contains_no_preview
    # A self-link never generates an <a> wrapper (Case 3), so the preview
    # (built but discarded by LinkHelperUtils) must not appear anywhere.
    page = create_doc({ 'path' => 'self.html' }, '/books/unique.html')
    ctx = create_context({}, { site: @site, page: page })
    output = Jekyll::Books::Core::BookLinkResolver.new(ctx).resolve('Unique Book', nil, nil)
    refute_match(/book-preview/, output)
    refute_match(/<a /, output)
  end
end
