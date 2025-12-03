# frozen_string_literal: true

# _tests/plugins/test_display_category_posts_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/tags/display_category_posts_tag'

# Tests for DisplayCategoryPostsTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between PostListUtils and Renderer.
class TestDisplayCategoryPostsTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {}
    @current_page = create_doc({ 'title' => 'Current Page', 'url' => '/tech/alpha.html',
                                 'path' => 'current.md' })
    @context = create_context(
      { 'page_category' => 'Tech', 'nil_cat' => nil, 'empty_cat_var' => '   ' },
      { site: @site, page: @current_page }
    )
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  def render_tag(markup, context = @context)
    Liquid::Template.parse("{% display_category_posts #{markup} %}").render!(context)
  end

  # --- Syntax Error Tests ---

  def test_syntax_error_missing_topic
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_category_posts %}')
    end
    assert_match "Required argument 'topic' is missing", err.message
  end

  def test_syntax_error_invalid_arguments_non_named
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_category_posts topic='Tech' some_bare_word %}")
    end
    expected_message = "Expected named arguments (e.g., key='value'). Found unexpected token near 'some_bare_word'"
    assert_match expected_message, err.message
  end

  def test_syntax_error_unknown_named_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_category_posts topic='Tech' badkey=arg %}")
    end
    assert_match "Unknown argument 'badkey'", err.message
  end

  def test_syntax_error_duplicate_named_argument
    # Tests line 88-90: duplicate argument detection
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_category_posts topic='Tech' topic='Science' %}")
    end
    assert_match "Duplicate argument 'topic'", err.message
  end

  def test_syntax_error_for_positional_topic_literal
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_category_posts 'Tech' %}")
    end
    expected_message = "Expected named arguments (e.g., key='value'). Found unexpected token near ''Tech''"
    assert_match expected_message, err.message
  end

  # --- Orchestration Tests ---

  def test_calls_post_list_utils_and_renderer_with_literal_topic
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '' }
    captured_util_args = nil

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div class="card-grid">HTML</div>'

    PostListUtils.stub :get_posts_by_category, lambda { |args|
      captured_util_args = args
      mock_result
    } do
      Jekyll::CategoryPosts::Renderer.stub :new, lambda { |context, posts|
        assert_equal @context, context
        assert_equal [mock_post], posts
        mock_renderer
      } do
        output = render_tag("topic='Tech'")

        assert_equal '<div class="card-grid">HTML</div>', output
        assert_equal 'Tech', captured_util_args[:category_name]
        assert_nil captured_util_args[:exclude_url]
        mock_renderer.verify
      end
    end
  end

  def test_calls_post_list_utils_and_renderer_with_variable_topic
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '' }
    captured_util_args = nil

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    PostListUtils.stub :get_posts_by_category, lambda { |args|
      captured_util_args = args
      mock_result
    } do
      Jekyll::CategoryPosts::Renderer.stub :new, ->(_context, _posts) { mock_renderer } do
        output = render_tag('topic=page_category')

        assert_includes output, '<div>HTML</div>'
        assert_equal 'Tech', captured_util_args[:category_name]
        mock_renderer.verify
      end
    end
  end

  def test_passes_exclude_url_when_exclude_current_page_true
    mock_result = { posts: [], log_messages: '' }
    captured_util_args = nil

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, ''

    PostListUtils.stub :get_posts_by_category, lambda { |args|
      captured_util_args = args
      mock_result
    } do
      Jekyll::CategoryPosts::Renderer.stub :new, ->(_context, _posts) { mock_renderer } do
        render_tag("topic='Tech' exclude_current_page=true")

        assert_equal @current_page.url, captured_util_args[:exclude_url]
        mock_renderer.verify
      end
    end
  end

  def test_passes_nil_exclude_url_when_exclude_current_page_false
    mock_result = { posts: [], log_messages: '' }
    captured_util_args = nil

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, ''

    PostListUtils.stub :get_posts_by_category, lambda { |args|
      captured_util_args = args
      mock_result
    } do
      Jekyll::CategoryPosts::Renderer.stub :new, ->(_context, _posts) { mock_renderer } do
        render_tag("topic='Tech' exclude_current_page=false")

        assert_nil captured_util_args[:exclude_url]
        mock_renderer.verify
      end
    end
  end

  def test_concatenates_log_messages_and_html_output
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '<!-- Debug log -->' }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    PostListUtils.stub :get_posts_by_category, ->(_args) { mock_result } do
      Jekyll::CategoryPosts::Renderer.stub :new, ->(_context, _posts) { mock_renderer } do
        output = render_tag("topic='Tech'")

        assert_equal '<!-- Debug log --><div>HTML</div>', output
        mock_renderer.verify
      end
    end
  end

  def test_returns_empty_string_from_renderer_when_no_posts
    mock_result = { posts: [], log_messages: '<!-- No posts -->' }

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, ''

    PostListUtils.stub :get_posts_by_category, ->(_args) { mock_result } do
      Jekyll::CategoryPosts::Renderer.stub :new, ->(_context, _posts) { mock_renderer } do
        output = render_tag("topic='Tech'")

        assert_equal '<!-- No posts -->', output
        mock_renderer.verify
      end
    end
  end

  def test_logs_error_if_topic_resolves_to_empty_string
    @site.config['plugin_logging']['DISPLAY_CATEGORY_POSTS'] = true

    Jekyll.stub :logger, @silent_logger_stub do
      output = render_tag("topic='   '")

      expected_log_pattern = /<!-- \[ERROR\] DISPLAY_CATEGORY_POSTS_FAILURE: Reason='Argument &#39;topic&#39; resolved to an empty string\.'/
      assert_match(expected_log_pattern, output)
      refute_match(/<div class="card-grid">/, output)
    end
  end

  def test_logs_error_if_topic_resolves_to_nil_from_variable
    @site.config['plugin_logging']['DISPLAY_CATEGORY_POSTS'] = true

    Jekyll.stub :logger, @silent_logger_stub do
      output = render_tag('topic=nil_cat')

      expected_log_pattern = /<!-- \[ERROR\] DISPLAY_CATEGORY_POSTS_FAILURE: Reason='Argument &#39;topic&#39; resolved to an empty string\.'/
      assert_match(expected_log_pattern, output)
      refute_match(/<div class="card-grid">/, output)
    end
  end
end
