# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../../_plugins/src/infrastructure/markdown_fence_parser'

# Tests the shared Markdown fence recognizer used by conversion and normalization.
class TestMarkdownFenceParser < Minitest::Test
  Parser = Jekyll::Infrastructure::MarkdownFenceParser

  def test_matching_container_and_longer_closer_define_the_block_boundary
    lines = ["> ````ruby\r\n", ">> `````\r\n", "> ```\r\n", "> ~~~~\r\n", "> `````\r\n", "tail\r\n"]
    fence = Parser.fence_start(lines.first)

    block, next_index = Parser.fenced_block(lines, 0, fence)

    assert_equal lines[0..4].join, block
    assert_equal 5, next_index
  end

  def test_list_indentation_opens_a_fence_but_plain_indented_code_does_not
    list_lines = ["1. Example:\n", "    ```text\n", "    code\n", "    ```\n", "After\n"]
    list_fence = Parser.fence_start(list_lines[1], lines: list_lines, line_index: 1)
    refute_nil list_fence
    assert_equal [:indent], list_fence.containers

    block, next_index = Parser.fenced_block(list_lines, 1, list_fence)
    assert_equal list_lines[1..3].join, block
    assert_equal 4, next_index

    plain_lines = ["Intro\n", "    ```text\n", "    literal\n", "After\n"]
    assert_nil Parser.fence_start(plain_lines[1], lines: plain_lines, line_index: 1)
  end

  def test_backtick_fence_rejects_backticks_in_info_string
    assert_nil Parser.fence_start("```ruby `invalid`\n")
  end
end
