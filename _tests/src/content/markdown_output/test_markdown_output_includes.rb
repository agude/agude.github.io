# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/markdown_whitespace_normalizer'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_html_converter'

# Tests for Markdown and HTML output from shared content includes.
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

  def test_books_topbar_markdown_keeps_sort_links_without_navigation_markup
    @site.data['link_cache']['books_topbar_nav'] = [
      { 'short_title' => 'Date', 'url' => '/books/' },
      { 'short_title' => 'Author', 'url' => '/books/by-author/' },
    ]
    output = render_include('books_topbar.html', {}, :markdown)
    markdown = WhitespaceNormalizer.normalize(MarkdownOutputConverter.convert(output))

    refute_match(%r{</?(?:aside|nav|a)\b}i, markdown)
    html = render_markdown(markdown)
    assert_includes html.text, 'Sort by:'
    links = html.css('a').map { |link| [link.text, link['href']] }
    assert_equal [['Date', '/books/'], ['Author', '/books/by-author/']], links
    assert_empty html.css('pre, code')
  end

  def test_linktree_markdown_keeps_accessible_link_text_without_svg_or_layout_markup
    parameters = {
      'link' => 'https://example.com/profile',
      'text' => 'My profile',
      'button_class' => 'profile-button',
      'icon' => '<svg aria-hidden="true"><path d="M0 0"/></svg>',
    }
    output = render_include('linktree_item.html', parameters, :markdown)
    markdown = WhitespaceNormalizer.normalize(MarkdownOutputConverter.convert(output))

    assert_equal '[My profile](https://example.com/profile)', markdown.strip
    link = render_markdown(markdown).at_css('a')
    assert_equal 'My profile', link.text
    assert_equal parameters['link'], link['href']
  end

  def test_linktree_page_markdown_keeps_all_author_links_without_layout_wrappers
    root = File.expand_path('../../../..', __dir__)
    author = {
      'bluesky' => 'writer.example',
      'mastodon_instance' => 'social.example',
      'mastodon' => 'writer',
      'github' => 'fixture-writer',
      'linkedin' => 'fixture-writer-profile',
      'name' => 'Fixture Writer',
    }
    config = Jekyll.configuration('source' => root, 'quiet' => true, 'author' => author)
    site = Jekyll::Site.new(config)
    content = File.read(File.join(root, 'linktree.md')).sub(/\A---\n.*?\n---\n/m, '')
    payload = {
      'site' => { 'author' => site.config['author'] },
      'page' => { 'url' => '/linktree/' },
      'render_mode' => 'html',
    }

    markdown = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(content, site, payload)
    html = render_markdown(markdown)

    actual_urls = html.css('a').map { |link| link['href'] }
    expected_urls = [
      'https://bsky.app/profile/writer.example',
      'https://social.example/@writer',
      'https://github.com/fixture-writer',
      'https://www.linkedin.com/in/fixture-writer-profile',
      '/',
      '/feed.xml',
      '/feed/books.xml',
    ]
    assert_equal expected_urls, actual_urls
    refute_match(%r{</?(?:div|svg|path|pre|code)\b}i, markdown)
    assert_equal 'html', payload['render_mode']

    html_payload = {
      'site' => { 'author' => site.config['author'] },
      'page' => { 'url' => '/linktree/' },
      'render_mode' => 'html',
    }
    output = Liquid::Template.parse(content).render!(
      html_payload,
      registers: { site: site, page: html_payload['page'], render_mode: :html },
    )
    assert_includes output, '<div class="linktree-container">'
  end

  def test_navigation_and_linktree_html_keep_layout_and_icons
    @site.data['link_cache']['books_topbar_nav'] = [{ 'short_title' => 'Date', 'url' => '/books/' }]
    navigation = Nokogiri::HTML.fragment(render_include('books_topbar.html', {}, :html))
    assert_equal '/books/', navigation.at_css('aside.book-topbar nav.book-nav a')['href']

    parameters = {
      'link' => 'https://example.com/profile',
      'text' => 'My profile',
      'icon' => '<svg aria-hidden="true"><path d="M0 0"/></svg>',
    }
    linktree = Nokogiri::HTML.fragment(render_include('linktree_item.html', parameters, :html))
    assert_equal 'me', linktree.at_css('a')['rel']
    assert_equal 'true', linktree.at_css('.linktree-images svg')['aria-hidden']
    assert_equal 'My profile', linktree.at_css('.linktree-text strong').text.strip
  end

  def test_topics_page_markdown_keeps_topic_anchors_and_post_links
    root = File.expand_path('../../../..', __dir__)
    content = File.read(File.join(root, 'topics/index.md')).sub(/\A---\n.*?\n---\n/m, '')
    post = create_doc({ 'title' => 'Example post' }, '/blog/example/')
    payload = {
      'site' => { 'categories' => { 'data-science' => [post] } },
      'page' => { 'url' => '/topics/' },
      'render_mode' => 'html',
    }
    result = { posts: [post], log_messages: '' }
    body = Jekyll::Posts::PostListUtils.stub(:get_posts_by_category, ->(**_args) { result }) do
      Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(content, @site, payload)
    end
    markdown = WhitespaceNormalizer.normalize(body)

    refute_match(%r{</?(?:ul|li|span|h3)\b}i, markdown)
    html = render_markdown(markdown)
    assert_equal '#data-science (1)', html.at_css('ul > li > a[href="#data-science"]').text
    assert_equal '#data-science', html.at_css('h3#data-science a').text
    assert_equal '/topics/data-science/', html.at_css('h3#data-science a')['href']
    assert_equal 'Example post', html.at_css('a[href="/blog/example/"]').text
    assert_empty html.css('pre, code')
    assert_equal 'html', payload['render_mode']
  end

  def test_chatgpt_markdown_preserves_quotes_and_labels_inside_footnote
    parameters = {
      'prompt' => 'Why <em>this</em>?<br><br>Next paragraph.',
      'output' => "1. <strong>First</strong>\n2. Second",
    }
    output = MarkdownOutputConverter.convert(render_include('chatgpt_edit.html', parameters, :markdown))
    refute_match(/<(?:div|blockquote|br)\b/i, output)

    markdown = "See this.[^edit]\n\n[^edit]: #{output}\n\nAfterwards.\n"
    config = Jekyll.configuration('source' => File.expand_path('../../../..', __dir__), 'quiet' => true)
    html = Nokogiri::HTML.fragment(Jekyll::Converters::Markdown.new(config).convert(markdown))
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

  def test_production_pipeline_preserves_quoted_fence_in_footnote
    root = File.expand_path('../../../..', __dir__)
    site = Jekyll::Site.new(Jekyll.configuration('source' => root, 'quiet' => true))
    code = "```ruby\nliteral = '<em>code</em>'\t\n\n\nlast = 1  \n```"
    prompt = "Explain <em>this</em>.\n\nUse `<em>literal</em>\ncontinued`."
    content = <<~LIQUID
      Read this.[^edit]

      [^edit]: {% include chatgpt_edit.html prompt=page.prompt output=page.code %}

      Afterwards.
    LIQUID
    payload = { 'page' => { 'code' => code, 'prompt' => prompt }, 'render_mode' => 'html' }
    body = Jekyll::MarkdownOutput::MarkdownBodyHook.render_markdown_body(content, site, payload)
    doc = create_doc({ 'title' => 'Example', 'layout' => 'page', 'markdown_body' => body }, '/example/')
    markdown = Jekyll::MarkdownOutput::MarkdownOutputAssembler.assemble_markdown(doc)
    quoted_code = code.split("\n", -1).map { |line| line.empty? ? '    >' : "    > #{line}" }.join("\n")
    assert_includes markdown, "\n#{quoted_code}\n"
    assert_includes markdown, "\n    > Use `<em>literal</em>\n    > continued`.\n"

    rendered = Jekyll::Converters::Markdown.new(site.config).convert(markdown)
    html = Nokogiri::HTML.fragment(rendered)
    footnote = html.at_css('.footnotes li')
    refute_nil footnote
    assert_equal 2, footnote.css('blockquote').length
    assert_equal %w[Prompt Output], footnote.css('strong').map(&:text)
    assert_equal 'this', footnote.at_css('em')&.text
    assert_equal "literal = '<em>code</em>'\t\n\n\nlast = 1  \n", footnote.at_css('pre > code')&.text, rendered
    assert_equal 'Afterwards.', html.xpath('./p').last.text.strip
    assert_equal 'html', payload['render_mode']
  end

  private

  def render_markdown(markdown)
    config = Jekyll.configuration('source' => File.expand_path('../../../..', __dir__), 'quiet' => true)
    Nokogiri::HTML.fragment(Jekyll::Converters::Markdown.new(config).convert(markdown))
  end

  def render_include(filename, parameters, render_mode)
    include_path = File.expand_path("../../../../_includes/#{filename}", __dir__)
    template = Liquid::Template.parse(File.read(include_path))
    scopes = {
      'include' => parameters,
      'render_mode' => render_mode.to_s,
      'site' => { 'data' => @site.data, 'baseurl' => @site.baseurl },
      'page' => { 'url' => '/books/' },
    }
    registers = { site: @site, render_mode: render_mode }
    context = create_context(scopes, registers)

    template.render!(context)
  end
end
