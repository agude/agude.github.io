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

  def test_nested_same_name_tags_form_one_region
    outer = '<div class="outer"><div class="inner">x</div> tail</div>'

    assert_equal [outer], protected_text("#{outer}\n\nAfter.\n")
  end

  def test_html_inside_fenced_code_is_not_a_region
    source = "```html\n<div>literal</div>\n```\n\n<div>raw</div>\n"

    assert_equal ['<div>raw</div>'], protected_text(source)
  end

  def test_inline_code_containing_div_is_not_a_region
    source = "Use `<div>` here.\n\n<section>raw</section>\n"

    assert_equal ['<section>raw</section>'], protected_text(source)
  end

  def test_indented_code_containing_div_is_not_a_region
    source = "<div>raw</div>\n\n    <div>code</div>\n"

    assert_equal ['<div>raw</div>'], protected_text(source)
  end

  def test_unclosed_tag_is_not_a_region
    source = "<div>never closed\n\n<section>raw</section>\n"

    assert_equal ['<section>raw</section>'], protected_text(source)
  end

  # Tag pairing cannot tell which opening tag is the unclosed one, so no
  # region of that tag name is protected from the first unbalanced tag on.
  def test_unclosed_tag_leaves_earlier_same_name_regions_unprotected
    assert_empty Parser.protected_ranges("<div>closed</div>\n\n<div>never closed\n")
  end

  def test_unclosed_details_protects_the_rest_of_the_text
    source = "<details><summary>Open</summary>\n\n<div>after</div>\n"

    assert_equal [source], protected_text(source)
  end

  # Code is found in the text with earlier raw regions blanked, so a
  # backtick or fence marker inside raw HTML does not hide later HTML.
  def test_backtick_inside_raw_html_does_not_open_a_code_span
    source = 'Text <div>a ` b</div> c <div>d</div> e `'

    assert_equal ['<div>a ` b</div>', '<div>d</div>'], protected_text(source)
  end

  def test_fence_marker_inside_raw_html_does_not_open_a_fence
    source = "<div>\n```\n</div>\n\n<section>x</section>\n"

    assert_equal ["<div>\n```\n</div>", '<section>x</section>'], protected_text(source)
  end

  # Finding code ranges scans the whole text. Doing it again after every
  # region made the parser quadratic in the number of regions.
  def test_code_ranges_are_not_recomputed_for_each_plain_region
    source = Array.new(50) { |i| "Paragraph #{i}.\n\n<div class=\"note\">\nInner #{i}.\n</div>\n\n" }.join

    assert_equal [50, 1], ranges_and_code_scans(source)
  end

  def test_code_ranges_are_not_recomputed_for_each_quoted_region
    source = Array.new(50) { |i| "> Quote #{i}.\n>\n> <div class=\"note\">Inner #{i}.</div>\n\n" }.join

    assert_equal [50, 1], ranges_and_code_scans(source)
  end

  def test_code_ranges_are_not_recomputed_after_closed_inline_code
    source = Array.new(50) { |i| "Use `code #{i}` then <div class=\"note\">Inner #{i}.</div>\n\n" }.join

    assert_equal [50, 1], ranges_and_code_scans(source)
  end

  private

  # Returns the number of protected ranges and of whole-text code scans.
  def ranges_and_code_scans(source)
    code_parser = Jekyll::Infrastructure::MarkdownCodeRegionParser
    original = code_parser.method(:protected_code_ranges)
    calls = 0
    counting = lambda do |text|
      calls += 1
      original.call(text)
    end

    ranges = code_parser.stub(:protected_code_ranges, counting) { Parser.protected_ranges(source) }
    [ranges.length, calls]
  end

  def protected_text(source)
    Parser.protected_ranges(source).map { |start_index, end_index| source[start_index...end_index] }
  end
end
