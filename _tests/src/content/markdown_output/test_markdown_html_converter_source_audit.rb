# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_html_converter'

# Stable list and footnote fixture for the corrected nowrap markup.
class TestMarkdownHtmlSourceAudit < Minitest::Test
  def test_nowrap_footnote_in_list_preserves_the_link_and_following_prose
    input = "1. Read [Detector](/paper/)<span\n   class=\"nowrap\">,[^ref]</span> carefully.\n\n[^ref]: Citation.\n"
    expected = "1. Read [Detector](/paper/),[^ref] carefully.\n\n[^ref]: Citation.\n"
    output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(input)
    assert_equal expected, output

    config = Jekyll.configuration('source' => File.expand_path('../../../..', __dir__), 'quiet' => true)
    html = Nokogiri::HTML.fragment(Jekyll::Converters::Markdown.new(config).convert(output))
    assert_equal '/paper/', html.at_css('ol > li a')['href']
    assert_equal 'Detector', html.at_css('ol > li a').text
    assert_includes html.at_css('ol > li').text, 'carefully.'
    assert_equal 1, html.css('.footnotes li').length
  end
end
