# frozen_string_literal: true

require_relative '../../test_helper'

# Tests for Jekyll::Infrastructure::MarkdownWhitespaceNormalizer.
#
# Verifies whitespace normalization for generated Markdown output.
class TestMarkdownWhitespaceNormalizer < Minitest::Test
  Normalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer

  def test_collapses_triple_blank_lines
    input = "Line 1\n\n\n\nLine 2\n"
    assert_equal "Line 1\n\nLine 2\n", Normalizer.normalize(input)
  end

  def test_removes_trailing_whitespace
    input = "Line 1 \nLine 2\t\n"
    assert_equal "Line 1\nLine 2\n", Normalizer.normalize(input)
  end

  def test_preserves_markdown_hard_break_spaces
    input = "First line  \nSecond line\n"
    assert_equal input, Normalizer.normalize(input)
  end

  def test_preserves_long_fenced_code_whitespace_and_normalizes_surrounding_prose
    code = "````text\nfirst  \n```short```\n\n\nlast\t\n````\n"
    input = "\nIntro \n\n\n#{code}\n\n\nEnd \n\n"
    assert_equal "Intro\n\n#{code}\nEnd\n", Normalizer.normalize(input)
  end

  def test_preserves_tilde_fenced_code_with_crlf
    code = "~~~text\r\nfirst  \r\n\r\n\r\nlast\t\r\n~~~\r\n"
    assert_equal "#{code}\nEnd\n", Normalizer.normalize("#{code}\nEnd \n")
  end

  def test_preserves_indented_code_whitespace
    input = "Example:\n\n    first  \n\n\n    last\t\n\nEnd\n"
    assert_equal input, Normalizer.normalize(input)
  end

  def test_preserves_complete_fenced_code_inside_list
    code = "    ```text\n    first\t\n\n\n    last  \n    ```\n"
    input = "1. Example:\n\n#{code}\nEnd \n"
    assert_equal "1. Example:\n\n#{code}\nEnd\n", Normalizer.normalize(input)
  end

  def test_indented_fence_without_list_context_does_not_swallow_following_prose
    input = "    ```\n    <em>code</em>\n\n<em>prose</em> \n"
    expected = "    ```\n    <em>code</em>\n\n<em>prose</em>\n"

    assert_equal expected, Normalizer.normalize(input)
  end

  def test_single_trailing_newline
    input = "Content\n\n\n"
    assert_equal "Content\n", Normalizer.normalize(input)
  end

  def test_removes_leading_blank_lines
    input = "\n\n\nContent\n"
    assert_equal "Content\n", Normalizer.normalize(input)
  end

  def test_preserves_double_blank_lines
    input = "Line 1\n\nLine 2\n"
    assert_equal "Line 1\n\nLine 2\n", Normalizer.normalize(input)
  end
end
