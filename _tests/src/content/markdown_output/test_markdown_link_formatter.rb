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

  # --- italic: true ---

  def test_format_link_italic_found
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    assert_equal '[_Dune_](/books/dune/)', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true)
  end

  def test_format_link_italic_not_found
    data = { status: :not_found, url: nil, display_text: 'Unknown Book' }
    assert_equal '_Unknown Book_', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true)
  end

  def test_format_link_italic_found_but_nil_url
    data = { status: :found, url: nil, display_text: 'No URL' }
    assert_equal '_No URL_', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true)
  end

  def test_format_link_italic_nil_display_text
    data = { status: :not_found, url: nil, display_text: nil }
    assert_equal '', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true)
  end

  # --- escaping ---

  def test_format_link_escapes_brackets_in_text
    data = { status: :found, url: '/books/test/', display_text: 'Title [Vol. 1]' }
    result = Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
    assert_equal '[Title \[Vol. 1\]](/books/test/)', result
  end

  def test_format_link_escapes_parens_in_url
    data = { status: :found, url: '/books/test_(edition)/', display_text: 'Title' }
    result = Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
    assert_equal '[Title](/books/test_\(edition\)/)', result
  end

  def test_format_link_passes_through_backslashes
    data = { status: :found, url: '/books/test\\path/', display_text: 'Title \\ Subtitle' }
    result = Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
    assert_equal '[Title \\ Subtitle](/books/test\\path/)', result
  end

  def test_format_link_italic_with_brackets
    data = { status: :found, url: '/books/test/', display_text: 'Book [Part 2]' }
    result = Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true)
    assert_equal '[_Book \[Part 2\]_](/books/test/)', result
  end

  def test_format_link_no_escaping_needed
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    result = Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data)
    assert_equal '[Dune](/books/dune/)', result
  end

  # --- self_link: true ---

  def test_format_link_self_link_returns_plain_text
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    assert_equal 'Dune', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, self_link: true)
  end

  def test_format_link_self_link_with_italic
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    assert_equal '_Dune_', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, italic: true, self_link: true)
  end

  def test_format_link_self_link_not_found_returns_plain_text
    data = { status: :not_found, url: nil, display_text: 'Unknown' }
    assert_equal 'Unknown', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, self_link: true)
  end

  def test_format_link_self_link_false_still_links
    data = { status: :found, url: '/books/dune/', display_text: 'Dune' }
    assert_equal '[Dune](/books/dune/)', Jekyll::MarkdownOutput::MarkdownLinkFormatter.format_link(data, self_link: false)
  end
end
