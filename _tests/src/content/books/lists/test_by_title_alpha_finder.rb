# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/by_title_alpha_finder'

# Tests for Jekyll::Books::Lists::ByTitleAlphaFinder
#
# Verifies that the finder correctly groups books by the first letter of their normalized title
# (with articles like "A", "An", "The" removed), handles edge cases, and sorts properly.
class TestBookListByTitleAlphaFinder < Minitest::Test
  def setup
    create_test_books
    @books_for_alpha_tests = collect_all_test_books
    @site = create_site({}, { 'books' => @books_for_alpha_tests })
    @context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') },
    )
    @silent_logger_stub = silent_logger
  end

  # Helper to call the finder directly
  def get_alpha_group_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::Books::Lists::ByTitleAlphaFinder.new(site: site, context: context)
      finder.find
    end
  end

  def test_by_title_alpha_finder_correct_grouping_and_sorting
    assert_equal(
      {
        alpha_groups: [
          { letter: '#', books: [@book_only_an, @book_empty_title_sort, @book_123go] },
          { letter: 'A', books: [@book_aardvark, @book_another_apple, @book_apple] },
          { letter: 'B', books: [@book_a_banana] },
          { letter: 'C', books: [@book_the_cherry] },
          { letter: 'Z', books: [@book_zebra] },
        ],
        log_messages: '',
      },
      get_alpha_group_data,
    )
  end

  def test_excludes_archived_reviews
    result = get_alpha_group_data
    all_rendered_titles = result[:alpha_groups].flat_map { |ag| ag[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @archived_book.data['title']
  end

  def test_by_title_alpha_finder_no_books_logs_info
    site_empty_books = create_site({}, { 'books' => [] }) # Empty collection
    # Enable specific logging
    site_empty_books.config['plugin_logging']['ALL_BOOKS_BY_TITLE_ALPHA_GROUP'] = true
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })

    result = get_alpha_group_data(site_empty_books, context_empty_books)
    assert_empty result[:alpha_groups]
    expected_log_pattern =
      /<!-- \[INFO\] ALL_BOOKS_BY_TITLE_ALPHA_GROUP_FAILURE: Reason='No published books found to group by title\.'\s*SourcePage='current_page\.html' -->/
    assert_match(expected_log_pattern, result[:log_messages])
  end

  def test_by_title_alpha_finder_collection_missing_logs_error
    site_no_books = create_site({}, {}) # No 'books' collection
    site_no_books.config['plugin_logging']['BOOK_LIST_UTIL'] = true # Enable general util logging
    context_no_books = create_context({}, { site: site_no_books, page: @context.registers[:page] })

    result = get_alpha_group_data(site_no_books, context_no_books)
    assert_empty result[:alpha_groups]
    expected_log_pattern =
      /<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_title_alpha_group'\s*SourcePage='current_page\.html' -->/
    assert_match(expected_log_pattern, result[:log_messages])
  end

  private

  # Creates all test book documents
  def create_test_books
    @book_apple = create_doc(
      { 'title' => 'Apple Pie Adventures', 'published' => true, 'date' => Time.now },
      '/apa.html',
    )
    # Sorts under B
    @book_a_banana = create_doc(
      { 'title' => 'A Banana Story', 'published' => true, 'date' => Time.now },
      '/abs.html',
    )
    # Sorts under C
    @book_the_cherry = create_doc(
      { 'title' => 'The Cherry Chronicle', 'published' => true, 'date' => Time.now },
      '/tcc.html',
    )
    # Sorts under A
    @book_another_apple = create_doc(
      { 'title' => 'Another Apple Tale', 'published' => true, 'date' => Time.now },
      '/aat.html',
    )
    # Sorts under A
    @book_aardvark = create_doc(
      { 'title' => 'Aardvark Antics', 'published' => true, 'date' => Time.now },
      '/aa.html',
    )
    # Sorts under Z
    @book_zebra = create_doc(
      { 'title' => 'Zebra Zoom', 'published' => true, 'date' => Time.now },
      '/zz.html',
    )
    # Sorts under #
    @book_123go = create_doc(
      { 'title' => '123 Go!', 'published' => true, 'date' => Time.now },
      '/123.html',
    )
    # Sorts under #
    @book_empty_title_sort = create_doc(
      { 'title' => 'The ', 'published' => true, 'date' => Time.now },
      '/the.html',
    )
    # Sorts under #
    @book_only_an = create_doc(
      { 'title' => 'An', 'published' => true, 'date' => Time.now },
      '/an.html',
    )
    @unpublished_book = create_doc(
      { 'title' => 'Unpublished Alpha Book', 'published' => false, 'date' => Time.now },
      '/unpub_alpha.html',
    )
    @archived_book = create_doc(
      { 'title' => 'Archived Book', 'published' => true, 'canonical_url' => '/some/path' },
      '/archived.html',
    )
  end

  # Collects all test books into an array
  def collect_all_test_books
    [
      @book_apple,
      @book_a_banana,
      @book_the_cherry,
      @book_another_apple,
      @book_aardvark,
      @book_zebra,
      @book_123go,
      @book_empty_title_sort,
      @book_only_an,
      @unpublished_book,
      @archived_book,
    ]
  end
end
