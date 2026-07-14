# frozen_string_literal: true

require_relative '../../test_helper'
# Jekyll::Infrastructure::TextProcessingUtils is loaded via test_helper's require 'utils/text_processing_utils'

# Tests for Jekyll::Infrastructure::TextProcessingUtils module.
#
# Verifies that the utility correctly processes text, including HTML cleaning, slugification, and list formatting.
class TestTextProcessingUtils < Minitest::Test
  # --- Tests for clean_text_from_html ---

  def test_clean_text_from_html_basic
    html = '<p>Hello <b>World</b></p>'
    expected = 'Hello World'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_with_entities
    html = '<p>Apples &amp; Pears &lt;br&gt;</p>' # &lt;br&gt; is text here
    expected = 'Apples & Pears <br>' # Nokogiri decodes entities
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_with_newlines_and_spaces
    html = "  <p>Line one.\n\n  Line  two.  </p> Extra.  "
    expected = 'Line one. Line two. Extra.' # Whitespace normalized
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_script_and_style_tags
    html = "<style>body { color: red; }</style><p>Visible</p><script>alert('hi');</script>"
    expected = 'Visible' # Script and style content should be gone
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(html)
  end

  def test_clean_text_from_html_empty_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html('')
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html('   ')
  end

  def test_clean_text_from_html_nil_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(nil)
  end

  def test_clean_text_from_html_no_html
    plain_text = 'This is just plain text with   multiple spaces.'
    expected = 'This is just plain text with multiple spaces.'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(plain_text)
  end

  # --- Tests for truncate_words ---

  def test_truncate_words_no_truncation_needed
    text = 'This is a short sentence.'
    assert_equal 'This is a short sentence.', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 10)
  end

  def test_truncate_words_truncation_occurs
    text = 'This is a longer sentence that will definitely be truncated.'
    expected = 'This is a longer sentence...'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 5)
  end

  def test_truncate_words_custom_omission
    text = 'This is a longer sentence that will definitely be truncated.'
    expected = 'This is a longer sentence---'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 5, '---')
  end

  def test_truncate_words_exact_word_count
    text = 'One two three four five.'
    # Should not truncate if num_words is equal to actual word count
    assert_equal 'One two three four five.', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 5)
  end

  def test_truncate_words_empty_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.truncate_words('', 5)
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.truncate_words('    ', 5) # Whitespace only
  end

  def test_truncate_words_nil_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(nil, 5)
  end

  def test_truncate_words_zero_words
    text = 'Some text.'
    # Truncating to 0 words should result in just the omission string
    assert_equal '...', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 0)
    # If input is empty, should still be empty
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.truncate_words('', 0)
  end

  def test_truncate_words_non_string_input
    assert_equal '12345', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(12_345, 5)
    assert_equal '...', Jekyll::Infrastructure::TextProcessingUtils.truncate_words(123, 0)
  end

  def test_truncate_words_input_with_leading_trailing_whitespace
    text = '  leading and trailing whitespace  '
    expected_no_trunc = 'leading and trailing whitespace'
    expected_trunc = 'leading and trailing...'
    assert_equal expected_no_trunc, Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 5)
    assert_equal expected_trunc, Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, 3)
  end

  # --- Tests for normalize_title (moved from LiquidUtils tests) ---
  def test_normalize_title_basic
    assert_equal 'hello world', Jekyll::Infrastructure::TextProcessingUtils.normalize_title("  Hello \n World  ")
  end

  def test_normalize_title_with_articles
    assert_equal 'test title', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('The Test Title', strip_articles: true)
    assert_equal 'example', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('an Example', strip_articles: true)
    assert_equal 'test', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('A Test', strip_articles: true)
  end

  def test_normalize_title_no_articles_to_strip
    assert_equal 'test title', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('Test Title', strip_articles: true)
  end

  def test_normalize_title_articles_not_stripped_by_default
    assert_equal 'the test title', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('The Test Title')
    assert_equal 'an example', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('An Example')
  end

  def test_normalize_title_nil
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title(nil)
  end

  def test_normalize_title_empty_string
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('')
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('   ')
  end

  def test_normalize_title_bare_article_becomes_empty
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('The', strip_articles: true)
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('an', strip_articles: true)
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.normalize_title('A', strip_articles: true)
  end

  def test_normalize_title_multiple_spaces_and_newlines
    assert_equal 'complex title with spaces', Jekyll::Infrastructure::TextProcessingUtils.normalize_title("  Complex\nTitle   with\n\nSpaces  ")
  end

  # --- Tests for format_list_as_sentence ---

  def test_format_list_as_sentence_nil_or_empty
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(nil)
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence([])
  end

  def test_format_list_as_sentence_one_item
    items = ['Author A']
    assert_equal 'Author A', Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_two_items
    items = ['Author A', 'Author B']
    assert_equal 'Author A and Author B', Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_three_items
    items = ['Author A', 'Author B', 'Author C']
    assert_equal 'Author A, Author B, and Author C', Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_four_items_default
    items = ['Author A', 'Author B', 'Author C', 'Author D']
    expected = 'Author A, Author B, Author C, and Author D'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_five_items_default
    items = ['Author A', 'Author B', 'Author C', 'Author D', 'Author E']
    expected = 'Author A, Author B, Author C, Author D, and Author E'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  # --- Tests for the etal_after parameter ---

  def test_format_list_as_sentence_with_etal_after_triggers_etal
    items = ['Author A', 'Author B', 'Author C', 'Author D']
    expected = 'Author A <abbr class="etal">et al.</abbr>'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_etal_after_at_limit_does_not_trigger
    # Length (3) is not > etal_after (3), so it should format the full list.
    items = ['Author A', 'Author B', 'Author C']
    expected = 'Author A, Author B, and Author C'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_etal_after_and_html_items
    item1 = "<a href='/a'>Author A</a>"
    item2 = '<span>Author B</span>'
    item3 = "<a href='/c'>Author C</a>"
    item4 = '<span>Author D</span>'
    items = [item1, item2, item3, item4]

    expected = "#{item1} <abbr class=\"etal\">et al.</abbr>"
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: 3)
  end

  def test_format_list_as_sentence_with_non_string_items
    items = [:alpha, 42, true]
    expected = 'alpha, 42, and true'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items)
  end

  def test_format_list_as_sentence_with_invalid_etal_after_defaults_to_full_list
    items = ['Author A', 'Author B', 'Author C', 'Author D']
    expected = 'Author A, Author B, Author C, and Author D'
    # Invalid values for etal_after should be ignored, defaulting to full list.
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: 0)
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: -1)
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.format_list_as_sentence(items, etal_after: 'foo')
  end

  def test_slugify_basic
    assert_equal 'hello-world', Jekyll::Infrastructure::TextProcessingUtils.slugify('Hello World')
  end

  def test_slugify_handles_case_and_whitespace
    assert_equal 'hello-world', Jekyll::Infrastructure::TextProcessingUtils.slugify('  Hello   World  ')
  end

  def test_slugify_removes_punctuation
    assert_equal 'a-story-about-stuff', Jekyll::Infrastructure::TextProcessingUtils.slugify('A Story About & Stuff!')
  end

  def test_slugify_preserves_hyphens_and_consolidates
    assert_equal 'a-b-test-for-c', Jekyll::Infrastructure::TextProcessingUtils.slugify('A-B Test -- For C')
  end

  def test_slugify_removes_leading_and_trailing_hyphens
    assert_equal 'hello-world', Jekyll::Infrastructure::TextProcessingUtils.slugify('-Hello-World-')
  end

  def test_slugify_nil_and_empty
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.slugify(nil)
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.slugify('')
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.slugify('   ')
  end

  def test_slugify_complex_case
    input = "  A & B's Test -- For #1!  "
    expected = 'a-b-s-test-for-1'
    assert_equal expected, Jekyll::Infrastructure::TextProcessingUtils.slugify(input)
  end

  # --- Tests for strip_tags (moved from HtmlTextUtils) ---

  def test_strip_simple_tags
    assert_equal 'Hello world', Jekyll::Infrastructure::TextProcessingUtils.strip_tags('<p>Hello world</p>')
  end

  def test_strip_nested_tags
    assert_equal 'Some emphasized & bold text',
                 Jekyll::Infrastructure::TextProcessingUtils.strip_tags('<p>Some <em>emphasized</em> &amp; <strong>bold</strong> text</p>')
  end

  def test_strip_html_comments
    assert_equal 'Some text',
                 Jekyll::Infrastructure::TextProcessingUtils.strip_tags('<!-- draft -->Some text<!-- end -->')
  end

  def test_strip_self_closing_tags
    assert_equal 'BeforeAfter', Jekyll::Infrastructure::TextProcessingUtils.strip_tags('Before<br/>After')
  end

  def test_strip_tags_with_attributes
    assert_equal 'Link text',
                 Jekyll::Infrastructure::TextProcessingUtils.strip_tags('<a href="/path" class="link">Link text</a>')
  end

  def test_strip_tags_plain_text_passthrough
    assert_equal 'No HTML here', Jekyll::Infrastructure::TextProcessingUtils.strip_tags('No HTML here')
  end

  def test_strip_tags_empty_string
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.strip_tags('')
  end

  def test_strip_tags_non_string_coercion
    assert_equal '42', Jekyll::Infrastructure::TextProcessingUtils.strip_tags(42)
  end

  def test_strip_tags_removes_book_preview_markup
    html = '<a href="/books/dune.html"><cite>Dune</cite>' \
           '<!--book-preview--><span class="book-link-preview">by Frank Herbert</span><!--/book-preview--></a>'
    assert_equal 'Dune', Jekyll::Infrastructure::TextProcessingUtils.strip_tags(html)
  end

  def test_strip_tags_removes_footnote_preview_markup
    html = '<span class="footnote-ref"><sup><a href="#fn:1">1</a></sup>' \
           '<!--footnote-preview--><span class="footnote-preview">Hidden note.</span><!--/footnote-preview-->' \
           '</span> body text'
    result = Jekyll::Infrastructure::TextProcessingUtils.strip_tags(html)
    refute_includes result, 'Hidden note.'
    assert_includes result, 'body text'
  end

  # --- Tests for strip_link_previews ---

  def test_strip_link_previews_removes_preview_span_and_content
    html = 'Before<!--book-preview--><span class="book-link-preview">by Frank Herbert</span><!--/book-preview-->After'
    assert_equal 'BeforeAfter', Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews(html)
  end

  def test_strip_link_previews_removes_multiple_occurrences
    html = 'A<!--book-preview-->one<!--/book-preview-->B<!--book-preview-->two<!--/book-preview-->C'
    assert_equal 'ABC', Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews(html)
  end

  def test_strip_link_previews_no_markers_passthrough
    html = '<p>Plain content, no preview here.</p>'
    assert_equal html, Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews(html)
  end

  def test_strip_link_previews_nil_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews(nil)
  end

  def test_strip_link_previews_empty_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.strip_link_previews('')
  end

  # --- Tests for strip_footnote_previews ---

  def test_strip_footnote_previews_removes_preview_content
    html = 'Before<!--footnote-preview--><span class="footnote-preview">Note.</span><!--/footnote-preview-->After'
    assert_equal 'BeforeAfter', Jekyll::Infrastructure::TextProcessingUtils.strip_footnote_previews(html)
  end

  def test_strip_footnote_previews_handles_nested_spans
    html = 'X<!--footnote-preview--><span class="footnote-preview"><cite>Title</cite> text</span><!--/footnote-preview-->Y'
    assert_equal 'XY', Jekyll::Infrastructure::TextProcessingUtils.strip_footnote_previews(html)
  end

  def test_strip_footnote_previews_removes_multiple_occurrences
    html = 'A<!--footnote-preview-->one<!--/footnote-preview-->B<!--footnote-preview-->two<!--/footnote-preview-->C'
    assert_equal 'ABC', Jekyll::Infrastructure::TextProcessingUtils.strip_footnote_previews(html)
  end

  def test_strip_footnote_previews_no_markers_passthrough
    html = '<p>Plain content.</p>'
    assert_equal html, Jekyll::Infrastructure::TextProcessingUtils.strip_footnote_previews(html)
  end

  def test_strip_footnote_previews_nil_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.strip_footnote_previews(nil)
  end

  # --- Tests for strip_links ---

  def test_strip_links_removes_anchor_tags_keeps_inner_html
    html = '<a href="/books/foo/"><cite class="book-title">Foo</cite></a>'
    assert_equal '<cite class="book-title">Foo</cite>',
                 Jekyll::Infrastructure::TextProcessingUtils.strip_links(html)
  end

  def test_strip_links_removes_multiple_links
    html = 'Read <a href="/a">Alpha</a> and <a href="/b">Beta</a>.'
    assert_equal 'Read Alpha and Beta.',
                 Jekyll::Infrastructure::TextProcessingUtils.strip_links(html)
  end

  def test_strip_links_nil_input
    assert_equal '', Jekyll::Infrastructure::TextProcessingUtils.strip_links(nil)
  end

  def test_strip_links_no_links_passthrough
    html = '<cite class="book-title">Foo</cite>'
    assert_equal html, Jekyll::Infrastructure::TextProcessingUtils.strip_links(html)
  end

  def test_strip_links_multiline_content
    html = "<a href=\"/foo\">\n<cite>Foo</cite>\n</a>"
    assert_equal "\n<cite>Foo</cite>\n", Jekyll::Infrastructure::TextProcessingUtils.strip_links(html)
  end

  # --- Tests for escape_link_text (moved from MarkdownTextUtils) ---

  def test_escape_link_text_escapes_brackets
    assert_equal 'Title \\[Vol. 1\\]', Jekyll::Infrastructure::TextProcessingUtils.escape_link_text('Title [Vol. 1]')
  end

  def test_escape_link_text_passes_through_parentheses
    assert_equal 'Title (Part 2)', Jekyll::Infrastructure::TextProcessingUtils.escape_link_text('Title (Part 2)')
  end

  def test_escape_link_text_passes_through_backslashes
    assert_equal 'Back\\Slash', Jekyll::Infrastructure::TextProcessingUtils.escape_link_text('Back\\Slash')
  end

  def test_escape_link_text_noop_on_safe_string
    assert_equal 'Safe Title', Jekyll::Infrastructure::TextProcessingUtils.escape_link_text('Safe Title')
  end

  def test_escape_link_text_handles_non_strings
    assert_equal '123', Jekyll::Infrastructure::TextProcessingUtils.escape_link_text(123)
  end

  # --- Tests for escape_url (moved from MarkdownTextUtils) ---

  def test_escape_url_escapes_parentheses
    assert_equal '/path/file\\(1\\)', Jekyll::Infrastructure::TextProcessingUtils.escape_url('/path/file(1)')
  end

  def test_escape_url_passes_through_backslashes
    assert_equal '/path/file\\name', Jekyll::Infrastructure::TextProcessingUtils.escape_url('/path/file\\name')
  end

  def test_escape_url_noop_on_safe_url
    assert_equal '/path/file-name', Jekyll::Infrastructure::TextProcessingUtils.escape_url('/path/file-name')
  end

  def test_escape_url_handles_non_strings
    assert_equal '456', Jekyll::Infrastructure::TextProcessingUtils.escape_url(456)
  end
end
