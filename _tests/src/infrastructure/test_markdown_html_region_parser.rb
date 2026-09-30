# frozen_string_literal: true

require_relative '../../test_helper'

# Regression tests for shared raw HTML source-region traversal.
class TestMarkdownHtmlRegionParser < Minitest::Test
  Parser = Jekyll::Infrastructure::MarkdownHtmlRegionParser

  def test_preserves_common_block_html_and_comments
    ['<section><strong>text</strong></section>', '<ul><li>text</li></ul>', '<!-- <em>text</em> -->'].each do |source|
      assert_equal([source], Parser.protected_ranges(source).map { |start_index, end_index| source[start_index...end_index] })
    end
  end

  def test_preserves_raw_div_but_leaves_markdown_enabled_div_open
    raw = '<div data-markdown="1"><em>text</em></div>'
    enabled = '<div markdown="1"><em>text</em></div>'

    assert_equal([raw], Parser.protected_ranges(raw).map { |range| raw[range[0]...range[1]] })
    assert_empty Parser.protected_ranges(enabled)
  end

  def test_balanced_pairs_reject_unclosed_outer_container
    source = '<details><details></details></details>'
    pairs = Parser.tag_pairs(source, 'details')

    assert_equal [source.index('<details>'), source.rindex('<details>')], pairs.map(&:first)
    assert_equal [false, true], pairs.map(&:last)
    assert_empty Parser.tag_pairs('<details><details></details>', 'details')
  end
end
