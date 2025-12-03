# frozen_string_literal: true

# _tests/plugins/utils/test_citation_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/src/ui/citations/citation_utils'

# Base test class with shared setup and helpers
class TestCitationUtilsBase < Minitest::Test
  NBSP = "\u00A0"

  def format_citation(params, _site = nil)
    CitationUtils.format_citation_html(params)
  end
end

# Tests for basic title and author formatting
class TestCitationUtilsBasicFormatting < TestCitationUtilsBase
  def test_empty_params
    assert_equal '', format_citation({})
  end

  def test_author_only_full
    params = { author_last: 'Doe', author_first: 'John', author_handle: 'jdoe' }
    expected = '<span class="citation">Doe, John (jdoe).</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_title_only_infers_standalone_cite_style
    params = { work_title: 'The Grand Book' }
    expected = '<span class="citation"><cite>The Grand Book</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_infers_work_quoted_style
    params = { work_title: 'A Great Article', container_title: 'The Journal' }
    expected = '<span class="citation">"A Great Article" <cite>The Journal</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_title_linked_infers_standalone_cite_style
    params = { work_title: 'My Linked Book', url: 'http://example.com/book' }
    expected = '<span class="citation"><a href="http://example.com/book">' \
               '<cite>My Linked Book</cite></a>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_linked_infers_work_quoted_style
    params = { work_title: 'My Linked Article', container_title: 'The Journal',
               url: 'http://example.com/article' }
    expected = '<span class="citation"><a href="http://example.com/article">"My Linked Article"</a> ' \
               '<cite>The Journal</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_container_title_only
    params = { container_title: 'The Big Collection' }
    expected = '<span class="citation"><cite>The Big Collection</cite>.</span>'
    assert_equal expected, format_citation(params)
  end
end

# Tests for DOI linking functionality
class TestCitationUtilsDoiLinking < TestCitationUtilsBase
  def test_doi_slug_is_linked
    params = { doi: '10.1234/xyz.567' }
    expected_doi_part = build_doi_link('10.1234/xyz.567', '10.1234/xyz.567')
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_is_extracted_and_linked
    params = { doi: 'https://doi.org/10.5678/abc.123' }
    expected_doi_part = build_doi_link('10.5678/abc.123', '10.5678/abc.123')
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_http_is_extracted_and_linked
    params = { doi: 'http://doi.org/10.5678/abc.123' }
    expected_doi_part = build_doi_link('10.5678/abc.123', '10.5678/abc.123')
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_with_www_is_extracted_and_linked
    params = { doi: 'https://www.doi.org/10.5678/abc.123' }
    expected_doi_part = build_doi_link('10.5678/abc.123', '10.5678/abc.123')
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_non_doi_string_is_not_linked
    params = { doi: 'arXiv:1234.5678' }
    expected_doi_part = "doi:#{NBSP}arXiv:1234.5678"
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_malformed_doi_string_is_not_linked
    params = { doi: 'not_a_doi_10.123' }
    expected_doi_part = "doi:#{NBSP}not_a_doi_10.123"
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  def test_doi_slug_with_complex_chars_is_linked_and_escaped_for_display
    complex_slug = '10.1007/s00253-007-1079-x(<>&)'
    escaped_complex_slug = '10.1007/s00253-007-1079-x(&lt;&gt;&amp;)'
    params = { doi: complex_slug }
    expected_doi_part = build_doi_link(complex_slug, escaped_complex_slug)
    expected = citation_span(expected_doi_part)
    assert_equal expected, format_citation(params)
  end

  private

  def build_doi_link(slug, display_text)
    "doi:#{NBSP}<a href=\"https://doi.org/#{slug}\">#{display_text}</a>"
  end

  def citation_span(content)
    "<span class=\"citation\">#{content}.</span>"
  end
end

