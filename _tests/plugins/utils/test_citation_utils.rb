# _tests/plugins/utils/test_citation_utils.rb
require_relative '../../test_helper'
require_relative '../../../_plugins/utils/citation_utils' # Ensure the module is loaded

class TestCitationUtils < Minitest::Test
  NBSP = "\u00A0".freeze # Non-breaking space

  # Helper to directly call the module's method.
  # The internal logic of CitationUtils.format_citation_html will now infer
  # work_title styling based on presence of container_title.
  def format_citation(params, _site = nil)
    CitationUtils.format_citation_html(params)
  end

  # --- Test Cases ---

  def test_empty_params
    assert_equal '', format_citation({})
  end

  def test_author_only_full
    params = { author_last: 'Doe', author_first: 'John', author_handle: 'jdoe' }
    expected = '<span class="citation">Doe, John (jdoe).</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_title_only_infers_standalone_cite_style
    params = { work_title: 'The Grand Book' } # No container_title, so work_title is <cite>
    expected = '<span class="citation"><cite>The Grand Book</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_infers_work_quoted_style
    params = { work_title: 'A Great Article', container_title: 'The Journal' } # Both present, so work_title is ""
    expected = '<span class="citation">"A Great Article" <cite>The Journal</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_title_linked_infers_standalone_cite_style
    params = { work_title: 'My Linked Book', url: 'http://example.com/book' }
    expected = '<span class="citation"><a href="http://example.com/book"><cite>My Linked Book</cite></a>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_linked_infers_work_quoted_style
    params = { work_title: 'My Linked Article', container_title: 'The Journal', url: 'http://example.com/article' }
    expected = '<span class="citation"><a href="http://example.com/article">"My Linked Article"</a> <cite>The Journal</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_container_title_only
    params = { container_title: 'The Big Collection' } # work_title is nil
    expected = '<span class="citation"><cite>The Big Collection</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  # --- DOI Linking Tests ---
  def test_doi_slug_is_linked
    params = { doi: '10.1234/xyz.567' }
    expected_doi_part = "doi:#{NBSP}<a href=\"https://doi.org/10.1234/xyz.567\">10.1234/xyz.567</a>"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_is_extracted_and_linked
    params = { doi: 'https://doi.org/10.5678/abc.123' }
    expected_doi_part = "doi:#{NBSP}<a href=\"https://doi.org/10.5678/abc.123\">10.5678/abc.123</a>"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_http_is_extracted_and_linked
    params = { doi: 'http://doi.org/10.5678/abc.123' }
    expected_doi_part = "doi:#{NBSP}<a href=\"https://doi.org/10.5678/abc.123\">10.5678/abc.123</a>"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_doi_full_url_with_www_is_extracted_and_linked
    params = { doi: 'https://www.doi.org/10.5678/abc.123' }
    expected_doi_part = "doi:#{NBSP}<a href=\"https://doi.org/10.5678/abc.123\">10.5678/abc.123</a>"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_non_doi_string_is_not_linked
    params = { doi: 'arXiv:1234.5678' }
    expected_doi_part = "doi:#{NBSP}arXiv:1234.5678"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_malformed_doi_string_is_not_linked
    params = { doi: 'not_a_doi_10.123' }
    expected_doi_part = "doi:#{NBSP}not_a_doi_10.123"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  def test_doi_slug_with_complex_chars_is_linked_and_escaped_for_display
    # Example from CrossRef: 10.1007/s00253-007-1079-x(test)
    # Our current slug detection is simple, so we'll test a more typical complex one.
    # Let's assume the slug itself doesn't need URL encoding for the href, but needs HTML escaping for display.
    complex_slug = '10.1007/s00253-007-1079-x(<>&)'
    escaped_complex_slug = '10.1007/s00253-007-1079-x(&lt;&gt;&amp;)' # How _escapeHTML would handle it
    params = { doi: complex_slug }
    expected_doi_part = "doi:#{NBSP}<a href=\"https://doi.org/#{complex_slug}\">#{escaped_complex_slug}</a>"
    expected = "<span class=\"citation\">#{expected_doi_part}.</span>"
    assert_equal expected, format_citation(params)
  end

  # --- Full Citation Style Examples (Adjusted for new DOI linking) ---

  def test_full_article_in_journal
    params = {
      author_last: 'Doe', author_first: 'Jane',
      work_title: 'My Research Findings',
      container_title: 'Journal of Important Discoveries', # Presence of this makes work_title quoted
      url: 'http://example.com/article_url',
      volume: '15', number: '3',
      date: '2023',
      first_page: '101', last_page: '115',
      doi: '10.1234/jid.2023.15.3.101'
    }
    expected_inner = "Doe, Jane. <a href=\"http://example.com/article_url\">\"My Research Findings\"</a> <cite>Journal of Important Discoveries</cite>. vol.#{NBSP}15, no.#{NBSP}3. 2023. pp.#{NBSP}101--115. doi:#{NBSP}<a href=\"https://doi.org/10.1234/jid.2023.15.3.101\">10.1234/jid.2023.15.3.101</a>."
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

