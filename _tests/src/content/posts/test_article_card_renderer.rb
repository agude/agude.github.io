# frozen_string_literal: true

require_relative '../../../test_helper'

# Article card data, HTML, and front-matter fallbacks.
class TestArticleCardRenderer < Minitest::Test
  Renderer = Jekyll::Posts::ArticleCardRenderer

  def setup
    @site = create_site({ 'url' => 'https://example.com', 'baseurl' => '/site' })
    @context = create_context({}, { site: @site, page: create_doc })
    @post = create_doc(
      {
        'title' => 'Post & <Title>',
        'image' => '/images/article.jpg',
        'image_alt' => 'Alt with "quotes" & <tags>',
        'description' => '  Front matter description.  ',
        'excerpt' => '<p>Unused excerpt.</p>',
      },
      '/article/',
    )
  end

  def test_extract_data_returns_raw_values
    data = Renderer.new(@post, @context).extract_data

    assert_predicate data, :frozen?
    assert_equal(
      {
        title: 'Post & <Title>',
        url: 'https://example.com/site/article/',
        image_url: 'https://example.com/site/images/article.jpg',
        excerpt: 'Front matter description.',
        date: @post.date,
        image_alt: 'Alt with "quotes" & <tags>',
      },
      data,
    )
  end

  def test_render_article_card_success
    sizes = Renderer::IMAGE_SIZES
    expected = <<~HTML.chomp
      <li class="article-card">
        <div class="card-element card-image">
          <a href="https://example.com/site/article/">
            <img src="https://example.com/site/images/article.jpg" alt="Alt with &quot;quotes&quot; &amp; &lt;tags&gt;" loading="lazy" decoding="async" sizes="auto, #{sizes}" />
          </a>
        </div>
        <div class="card-element card-text">
          <a href="https://example.com/site/article/">
            <strong>Post &amp; &lt;Title&gt;</strong>
          </a>
      <br>
      Front matter description.  </div>
      </li>
    HTML

    assert_equal expected, Renderer.render(@post, @context)
  end

  def test_render_article_card_no_image
    [nil, '  '].each do |blank|
      post = create_doc({ 'title' => 'No Image', 'image' => blank, 'description' => blank, 'excerpt' => blank })
      data = Renderer.new(post, @context).extract_data

      assert_nil data[:image_url]
      assert_empty data[:excerpt]
      assert_equal 'Article header image, used for decoration.', data[:image_alt]
      refute_match(/<img|<br>/, Renderer.render(post, @context))
    end
  end

  def test_render_article_card_description_from_excerpt
    [nil, '  '].each do |description|
      @post.data['description'] = description
      @post.data['excerpt'] = Struct.new(:output).new("  <p>Excerpt content.</p>\n")

      assert_equal '<p>Excerpt content.</p>', Renderer.new(@post, @context).extract_data[:excerpt]
    end
  end

  def test_render_returns_log_if_base_data_has_no_item_data_source
    @site.config['plugin_logging']['ARTICLE_CARD_UTIL'] = true
    output = Jekyll.stub(:logger, silent_logger) { Renderer.render(false, @context) }

    assert_match(/\A<!-- \[WARN\] ARTICLE_CARD_UTIL_FAILURE:.*Invalid item_object.*-->\s*\z/, output)
  end

  def test_extract_data_returns_nil_when_base_extraction_fails
    Jekyll.stub :logger, silent_logger do
      assert_nil Renderer.new(@post, create_context).extract_data
    end
  end

  def test_render_article_card_missing_alt_logs_warning
    @site.config['plugin_logging']['ARTICLE_CARD_ALT_MISSING'] = true
    [nil, '   ', false].each do |blank|
      @post.data['image_alt'] = blank
      output = Jekyll.stub(:logger, silent_logger) { Renderer.render(@post, @context) }

      assert_match(/\A<!-- \[WARN\] ARTICLE_CARD_ALT_MISSING_FAILURE:.*Missing &#39;image_alt&#39;/, output)
      assert_includes output, 'alt="Article header image, used for decoration."'
    end
  end
end
