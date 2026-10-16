# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for BookCandidateSelector: which same-titled book a book_link points
# to. BookLinkResolver and LinkTagTargetResolver both call it;
# TestBacklinkRendererParity checks that they agree.
class TestBookCandidateSelector < Minitest::Test
  Selector = Jekyll::Infrastructure::LinkCache::BookCandidateSelector

  ANN = { 'url' => '/books/twin-ann.html', 'authors' => ['Ann Author'] }.freeze
  BOB = { 'url' => '/books/twin-bob.html', 'authors' => ['Bob Author', 'Co Author'] }.freeze

  AUTHOR_CACHE = {
    'ann author' => { 'title' => 'Ann Author' },
    'pen name' => { 'title' => 'Ann Author' },
  }.freeze

  def select(candidates, author, author_cache: AUTHOR_CACHE)
    Selector.select_book(candidates, author, author_cache)
  end

  def test_single_candidate_without_author_is_chosen
    assert_same ANN, select([ANN], nil)
  end

  def test_several_candidates_without_author_are_ambiguous
    assert_equal :ambiguous, select([ANN, BOB], nil)
    assert_equal :ambiguous, select([ANN, BOB], '  ')
  end

  def test_author_picks_the_matching_candidate
    assert_same BOB, select([ANN, BOB], 'Co Author')
  end

  def test_author_ignores_case_and_surrounding_whitespace
    assert_same BOB, select([ANN, BOB], '  bob AUTHOR ')
  end

  def test_pen_name_matches_its_canonical_author
    assert_same ANN, select([ANN, BOB], 'Pen Name')
  end

  def test_author_matching_no_candidate_is_a_mismatch
    assert_equal :author_mismatch, select([ANN, BOB], 'Nobody')
    assert_equal :author_mismatch, select([ANN], 'Nobody')
  end

  def test_candidate_without_authors_never_matches
    no_authors = { 'url' => '/books/anon.html', 'authors' => nil }
    assert_equal :author_mismatch, select([no_authors], 'Ann Author')
  end

  def test_nil_author_cache_is_treated_as_empty
    assert_same BOB, select([ANN, BOB], 'Bob Author', author_cache: nil)
  end
end
