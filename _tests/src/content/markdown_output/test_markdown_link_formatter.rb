# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::MarkdownOutput::MarkdownLinkFormatter.
#
# Verifies that link data hashes are formatted as Markdown links
# when the status is :found, and as plain text otherwise.
class TestMarkdownLinkFormatter < Minitest::Test
  def test_format_link_found
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    assert_equal '[Dune](/books/dune/)', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end

  def test_format_link_not_found
    data = { status: :not_found, url: nil, display_text: 'Unknown Book' }
    assert_equal 'Unknown Book', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end

  def test_format_link_found_but_nil_url
    data = { status: :found, url: nil, display_text: 'No URL' }
    assert_equal 'No URL', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end

  def test_format_link_empty_display_text
    data = { status: :found, url: '/books/test/', display_text: '' }
    assert_equal '[](/books/test/)', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end

  def test_format_link_nil_display_text
    data = { status: :not_found, url: nil, display_text: nil }
    assert_equal '', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end

  def test_format_link_ambiguous_status
    data = { status: :ambiguous, url: nil, display_text: 'Ambiguous Title' }
    assert_equal 'Ambiguous Title', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
  end
end
