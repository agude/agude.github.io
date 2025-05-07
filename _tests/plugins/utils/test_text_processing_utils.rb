# _tests/plugins/utils/test_text_processing_utils.rb
require_relative '../../test_helper'
# TextProcessingUtils is loaded via test_helper's require 'utils/text_processing_utils'

class TestTextProcessingUtils < Minitest::Test

  # --- Tests for clean_text_from_html ---

  def test_clean_text_from_html_basic
    html = "<p>Hello <b>World</b></p>"
    expected = "Hello World"
    assert_equal expected, TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_with_entities
    html = "<p>Apples &amp; Pears &lt;br&gt;</p>" # &lt;br&gt; is text here
    expected = "Apples & Pears <br>" # Nokogiri decodes entities
    assert_equal expected, TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_with_newlines_and_spaces
    html = "  <p>Line one.\n\n  Line  two.  </p> Extra.  "
    expected = "Line one. Line two. Extra." # Whitespace normalized
    assert_equal expected, TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_script_and_style_tags
    html = "<style>body { color: red; }</style><p>Visible</p><script>alert('hi');</script>"
    expected = "Visible" # Script and style content should be gone
    assert_equal expected, TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_empty_input
    assert_equal "", TextProcessingUtils.clean_text_from_html("")
    assert_equal "", TextProcessingUtils.clean_text_from_html("   ")
  end

  def test_clean_text_from_html_nil_input
    assert_equal "", TextProcessingUtils.clean_text_from_html(nil)
  end

  def test_clean_text_from_html_no_html
    plain_text = "This is just plain text with   multiple spaces."
    expected = "This is just plain text with multiple spaces."
    assert_equal expected, TextProcessingUtils.clean_text_from_html(plain_text)
  end

  # --- Tests for truncate_words ---

  def test_truncate_words_no_truncation_needed
    text = "This is a short sentence."
    assert_equal "This is a short sentence.", TextProcessingUtils.truncate_words(text, 10)
  end

  def test_truncate_words_truncation_occurs
    text = "This is a longer sentence that will definitely be truncated."
    expected = "This is a longer sentence..."
    assert_equal expected, TextProcessingUtils.truncate_words(text, 5)
  end

  def test_truncate_words_custom_omission
    text = "This is a longer sentence that will definitely be truncated."
    expected = "This is a longer sentence---"
    assert_equal expected, TextProcessingUtils.truncate_words(text, 5, "---")
  end

  def test_truncate_words_exact_word_count
    text = "One two three four five."
    # Should not truncate if num_words is equal to actual word count
    assert_equal "One two three four five.", TextProcessingUtils.truncate_words(text, 5)
  end

  def test_truncate_words_empty_input
    assert_equal "", TextProcessingUtils.truncate_words("", 5)
    assert_equal "", TextProcessingUtils.truncate_words("    ", 5) # Whitespace only
  end

  def test_truncate_words_nil_input
    assert_equal "", TextProcessingUtils.truncate_words(nil, 5)
  end

  def test_truncate_words_zero_words
    text = "Some text."
    # Truncating to 0 words should result in just the omission string
    assert_equal "...", TextProcessingUtils.truncate_words(text, 0)
    # If input is empty, should still be empty
    assert_equal "", TextProcessingUtils.truncate_words("", 0)
  end

  def test_truncate_words_input_with_leading_trailing_whitespace
    text = "  leading and trailing whitespace  "
    expected_no_trunc = "leading and trailing whitespace"
    expected_trunc = "leading and trailing..."
    assert_equal expected_no_trunc, TextProcessingUtils.truncate_words(text, 5)
    assert_equal expected_trunc, TextProcessingUtils.truncate_words(text, 3)
  end

end
