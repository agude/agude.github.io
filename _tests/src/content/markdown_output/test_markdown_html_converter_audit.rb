# frozen_string_literal: true

require_relative '../../../test_helper'

# Regression cases taken from the generated Markdown HTML audit.
class TestMarkdownHtmlConverterAudit < Minitest::Test
  Converter = Jekyll::MarkdownOutput::MarkdownHtmlConverter
  Normalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer

  def test_horizontal_rule_becomes_markdown_with_paragraph_boundaries
    output = convert('Before.<hr class="divider"/>After.')

    refute_match(/<hr\b/i, output)
    html = render(output)
    assert_equal %w[p hr p], html.element_children.map(&:name)
    assert_equal ['Before.', 'After.'], html.css('p').map(&:text)
    assert_equal '<hr-extra>Keep.', Converter.convert('<hr-extra>Keep.')
  end

  def test_nested_table_layout_wrappers_leave_a_markdown_table
    input = <<~MARKDOWN
      Before.

      <div class="low-width-table" markdown="1" style="max-width: 20%">
      <div class="low-width-table" markdown="1">

      | Value | Count |
      | ----- | ----- |
      | A     | 2     |

      </div>
      </div>

      After.
    MARKDOWN
    output = convert(input)

    refute_match(%r{</?div\b}i, output)
    html = render(output)
    assert_equal %w[p table p], html.element_children.map(&:name)
    assert_equal %w[Value Count], html.css('th').map(&:text)
    assert_equal %w[A 2], html.css('td').map(&:text)
  end

  def test_colored_status_spans_keep_words_links_and_emphasis
    input = '| <span style="color:ForestGreen"><strong>Pass</strong></span> | ' \
            '<span style="color:DarkBlue"><a href="/decision/">Declined</a></span> |'

    assert_equal '| **Pass** | [Declined](/decision/) |', convert(input)
  end

  def test_citations_dates_underlines_and_super_and_subscripts_are_preserved
    input = '<cite class="newspaper">Daily Cal</cite>, ' \
            '<time datetime="2025-07-02">July 2, 2025</time>, ' \
            '<u style="color:ForestGreen">underlined answer</u>, ' \
            'x<sup>2</sup> and H<sub>2</sub>O.'

    assert_equal input, convert(input)
    html = render(convert(input))
    assert_equal 'Daily Cal', html.at_css('cite').text
    assert_equal '2025-07-02', html.at_css('time')['datetime']
    assert_equal 'underlined answer', html.at_css('u').text
    assert_equal %w[2 2], html.css('sup, sub').map(&:text)
  end

  def test_raw_table_retains_merged_cells_and_alignment
    input = <<~HTML
      <table>
        <thead><tr><th>Region</th><th>Gender</th><th><strong>Pay</strong></th></tr></thead>
        <tbody>
          <tr><td rowspan="2">California</td><td><em>Female</em></td><td style="text-align: right"><a href="/pay/">$168k</a></td></tr>
          <tr><td>Male</td><td style="text-align: right">$162k</td></tr>
        </tbody>
      </table>
    HTML

    assert_equal input, Converter.convert(input)
    html = render(convert(input))
    assert_equal '2', html.at_css('td')['rowspan']
    assert_equal ['California', 'Female', '$168k', 'Male', '$162k'], html.css('td').map(&:text)
    assert_equal 2, html.css('td[style="text-align: right"]').length
    assert_equal 'Pay', html.at_css('th strong')&.text
    assert_equal 'Female', html.at_css('td em')&.text
    assert_equal '/pay/', html.at_css('td a')&.[]('href')
  end

  def test_media_embed_and_comments_are_preserved
    input = '<!-- Interactive visualization -->' \
            '<iframe title="Chart" src="https://example.com/chart"></iframe>'

    assert_equal input, convert(input)
  end

  def test_audited_html_inside_code_is_preserved_exactly
    literal = '<hr><cite>Title</cite><time datetime="2025-07-02">Date</time>' \
              '<span style="color:ForestGreen">Pass</span>' \
              '<div class="low-width-table" markdown="1">Table</div>' \
              '<u>Answer</u><sup>2</sup><sub>2</sub><!-- Example -->'
    code = "```html\n#{literal}\t\n\n\n#{literal}  \n```\n"
    input = "Use `#{literal}` literally.\n\n#{code}"

    assert_equal input, convert(input)
    assert_equal "#{literal}\t\n\n\n#{literal}  \n", render(input).at_css('pre > code').text
  end

  private

  def convert(input)
    Normalizer.normalize(Converter.convert(input))
  end

  def render(markdown)
    config = Jekyll.configuration('source' => File.expand_path('../../../..', __dir__), 'quiet' => true)
    Nokogiri::HTML.fragment(Jekyll::Converters::Markdown.new(config).convert(markdown))
  end
end
