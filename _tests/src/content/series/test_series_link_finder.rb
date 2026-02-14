# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/series/series_link_finder'

# Tests for Jekyll::Series::SeriesLinkFinder.
#
# Verifies that the finder returns clean data without formatting.
class TestSeriesLinkFinder < Minitest::Test
  Finder = Jekyll::Series::SeriesLinkFinder

  def setup
    @series_entry = {
      'title' => 'The Hyperion Cantos',
      'url' => '/series/hyperion-cantos/'
    }
    # normalize_title returns 'the hyperion cantos' (with spaces, lowercase)
    @site = create_site_with_link_cache({
                                          'series' => {
                                            'the hyperion cantos' => @series_entry
                                          }
                                        })
    @page = create_doc({}, '/current.html')
    @context = create_context({}, { site: @site, page: @page })
  end

  # --- Basic Finding Tests ---

  def test_find_returns_found_true_when_series_exists
    finder = Finder.new(@context)
    result = finder.find('The Hyperion Cantos')
    assert result[:found]
  end

  def test_find_returns_correct_url
    finder = Finder.new(@context)
    result = finder.find('The Hyperion Cantos')
    assert_equal '/series/hyperion-cantos/', result[:url]
  end

  def test_find_returns_canonical_title_as_display_name
    finder = Finder.new(@context)
    result = finder.find('the hyperion cantos') # lowercase input
    assert_equal 'The Hyperion Cantos', result[:display_name]
  end

  def test_find_returns_found_false_when_series_missing
    finder = Finder.new(@context)
    result = finder.find('Nonexistent Series')
    refute result[:found]
    assert_nil result[:url]
  end

  def test_find_returns_input_as_display_name_when_not_found
    finder = Finder.new(@context)
    result = finder.find('Unknown Series')
    assert_equal 'Unknown Series', result[:display_name]
  end

  # --- Override Tests ---

  def test_find_with_override_uses_override_as_display_name
    finder = Finder.new(@context)
    result = finder.find('The Hyperion Cantos', override: 'Hyperion Series')
    assert_equal 'Hyperion Series', result[:display_name]
    assert_equal '/series/hyperion-cantos/', result[:url] # Still finds the series
  end

  def test_find_with_empty_override_uses_canonical_name
    finder = Finder.new(@context)
    result = finder.find('The Hyperion Cantos', override: '  ')
    assert_equal 'The Hyperion Cantos', result[:display_name]
  end

  # --- Empty/Nil Input Tests ---

  def test_find_with_nil_context_returns_empty_result
    finder = Finder.new(nil)
    result = finder.find('The Hyperion Cantos')
    refute result[:found]
    assert_equal 'The Hyperion Cantos', result[:display_name]
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
    result = finder.find('The Hyperion Cantos')

    assert result.key?(:found)
    assert result.key?(:display_name)
    assert result.key?(:url)
    assert result.key?(:log_output)
  end

  # --- Normalization Tests ---

  def test_find_normalizes_title_for_lookup
    # The normalized key is 'thehyperioncantos' (no spaces, lowercase)
    finder = Finder.new(@context)
    result = finder.find('THE HYPERION CANTOS')
    assert result[:found]
    assert_equal 'The Hyperion Cantos', result[:display_name]
  end
end
