# frozen_string_literal: true

require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/core/book_link_finder'

# Tests for Jekyll::Books::Core::BookLinkFinder.
#
# Verifies that the finder returns clean data without formatting.
class TestBookLinkFinder < Minitest::Test
  Finder = Jekyll::Books::Core::BookLinkFinder

  def setup
    @book_entry = {
      'title' => 'Hyperion',
      'url' => '/books/hyperion/',
      'authors' => ['Dan Simmons'],
      'date' => Date.new(2024, 1, 15)
    }
    @site = create_site_with_link_cache({
                                          'books' => {
                                            'hyperion' => [@book_entry]
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Basic Finding Tests ---

  def test_find_returns_found_true_when_book_exists
    finder = Finder.new(@context)
    result = finder.find('Hyperion')
    assert result[:found]
  end

  def test_find_returns_correct_url
    finder = Finder.new(@context)
    result = finder.find('Hyperion')
    assert_equal '/books/hyperion/', result[:url]
  end

  def test_find_returns_canonical_title_as_display_name
    finder = Finder.new(@context)
    result = finder.find('hyperion') # lowercase input
    assert_equal 'Hyperion', result[:display_name]
  end

  def test_find_returns_found_false_when_book_missing
    finder = Finder.new(@context)
    result = finder.find('Nonexistent Book')
    refute result[:found]
    assert_nil result[:url]
  end

  def test_find_returns_input_as_display_name_when_not_found
    finder = Finder.new(@context)
    result = finder.find('Unknown Title')
    assert_equal 'Unknown Title', result[:display_name]
  end

  # --- Override Tests ---

  def test_find_with_override_uses_override_as_display_name
    finder = Finder.new(@context)
    result = finder.find('Hyperion', override: 'The Shrike Pilgrimage')
    assert_equal 'The Shrike Pilgrimage', result[:display_name]
    assert_equal '/books/hyperion/', result[:url] # Still finds the book
  end

  def test_find_with_empty_override_uses_canonical_name
    finder = Finder.new(@context)
    result = finder.find('Hyperion', override: '  ')
    assert_equal 'Hyperion', result[:display_name]
  end

  # --- Cite Tests ---

  def test_find_passes_through_cite_true_by_default
    finder = Finder.new(@context)
    result = finder.find('Hyperion')
    assert result[:cite]
  end

  def test_find_passes_through_cite_false
    finder = Finder.new(@context)
    result = finder.find('Hyperion', cite: false)
    refute result[:cite]
  end

  # --- Author Filter Tests ---

  def test_find_with_author_filter_succeeds_when_matching
    site = create_site_with_link_cache({
                                         'books' => {
                                           'dune' => [
                                             { 'title' => 'Dune', 'url' => '/books/dune-herbert/', 'authors' => ['Frank Herbert'], 'date' => Date.new(2024, 1, 1) },
                                             { 'title' => 'Dune', 'url' => '/books/dune-anderson/', 'authors' => ['Brian Herbert'], 'date' => Date.new(2024, 2, 1) }
                                           ]
                                         },
                                         'authors' => {
                                           'frankherbert' => { 'title' => 'Frank Herbert', 'url' => '/authors/frank-herbert/' },
                                           'brianherbert' => { 'title' => 'Brian Herbert', 'url' => '/authors/brian-herbert/' }
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Dune', author_filter: 'Frank Herbert')
    assert result[:found]
    assert_equal '/books/dune-herbert/', result[:url]
  end

  def test_find_with_author_filter_fails_when_no_match
    site = create_site_with_link_cache({
                                         'books' => {
                                           'dune' => [
                                             { 'title' => 'Dune', 'url' => '/books/dune/', 'authors' => ['Frank Herbert'], 'date' => Date.new(2024, 1, 1) }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Dune', author_filter: 'Isaac Asimov')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Date Filter Tests ---

  def test_find_with_date_filter_succeeds_when_matching
    site = create_site_with_link_cache({
                                         'books' => {
                                           'hyperion' => [
                                             { 'title' => 'Hyperion', 'url' => '/books/hyperion-2024/', 'authors' => ['Dan Simmons'], 'date' => Date.new(2024, 1, 15) },
                                             { 'title' => 'Hyperion', 'url' => '/books/hyperion-2023/', 'authors' => ['Dan Simmons'], 'date' => Date.new(2023, 6, 1) }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Hyperion', date_filter: '2024-01-15')
    assert result[:found]
    assert_equal '/books/hyperion-2024/', result[:url]
  end

  def test_find_with_date_filter_fails_when_no_match
    finder = Finder.new(@context)
    result = finder.find('Hyperion', date_filter: '2099-01-01')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Ambiguous Title Tests ---

  def test_find_raises_on_ambiguous_title_without_filter
    site = create_site_with_link_cache({
                                         'books' => {
                                           'dune' => [
                                             { 'title' => 'Dune', 'url' => '/books/dune-1/', 'authors' => ['Frank Herbert'], 'date' => Date.new(2024, 1, 1) },
                                             { 'title' => 'Dune', 'url' => '/books/dune-2/', 'authors' => ['Brian Herbert'], 'date' => Date.new(2024, 2, 1) }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    assert_raises(Jekyll::Errors::FatalException) do
      finder.find('Dune')
    end
  end

  # --- Empty/Nil Input Tests ---

  def test_find_with_nil_context_returns_empty_result
    finder = Finder.new(nil)
    result = finder.find('Hyperion')
    refute result[:found]
    assert_equal 'Hyperion', result[:display_name]
  end

  def test_find_with_empty_title_returns_not_found
    finder = Finder.new(@context)
    result = finder.find('   ')
    refute result[:found]
    assert_nil result[:url]
  end

  # --- Canonical URL Filtering ---

  def test_find_filters_out_canonical_url_entries
    # The resolver filters out entries with canonical_url starting with /
    site = create_site_with_link_cache({
                                         'books' => {
                                           'hyperion' => [
                                             { 'title' => 'Hyperion', 'url' => '/books/hyperion/', 'authors' => ['Dan Simmons'], 'canonical_url' => '/books/hyperion-main/' }
                                           ]
                                         }
                                       })
    context = create_context({}, { site: site, page: @page })
    finder = Finder.new(context)

    result = finder.find('Hyperion')
    refute result[:found]
  end

  # --- Result Structure ---

  def test_find_result_contains_expected_keys
    finder = Finder.new(@context)
    result = finder.find('Hyperion')

    assert result.key?(:found)
    assert result.key?(:display_name)
    assert result.key?(:url)
    assert result.key?(:cite)
    assert result.key?(:log_output)
  end
end
