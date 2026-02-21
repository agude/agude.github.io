# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::MarkdownOutput::MarkdownHtmlConverter.
#
# Verifies that inline HTML tags in markdown body strings are converted
# to their Markdown equivalents while code blocks are preserved.
class TestMarkdownHtmlConverter < Minitest::Test
  Converter = Jekyll::MarkdownOutput::MarkdownHtmlConverter

  # --- cite → italics ---

  def test_book_title_cite
    html = '<cite class="book-title">Hyperion</cite>'
    assert_equal '_Hyperion_', Converter.convert(html)
  end

  def test_movie_title_cite
    html = '<cite class="movie-title">Soylent Green</cite>'
    assert_equal '_Soylent Green_', Converter.convert(html)
  end

  def test_short_story_title_cite
    html = '<cite class="short-story-title">Rogue</cite>'
    assert_equal '_Rogue_', Converter.convert(html)
  end

  def test_tv_show_title_cite
    html = '<cite class="tv-show-title">Battlestar Galactica</cite>'
    assert_equal '_Battlestar Galactica_', Converter.convert(html)
  end

  def test_video_game_title_cite
    html = '<cite class="video-game-title">Disco Elysium</cite>'
    assert_equal '_Disco Elysium_', Converter.convert(html)
  end

  def test_table_top_game_title_cite
    html = '<cite class="table-top-game-title">Warhammer 40k</cite>'
    assert_equal '_Warhammer 40k_', Converter.convert(html)
  end

  # --- span → plain text ---

  def test_author_name_span
    html = '<span class="author-name">Dan Simmons</span>'
    assert_equal 'Dan Simmons', Converter.convert(html)
  end

  def test_book_series_span
    html = '<span class="book-series">Hyperion Cantos</span>'
    assert_equal 'Hyperion Cantos', Converter.convert(html)
  end

  def test_written_by_span
    html = '<span class="written-by">Written by</span>'
    assert_equal 'Written by', Converter.convert(html)
  end

  # --- abbr → plain text ---

  def test_etal_abbr
    html = '<abbr class="etal">et al.</abbr>'
    assert_equal 'et al.', Converter.convert(html)
  end

  # --- anchor → markdown link ---

  def test_simple_anchor
    html = '<a href="/books/hyperion/">Hyperion</a>'
    assert_equal '[Hyperion](/books/hyperion/)', Converter.convert(html)
  end

  # --- nested tags (inner converted before outer) ---

  def test_anchor_wrapping_cite
    html = '<a href="/books/hyperion/"><cite class="book-title">Hyperion</cite></a>'
    assert_equal '[_Hyperion_](/books/hyperion/)', Converter.convert(html)
  end

  def test_anchor_wrapping_span
    html = '<a href="/books/series/hyperion_cantos/"><span class="book-series">Hyperion Cantos</span></a>'
    assert_equal '[Hyperion Cantos](/books/series/hyperion_cantos/)', Converter.convert(html)
  end

  def test_anchor_wrapping_author_span
    html = '<a href="/books/authors/dan_simmons/"><span class="author-name">Dan Simmons</span></a>'
    assert_equal '[Dan Simmons](/books/authors/dan_simmons/)', Converter.convert(html)
  end

  # --- multiline tags ---

  def test_multiline_cite
    html = "<cite\n  class=\"book-title\">The Rise\nof Endymion</cite>"
    assert_equal "_The Rise\nof Endymion_", Converter.convert(html)
  end

  def test_multiline_span
    html = "<span\nclass=\"author-name\">Dan Simmons</span>"
    assert_equal 'Dan Simmons', Converter.convert(html)
  end

  # --- code block stashing ---

  def test_inline_code_preserved
    input = 'Use `<cite class="book-title">Foo</cite>` for titles.'
    assert_equal input, Converter.convert(input)
  end

  def test_fenced_code_block_preserved
    input = "Some text.\n\n```html\n<cite class=\"book-title\">Foo</cite>\n```\n\nMore text."
    assert_equal input, Converter.convert(input)
  end

  def test_backreference_in_code_preserved
    input = 'Replace with `\\1` to reference the first group.'
    assert_equal input, Converter.convert(input)
  end

  # --- mixed content ---

  def test_multiple_conversions
    html = '<cite class="book-title">Hyperion</cite>, by <span class="author-name">Dan Simmons</span>, ' \
           'is the first book in the <span class="book-series">Hyperion Cantos</span>.'
    expected = '_Hyperion_, by Dan Simmons, is the first book in the Hyperion Cantos.'
    assert_equal expected, Converter.convert(html)
  end

  def test_realistic_paragraph
    html = '<cite class="book-title">The Rise of Endymion</cite>, by <span ' \
           "class=\"author-name\">Dan Simmons</span>, is the fourth and final book in the\n" \
           '<span class="book-series">Hyperion Cantos</span>.'
    expected = "_The Rise of Endymion_, by Dan Simmons, is the fourth and final book in the\n" \
               'Hyperion Cantos.'
    assert_equal expected, Converter.convert(html)
  end

  # --- no-op cases ---

  def test_plain_markdown_unchanged
    input = "# Title\n\nSome _italic_ and **bold** text."
    assert_equal input, Converter.convert(input)
  end

  def test_nil_input
    assert_nil Converter.convert(nil)
  end

  def test_empty_string
    assert_equal '', Converter.convert('')
  end

  # --- unrecognized HTML passes through ---

  def test_unrecognized_span_class_unchanged
    html = '<span class="other-class">text</span>'
    assert_equal html, Converter.convert(html)
  end

  def test_cite_without_title_class_unchanged
    html = '<cite class="source">text</cite>'
    assert_equal html, Converter.convert(html)
  end
end
