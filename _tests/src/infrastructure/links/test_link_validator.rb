# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::Links::LinkValidator
#
# Verifies that raw Markdown/HTML links to books, authors, and series
# are detected and raise errors.
class TestLinkValidator < Minitest::Test
  def setup
    @book = create_doc(
      { 'title' => 'Test Book', 'published' => true },
      '/books/test-book.html'
    )
    @author_page = create_doc(
      { 'title' => 'Jane Doe', 'layout' => 'author_page' },
      '/authors/jane-doe.html'
    )
    @series_page = create_doc(
      { 'title' => 'Test Series', 'layout' => 'series_page' },
      '/series/test-series.html'
    )
  end

  def test_passes_when_no_raw_links
    post = create_doc(
      { 'title' => 'Clean Post' },
      '/posts/clean.html',
      "This post uses {% book_link 'Test Book' %} properly."
    )

    # Should not raise
    site = create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    assert site.data['link_cache']
  end

  def test_detects_raw_markdown_link_to_book
    post = create_doc(
      { 'title' => 'Bad Post' },
      '/posts/bad.html',
      'Check out [this book](/books/test-book.html)!'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, 'Found raw Markdown/HTML links'
    assert_includes error.message, 'Markdown:'
    assert_includes error.message, '/books/test-book.html'
  end

  def test_detects_raw_html_link_to_book
    post = create_doc(
      { 'title' => 'Bad Post' },
      '/posts/bad.html',
      '<a href="/books/test-book.html">Read this</a>'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, 'HTML:'
  end

  def test_detects_raw_link_to_author
    post = create_doc(
      { 'title' => 'Bad Post' },
      '/posts/bad.html',
      '[Jane Doe](/authors/jane-doe.html) wrote great books.'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, '/authors/jane-doe.html'
  end

  def test_detects_raw_link_to_series
    post = create_doc(
      { 'title' => 'Bad Post' },
      '/posts/bad.html',
      'Read the [Test Series](/series/test-series.html).'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, '/series/test-series.html'
  end

  def test_allows_links_to_unknown_urls
    post = create_doc(
      { 'title' => 'External Links' },
      '/posts/external.html',
      '[External](https://example.com) and [internal](/other/page.html).'
    )

    # Should not raise - these are not known cached URLs
    site = create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    assert site.data['link_cache']
  end

  def test_handles_links_with_anchors
    post = create_doc(
      { 'title' => 'Anchor Link' },
      '/posts/anchor.html',
      '[Section](/books/test-book.html#chapter-1)'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    # Should detect even with anchor
    assert_includes error.message, '/books/test-book.html'
  end

  def test_reports_file_path_in_error
    post = create_doc(
      { 'title' => 'Bad Post', 'path' => 'posts/bad.html' },
      '/posts/bad.html',
      '[Bad link](/books/test-book.html)'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, 'posts/bad.html'
  end

  def test_checks_documents_and_pages
    bad_page = create_doc(
      { 'title' => 'Bad Page' },
      '/pages/bad.html',
      '[Link](/books/test-book.html)'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page, bad_page], [])
    end

    assert_includes error.message, '/books/test-book.html'
  end

  def test_detects_multiple_violations_in_same_file
    post = create_doc(
      { 'title' => 'Multiple Bad' },
      '/posts/multi.html',
      '[Book](/books/test-book.html) and [Author](/authors/jane-doe.html).'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    assert_includes error.message, '/books/test-book.html'
    assert_includes error.message, '/authors/jane-doe.html'
  end

  def test_detects_violations_across_multiple_files
    post1 = create_doc(
      { 'title' => 'Bad Post 1' },
      '/posts/bad1.html',
      '[Book](/books/test-book.html)'
    )
    post2 = create_doc(
      { 'title' => 'Bad Post 2' },
      '/posts/bad2.html',
      '[Author](/authors/jane-doe.html)'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post1, post2])
    end

    assert_includes error.message, 'posts/bad1.html'
    assert_includes error.message, '/books/test-book.html'
    assert_includes error.message, 'posts/bad2.html'
    assert_includes error.message, '/authors/jane-doe.html'
  end

  def test_deduplicates_repeated_violations_in_same_file
    post = create_doc(
      { 'title' => 'Repeat Bad' },
      '/posts/repeat.html',
      '[First](/books/test-book.html) and [Second](/books/test-book.html).'
    )

    error = assert_raises(Jekyll::Errors::FatalException) do
      create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [post])
    end

    # The error message should contain the link only once due to .uniq
    occurrences = error.message.scan('Markdown: /books/test-book.html').length
    assert_equal 1, occurrences, 'Duplicate violations should be deduplicated'
  end

  def test_skips_docs_without_content
    # MockDocument with nil content
    nil_doc = create_doc(
      { 'title' => 'No Content' },
      '/posts/nil.html',
      nil
    )

    # Should not raise
    site = create_site({}, { 'books' => [@book] }, [@author_page, @series_page], [nil_doc])
    assert site.data['link_cache']
  end
end
