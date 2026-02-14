# frozen_string_literal: true

require_relative '../../../test_helper'

# Tests for Jekyll::Infrastructure::Links::LinkFormatter
#
# The LinkFormatter provides a unified interface for generating links
# in different formats (HTML, Markdown) without mixing data and formatting concerns.
class TestLinkFormatter < Minitest::Test
  Formatter = Jekyll::Infrastructure::Links::LinkFormatter

  # --- Markdown Link Tests ---

  def test_markdown_link_basic
    result = Formatter.markdown('Dan Simmons', '/authors/dan_simmons/')
    assert_equal '[Dan Simmons](/authors/dan_simmons/)', result
  end

  def test_markdown_link_with_italic
    result = Formatter.markdown('Endymion', '/books/endymion/', italic: true)
    assert_equal '[*Endymion*](/books/endymion/)', result
  end

  def test_markdown_link_without_url_returns_plain_text
    result = Formatter.markdown('Dan Simmons', nil)
    assert_equal 'Dan Simmons', result
  end

  def test_markdown_link_without_url_with_italic
    result = Formatter.markdown('Endymion', nil, italic: true)
    assert_equal '*Endymion*', result
  end

  def test_markdown_link_with_empty_url_returns_plain_text
    result = Formatter.markdown('Dan Simmons', '')
    assert_equal 'Dan Simmons', result
  end

  # --- HTML Link Tests ---

  def test_html_link_basic
    result = Formatter.html('Dan Simmons', '/authors/dan_simmons/')
    assert_equal '<a href="/authors/dan_simmons/">Dan Simmons</a>', result
  end

  def test_html_link_with_wrapper_span
    result = Formatter.html('Dan Simmons', '/authors/dan_simmons/', wrapper: :span)
    assert_equal '<a href="/authors/dan_simmons/"><span>Dan Simmons</span></a>', result
  end

  def test_html_link_with_wrapper_span_and_class
    result = Formatter.html('Dan Simmons', '/authors/dan_simmons/', wrapper: :span, css_class: 'author-name')
    assert_equal '<a href="/authors/dan_simmons/"><span class="author-name">Dan Simmons</span></a>', result
  end

  def test_html_link_with_wrapper_cite
    result = Formatter.html('Endymion', '/books/endymion/', wrapper: :cite, css_class: 'book-title')
    assert_equal '<a href="/books/endymion/"><cite class="book-title">Endymion</cite></a>', result
  end

  def test_html_link_without_url_returns_wrapped_text
    result = Formatter.html('Dan Simmons', nil, wrapper: :span, css_class: 'author-name')
    assert_equal '<span class="author-name">Dan Simmons</span>', result
  end

  def test_html_link_with_empty_url_returns_wrapped_text
    result = Formatter.html('Dan Simmons', '', wrapper: :span, css_class: 'author-name')
    assert_equal '<span class="author-name">Dan Simmons</span>', result
  end

  def test_html_link_without_wrapper_and_without_url
    result = Formatter.html('Dan Simmons', nil)
    assert_equal 'Dan Simmons', result
  end

  def test_html_link_escapes_special_characters
    result = Formatter.html('A & B <Company>', '/authors/a-b/', wrapper: :span)
    assert_equal '<a href="/authors/a-b/"><span>A &amp; B &lt;Company&gt;</span></a>', result
  end

  # --- Format Method Tests (unified interface) ---

  def test_format_with_html
    result = Formatter.format('Dan Simmons', '/authors/dan_simmons/', format: :html, wrapper: :span)
    assert_equal '<a href="/authors/dan_simmons/"><span>Dan Simmons</span></a>', result
  end

  def test_format_with_markdown
    result = Formatter.format('Dan Simmons', '/authors/dan_simmons/', format: :markdown)
    assert_equal '[Dan Simmons](/authors/dan_simmons/)', result
  end

  def test_format_raises_on_unknown_format
    assert_raises(ArgumentError) do
      Formatter.format('Text', '/url/', format: :unknown)
    end
  end
end