# work_title is present, container_title is not
  def test_full_book_citation
    params = {
      author_last: 'Smith', author_first: 'John',
      work_title: 'A History of Everything',
      url: 'http://example.com/books/history',
      editor: 'Alice Wonderland',
      publisher: 'Academic Books Ltd.',
      date: '2020'
    }
    expected_inner = 'Smith, John. <a href="http://example.com/books/history"><cite>A History of Everything</cite></a>. Edited by Alice Wonderland. Academic Books Ltd. 2020.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_full_chapter_in_edited_book
    params = {
      author_last: 'ChapterAuthor', author_first: 'C.',
      work_title: 'On Specific Topics',
      container_title: 'The Big Book of Topics', # Presence of this makes work_title quoted
      url: 'http://example.com/chapter_url',
      editor: 'Book Editor',
      publisher: 'University Press',
      date: '2021',
      first_page: '45', last_page: '60'
    }
    expected_inner = "ChapterAuthor, C. <a href=\"http://example.com/chapter_url\">\"On Specific Topics\"</a> <cite>The Big Book of Topics</cite>. Edited by Book Editor. University Press. 2021. pp.#{NBSP}45--60."
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_web_page_article_on_website
    params = {
      author_last: 'WebWriter', author_first: 'W.',
      work_title: 'My Thoughts on the Web',
      container_title: 'Personal Blog', # Presence of this makes work_title quoted
      url: 'http://webwriter.blog/thoughts',
      date: 'January 1, 2024'
    }
    expected_inner = 'WebWriter, W. <a href="http://webwriter.blog/thoughts">"My Thoughts on the Web"</a> <cite>Personal Blog</cite>. January 1, 2024.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

# work_title is present, container_title is not
  def test_whole_website_citation
    params = {
      work_title: 'Comprehensive News Site',
      url: 'http://comprehensivenews.com',
      publisher: 'News Network Inc.',
      date: '2024'
    }
    expected_inner = '<a href="http://comprehensivenews.com"><cite>Comprehensive News Site</cite></a>. News Network Inc. 2024.'
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_journal_article_no_url_only_doi_linked
    params = {
      author_first: 'Henrietta', author_last: 'Clopath',
      work_title: 'Genuine Art versus Mechanism',
      container_title: 'Brush and Pencil', # Presence of this makes work_title quoted
      volume: '7', number: '6',
      date: 'March 1, 1901',
      first_page: '331', last_page: '333',
      doi: '10.2307/25505621'
    }
    expected_inner = "Clopath, Henrietta. \"Genuine Art versus Mechanism\" <cite>Brush and Pencil</cite>. vol.#{NBSP}7, no.#{NBSP}6. March 1, 1901. pp.#{NBSP}331--333. doi:#{NBSP}<a href=\"https://doi.org/10.2307/25505621\">10.2307/25505621</a>."
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_all_possible_parts_present_with_linked_doi
    params = {
      author_last: 'Maximus', author_first: 'A.',
      work_title: 'The Component Piece',
      container_title: 'The Grand Collection', # Presence of this makes work_title quoted
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
    expected_inner = "Maximus, A. <a href=\"http://example.com/max\">\"The Component Piece\"</a> <cite>The Grand Collection</cite>. Edited by Ed Itor. 3rd Revised ed. vol.#{NBSP}X, no.#{NBSP}1. OmniPress. 2025. pp.#{NBSP}10--20. doi:#{NBSP}<a href=\"https://doi.org/10.9999/max.123\">10.9999/max.123</a>. Retrieved Feb 29, 2028."
    expected = "<span class=\"citation\">#{expected_inner}</span>"
    assert_equal expected, format_citation(params)
  end

  def test_only_doi_present
    params = { doi: '10.555/testdoi' }
    expected = '<span class="citation">doi: <a href="https://doi.org/10.555/testdoi">10.555/testdoi</a>.</span>'
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

  # Test cases to ensure correct handling when one of work/container is missing
  def test_work_and_container_part_only_work_present
    # This is effectively the same as test_work_title_only_infers_standalone_cite_style
    params = { work_title: 'Just Work Title' }
    expected = '<span class="citation"><cite>Just Work Title</cite>.</span>'
    assert_equal expected, format_citation(params)
  end

  def test_work_and_container_part_only_container_present
    # This is effectively the same as test_container_title_only
    params = { container_title: 'Just Container Title' }
    expected = '<span class="citation"><cite>Just Container Title</cite>.</span>'
    assert_equal expected, format_citation(params)
  end
end
