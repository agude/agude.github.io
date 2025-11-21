# _tests/plugins/utils/test_series_text_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/series_text_utils' # Load the util

# Tests for SeriesTextUtils module.
#
# Verifies that the utility correctly analyzes and formats series names with appropriate prefixes and suffixes.
class TestSeriesTextUtils < Minitest::Test
  def test_analyze_series_name_basic
    result = SeriesTextUtils.analyze_series_name('Foundation')
    expected = { prefix: 'the ', name: 'Foundation', suffix: ' series' }
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_the
    result = SeriesTextUtils.analyze_series_name('The Expanse')
    expected = { prefix: '', name: 'The Expanse', suffix: ' series' }
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_a
    result = SeriesTextUtils.analyze_series_name('A Canticle for Leibowitz')
    expected = { prefix: '', name: 'A Canticle for Leibowitz', suffix: ' series' } # Assuming 'Canticle' isn't a keyword
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_an
    result = SeriesTextUtils.analyze_series_name('Ancillary Justice')
    expected = { prefix: 'the ', name: 'Ancillary Justice', suffix: ' series' } # Assuming 'Ancillary' isn't a keyword
    assert_equal expected, result
  end

  def test_analyze_series_name_contains_keyword_saga
    result = SeriesTextUtils.analyze_series_name('Dune Saga')
    expected = { prefix: 'the ', name: 'Dune Saga', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_contains_keyword_series
    result = SeriesTextUtils.analyze_series_name('Hyperion Cantos Series')
    expected = { prefix: 'the ', name: 'Hyperion Cantos Series', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_is_keyword_itself
    result = SeriesTextUtils.analyze_series_name('Saga') # 'Saga' is a keyword
    expected = { prefix: 'the ', name: 'Saga', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_the_and_contains_keyword
    result = SeriesTextUtils.analyze_series_name('The Wheel of Time Saga')
    expected = { prefix: '', name: 'The Wheel of Time Saga', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_a_and_contains_keyword
    result = SeriesTextUtils.analyze_series_name('A Song of Ice and Fire')
    expected = { prefix: '', name: 'A Song of Ice and Fire', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_starts_with_the_and_contains_keyword_2
    result = SeriesTextUtils.analyze_series_name('The Chronicles of Narnia')
    expected = { prefix: '', name: 'The Chronicles of Narnia', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_with_internal_punctuation_and_keyword
    result = SeriesTextUtils.analyze_series_name('Known Space: The Man-Kzin Wars series')
    expected = { prefix: 'the ', name: 'Known Space: The Man-Kzin Wars series', suffix: '' }
    assert_equal expected, result
  end

  def test_analyze_series_name_keyword_with_trailing_punctuation
    # Example: "The Dark Tower." (assuming "Tower" is not a keyword, but "Series" would be)
    # Let's test with a keyword that might have punctuation
    result = SeriesTextUtils.analyze_series_name('The Culture series.')
    expected = { prefix: '', name: 'The Culture series.', suffix: '' } # suffix is empty because "series" is found
    assert_equal expected, result
  end

  def test_analyze_series_name_no_keywords_complex_name
    result = SeriesTextUtils.analyze_series_name('His Dark Materials')
    expected = { prefix: 'the ', name: 'His Dark Materials', suffix: ' series' }
    assert_equal expected, result
  end

  def test_analyze_series_name_input_with_extra_whitespace
    result = SeriesTextUtils.analyze_series_name('  Foundation  ')
    expected = { prefix: 'the ', name: 'Foundation', suffix: ' series' }
    assert_equal expected, result

    result_the = SeriesTextUtils.analyze_series_name('   The Expanse   ')
    expected_the = { prefix: '', name: 'The Expanse', suffix: ' series' }
    assert_equal expected_the, result_the
  end

  def test_analyze_series_name_nil_input
    assert_nil SeriesTextUtils.analyze_series_name(nil)
  end

  def test_analyze_series_name_empty_string_input
    assert_nil SeriesTextUtils.analyze_series_name('')
  end

  def test_analyze_series_name_whitespace_only_input
    assert_nil SeriesTextUtils.analyze_series_name('    ')
  end

  def test_analyze_series_name_keyword_as_substring_does_not_match
    # "Arc" is a keyword, but "Arcane" is not "Arc" as a whole word.
    result = SeriesTextUtils.analyze_series_name('Arcane')
    expected = { prefix: 'the ', name: 'Arcane', suffix: ' series' }
    assert_equal expected, result
  end

  def test_analyze_series_name_multiple_keywords
    result = SeriesTextUtils.analyze_series_name('The Great Book Saga Collection')
    # Should stop at the first keyword match for suffix determination.
    # "Book" is a keyword, "Saga" is a keyword, "Collection" is a keyword.
    # The logic `series_title_words.any? { ... type_word }` will find one.
    expected = { prefix: '', name: 'The Great Book Saga Collection', suffix: '' }
    assert_equal expected, result
  end
end
