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

  def test_emphasis_tag
    assert_equal '_et al._', Converter.convert('<em>et al.</em>')
  end

  def test_strong_tag
    assert_equal '**Prompt**', Converter.convert('<strong>Prompt</strong>')
  end

  def test_attributed_strong_tag
    html = '<strong class="prompt">Prompt</strong>'
    assert_equal '**Prompt**', Converter.convert(html)
  end

  def test_attributed_emphasis_tag
    html = '<em class="author-emphasis">et al.</em>'
    assert_equal '_et al._', Converter.convert(html)
  end

  # --- span → plain text ---

  def test_nowrap_span_preserves_link_and_adjacent_prose
    input = "Read <span class=\"nowrap\"><a href=\"/books/neuromancer/\">Neuromancer</a>'s</span> sequel."
    assert_equal "Read [Neuromancer](/books/neuromancer/)'s sequel.", Converter.convert(input)
  end

  def test_similar_presentation_classes_remain_unchanged
    input = '<span data-class="nowrap">one</span> <span class="nowrapish">two</span> ' \
            '<div class="written-by-note">three</div> ' \
            '<div class="chatgpt-edit-block-note">four</div> ' \
            '<div data-class="chatgpt-prompt-only">five</div> ' \
            '<span-other class="nowrap">six</span-other> ' \
            '<div-other class="written-by">seven</div-other>'
    assert_equal input, Converter.convert(input)
  end

  def test_written_by_block_preserves_paragraph_boundaries
    input = 'Before.<div class="written-by">by <a href="/books/authors/william_gibson/">William Gibson</a></div>After.'
    assert_equal "Before.\n\nby [William Gibson](/books/authors/william_gibson/)\n\nAfter.", Converter.convert(input)
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

  def test_anchor_wrapping_emphasis
    html = '<a href="/books/hyperion/"><em>Hyperion</em></a>'
    assert_equal '[_Hyperion_](/books/hyperion/)', Converter.convert(html)
  end

  def test_anchor_wrapping_strong
    html = '<a href="/prompts/1"><strong>Prompt</strong></a>'
    assert_equal '[**Prompt**](/prompts/1)', Converter.convert(html)
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
    input = 'Use `<cite class="book-title">Foo</cite>, <em>literal</em>, and ' \
            '<strong>bold</strong>, <span class="nowrap">title</span>, and ' \
            '<details><summary>literal</summary>answer</details>, and ' \
            '<div class="chatgpt-prompt-only">literal</div>` for titles.'
    assert_equal input, Converter.convert(input)
  end

  def test_fenced_code_block_preserved
    input = "Some text.\n\n```html\n<cite class=\"book-title\">Foo</cite> and " \
            '<em>literal</em>, <strong>bold</strong>, and ' \
            '<span class="band-name">The Beatles</span> and ' \
            '<details><summary>literal</summary>answer</details> and ' \
            '<div class="chatgpt-edit-block"><div class="chatgpt-output-only">literal</div></div> and ' \
            '<div class="chatgpt-edit-markdown"><strong>Prompt</strong><blockquote>x</blockquote>' \
            '<strong>Output</strong><blockquote>y</blockquote></div> and ' \
            "<div class=\"written-by\">by Author</div>\n```\n\n" \
            '<cite class="book-title">After</cite>'
    expected = "Some text.\n\n```html\n<cite class=\"book-title\">Foo</cite> and " \
               '<em>literal</em>, <strong>bold</strong>, and ' \
               '<span class="band-name">The Beatles</span> and ' \
               '<details><summary>literal</summary>answer</details> and ' \
               '<div class="chatgpt-edit-block"><div class="chatgpt-output-only">literal</div></div> and ' \
               '<div class="chatgpt-edit-markdown"><strong>Prompt</strong><blockquote>x</blockquote>' \
               '<strong>Output</strong><blockquote>y</blockquote></div> and ' \
               "<div class=\"written-by\">by Author</div>\n```\n\n_After_"
    assert_equal expected, Converter.convert(input)
  end

  def test_tilde_fenced_code_block_preserved
    input = "~~~html\n<cite class=\"book-title\">Inside</cite>\n~~~\n" \
            '<cite class="book-title">After</cite>'
    expected = "~~~html\n<cite class=\"book-title\">Inside</cite>\n~~~\n_After_"
    assert_equal expected, Converter.convert(input)
  end

  def test_long_backtick_fence_preserves_shorter_runs
    input = "````markdown\nUse `code` and ```short``` before " \
            "<cite class=\"book-title\">Inside</cite>.\n````\n" \
            '<cite class="book-title">After</cite>'
    expected = "````markdown\nUse `code` and ```short``` before " \
               "<cite class=\"book-title\">Inside</cite>.\n````\n_After_"
    assert_equal expected, Converter.convert(input)
  end

  def test_fence_closer_can_be_longer_than_opener
    input = "~~~html\n<cite class=\"book-title\">Inside</cite>\n~~~~\n" \
            '<cite class="book-title">After</cite>'
    expected = "~~~html\n<cite class=\"book-title\">Inside</cite>\n~~~~\n_After_"
    assert_equal expected, Converter.convert(input)
  end

  def test_crlf_fenced_code_block_preserved
    input = "```html\r\n<cite class=\"book-title\">Inside</cite>\r\n```\r\n" \
            '<cite class="book-title">After</cite>'
    expected = "```html\r\n<cite class=\"book-title\">Inside</cite>\r\n```\r\n_After_"
    assert_equal expected, Converter.convert(input)
  end

  def test_unclosed_fenced_code_block_preserved
    input = "<cite class=\"book-title\">Before</cite>\n```html\n" \
            '<cite class="book-title">Inside</cite>'
    expected = "_Before_\n```html\n<cite class=\"book-title\">Inside</cite>"
    assert_equal expected, Converter.convert(input)
  end

  def test_multibacktick_inline_span_preserves_shorter_and_longer_runs
    input = 'Use ``a ` short and ``` longer <cite class="book-title">Inside</cite>``; ' \
            '<cite class="book-title">Outside</cite>.'
    expected = 'Use ``a ` short and ``` longer <cite class="book-title">Inside</cite>``; _Outside_.'
    assert_equal expected, Converter.convert(input)
  end

  def test_single_backtick_span_allows_embedded_double_run
    input = 'Use `one ``two <cite class="book-title">Inside</cite> three` and ' \
            '<cite class="book-title">Outside</cite>.'
    expected = 'Use `one ``two <cite class="book-title">Inside</cite> three` and _Outside_.'
    assert_equal expected, Converter.convert(input)
  end

  def test_multiline_inline_span_is_preserved
    input = "Use ``<cite class=\"book-title\">Foo</cite>\ncontinued`` here."
    assert_equal input, Converter.convert(input)
  end

  def test_inline_code_does_not_cross_blank_line
    [
      "A lone ` here.\n\n<em>prose</em> and `code`.",
      "> A lone ` here.\n>\n> <em>prose</em> and `code`.",
      "A lone ` here.\r\n \t\r\n<em>prose</em> and `code`.",
    ].each do |input|
      expected = input.gsub('<em>prose</em>', '_prose_')
      assert_equal expected, Converter.convert(input)
    end
  end

  def test_nested_presentation_spans_convert_anchors_and_preserve_adjacent_prose
    input = '<span class="nowrap">Listen to <span class="band-name">' \
            '<a href="/music/">The Beatles</a></span>.</span> Afterwards.'
    assert_equal 'Listen to [The Beatles](/music/). Afterwards.', Converter.convert(input)
  end

  def test_unmatched_inline_delimiter_does_not_hide_later_html
    input = 'A lone ` delimiter, then <cite class="book-title">Foo</cite>.'
    assert_equal 'A lone ` delimiter, then _Foo_.', Converter.convert(input)
  end

  def test_backreference_in_code_preserved
    input = 'Replace with `\\1` to reference the first group.'
    assert_equal input, Converter.convert(input)
  end

  # --- mixed content ---

  def test_handwritten_chatgpt_sections_preserve_labels_quotes_and_surrounding_prose
    input = <<~MARKDOWN
      Before.

      <div class="chatgpt-edit-block">
      <div class="chatgpt-prompt">
      <strong>Prompt</strong>
      <div class="chatgpt-prompt-only" markdown="1">
      > Rewrite _this_.
      >
      > Keep the meaning.
      </div>
      </div>

      <div class="chatgpt-output">
      <strong>Output</strong>
      <div class="chatgpt-output-only" markdown="1">
      > 1. First version.
      > 2. Second version.
      </div>
      </div>
      </div>

      Afterwards.
    MARKDOWN
    output = Converter.convert(input)
    refute_match(%r{</?div\b}i, output)

    config = Jekyll.configuration('source' => File.expand_path('../../../..', __dir__), 'quiet' => true)
    html = Nokogiri::HTML.fragment(Jekyll::Converters::Markdown.new(config).convert(output))
    assert_equal %w[Prompt Output], html.css('strong').map(&:text)
    quotes = html.css('blockquote')
    assert_equal 2, quotes.length
    assert_equal ['Rewrite this.', 'Keep the meaning.'], quotes.first.css('p').map(&:text).map(&:strip)
    assert_equal 'this', quotes.first.at_css('em')&.text
    assert_equal ['First version.', 'Second version.'], quotes.last.css('ol > li').map(&:text).map(&:strip)
    assert_equal ['Before.', 'Prompt', 'Output', 'Afterwards.'], html.xpath('./p').map(&:text).map(&:strip)
  end

  def test_handwritten_chatgpt_prompt_only_preserves_quote_and_code
    input = <<~MARKDOWN
      <div class="chatgpt-edit-block">
      <div class="chatgpt-prompt-only" markdown="1">
      > Check `NONE` in this enum:
      >
      > ```python
      > class Make(Enum):
      >     UNKNOWN = "none"
      > ```
      </div>
      </div>
    MARKDOWN
    expected = <<~MARKDOWN
      > Check `NONE` in this enum:
      >
      > ```python
      > class Make(Enum):
      >     UNKNOWN = "none"
      > ```
    MARKDOWN
    assert_equal expected.strip, Converter.convert(input).strip
  end

  def test_handwritten_chatgpt_output_only_preserves_quote_without_inventing_label
    input = <<~MARKDOWN
      <div class="chatgpt-edit-block">
      <div class="chatgpt-output-only" markdown="1">
      > The answer is **correct**.
      >
      > Here is why.
      </div>
      </div>
    MARKDOWN
    expected = "> The answer is **correct**.\n>\n> Here is why."
    assert_equal expected, Converter.convert(input).strip
  end

  def test_disclosure_preserves_summary_and_full_body_as_markdown
    input = 'Before.<details markdown="1"><summary markdown="1"><strong>Check the data</strong></summary>' \
            "\n\nThe answer is <em>complete</em>.\n\n```sql\nSELECT COUNT(*) FROM collisions;\n```\n" \
            '</details>After.'
    expected = "Before.\n\n**Check the data**\n\nThe answer is _complete_.\n\n" \
               "```sql\nSELECT COUNT(*) FROM collisions;\n```\n\nAfter."
    assert_equal expected, Converter.convert(input)
  end

  def test_disclosure_keeps_existing_markdown_in_multiline_summary
    input = "<details>\n<summary>Data is **_never_** clean.\nCheck first.</summary>\n\nAnswer.\n</details>"
    expected = "Data is **_never_** clean.\nCheck first.\n\nAnswer."
    assert_equal expected, Converter.convert(input).strip
  end

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
