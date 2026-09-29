# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/markdown_whitespace_normalizer'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_html_converter'

# Tests for Markdown and HTML output from figure and video includes.
class TestMarkdownOutputIncludes < Minitest::Test
  MarkdownOutputConverter = Jekyll::MarkdownOutput::MarkdownHtmlConverter
  WhitespaceNormalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer

  def setup
    @site = create_site
  end

  def test_figure_markdown_renders_caption_and_converts_supported_inline_html
    parameters = {
      'url' => '/images/figure.png',
      'caption' => '<em>A book</em>',
      'image_alt' => 'A chart',
    }
    output = render_include('figure.html', parameters, :markdown)

    normalized_output = WhitespaceNormalizer.normalize(MarkdownOutputConverter.convert(output))

    assert_equal "![A chart](/images/figure.png)\n\n_A book_\n", normalized_output
    refute_includes output, '<figure>'
  end

  def test_figure_markdown_omits_absent_caption
    parameters = {
      'url' => '/images/figure.png',
      'image_alt' => 'A chart',
    }
    output = render_include('figure.html', parameters, :markdown)

    assert_equal '![A chart](/images/figure.png)', output.strip
  end

  def test_figure_html_keeps_figure_and_caption_markup
    parameters = {
      'url' => '/images/figure.png',
      'caption' => 'A chart caption',
      'image_alt' => 'A chart',
    }
    output = render_include('figure.html', parameters, :html)

    assert_includes output, '<figure>'
    assert_includes output, '<figcaption>A chart caption</figcaption>'
    assert_includes output, '<img src="/images/figure.png" alt="A chart"'
  end

  def test_video_markdown_renders_file_link
    output = render_include('video.html', { 'file' => '/videos/demo.mp4' }, :markdown)

    assert_includes output, '[Video](/videos/demo.mp4)'
    refute_includes output, '<video'
  end

  def test_video_html_keeps_video_markup
    output = render_include('video.html', { 'file' => '/videos/demo.mp4' }, :html)

    assert_includes output, '<div class="video-gif">'
    assert_includes output, '<video '
    assert_includes output, '<source src="/videos/demo.mp4" type="video/mp4" />'
    refute_includes output, '[Video]'
  end

  def test_chatgpt_markdown_preserves_quotes_and_labels_inside_footnote
    parameters = {
      'prompt' => 'Why <em>this</em>?<br><br>Next paragraph.',
      'output' => "1. <strong>First</strong>\n2. Second",
    }
    output = MarkdownOutputConverter.convert(render_include('chatgpt_edit.html', parameters, :markdown))
    refute_match(/<(?:div|blockquote|br)\b/i, output)

    markdown = "See this.[^edit]\n\n[^edit]: #{output}\n\nAfterwards.\n"
    html = Nokogiri::HTML.fragment(Kramdown::Document.new(markdown).to_html)
    footnote = html.at_css('.footnotes li')
    refute_nil footnote
    quotes = footnote.css('blockquote')
    assert_equal 2, quotes.length
    assert_equal ['Why this?', 'Next paragraph.'], quotes.first.css('p').map(&:text).map(&:strip)
    assert_equal %w[First Second], quotes.last.css('ol > li').map(&:text).map(&:strip)
    assert_equal %w[Prompt Output First], footnote.css('strong').map(&:text)
    assert_equal 'Afterwards.', html.css('p').find { |paragraph| paragraph.text == 'Afterwards.' }&.text
  end

  def test_chatgpt_html_preserves_existing_compact_markup
    output = render_include('chatgpt_edit.html', { 'prompt' => 'Question', 'output' => 'Answer' }, :html)
    assert_includes output, '<div class="chatgpt-edit-block">'
    assert_includes output, '<strong>Prompt</strong>'
    assert_includes output, '<blockquote>Question</blockquote>'
    assert_includes output, '<strong>Output</strong>'
    assert_includes output, '<blockquote>Answer</blockquote>'
    refute_includes output, "\n"
  end

  private

  def render_include(filename, parameters, render_mode)
    include_path = File.expand_path("../../../../_includes/#{filename}", __dir__)
    template = Liquid::Template.parse(File.read(include_path))
    scopes = { 'include' => parameters, 'render_mode' => render_mode.to_s }
    registers = { site: @site, render_mode: render_mode }
    context = create_context(scopes, registers)

    template.render!(context)
  end
end