# Tests for full citation examples
class TestCitationUtilsFullCitations < TestCitationUtilsBase
  def test_full_article_in_journal
    params = build_article_params
    expected_inner = build_article_expected
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_full_book_citation
    params = build_book_params
    expected_inner = 'Smith, John. <a href="http://example.com/books/history">' \
                     '<cite>A History of Everything</cite></a>. Edited by Alice Wonderland. ' \
                     'Academic Books Ltd. 2020.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_full_chapter_in_edited_book
    params = build_chapter_params
    expected_inner = build_chapter_expected
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_web_page_article_on_website
    params = {
      author_last: 'WebWriter', author_first: 'W.',
      work_title: 'My Thoughts on the Web',
      container_title: 'Personal Blog',
      url: 'http://webwriter.blog/thoughts',
      date: 'January 1, 2024'
    }
    expected_inner = 'WebWriter, W. <a href="http://webwriter.blog/thoughts">' \
                     '"My Thoughts on the Web"</a> <cite>Personal Blog</cite>. January 1, 2024.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_whole_website_citation
    params = {
      work_title: 'Comprehensive News Site',
      url: 'http://comprehensivenews.com',
      publisher: 'News Network Inc.',
      date: '2024'
    }
    expected_inner = '<a href="http://comprehensivenews.com">' \
                     '<cite>Comprehensive News Site</cite></a>. News Network Inc. 2024.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_journal_article_no_url_only_doi_linked
    params = build_journal_no_url_params
    expected_inner = build_journal_no_url_expected
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_all_possible_parts_present_with_linked_doi
    params = build_maximal_params
    expected_inner = build_maximal_expected
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  private

  def build_article_params
    {
      author_last: 'Doe', author_first: 'Jane',
      work_title: 'My Research Findings',
      container_title: 'Journal of Important Discoveries',
      url: 'http://example.com/article_url',
      volume: '15', number: '3',
      date: '2023',
      first_page: '101', last_page: '115',
      doi: '10.1234/jid.2023.15.3.101'
    }
  end

  def build_article_expected
    'Doe, Jane. <a href="http://example.com/article_url">"My Research Findings"</a> ' \
      "<cite>Journal of Important Discoveries</cite>. vol.#{NBSP}15, no.#{NBSP}3. 2023. " \
      "pp.#{NBSP}101--115. doi:#{NBSP}<a href=\"https://doi.org/10.1234/jid.2023.15.3.101\">" \
      '10.1234/jid.2023.15.3.101</a>.'
  end

  def build_book_params
    {
      author_last: 'Smith', author_first: 'John',
      work_title: 'A History of Everything',
      url: 'http://example.com/books/history',
      editor: 'Alice Wonderland',
      publisher: 'Academic Books Ltd.',
      date: '2020'
    }
  end

  def build_chapter_params
    {
      author_last: 'ChapterAuthor', author_first: 'C.',
      work_title: 'On Specific Topics',
      container_title: 'The Big Book of Topics',
      url: 'http://example.com/chapter_url',
      editor: 'Book Editor',
      publisher: 'University Press',
      date: '2021',
      first_page: '45', last_page: '60'
    }
  end

  def build_chapter_expected
    'ChapterAuthor, C. <a href="http://example.com/chapter_url">"On Specific Topics"</a> ' \
      '<cite>The Big Book of Topics</cite>. Edited by Book Editor. University Press. 2021. ' \
      "pp.#{NBSP}45--60."
  end

  def build_journal_no_url_params
    {
      author_first: 'Henrietta', author_last: 'Clopath',
      work_title: 'Genuine Art versus Mechanism',
      container_title: 'Brush and Pencil',
      volume: '7', number: '6',
      date: 'March 1, 1901',
      first_page: '331', last_page: '333',
      doi: '10.2307/25505621'
    }
  end

  def build_journal_no_url_expected
    'Clopath, Henrietta. "Genuine Art versus Mechanism" <cite>Brush and Pencil</cite>. ' \
      "vol.#{NBSP}7, no.#{NBSP}6. March 1, 1901. pp.#{NBSP}331--333. doi:#{NBSP}" \
      '<a href="https://doi.org/10.2307/25505621">10.2307/25505621</a>.'
  end

  def build_maximal_params
    {
      author_last: 'Maximus', author_first: 'A.',
      work_title: 'The Component Piece',
      container_title: 'The Grand Collection',
      url: 'http://example.com/max',
      editor: 'Ed Itor',
      edition: '3rd Revised',
      volume: 'X', number: '1',
      publisher: 'OmniPress',
      date: '2025',
      first_page: '10', last_page: '20',
      doi: '10.9999/max.123',
      access_date: 'Feb 29, 2028'
    }
  end

  def build_maximal_expected
    'Maximus, A. <a href="http://example.com/max">"The Component Piece"</a> ' \
      '<cite>The Grand Collection</cite>. Edited by Ed Itor. 3rd Revised ed. ' \
      "vol.#{NBSP}X, no.#{NBSP}1. OmniPress. 2025. pp.#{NBSP}10--20. doi:#{NBSP}" \
      '<a href="https://doi.org/10.9999/max.123">10.9999/max.123</a>. Retrieved Feb 29, 2028.'
  end
end

# Tests for single field citations
class TestCitationUtilsSingleField < TestCitationUtilsBase
  def test_only_doi_present
    params = { doi: '10.555/testdoi' }
    expected = "<span class=\"citation\">doi:#{NBSP}<a href=\"https://doi.org/10.555/testdoi\">" \
               '10.555/testdoi</a>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_only_access_date_present
    params = { access_date: 'March 15, 2023' }
    expected = '<span class="citation">Retrieved March 15, 2023.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_only_editor_present
    params = { editor: 'Dr. Edit' }
    expected = '<span class="citation">Edited by Dr. Edit.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_only_publisher_and_date
    params = { publisher: 'PubCo', date: '2024' }
    expected = '<span class="citation">PubCo. 2024.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_part_only_work_present
    params = { work_title: 'Just Work Title' }
    expected = '<span class="citation"><cite>Just Work Title</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_part_only_container_present
    params = { container_title: 'Just Container Title' }
    expected = '<span class="citation"><cite>Just Container Title</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_only_author_handle_no_last_or_first
    # Tests line 127 'then' and line 128
    params = { author_handle: '@johndoe' }
    expected = '<span class="citation">@johndoe.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_author_last_only_no_first_or_handle
    # Tests line 134 'else' and line 137 'else'
    params = { author_last: 'Smith' }
    expected = '<span class="citation">Smith.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_author_last_and_first_no_handle
    # Tests line 137 'else'
    params = { author_last: 'Doe', author_first: 'Jane' }
    expected = '<span class="citation">Doe, Jane.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_single_page_number
    # Tests line 192 'then' and line 193
    params = { page: '42' }
    expected = "<span class=\"citation\">p.#{NBSP}42.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_first_page_without_last_page
    # Tests line 190 'else'
    params = { first_page: '100' }
    expected = "<span class=\"citation\">pp.#{NBSP}100.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_doi_extraction_fails_for_malformed
    # Tests line 216 'else' - when DOI URL extraction returns nil
    params = { doi: 'https://doi.org/invalid' }
    expected_doi_part = "doi:#{NBSP}https://doi.org/invalid"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end
end
