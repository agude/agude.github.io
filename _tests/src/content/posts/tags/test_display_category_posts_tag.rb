# frozen_string_literal: true

# _tests/plugins/test_display_category_posts_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/tags/display_category_posts_tag'

# Tests for Jekyll::Posts::Tags::DisplayCategoryPostsTag Liquid tag.
#
# Stubs PostListUtils (the data source) but lets the real Renderer run,
# stubbing only ArticleCardRenderer.render as the leaf dependency.
# This tests the tag's parsing, variable resolution, exclude logic,
# DisplayTagRenderable branching, and Renderer integration.
class TestDisplayCategoryPostsTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {}
    @current_page = create_doc(
      {
        'title' => 'Current Page',
        'url' => '/tech/alpha.html',
        'path' => 'current.md',
      },
    )
    @context = create_context(
      { 'page_category' => 'Tech', 'nil_cat' => nil, 'empty_cat_var' => '   ' },
      { site: @site, page: @current_page },
    )
    @silent_logger_stub = silent_logger
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

  def test_resolves_literal_topic_and_renders_card_grid
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '' }

    stub_data_and_cards(mock_result) do
      output = render_tag("topic='Tech'")

      assert_includes output, '<div class="card-grid">'
      assert_includes output, '[card:Tech Post]'
      assert_includes output, "</div>\n"
    end
  end

  def test_resolves_variable_topic
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')

    stub_data_capturing_args(posts: [mock_post], log_messages: '') do |captured_args|
      render_tag('topic=page_category')

      assert_equal 'Tech', captured_args[:category_name]
    end
  end

  def test_passes_exclude_url_when_exclude_current_page_true
    stub_data_capturing_args do |captured_args|
      render_tag("topic='Tech' exclude_current_page=true")

      assert_equal @current_page.url, captured_args[:exclude_url]
    end
  end

  def test_passes_nil_exclude_url_when_exclude_current_page_false
    stub_data_capturing_args do |captured_args|
      render_tag("topic='Tech' exclude_current_page=false")

      assert_nil captured_args[:exclude_url]
    end
  end

  def test_prepends_log_messages_to_html_output
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '<!-- Debug log -->' }

    stub_data_and_cards(mock_result) do
      output = render_tag("topic='Tech'")

      assert output.start_with?('<!-- Debug log -->'), 'Log messages should precede card HTML'
      assert_includes output, '<div class="card-grid">'
    end
  end

  def test_empty_posts_returns_empty_renderer_output
    mock_result = { posts: [], log_messages: '<!-- No posts -->' }

    stub_data_and_cards(mock_result) do
      output = render_tag("topic='Tech'")

      assert_equal '<!-- No posts -->', output
      refute_includes output, '<div class="card-grid">'
    end
  end

  def test_multiple_posts_renders_all_cards
    posts = [
      create_doc({ 'title' => 'Post A' }, '/tech/a.html'),
      create_doc({ 'title' => 'Post B' }, '/tech/b.html'),
      create_doc({ 'title' => 'Post C' }, '/tech/c.html'),
    ]
    mock_result = { posts: posts, log_messages: '' }

    stub_data_and_cards(mock_result) do
      output = render_tag("topic='Tech'")

      assert_includes output, '[card:Post A]'
      assert_includes output, '[card:Post B]'
      assert_includes output, '[card:Post C]'
    end
  end

  # --- Markdown mode ---

  def test_markdown_mode_renders_article_card_links
    mock_post = create_doc({ 'title' => 'Tech Post' }, '/tech/post.html')
    mock_result = { posts: [mock_post], log_messages: '' }

    md_context = create_context(
      {},
      { site: @site, page: @current_page, render_mode: :markdown },
    )
    Jekyll::Posts::PostListUtils.stub :get_posts_by_category, ->(_args) { mock_result } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse("{% display_category_posts topic='Tech' %}").render!(md_context)
        assert_includes output, '- [Tech Post](/tech/post.html)'
        refute_match(/<div/, output)
      end
    end
  end

  # --- Error logging ---

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

  private

  def stub_cards(&)
    Jekyll::Posts::ArticleCardRenderer.stub(
      :render,
      ->(post, _context) { "[card:#{post.data['title']}]" },
      &
    )
  end

  def stub_data_and_cards(mock_result, &block)
    stub_cards do
      Jekyll::Posts::PostListUtils.stub(:get_posts_by_category, ->(_args) { mock_result }, &block)
    end
  end

  def stub_data_capturing_args(mock_result = { posts: [], log_messages: '' })
    captured = {}
    stub_cards do
      Jekyll::Posts::PostListUtils.stub :get_posts_by_category,
                                        lambda { |args|
                                          captured.merge!(args)
                                          mock_result
                                        } do
        yield captured
      end
    end
  end
end
