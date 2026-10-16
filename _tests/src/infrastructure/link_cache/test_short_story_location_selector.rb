# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for ShortStoryLocationSelector: which cached location a
# short_story_link points to. ShortStoryResolver and LinkTagTargetResolver
# both call it; TestBacklinkRendererParity checks that they agree.
class TestShortStoryLocationSelector < Minitest::Test
  Selector = Jekyll::Infrastructure::LinkCache::ShortStoryLocationSelector

  FIRST = { 'url' => '/books/first.html', 'parent_book_title' => 'First Book' }.freeze
  SECOND = { 'url' => '/books/second.html', 'parent_book_title' => 'Second Book' }.freeze
  ARCHIVED = { 'url' => '/books/first/2020.html', 'parent_book_title' => 'Old First' }.freeze

  # Every book is canonical except the archived review of First Book.
  CANONICAL_MAP = {
    '/books/first.html' => '/books/first.html',
    '/books/second.html' => '/books/second.html',
    '/books/first/2020.html' => '/books/first.html',
  }.freeze

  def select(locations, book_filter, canonical_map: CANONICAL_MAP)
    Selector.select_location(locations, canonical_map, book_filter)
  end

  def test_sole_canonical_location_wins_over_the_filter
    assert_same FIRST, select([ARCHIVED, FIRST], 'Old First')
  end

  def test_sole_canonical_location_wins_when_the_filter_matches_nothing
    assert_same FIRST, select([ARCHIVED, FIRST], 'Missing Book')
  end

  def test_several_canonical_locations_fall_through_to_the_filter
    assert_same SECOND, select([FIRST, SECOND], 'Second Book')
  end

  def test_locations_in_one_book_pick_the_first
    other_mention = FIRST.merge('slug' => 'second-mention')
    assert_same FIRST, select([FIRST, other_mention], nil, canonical_map: {})
  end

  def test_filter_ignores_case_and_surrounding_whitespace
    assert_same SECOND, select([FIRST, SECOND], '  second BOOK ')
  end

  def test_filter_matching_nothing_is_not_found_in_book
    assert_equal :not_found_in_book, select([FIRST, SECOND], 'Missing Book')
  end

  def test_no_filter_with_several_books_is_ambiguous
    assert_equal :ambiguous, select([FIRST, SECOND], nil)
    assert_equal :ambiguous, select([FIRST, SECOND], '   ')
  end

  def test_nil_canonical_map_is_treated_as_empty
    assert_same SECOND, select([FIRST, SECOND], 'Second Book', canonical_map: nil)
    assert_equal :ambiguous, select([ARCHIVED, FIRST], nil, canonical_map: nil)
  end
end
