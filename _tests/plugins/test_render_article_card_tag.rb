# frozen_string_literal: true

# _tests/plugins/test_render_article_card_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/render_article_card_tag' # Load the tag

class TestRenderArticleCardTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' }) # For ArticleCardUtils -> CardDataExtractorUtils -> UrlUtils
    @post_obj = create_doc({ 'title' => 'Test Post', 'path' => 'test-post.md' }, '/test-post.html')
    @context = create_context(
      { 'my_post' => @post_obj, 'nil_post_var' => nil },
      { site: @site, page: create_doc({ 'path' => 'current_page.md' }, '/current-page.html') } # Page path for SourcePage
    )

    # Silent logger for tests not asserting specific console output from PluginLoggerUtils
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end

      def logger.log_level=(level); end

      def logger.progname=(name); end
    end
  end

  def render_tag(markup, context = @context)
    output = ''
    # Stub Jekyll.logger to silence console output from PluginLoggerUtils during most tests
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% render_article_card #{markup} %}").render!(context)
    end
    output
  end

  # --- Test Cases ---

  # 1. Syntax Error
  def test_syntax_error_if_markup_is_empty
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% render_article_card %}')
    end
    assert_match 'A post object variable must be provided', err.message

    err_whitespace = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% render_article_card    %}')
    end
    assert_match 'A post object variable must be provided', err_whitespace.message
  end

  # 2. Render - Success
  def test_render_success_calls_article_card_utils
    markup = 'my_post' # 'my_post' is @post_obj in context
    expected_card_html = "<div class='article-card'>Rendered Test Post</div>"
    captured_args = nil

    ArticleCardUtils.stub :render, lambda { |post_arg, context_arg|
      captured_args = { post: post_arg, context: context_arg }
      expected_card_html
    } do
      output = render_tag(markup)
      assert_equal expected_card_html, output
    end

    refute_nil captured_args, 'ArticleCardUtils.render should have been called'
    assert_equal @post_obj, captured_args[:post], 'Incorrect post object passed to ArticleCardUtils'
    assert_equal @context, captured_args[:context], 'Incorrect context passed to ArticleCardUtils'
  end

  # 3. Render - Failure: Post object resolves to nil
  def test_render_failure_if_post_object_is_nil
    markup = 'nil_post_var' # 'nil_post_var' resolves to nil
    expected_log_html = '<!-- RENDER_ARTICLE_CARD_TAG: NIL POST OBJECT -->'
    captured_log_args = nil

    # Enable logging for this specific tag type for this test
    @site.config['plugin_logging']['RENDER_ARTICLE_CARD_TAG'] = true

    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args|
      captured_log_args = args
      expected_log_html # Return the stubbed HTML comment
    } do
      output = render_tag(markup)
      assert_equal expected_log_html, output
    end

    refute_nil captured_log_args, 'PluginLoggerUtils.log_liquid_failure should have been called'
    assert_equal @context, captured_log_args[:context]
    assert_equal 'RENDER_ARTICLE_CARD_TAG', captured_log_args[:tag_type]
    assert_match "Post object variable '#{markup}' resolved to nil", captured_log_args[:reason]
    assert_equal({ markup: markup }, captured_log_args[:identifiers])
    # Default level for this log in the tag is :error
    assert_equal :error, captured_log_args[:level]
  end

  def test_render_failure_if_post_variable_not_found
    markup = 'non_existent_post_var' # Variable does not exist in context
    expected_log_html = '<!-- RENDER_ARTICLE_CARD_TAG: NON-EXISTENT POST VAR -->'
    captured_log_args = nil

    @site.config['plugin_logging']['RENDER_ARTICLE_CARD_TAG'] = true

    PluginLoggerUtils.stub :log_liquid_failure, lambda { |args|
      captured_log_args = args
      expected_log_html
    } do
      output = render_tag(markup)
      assert_equal expected_log_html, output
    end

    refute_nil captured_log_args
    assert_equal 'RENDER_ARTICLE_CARD_TAG', captured_log_args[:tag_type]
    assert_match "Post object variable '#{markup}' resolved to nil", captured_log_args[:reason]
  end

  # 4. Render - Failure: ArticleCardUtils.render raises an error
  def test_render_failure_if_article_card_utils_raises_error
    markup = 'my_post'
    error_message = 'Something went wrong in ArticleCardUtils'
    expected_log_html = '<!-- RENDER_ARTICLE_CARD_TAG: UTIL ERROR -->'
    captured_log_args = nil

    @site.config['plugin_logging']['RENDER_ARTICLE_CARD_TAG'] = true

    ArticleCardUtils.stub :render, ->(_post, _ctx) { raise StandardError, error_message } do
      PluginLoggerUtils.stub :log_liquid_failure, lambda { |args|
        captured_log_args = args
        expected_log_html
      } do
        output = render_tag(markup)
        assert_equal expected_log_html, output
      end
    end

    refute_nil captured_log_args, 'PluginLoggerUtils.log_liquid_failure should have been called for util error'
    assert_equal @context, captured_log_args[:context]
    assert_equal 'RENDER_ARTICLE_CARD_TAG', captured_log_args[:tag_type]
    assert_match "Error rendering article card via ArticleCardUtils: #{error_message}", captured_log_args[:reason]
    assert_equal({ post_markup: markup, error_class: 'StandardError', error_message: error_message.slice(0, 100) },
                 captured_log_args[:identifiers])
    assert_equal :error, captured_log_args[:level]
  end
end
