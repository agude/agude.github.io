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
    input = "Line 1   \nLine 2\t\n"
    assert_equal "Line 1\nLine 2\n", Normalizer.normalize(input)
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
