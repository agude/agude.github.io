# frozen_string_literal: true

require_relative '../../../test_helper'

# Check code bytes and rendered structure through the production Markdown pass.
class TestMarkdownHtmlConverterFidelity < Minitest::Test
  def setup
    root = File.expand_path('../../../..', __dir__)
    @site = Jekyll::Site.new(Jekyll.configuration('source' => root, 'quiet' => true))
    @renderer = Jekyll::Converters::Markdown.new(@site.config)
  end

  def test_indented_code_bytes_survive_liquid_conversion_and_normalization
    blocks = {
      spaces: "    <strong>literal</strong>\t\n\n\n    last  \n",
      deeper_first: "        <strong>literal</strong>\t\n    <em>still code</em>  \n",
      tabs: "\t<em>literal</em>\t\n\n\n\tlast  \n",
      quoted: ">     <strong>literal</strong>\t\n>\n>\n>     last  \n",
      tab_marker: "1.\titem\n\n\t\t<em>literal</em>\t\n",
    }
    blocks.each do |name, code|
      assert_code_survives_pipeline("Example:\n\n#{code}\nAfter <em>prose</em>.\n", code, name)
    end
  end

  def test_fenced_code_bytes_survive_tab_and_combined_containers
    blocks = {
      tab_list: "1. item\n\n\t```html\n\t<em>literal</em>\t\n\n\n\tlast  \n\t```\n",
      quoted_list: "> 123. item\n>\n>      ```html\n>      <em>literal</em>\t\n>\n>\n>      last  \n>      ```\n",
      list_quote: "1. item\n\n    > ```html\n    > <em>literal</em>\t\n    >\n    >\n    > last  \n    > ```\n",
      nested_quote_list: "> > 123. item\n> >\n> >      ~~~html\n> >      <em>literal</em>\t\n> >\n> >\n> >      last  \n> >      ~~~\n",
    }
    blocks.each do |name, code|
      assert_code_survives_pipeline("#{code}\nAfter <em>prose</em>.\n", code, name)
    end
  end

  def test_indented_list_continuation_remains_prose
    [
      "1. First.\n\n    Continue with <em>emphasis</em>.\n",
      "123. First.\n\n        Continue with <em>emphasis</em>.\n",
    ].each do |input|
      original = render(input)
      assert_empty original.css('pre'), input

      output = pipeline(input)
      assert_includes output, 'Continue with _emphasis_.', input
      assert_equal original.at_css('ol').to_html, render(output).at_css('ol').to_html, input
      assert_equal 'emphasis', render(output).at_css('li em')&.text, input
    end
  end

  def test_list_code_range_stops_before_list_continuation_prose
    input = "1. item\n\n        <strong>literal</strong>\n\n    Continue <em>prose</em>.\n"
    original = render(input)
    original_code = original.at_css('pre > code')&.text
    output = pipeline(input)

    assert_equal " <strong>literal</strong>\n", original_code
    assert_includes output, 'Continue _prose_.'
    assert_equal original.at_css('ol').to_html, render(output).at_css('ol').to_html
  end

  def test_raw_html_regions_keep_inline_formatting_links_and_literal_payloads
    regions = [
      '<div class="custom"><em>italic</em> and <a href="/reference/">reference</a></div>',
      '<section><strong>literal</strong> prose.</section>',
      '<ul><li><strong>literal</strong> item</li></ul>',
      '<aside><a href="/reference/">reference</a></aside>',
      '<pre><strong>literal</strong> and <em>literal</em></pre>',
      '<!-- <em>literal</em><hr><div class="low-width-table">example</div> -->',
      '<script>const example = "<strong>literal</strong>";</script>',
      '<style>/* <em>literal</em> */ .example { color: red; }</style>',
    ]
    regions.each do |region|
      output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(region)
      assert_equal region, output, region
      assert_equal render(region).to_html, render(output).to_html, region
    end
    table = '<table><tr><td><strong>Bold</strong></td></tr></table>'
    code = "```html\n<details>literal\n```\n"
    script = "<script type=\"text/plain\">\n```\n</script>\n\n#{code}\n#{table}\n\nOutside <em>prose</em>.\n"
    output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(script)
    assert_includes output, code
    assert_includes output, table
    assert_includes output, 'Outside _prose_.'

    production = pipeline(script)
    assert_includes production, "<script type=\"text/plain\">\n```\n</script>"
    assert_includes production, code
    assert_includes production, table
    assert_includes production, 'Outside _prose_.'
  end

  def test_html_with_markdown_enabled_still_converts_prose
    %w[1 block span].each do |value|
      input = "<div markdown=\"#{value}\">\n\n<em>Prose</em> with <strong>formatting</strong>.\n\n</div>\n"
      output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(input)

      assert_includes output, '_Prose_ with **formatting**.'
      assert_equal render(input).to_html, render(output).to_html
    end
  end

  def test_markdown_attribute_near_matches_remain_raw
    ['<div data-markdown="1"><em>literal</em></div>', '<div markdown="0"><em>literal</em></div>'].each do |input|
      assert_equal input, Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(input)
    end
  end

  def test_inline_code_tags_do_not_hide_later_prose
    input = 'Use `<div>` literal. Outside <em>prose</em>. `</div>`'
    output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(input)

    assert_includes output, '`<div>`'
    assert_includes output, 'Outside _prose_.'
    assert_includes output, '`</div>`'
  end

  def test_emphasis_at_word_boundaries_preserves_rendered_formatting
    assert_rendering_preserved('pre<em>fix</em>ed')
  end

  def test_emphasis_with_boundary_whitespace_preserves_text_and_formatting
    ['<em> spaced </em>', '<strong> spaced </strong>'].each do |input|
      assert_rendering_preserved(input)
    end
  end

  def test_nested_emphasis_and_delimiter_contents_preserve_rendered_formatting
    [
      '<em>outer <em>inner</em> tail</em>',
      '<strong>outer <strong>inner</strong> tail</strong>',
      '<em>first_</em>',
      '<em>_both_</em>',
      '<strong>first*</strong>',
    ].each do |input|
      assert_rendering_preserved(input)
    end
  end

  def pipeline(content)
    payload = { 'page' => { 'example' => '<strong>literal</strong>' }, 'render_mode' => 'html' }
    content = content.sub('<strong>literal</strong>', '{{ page.example }}')
    body = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(content, @site, payload)
    doc = create_doc({ 'title' => 'Example', 'layout' => 'page', 'markdown_body' => body }, '/example/')
    Jekyll::MarkdownOutput::MarkdownOutputAssembler.assemble_markdown(doc)
  end

  def render(markdown)
    Nokogiri::HTML.fragment(@renderer.convert(markdown))
  end

  def assert_code_survives_pipeline(input, code, name)
    original = render(input).css('pre > code').map(&:text)
    refute_empty original, "#{name}: fixture must render as code"
    output = pipeline(input)
    assert_includes output, code, "#{name}: preserve the complete source region"
    assert_equal original, render(output).css('pre > code').map(&:text), name
    assert_equal 'prose', render(output).at_css('p em')&.text, name
  end

  def assert_rendering_preserved(input)
    output = Jekyll::MarkdownOutput::MarkdownHtmlConverter.convert(input)
    assert_equal render(input).to_html, render(output).to_html, "#{input.inspect} became #{output.inspect}"
  end
end
