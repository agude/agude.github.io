# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/links/markdown_link_utils'

# Tests for Jekyll::Infrastructure::Links::MarkdownLinkUtils
class TestMarkdownLinkUtils < Minitest::Test
  MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils

  # --- render_link tests ---

  def test_render_link_with_text_and_url
    result = MarkdownUtils.render_link('My Title', '/books/my-title/')
    assert_equal '[My Title](/books/my-title/)', result
  end

  def test_render_link_with_italic_text_and_url
    result = MarkdownUtils.render_link('My Title', '/books/my-title/', italic: true)
    assert_equal '[*My Title*](/books/my-title/)', result
  end

  def test_render_link_without_url_returns_plain_text
    result = MarkdownUtils.render_link('My Title', nil)
    assert_equal 'My Title', result
  end

  def test_render_link_without_url_returns_italic_text
    result = MarkdownUtils.render_link('My Title', nil, italic: true)
    assert_equal '*My Title*', result
  end

  def test_render_link_with_empty_url_returns_text
    result = MarkdownUtils.render_link('My Title', '')
    assert_equal 'My Title', result
  end

  def test_render_link_with_empty_url_returns_italic_text
    result = MarkdownUtils.render_link('My Title', '', italic: true)
    assert_equal '*My Title*', result
  end

  def test_render_link_with_anchor_url
    result = MarkdownUtils.render_link('Story', '/books/anthology/#story-slug')
    assert_equal '[Story](/books/anthology/#story-slug)', result
  end

  # --- markdown_mode? tests ---

  def test_markdown_mode_returns_true_when_enabled
    context = create_context({}, { markdown_mode: true })
    assert MarkdownUtils.markdown_mode?(context)
  end

  def test_markdown_mode_returns_false_when_disabled
    context = create_context({}, { markdown_mode: false })
    refute MarkdownUtils.markdown_mode?(context)
  end

  def test_markdown_mode_returns_false_when_not_set
    context = create_context
    refute MarkdownUtils.markdown_mode?(context)
  end

  def test_markdown_mode_returns_false_for_nil_context
    refute MarkdownUtils.markdown_mode?(nil)
  end

  def test_markdown_mode_returns_false_for_non_boolean_value
    context = create_context({}, { markdown_mode: 'true' })
    refute MarkdownUtils.markdown_mode?(context)
  end
end
