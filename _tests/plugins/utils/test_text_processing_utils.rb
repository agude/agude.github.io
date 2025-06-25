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

  # --- Tests for normalize_title (moved from LiquidUtils tests) ---
  def test_normalize_title_basic
    assert_equal "hello world", TextProcessingUtils.normalize_title("  Hello \n World  ")
  end

  def test_normalize_title_with_articles
    assert_equal "test title", TextProcessingUtils.normalize_title("The Test Title", strip_articles: true)
    assert_equal "example", TextProcessingUtils.normalize_title("an Example", strip_articles: true)
    assert_equal "test", TextProcessingUtils.normalize_title("A Test", strip_articles: true)
  end

  def test_normalize_title_no_articles_to_strip
    assert_equal "test title", TextProcessingUtils.normalize_title("Test Title", strip_articles: true)
  end

  def test_normalize_title_articles_not_stripped_by_default
    assert_equal "the test title", TextProcessingUtils.normalize_title("The Test Title")
    assert_equal "an example", TextProcessingUtils.normalize_title("An Example")
  end

  def test_normalize_title_nil
    assert_equal "", TextProcessingUtils.normalize_title(nil)
  end

  def test_normalize_title_empty_string
    assert_equal "", TextProcessingUtils.normalize_title("")
    assert_equal "", TextProcessingUtils.normalize_title("   ")
  end

  def test_normalize_title_multiple_spaces_and_newlines
    assert_equal "complex title with spaces", TextProcessingUtils.normalize_title("  Complex\nTitle   with\n\nSpaces  ")
  end


  # --- Tests for format_list_as_sentence ---

  def test_format_list_as_sentence_nil_or_empty
    assert_equal "", TextProcessingUtils.format_list_as_sentence(nil)
    assert_equal "", TextProcessingUtils.format_list_as_sentence([])
  end

  def test_format_list_as_sentence_one_item
    items = ["Author A"]
    assert_equal "Author A", TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_two_items
    items = ["Author A", "Author B"]
    assert_equal "Author A and Author B", TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_three_items
    items = ["Author A", "Author B", "Author C"]
    assert_equal "Author A, Author B, and Author C", TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_four_items_default
    items = ["Author A", "Author B", "Author C", "Author D"]
    expected = "Author A, Author B, Author C, and Author D"
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_five_items_default
    items = ["Author A", "Author B", "Author C", "Author D", "Author E"]
    expected = "Author A, Author B, Author C, Author D, and Author E"
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items)
  end

  # --- Tests for the etal_after parameter ---

  def test_format_list_as_sentence_with_etal_after_triggers_etal
    items = ["Author A", "Author B", "Author C", "Author D"]
    expected = "Author A <abbr class=\"etal\">et al.</abbr>"
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_etal_after_at_limit_does_not_trigger
    # Length (3) is not > etal_after (3), so it should format the full list.
    items = ["Author A", "Author B", "Author C"]
    expected = "Author A, Author B, and Author C"
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_etal_after_and_html_items
    item1 = "<a href='/a'>Author A</a>"
    item2 = "<span>Author B</span>"
    item3 = "<a href='/c'>Author C</a>"
    item4 = "<span>Author D</span>"
    items = [item1, item2, item3, item4]

    expected = "#{item1} <abbr class=\"etal\">et al.</abbr>"
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_invalid_etal_after_defaults_to_full_list
    items = ["Author A", "Author B", "Author C", "Author D"]
    expected = "Author A, Author B, Author C, and Author D"
    # Invalid values for etal_after should be ignored, defaulting to full list.
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: 0)
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: -1)
    assert_equal expected, TextProcessingUtils.format_list_as_sentence(items, etal_after: "foo")
  end
end
