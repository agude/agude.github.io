# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_by_title_alpha_finder.rb
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
      { site: @site, page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') }
    )
    @silent_logger_stub = create_silent_logger_stub
  end

  # Helper to call the finder directly
  def get_alpha_group_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::Books::Lists::ByTitleAlphaFinder.new(site: site, context: context)
      finder.find
    end
  end

  def test_by_title_alpha_finder_correct_grouping_and_sorting
    result = get_alpha_group_data

    assert_empty result[:log_messages].to_s
    # Expected groups: #, A, B, C, E, Z (based on the published books in setup)
    assert_equal 6, result[:alpha_groups].size, 'Incorrect number of alpha groups'

    assert_group_hash_correct(result)
    assert_group_a_correct(result)
    assert_group_b_correct(result)
    assert_group_c_correct(result)
    assert_group_e_correct(result)
    assert_group_z_correct(result)
    assert_letter_groups_ordered(result)
  end

  def test_by_title_alpha_finder_ignores_unpublished
    result = get_alpha_group_data
    all_rendered_titles = result[:alpha_groups].flat_map { |ag| ag[:books].map { |b| b.data['title'] } }
    refute_includes all_rendered_titles, @unpublished_book.data['title']
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
      '/apa.html'
    )
    # Sorts under B
    @book_a_banana = create_doc(
      { 'title' => 'A Banana Story', 'published' => true, 'date' => Time.now },
      '/abs.html'
    )
    # Sorts under C
    @book_the_cherry = create_doc(
      { 'title' => 'The Cherry Chronicle', 'published' => true, 'date' => Time.now },
      '/tcc.html'
    )
    # Sorts under A
    @book_another_apple = create_doc(
      { 'title' => 'Another Apple Tale', 'published' => true, 'date' => Time.now },
      '/aat.html'
    )
    # Sorts under A
    @book_aardvark = create_doc(
      { 'title' => 'Aardvark Antics', 'published' => true, 'date' => Time.now },
      '/aa.html'
    )
    # Sorts under Z
    @book_zebra = create_doc(
      { 'title' => 'Zebra Zoom', 'published' => true, 'date' => Time.now },
      '/zz.html'
    )
    # Sorts under #
    @book_123go = create_doc(
      { 'title' => '123 Go!', 'published' => true, 'date' => Time.now },
      '/123.html'
    )
    # Sorts under #
    @book_empty_title_sort = create_doc(
      { 'title' => 'The ', 'published' => true, 'date' => Time.now },
      '/the.html'
    )
    # Sorts under #
    @book_only_an = create_doc(
      { 'title' => 'An', 'published' => true, 'date' => Time.now },
      '/an.html'
    )
    @unpublished_book = create_doc(
      { 'title' => 'Unpublished Alpha Book', 'published' => false, 'date' => Time.now },
      '/unpub_alpha.html'
    )
    @archived_book = create_doc(
      { 'title' => 'Archived Book', 'published' => true, 'canonical_url' => '/some/path' },
      '/archived.html'
    )
    @external_canonical_book = create_doc(
      { 'title' => 'External Canon Book', 'published' => true, 'canonical_url' => 'http://othersite.com' },
      '/external.html'
    )
  end

  # Collects all test books into an array
  def collect_all_test_books
    [
      @book_apple, @book_a_banana, @book_the_cherry, @book_another_apple,
      @book_aardvark, @book_zebra, @book_123go, @book_empty_title_sort, @book_only_an,
      @unpublished_book, @archived_book, @external_canonical_book
    ]
  end

  # Creates a silent logger stub
  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # --- Assert Group # (Hash) ---
  # Books: "An" (norm: ""), "The " (norm: ""), "123 Go!" (norm: "123 go!")
  # Order within #: empty sort_titles first (sorted by original title), then "123 go!"
  def assert_group_hash_correct(result)
    group_hash = result[:alpha_groups].find { |g| g[:letter] == '#' }
    refute_nil group_hash, "Group '#' missing"
    expected_hash_titles = [
      @book_only_an.data['title'],
      @book_empty_title_sort.data['title'],
      @book_123go.data['title']
    ]
    actual_hash_titles = group_hash[:books].map { |b| b.data['title'] }
    assert_equal expected_hash_titles, actual_hash_titles
  end

  # --- Assert Group A ---
  # Books: Aardvark Antics, Another Apple Tale, Apple Pie Adventures (sorted by normalized title)
  def assert_group_a_correct(result)
    group_a = result[:alpha_groups].find { |g| g[:letter] == 'A' }
    refute_nil group_a, "Group 'A' missing"
    expected_a_titles = [
      @book_aardvark.data['title'],
      @book_another_apple.data['title'],
      @book_apple.data['title']
    ]
    assert_equal(expected_a_titles, group_a[:books].map { |b| b.data['title'] })
  end

  # --- Assert Group B ---
  # Book: A Banana Story (normalized: "banana story")
  def assert_group_b_correct(result)
    group_b = result[:alpha_groups].find { |g| g[:letter] == 'B' }
    refute_nil group_b, "Group 'B' missing"
    assert_equal([@book_a_banana.data['title']], group_b[:books].map { |b| b.data['title'] })
  end

  # --- Assert Group C ---
  # Book: The Cherry Chronicle (normalized: "cherry chronicle")
  def assert_group_c_correct(result)
    group_c = result[:alpha_groups].find { |g| g[:letter] == 'C' }
    refute_nil group_c, "Group 'C' missing"
    assert_equal([@book_the_cherry.data['title']], group_c[:books].map { |b| b.data['title'] })
  end

  # --- Assert Group E ---
  def assert_group_e_correct(result)
    group_e = result[:alpha_groups].find { |g| g[:letter] == 'E' }
    refute_nil group_e, "Group 'E' missing"
    assert_equal([@external_canonical_book.data['title']], group_e[:books].map { |b| b.data['title'] })
  end

  # --- Assert Group Z ---
  # Book: Zebra Zoom
  def assert_group_z_correct(result)
    group_z = result[:alpha_groups].find { |g| g[:letter] == 'Z' }
    refute_nil group_z, "Group 'Z' missing"
    assert_equal([@book_zebra.data['title']], group_z[:books].map { |b| b.data['title'] })
  end

  # --- Assert Overall Order of Letter Groups ---
  def assert_letter_groups_ordered(result)
    letters_ordered = result[:alpha_groups].map { |g| g[:letter] }
    assert_equal ['#', 'A', 'B', 'C', 'E', 'Z'], letters_ordered, 'Letter groups are not in # then A-Z order'
  end
end
