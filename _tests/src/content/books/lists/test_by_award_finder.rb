# frozen_string_literal: true

# _tests/plugins/logic/book_lists/test_by_award_finder.rb
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
      { 'title' => 'Book A (Hugo & Locus)', 'awards' => %w[Hugo Locus], 'published' => true,
        'date' => Time.now }, '/award_a.html'
    )
    @award_book_nebula = create_doc(
      { 'title' => 'Book B (Nebula)', 'awards' => ['Nebula'], 'published' => true, 'date' => Time.now }, '/award_b.html'
    )
    @award_book_hugo_lower = create_doc(
      { 'title' => 'Book C (hugo)', 'awards' => ['hugo'], 'published' => true, 'date' => Time.now }, '/award_c.html'
    )
    @award_book_acc = create_doc(
      { 'title' => 'Book D (Arthur C. Clarke)', 'awards' => ['arthur c. clarke'], 'published' => true,
        'date' => Time.now }, '/award_d.html'
    )
    @award_book_no_awards = create_doc({ 'title' => 'Book E (No Awards)', 'published' => true, 'date' => Time.now },
                                       '/award_e.html')
    @award_book_locus_only = create_doc(
      { 'title' => 'Book F (Locus Only)', 'awards' => ['Locus'], 'published' => true,
        'date' => Time.now }, '/award_f.html'
    )
    @award_book_mixed_case = create_doc(
      { 'title' => 'Book G (mIxEd CaSe AwArD)', 'awards' => ['mIxEd CaSe AwArD'], 'published' => true,
        'date' => Time.now }, '/award_g.html'
    )
    @award_book_locus_sf_novel = create_doc(
      { 'title' => 'Locus SF Winner', 'awards' => ['Locus for Best SF Novel'], 'published' => true,
        'date' => Time.now }, '/locus_sf.html'
    )
    @award_book_empty_award_array = create_doc(
      { 'title' => 'Book H (Empty Awards Array)', 'awards' => [], 'published' => true,
        'date' => Time.now }, '/award_h.html'
    )
    @award_book_nil_in_awards = create_doc(
      { 'title' => 'Book I (Nil in Awards)', 'awards' => ['Valid Award', nil, 'Another Valid'], 'published' => true,
        'date' => Time.now }, '/award_i.html'
    )
    @unpublished_award_book = create_doc(
      { 'title' => 'Unpublished Award Book', 'awards' => ['Hugo'], 'published' => false,
        'date' => Time.now }, '/unpub_award.html'
    )
    @award_book_pkd = create_doc(
      { 'title' => 'Book J (Philip K. Dick)', 'awards' => ['philip k. dick'], 'published' => true,
        'date' => Time.now }, '/award_j.html'
    )
    @award_book_british_fantasy = create_doc(
      { 'title' => 'Book K (British Fantasy)', 'awards' => ['british fantasy'], 'published' => true,
        'date' => Time.now }, '/award_k.html'
    )

    @books_for_award_tests = [
      @award_book_hugo_locus, @award_book_nebula, @award_book_hugo_lower, @award_book_acc,
      @award_book_no_awards, @award_book_locus_only, @award_book_mixed_case,
      @award_book_locus_sf_novel, @award_book_empty_award_array, @award_book_nil_in_awards,
      @unpublished_award_book, @award_book_pkd, @award_book_british_fantasy
    ]

    @site = create_site({}, { 'books' => @books_for_award_tests })
    @context = create_context({},
                              { site: @site,
                                page: create_doc({ 'path' => 'current_page.html' }, '/current_page.html') })

    @silent_logger_stub = create_silent_logger
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

  # Helper to call the finder directly
  def get_all_books_by_award_data(site = @site, context = @context)
    Jekyll.stub :logger, @silent_logger_stub do
      finder = Jekyll::Books::Lists::ByAwardFinder.new(site: site, context: context)
      finder.find
    end
  end

  def test_by_award_finder_correct_grouping_and_sorting
    result = get_all_books_by_award_data

    assert_empty result[:log_messages].to_s
    # Expected unique formatted awards:
    # "Another Valid Award", "Arthur C. Clarke Award", "British Fantasy Award", "Hugo Award", "Locus Award",
    # "Locus For Best Sf Novel Award", "Mixed Case Award Award", "Nebula Award", "Philip K. Dick Award", "Valid Award Award"
    # The format_award_display_name method appends " Award"
    # Raw unique awards are: "Another Valid", "arthur c. clarke", "british fantasy", "Hugo" (from Hugo & hugo),
    # "Locus", "Locus for Best SF Novel", "mIxEd CaSe AwArD", "Nebula", "philip k. dick", "Valid Award"
    # This makes 10 unique awards.
    assert_equal 10, result[:awards_data].size, 'Incorrect number of award groups'

    # Check Arthur C. Clarke Award
    acc_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Arthur C. Clarke Award' }
    refute_nil acc_award_data, 'Arthur C. Clarke Award group missing'
    assert_equal 'arthur-c-clarke-award', acc_award_data[:award_slug]
    assert_equal 1, acc_award_data[:books].size
    assert_equal @award_book_acc.data['title'], acc_award_data[:books][0].data['title']

    # Check Hugo Award (combines "Hugo" and "hugo")
    hugo_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Hugo Award' }
    refute_nil hugo_award_data, 'Hugo Award group missing'
    assert_equal 'hugo-award', hugo_award_data[:award_slug]
    assert_equal 2, hugo_award_data[:books].size
    assert_includes hugo_award_data[:books].map { |b| b.data['title'] }, @award_book_hugo_locus.data['title']
    assert_includes hugo_award_data[:books].map { |b| b.data['title'] }, @award_book_hugo_lower.data['title']
    # Check internal sort by title
    assert_equal [@award_book_hugo_locus.data['title'], @award_book_hugo_lower.data['title']].sort, hugo_award_data[:books].map { |b|
      b.data['title']
    }.sort

    # Check Locus Award
    locus_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Locus Award' }
    refute_nil locus_award_data, 'Locus Award group missing'
    assert_equal 'locus-award', locus_award_data[:award_slug]
    assert_equal 2, locus_award_data[:books].size
    assert_includes locus_award_data[:books].map { |b| b.data['title'] }, @award_book_hugo_locus.data['title']
    assert_includes locus_award_data[:books].map { |b| b.data['title'] }, @award_book_locus_only.data['title']

    # Check Locus For Best Sf Novel Award
    locus_sf_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Locus For Best Sf Novel Award' }
    refute_nil locus_sf_award_data, '"Locus For Best Sf Novel Award" group missing'
    assert_equal 'locus-for-best-sf-novel-award', locus_sf_award_data[:award_slug]
    assert_equal 1, locus_sf_award_data[:books].size
    assert_equal @award_book_locus_sf_novel.data['title'], locus_sf_award_data[:books][0].data['title']

    # Check Mixed Case Award Award
    mixed_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Mixed Case Award Award' }
    refute_nil mixed_award_data, 'Mixed Case Award Award group missing'
    assert_equal 'mixed-case-award-award', mixed_award_data[:award_slug]
    assert_equal 1, mixed_award_data[:books].size
    assert_equal @award_book_mixed_case.data['title'], mixed_award_data[:books][0].data['title']

    # Check Nebula Award
    nebula_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Nebula Award' }
    refute_nil nebula_award_data, 'Nebula Award group missing'
    assert_equal 'nebula-award', nebula_award_data[:award_slug]
    assert_equal 1, nebula_award_data[:books].size
    assert_equal @award_book_nebula.data['title'], nebula_award_data[:books][0].data['title']

    # Check "Valid Award" and "Another Valid Award" from @award_book_nil_in_awards
    valid_award_data = # _format_award_display_name appends " Award"
      result[:awards_data].find do |ad|
        ad[:award_name] == 'Valid Award Award'
      end
    refute_nil valid_award_data, 'Valid Award Award group missing'
    assert_equal 1, valid_award_data[:books].size
    assert_equal @award_book_nil_in_awards.data['title'], valid_award_data[:books][0].data['title']

    another_valid_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Another Valid Award' }
    refute_nil another_valid_award_data, 'Another Valid Award group missing'
    assert_equal 1, another_valid_award_data[:books].size
    assert_equal @award_book_nil_in_awards.data['title'], another_valid_award_data[:books][0].data['title']

    # Check Philip K. Dick Award (tests multi-initial formatting)
    pkd_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'Philip K. Dick Award' }
    refute_nil pkd_award_data, 'Philip K. Dick Award group missing'
    assert_equal 'philip-k-dick-award', pkd_award_data[:award_slug]
    assert_equal 1, pkd_award_data[:books].size
    assert_equal @award_book_pkd.data['title'], pkd_award_data[:books][0].data['title']

    # Check British Fantasy Award (tests multi-word formatting)
    british_fantasy_award_data = result[:awards_data].find { |ad| ad[:award_name] == 'British Fantasy Award' }
    refute_nil british_fantasy_award_data, 'British Fantasy Award group missing'
    assert_equal 'british-fantasy-award', british_fantasy_award_data[:award_slug]
    assert_equal 1, british_fantasy_award_data[:books].size
    assert_equal @award_book_british_fantasy.data['title'], british_fantasy_award_data[:books][0].data['title']

    # Check overall sort order of awards (based on formatted names)
    award_names_in_order = result[:awards_data].map { |ad| ad[:award_name] }
    expected_award_order = [ # Sorted alphabetically by formatted name
      'Another Valid Award',
      'Arthur C. Clarke Award',
      'British Fantasy Award',
      'Hugo Award',
      'Locus Award',
      'Locus For Best Sf Novel Award',
      'Mixed Case Award Award',
      'Nebula Award',
      'Philip K. Dick Award',
      'Valid Award Award'
    ].sort # Ensure test expectation is also sorted for comparison
    assert_equal expected_award_order, award_names_in_order.sort
  end

  def test_by_award_finder_no_books_with_awards
    site_no_awards = create_site({}, { 'books' => [@award_book_no_awards, @award_book_empty_award_array] })
    site_no_awards.config['plugin_logging']['ALL_BOOKS_BY_AWARD_DISPLAY'] = true
    context_no_awards = create_context({}, { site: site_no_awards, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_no_awards, context_no_awards)
    assert_empty result[:awards_data]
    assert_match(/<!-- \[INFO\] ALL_BOOKS_BY_AWARD_DISPLAY_FAILURE: Reason='No books with awards found\.'\s*SourcePage='current_page\.html' -->/,
                 result[:log_messages])
  end

  def test_by_award_finder_books_collection_missing
    site_no_books_coll = create_site({}, {})
    site_no_books_coll.config['plugin_logging']['BOOK_LIST_UTIL'] = true
    context_no_books_coll = create_context({}, { site: site_no_books_coll, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_no_books_coll, context_no_books_coll)
    assert_empty result[:awards_data]
    assert_match(/<!-- \[ERROR\] BOOK_LIST_UTIL_FAILURE: Reason='Required &#39;books&#39; collection not found in site configuration\.'\s*filter_type='all_books_by_award'\s*SourcePage='current_page\.html' -->/,
                 result[:log_messages])
  end

  def test_by_award_finder_empty_book_collection
    site_empty_books = create_site({}, { 'books' => [] })
    context_empty_books = create_context({}, { site: site_empty_books, page: @context.registers[:page] })
    result = get_all_books_by_award_data(site_empty_books, context_empty_books)
    assert_empty result[:awards_data]
    assert_empty result[:log_messages].to_s # Finder returns early before logging "no awards found"
  end
end
