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
end
