# frozen_string_literal: true

require_relative '../../../../test_helper'

# Liquid article-card errors and Markdown rendering.
class TestRenderArticleCardTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com', 'baseurl' => '/site' })
    @post = create_doc({ 'title' => 'Part<BR /> Two [Update]', 'description' => 'Read <em>more</em>.' }, '/post(v2)/')
    @context = create_context({ 'post' => @post, 'nil_post_var' => nil }, { site: @site, page: create_doc })
  end

  def test_fatal_card_error_stops_liquid_render
    @post.data['image'] = { 'path' => '/image.jpg' }

    error = assert_raises(Jekyll::Errors::FatalException) { render_tag('post') }
    assert_match(/Front-matter image .*must be a string path or URL/, error.message)
  end

  def test_syntax_error_if_markup_is_empty
    ['{% render_article_card %}', '{% render_article_card    %}'].each do |markup|
      error = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse(markup) }
      assert_match 'A post object variable must be provided', error.message
    end
  end

  def test_render_failure_if_post_object_is_nil
    @site.config['plugin_logging']['RENDER_ARTICLE_CARD_TAG'] = true

    %w[nil_post_var missing_post_var].each do |markup|
      output = render_tag(markup)

      assert_includes output, '[ERROR] RENDER_ARTICLE_CARD_TAG_FAILURE'
      assert_includes output, "Post object variable &#39;#{markup}&#39; resolved to nil."
    end
  end

  def test_render_failure_if_article_card_utils_raises_error
    @site.config['plugin_logging']['RENDER_ARTICLE_CARD_TAG'] = true
    failure = ->(*) { raise StandardError, "Invalid card\nBacktrace details" }

    Jekyll::Posts::ArticleCardRenderer.stub :render, failure do
      output = render_tag('post')

      assert_includes output, '[ERROR] RENDER_ARTICLE_CARD_TAG_FAILURE'
      assert_includes output, 'Error rendering article card: Invalid card'
      assert_includes output, "post_markup='post'"
      assert_includes output, "error_class='StandardError'"
      assert_includes output, "error_message='Invalid card'"
    end
  end

  def test_markdown_mode_works_with_document_drop
    drop = Jekyll::Drops::DocumentDrop.new(@post)
    context = create_context({ 'post' => drop }, { site: @site, render_mode: :markdown })

    assert_equal '- [Part Two \[Update\]](/post\(v2\)/): Read more.', render_tag('post', context)
  end

  private

  def render_tag(markup, context = @context)
    Jekyll.stub :logger, silent_logger do
      Liquid::Template.parse("{% render_article_card #{markup} %}").render!(context)
    end
  end
end
