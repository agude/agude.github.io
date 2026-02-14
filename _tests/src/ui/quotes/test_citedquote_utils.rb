# frozen_string_literal: true

# _tests/src/ui/quotes/test_citedquote_utils.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/quotes/citedquote_utils'

# Tests for Jekyll::UI::Quotes::CitedQuoteUtils utility module.
#
# Verifies that the module correctly renders cited quotes with proper HTML structure.
class TestCitedQuoteUtils < Minitest::Test
  def setup
    @site = create_site
  end

  # --- Tests for HTML Structure ---

  def test_render_outputs_figure_with_cited_quote_class
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe' },
      @site,
    )

    assert_match(/<figure class="cited-quote">/, output)
    assert_match(%r{</figure>}, output)
  end

  def test_render_wraps_output_in_nomarkdown
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe' },
      @site,
    )

    # Output wrapped in {::nomarkdown}...{:/nomarkdown} for Kramdown compatibility
    assert_match(/^\{::nomarkdown\}/, output)
    assert_match(%r{\{:/nomarkdown\}$}, output)
  end

  def test_render_outputs_blockquote_element
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe' },
      @site,
    )

    assert_match(/<blockquote>/, output)
    assert_match(%r{</blockquote>}, output)
  end

  def test_render_includes_cite_attribute_when_url_provided
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe', url: 'http://example.com/source' },
      @site,
    )

    assert_match(%r{cite="http://example\.com/source"}, output)
  end

  def test_render_omits_cite_attribute_when_no_url
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe' },
      @site,
    )

    refute_match(/cite=/, output)
  end

  def test_render_outputs_figcaption_with_citation
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Some quote text',
      { author_last: 'Doe' },
      @site,
    )

    assert_match(/<figcaption>/, output)
    assert_match(%r{</figcaption>}, output)
    # Should contain em-dash before citation
    assert_match(/—/, output)
  end

  # --- Tests for Content Processing ---

  def test_render_processes_content_as_markdown
    # Create a mock converter that wraps content in <p> tags
    mock_converter = Object.new
    def mock_converter.convert(content)
      "<p>#{content.strip}</p>"
    end

    @site.stub :find_converter_instance, mock_converter do
      output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
        '**bold** text',
        { author_last: 'Doe' },
        @site,
      )

      # The mock converter wraps in <p> tags
      assert_match(/<p>/, output)
    end
  end

  def test_render_preserves_html_in_content
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      '<em>emphasized</em> text',
      { author_last: 'Doe' },
      @site,
    )

    assert_match(%r{<em>emphasized</em>}, output)
  end

  def test_render_preserves_br_tags_in_content
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      "Line one<br>\nLine two",
      { author_last: 'Doe' },
      @site,
    )

    assert_match(/<br>/, output)
  end

  # --- Tests for Citation Delegation ---

  def test_render_delegates_to_citation_utils
    params = {
      author_last: 'Doe',
      author_first: 'John',
      work_title: 'Test Article',
    }

    captured_params = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html,
                                              lambda { |p, _site|
                                                captured_params = p
                                                '<span class="citation">Doe, John. "Test Article".</span>'
                                              } do
      Jekyll::UI::Quotes::CitedQuoteUtils.render('content', params, @site)
    end

    refute_nil captured_params
    assert_equal 'Doe', captured_params[:author_last]
    assert_equal 'John', captured_params[:author_first]
    assert_equal 'Test Article', captured_params[:work_title]
  end

  def test_render_includes_citation_output_in_figcaption
    mock_citation = '<span class="citation">Doe, John. "Test".</span>'

    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, mock_citation do
      output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
        'content',
        { author_last: 'Doe', author_first: 'John' },
        @site,
      )

      assert_match(/#{Regexp.escape(mock_citation)}/, output)
    end
  end

  # --- Tests for HTML Escaping ---

  def test_render_escapes_url_in_cite_attribute
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'content',
      { author_last: 'Doe', url: 'http://example.com/path?a=1&b=2' },
      @site,
    )

    # Ampersand should be escaped in attribute
    assert_match(%r{cite="http://example\.com/path\?a=1&amp;b=2"}, output)
  end

  # --- Tests for Full Output ---

  def test_render_produces_complete_structure
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'A famous quote',
      { author_last: 'Doe', url: 'http://example.com' },
      @site,
    )

    # Check overall structure order
    assert_match(
      %r{<figure class="cited-quote">.*<blockquote.*>.*</blockquote>.*<figcaption>.*</figcaption>.*</figure>}m,
      output,
    )
  end

  def test_render_handles_all_citation_params
    params = {
      author_last: 'Doe',
      author_first: 'John',
      author_handle: '@jdoe',
      work_title: 'Work',
      container_title: 'Container',
      editor: 'Ed',
      edition: '2nd',
      volume: 'X',
      number: '1',
      publisher: 'Pub',
      date: '2023',
      first_page: '10',
      last_page: '20',
      page: '15',
      doi: '10.123',
      url: 'http://example.com',
      access_date: 'Today',
    }

    # Should not raise error
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render('content', params, @site)
    assert_match(/<figure/, output)
  end

  # --- Tests for nil Converter Path ---

  def test_render_returns_unprocessed_content_when_no_converter_available
    # Stub find_converter_instance to return nil
    @site.stub :find_converter_instance, nil do
      output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
        'Raw content here',
        { author_last: 'Doe' },
        @site,
      )

      # Content should be passed through unprocessed (no <p> wrapper)
      assert_match(/Raw content here/, output)
      assert_match(%r{<blockquote>Raw content here</blockquote>}, output)
    end
  end

  # --- Tests for Empty String Parameters ---

  def test_render_handles_empty_string_parameter_gracefully
    # Empty string for author_last should be treated as not present
    output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'Quote text',
      { author_last: '', work_title: 'A Book' },
      @site,
    )

    # Should still produce valid output without error
    assert_match(/<figure class="cited-quote">/, output)
    assert_match(/<figcaption>/, output)
    # The citation should include the work title
    assert_match(/A Book/, output)
  end

  # --- Integration Test for Kramdown Footnote Compatibility ---

  def test_render_output_not_escaped_when_processed_by_kramdown_in_footnote
    # This integration test verifies the {::nomarkdown} wrapper works correctly
    # when the output is placed inside a Kramdown footnote.
    require 'kramdown'

    # Get the actual output from CitedQuoteUtils
    citedquote_output = Jekyll::UI::Quotes::CitedQuoteUtils.render(
      'A great quote.',
      { author_last: 'Doe', work_title: 'Test Work' },
      @site,
    )

    # Create markdown with a footnote containing the citedquote output
    markdown_with_footnote = <<~MARKDOWN
      Some text with a footnote.[^note]

      [^note]: Introduction text #{citedquote_output}
    MARKDOWN

    # Process through Kramdown
    html_output = Kramdown::Document.new(markdown_with_footnote).to_html

    # The HTML should contain proper <figure> and <blockquote> tags, not escaped
    assert_match(
      /<figure class="cited-quote">/,
      html_output,
      'Figure tag should not be escaped in footnote',
    )
    assert_match(
      /<blockquote>/,
      html_output,
      'Blockquote tag should not be escaped in footnote',
    )
    assert_match(
      /<figcaption>/,
      html_output,
      'Figcaption tag should not be escaped in footnote',
    )

    # Verify tags are NOT escaped (would appear as &lt;figure&gt; if escaped)
    refute_match(
      /&lt;figure/,
      html_output,
      'Figure tag should not be HTML-escaped',
    )
    refute_match(
      /&lt;blockquote/,
      html_output,
      'Blockquote tag should not be HTML-escaped',
    )
  end
end
