# frozen_string_literal: true

require_relative '../../../../_tests/test_helper'
require_relative '../../../../_plugins/src/infrastructure/text/markdown_text_utils'

# Tests for MarkdownTextUtils
class TestMarkdownTextUtils < Minitest::Test
  MdText = Jekyll::Infrastructure::Text::MarkdownTextUtils

  # --- escape_link_text ---

  def test_escape_link_text_escapes_brackets
    assert_equal 'Title \\[Vol. 1\\]', MdText.escape_link_text('Title [Vol. 1]')
  end

  def test_escape_link_text_escapes_parentheses
    assert_equal 'Title \\(Part 2\\)', MdText.escape_link_text('Title (Part 2)')
  end

  def test_escape_link_text_escapes_backslashes
    assert_equal 'Back\\\\Slash', MdText.escape_link_text('Back\\Slash')
  end

  def test_escape_link_text_noop_on_safe_string
    assert_equal 'Safe Title', MdText.escape_link_text('Safe Title')
  end

  def test_escape_link_text_handles_non_strings
    assert_equal '123', MdText.escape_link_text(123)
  end

  # --- escape_url ---

  def test_escape_url_escapes_parentheses
    assert_equal '/path/file\\(1\\)', MdText.escape_url('/path/file(1)')
  end

  def test_escape_url_escapes_backslashes
    assert_equal '/path/file\\\\name', MdText.escape_url('/path/file\\name')
  end

  def test_escape_url_noop_on_safe_url
    assert_equal '/path/file-name', MdText.escape_url('/path/file-name')
  end

  def test_escape_url_handles_non_strings
    assert_equal '456', MdText.escape_url(456)
  end
end
