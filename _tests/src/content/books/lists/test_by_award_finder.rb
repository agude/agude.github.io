# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/lists/by_award_finder'

# Tests for Jekyll::Books::Lists::ByAwardFinder
#
# Verifies that the finder correctly groups books by award, formats award names,
# and handles various edge cases including multi-word awards, initials, and case sensitivity.
class TestBookListByAwardFinder < Minitest::Test
  def setup
    # --- Book Data for Award Display Tests ---
    @award_book_hugo_locus = create_doc(
      {
        'title' => 'The Apple',
        'awards' => %w[Hugo Locus],
        'published' => true,
        'date' => Time.now,
      },
      '/award_a.html',
    )
    @award_book_nebula = create_doc(
      { 'title' => 'Book B (Nebula)', 'awards' => ['Nebula'], 'published' => true, 'date' => Time.now }, '/award_b.html',
    )
    @award_book_hugo_lower = create_doc(
      { 'title' => 'Cherry', 'awards' => ['hugo'], 'published' => true, 'date' => Time.now }, '/award_c.html',
    )
    @award_book_acc = create_doc(
      {
        'title' => 'Book D (Arthur C. Clarke)',
        'awards' => ['arthur c. clarke'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_d.html',
    )
    @award_book_no_awards = create_doc(
      { 'title' => 'Book E (No Awards)', 'published' => true, 'date' => Time.now },
      '/award_e.html',
    )
    @award_book_locus_only = create_doc(
      {
        'title' => 'Fig',
        'awards' => ['Locus'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_f.html',
    )
    @award_book_mixed_case = create_doc(
      {
        'title' => 'Book G (mIxEd CaSe AwArD)',
        'awards' => ['mIxEd CaSe AwArD'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_g.html',
    )
    @award_book_locus_sf_novel = create_doc(
      {
        'title' => 'Locus SF Winner',
        'awards' => ['Locus for Best SF Novel'],
        'published' => true,
        'date' => Time.now,
      },
      '/locus_sf.html',
    )
    @award_book_empty_award_array = create_doc(
      {
        'title' => 'Book H (Empty Awards Array)',
        'awards' => [],
        'published' => true,
        'date' => Time.now,
      },
      '/award_h.html',
    )
    @award_book_nil_in_awards = create_doc(
      {
        'title' => 'Book I (Nil in Awards)',
        'awards' => ['Valid Award', nil, 'Another Valid'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_i.html',
    )
    @unpublished_award_book = create_doc(
      {
        'title' => 'Unpublished Award Book',
        'awards' => ['Hugo'],
        'published' => false,
        'date' => Time.now,
      },
      '/unpub_award.html',
    )
    @award_book_pkd = create_doc(
      {
        'title' => 'Book J (Philip K. Dick)',
        'awards' => ['philip k. dick'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_j.html',
    )
    @award_book_british_fantasy = create_doc(
      {
        'title' => 'Book K (British Fantasy)',
        'awards' => ['british fantasy'],
        'published' => true,
        'date' => Time.now,
      },
      '/award_k.html',
    )

    @books_for_award_tests = [
      @award_book_hugo_locus,
      @award_book_nebula,
      @award_book_hugo_lower,
      @award_book_acc,
      @award_book_no_awards,
      @award_book_locus_only,
      @award_book_mixed_case,
      @award_book_locus_sf_novel,
      @award_book_empty_award_array,
      @award_book_nil_in_awards,
      @unpublished_award_book,
      @award_book_pkd,
      @award_book_british_fantasy,
    ]

    @site = create_site({}, { 'books' => @books_for_award_tests })
    @context = create_context(
      {},
      {
        site: @site,
        page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html'),
      },
    )

    @silent_logger_stub = silent_logger
  end

  # Helper to call the finder directly
  def get_all_books_by_award_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::Books::Lists::ByAwardFinder.new(site: site, context: context)
      finder.find
    end
  end

  def test_by_award_finder_correct_grouping_and_sorting
    assert_equal(
      {
        awards_data: [
          { award_name: 'Another Valid Award', award_slug: 'another-valid-award', books: [@award_book_nil_in_awards] },
          { award_name: 'Arthur C. Clarke Award', award_slug: 'arthur-c-clarke-award', books: [@award_book_acc] },
          { award_name: 'British Fantasy Award', award_slug: 'british-fantasy-award', books: [@award_book_british_fantasy] },
          { award_name: 'Hugo Award', award_slug: 'hugo-award', books: [@award_book_hugo_locus, @award_book_hugo_lower] },
          { award_name: 'Locus Award', award_slug: 'locus-award', books: [@award_book_hugo_locus, @award_book_locus_only] },
          { award_name: 'Locus For Best Sf Novel Award', award_slug: 'locus-for-best-sf-novel-award', books: [@award_book_locus_sf_novel] },
          { award_name: 'Mixed Case Award Award', award_slug: 'mixed-case-award-award', books: [@award_book_mixed_case] },
          { award_name: 'Nebula Award', award_slug: 'nebula-award', books: [@award_book_nebula] },
          { award_name: 'Philip K. Dick Award', award_slug: 'philip-k-dick-award', books: [@award_book_pkd] },
          { award_name: 'Valid Award Award', award_slug: 'valid-award-award', books: [@award_book_nil_in_awards] },
        ],
        log_messages: '',
      },
      get_all_books_by_award_data,
    )
  end

  def test_by_award_finder_no_books_with_awards
    site_no_awards = create_site({}, { 'books' => [@award_book_no_awards, @award_book_empty_award_array] })
    site_no_awards.config['plugin_logging']['ALL_BOOKS_BY_AWARD_DISPLAY'] = true
    context_no_awards = create_context({}, { site: site_no_awards, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_no_awards, context_no_awards)
    assert_empty result[:awards_data]
    assert_match(
      /<!-- \[INFO\] ALL_BOOKS_BY_AWARD_DISPLAY_FAILURE: Reason='No books with awards found\.'\s*SourcePage='current_page\.html' -->/,
      result[:log_messages],
    )
  end

  def test_by_award_finder_books_collection_missing
    site_no_books_coll = create_site({}, {})
    site_no_books_coll.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_coll = create_context({}, { site: site_no_books_coll, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_no_books_coll, context_no_books_coll)
    assert_empty result[:awards_data]
    assert_match(
      /<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_award'\s*SourcePage='current_page\.html' -->/,
      result[:log_messages],
    )
  end

  def test_by_award_finder_empty_book_collection
    site_empty_books = create_site({}, { 'books' => [] })
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_empty_books, context_empty_books)
    assert_empty result[:awards_data]
    assert_empty result[:log_messages].to_s # Finder returns early before logging "no awards found"
  end

  def test_find_ignores_nil_and_blank_award_entries
    book = create_doc({ 'awards' => [nil, '', '   ', ' Hugo '] }, '/book.html')
    malformed_book = create_doc({ 'awards' => 'Hugo' }, '/malformed.html')
    site = create_site({}, { 'books' => [book, malformed_book] })
    context = create_context({}, { site: site, page: @context.registers[:page] })

    assert_equal(
      { awards_data: [{ award_name: 'Hugo Award', award_slug: 'hugo-award', books: [book] }], log_messages: '' },
      get_all_books_by_award_data(site, context),
    )
  end
end
