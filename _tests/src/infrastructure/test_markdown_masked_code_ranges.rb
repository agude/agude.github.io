# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::Infrastructure::MarkdownMaskedCodeRanges: its answers
# must equal MarkdownCodeRegionParser run on the masked text, and it must
# skip that run when the queried position cannot be in code.
class TestMarkdownMaskedCodeRanges < Minitest::Test
  Tracker = Jekyll::Infrastructure::MarkdownMaskedCodeRanges
  CodeParser = Jekyll::Infrastructure::MarkdownCodeRegionParser

  def test_without_masks_matches_code_parser
    text = "Prose `<div>` here.\n\n    <div>indented</div>\n\n```\n<div>fenced</div>\n```\n<div>raw</div>\n"
    tracker = Tracker.new(text)

    text.enum_for(:scan, /<div>/).map { Regexp.last_match.begin(0) }.each do |position|
      assert_equal expected_in_code?(text, [], position), tracker.in_code?(position), position
    end
  end

  # Blanking a region at the start of a line indents the rest of that line.
  def test_masked_line_start_can_make_later_html_indented_code
    text = "<div>\nx\n</div>    <section>y</section>\n"

    assert_after_mask(text, [0, text.index('</div>') + 6], text.index('<section>'), in_code: true)
  end

  def test_backtick_inside_masked_region_does_not_open_a_code_span
    text = 'Text <div>a ` b</div> c <div>d</div> e `'

    assert_after_mask(text, [5, text.index('</div>') + 6], text.rindex('<div>'), in_code: false)
  end

  def test_fence_marker_inside_masked_region_does_not_open_a_fence
    text = "<div>\n```\n</div>\n\n<section>x</section>\n"

    assert_after_mask(text, [0, text.index('</div>') + 6], text.index('<section>'), in_code: false)
  end

  def test_fence_after_masked_region_is_code
    text = "<div>x</div>\n```\n<section>x</section>\n```\n"

    assert_after_mask(text, [0, text.index('</div>') + 6], text.index('<section>'), in_code: true)
  end

  def test_quoted_indented_html_after_blank_quote_line_is_code
    text = "> <div>a</div>\n>\n>     <section>b</section>\n"

    assert_after_mask(text, [2, text.index('</div>') + 6], text.index('<section>'), in_code: true)
  end

  # Blanking a region inside a quote's leading whitespace indents the rest
  # of the line.
  def test_masked_region_after_quote_marker_can_make_later_html_indented_code
    text = "> <div>a</div>    <section>b</section>\n"

    assert_after_mask(text, [2, text.index('</div>') + 6], text.index('<section>'), in_code: true)
  end

  def test_code_span_around_html_after_masked_region_is_code
    text = 'Text <div>a</div> `b <section>c</section> d`'

    assert_after_mask(text, [5, text.index('</div>') + 6], text.index('<section>'), in_code: true)
  end

  def test_skips_recompute_when_position_cannot_be_code
    text = "<div>x</div>\n\n<section>y</section>\n"
    calls = 0
    original = CodeParser.method(:protected_code_ranges)
    counting = lambda do |source|
      calls += 1
      original.call(source)
    end

    CodeParser.stub(:protected_code_ranges, counting) do
      tracker = Tracker.new(text)
      tracker.mask(0, text.index('</div>') + 6)

      refute tracker.in_code?(text.index('<section>'))
    end
    assert_equal 1, calls, 'only the initial computation should run'
  end

  private

  def assert_after_mask(text, mask, position, in_code:)
    assert_equal in_code, expected_in_code?(text, [mask], position), 'fixture expectation'
    tracker = Tracker.new(text)
    refute tracker.in_code?(mask[0]), 'a masked range must start outside code'
    tracker.mask(*mask)

    assert_equal in_code, tracker.in_code?(position)
  end

  def expected_in_code?(text, masks, position)
    masked = text.dup
    masks.each do |start_index, end_index|
      masked[start_index...end_index] = masked[start_index...end_index].gsub(/[^\r\n]/, ' ')
    end
    CodeParser.protected_code_ranges(masked).any? { |start_index, end_index| position >= start_index && position < end_index }
  end
end
