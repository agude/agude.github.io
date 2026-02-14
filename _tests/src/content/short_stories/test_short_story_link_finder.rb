# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/short_stories/short_story_link_finder'

# Tests for Jekyll::ShortStories::ShortStoryLinkFinder.
#
# Verifies that the finder returns clean data without formatting.
class TestShortStoryLinkFinder < Minitest::Test
  Finder = Jekyll::ShortStories::ShortStoryLinkFinder

  def setup
    @story_entry = {
      'title' => 'The Last Question',
      'url' => '/books/robot-dreams/',
      'slug' => 'the-last-question',
      'parent_book_title' => 'Robot Dreams'
    }
    @site = create_site_with_link_cache({
                                          'short_stories' => {
                                            'the last question' => [@story_entry]
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Basic Finding Tests ---

  def test_find_returns_found_true_when_story_exists
    finder = Finder.new(@context)
    result = finder.find('The Last Question')
    assert result[:found]
  end

  def test_find_returns_correct_url_with_anchor
    finder = Finder.new(@context)
    result = finder.find('The Last Question')
    assert_equal '/books/robot-dreams/#the-last-question', result[:url]
  end

  def test_find_returns_canonical_title_as_display_name
    finder = Finder.new(@context)
    result = finder.find('the last question') # lowercase input
    assert_equal 'The Last Question', result[:display_name]
  end

  def test_find_returns_found_false_when_story_missing
    finder = Finder.new(@context)
    result = finder.find('Nonexistent Story')
    refute result[:found]
    assert_nil result[:url]
  end

  def test_find_returns_input_as_display_name_when_not_found
    finder = Finder.new(@context)
    result = finder.find('Unknown Story')
    assert_equal 'Unknown Story', result[:display_name]
  end

  # --- From Book Filter Tests ---

  def test_find_with_from_book_filter_succeeds_when_matching
    # Story appears in multiple books
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/nightfall-stories/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Nightfall and Other Stories' },
                                             { 'title' => 'Nightfall', 'url' => '/books/asimov-collection/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'The Asimov Collection' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Nightfall', from_book: 'Nightfall and Other Stories')
    assert result[:found]
    assert_equal '/books/nightfall-stories/#nightfall', result[:url]
  end

  def test_find_with_from_book_filter_fails_when_no_match
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/nightfall-stories/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Nightfall and Other Stories' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Nightfall', from_book: 'Wrong Book')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Canonical Location Tests ---

  def test_find_prefers_canonical_location
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/reprint/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Reprint Collection' },
                                             { 'title' => 'Nightfall', 'url' => '/books/original/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Original Collection' }
                                           ]
                                         },
                                         'url_to_canonical_map' => {
                                           '/books/original/' => '/books/original/' # Only original is canonical
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Nightfall')
    assert result[:found]
    assert_equal '/books/original/#nightfall', result[:url]
  end

  # --- Same Book All Locations ---

  def test_find_succeeds_when_all_locations_same_book
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/same-book/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Same Book' },
                                             { 'title' => 'Nightfall', 'url' => '/books/same-book/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Same Book' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Nightfall')
    assert result[:found]
    assert_equal '/books/same-book/#nightfall', result[:url]
  end

  # --- Ambiguous Location Tests ---

  def test_find_returns_not_found_when_ambiguous
    site = create_site_with_link_cache({
                                         'short_stories' => {
                                           'nightfall' => [
                                             { 'title' => 'Nightfall', 'url' => '/books/book-a/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Book A' },
                                             { 'title' => 'Nightfall', 'url' => '/books/book-b/', 'slug' => 'nightfall',
                                               'parent_book_title' => 'Book B' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    # Without canonical mapping or from_book filter, this is ambiguous
    result = finder.find('Nightfall')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Empty/Nil Input Tests ---

  def test_find_with_nil_context_returns_empty_result
    finder = Finder.new(nil)
    result = finder.find('The Last Question')
    refute result[:found]
    assert_equal 'The Last Question', result[:display_name]
  end

  def test_find_with_empty_title_returns_not_found
    finder = Finder.new(@context)
    result = finder.find('   ')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Result Structure ---

  def test_find_result_contains_expected_keys
    finder = Finder.new(@context)
    result = finder.find('The Last Question')

    assert result.key?(:found)
    assert result.key?(:display_name)
    assert result.key?(:url)
    assert result.key?(:log_output)
  end
end
