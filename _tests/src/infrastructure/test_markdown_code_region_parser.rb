# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/markdown_code_region_parser'

# Tests shared source ranges for Markdown code preserved by conversion stages.
class TestMarkdownCodeRegionParser < Minitest::Test
  Parser = Jekyll::Infrastructure::MarkdownCodeRegionParser

  def test_protected_ranges_include_indented_and_inline_code_but_not_list_prose
    input = "Intro.\n\n    first\t\n\n    last  \n\nUse `inline\t` text.\n"
    ranges = Parser.protected_code_ranges(input)
    regions = ranges.map { |start_index, end_index| input[start_index...end_index] }

    assert_equal ["    first\t\n\n    last  \n", "`inline\t`"], regions
    prose = "1. First.\n\n    Continue with emphasis.\n"
    assert_empty Parser.protected_code_ranges(prose)
  end

  def test_matching_container_and_longer_closer_define_the_block_boundary
    lines = ["> ````ruby\r\n", ">> `````\r\n", "> ```\r\n", "> ~~~~\r\n", "> `````\r\n", "tail\r\n"]

    assert_equal [[0, lines[0..4].sum(&:length)]], Parser.protected_code_ranges(lines.join)
  end

  def test_list_indentation_opens_a_fence_but_plain_indented_code_does_not
    lines = ["1. Example:\n", "    ```text\n", "    code\n", "    ```\n", "After\n"]

    assert_equal [[lines.first.length, lines[0..3].sum(&:length)]], Parser.protected_code_ranges(lines.join)
    assert_empty Parser.protected_code_ranges("Intro\n    ```text\n    literal\nAfter\n")
  end

  def test_backtick_fence_rejects_backticks_in_info_string
    source = "```ruby `invalid`\nAfter\n"

    assert_equal [[8, 17]], Parser.protected_code_ranges(source)
  end

  def test_tab_indented_list_fence_has_an_exact_closing_boundary
    lines = ["1. item\n", "\n", "\t```html\n", "\tcode\t\n", "\t````\n", "After\n"]

    assert_equal [[lines[0..1].sum(&:length), lines[0..4].sum(&:length)]], Parser.protected_code_ranges(lines.join)
  end

  def test_both_quote_and_list_container_orders_are_recognized
    [
      ["> 123. item\n", ">\n", ">      ~~~html\n", ">      code\n", ">      ~~~~\n", "After\n"],
      ["1. item\n", "\n", "    > ~~~html\n", "    > code\n", "    > ~~~~\n", "After\n"],
    ].each do |lines|
      expected = [[lines[0..1].sum(&:length), lines[0..4].sum(&:length)]]

      assert_equal expected, Parser.protected_code_ranges(lines.join), lines[2]
    end
  end
end
