# frozen_string_literal: true

require_relative '../../../../_tests/test_helper'
require_relative '../../../../_plugins/src/infrastructure/text/html_text_utils'

# Tests for HtmlTextUtils
class TestHtmlTextUtils < Minitest::Test
  HtmlText = Jekyll::Infrastructure::Text::HtmlTextUtils

  def test_strip_simple_tags
    assert_equal 'Hello world', HtmlText.strip_tags('<p>Hello world</p>')
  end

  def test_strip_nested_tags
    assert_equal 'Some emphasized & bold text',
                 HtmlText.strip_tags('<p>Some <em>emphasized</em> &amp; <strong>bold</strong> text</p>')
  end

  def test_strip_html_comments
    assert_equal 'Some text',
                 HtmlText.strip_tags('<!-- draft -->Some text<!-- end -->')
  end

  def test_strip_self_closing_tags
    assert_equal 'BeforeAfter', HtmlText.strip_tags('Before<br/>After')
  end

  def test_strip_tags_with_attributes
    assert_equal 'Link text',
                 HtmlText.strip_tags('<a href="/path" class="link">Link text</a>')
  end

  def test_plain_text_passthrough
    assert_equal 'No HTML here', HtmlText.strip_tags('No HTML here')
  end

  def test_empty_string
    assert_equal '', HtmlText.strip_tags('')
  end

  def test_non_string_coercion
    assert_equal '42', HtmlText.strip_tags(42)
  end
end
