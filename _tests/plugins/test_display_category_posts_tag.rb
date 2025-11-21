# frozen_string_literal: true

# _tests/plugins/test_display_category_posts_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/display_category_posts_tag'

class TestDisplayCategoryPostsTag < Minitest::Test
  def setup
    @post1_tech = create_doc({ 'title' => 'Tech Post Alpha', 'categories' => ['Tech'] }, '/tech/alpha.html')
    @post2_tech = create_doc({ 'title' => 'Tech Post Beta', 'categories' => ['Tech'] }, '/tech/beta.html')

    @mock_tech_posts_data = { posts: [@post1_tech, @post2_tech], log_messages: '' }
    @mock_empty_posts_data = { posts: [], log_messages: '<!-- No posts log -->' }

    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {} # Ensure plugin_logging key exists
    @current_page_for_exclusion_test = create_doc({ 'title' => 'Current Page', 'url' => '/tech/alpha.html',
                                                    'path' => 'current.md' })
    @context = create_context(
      { 'page_category' => 'Tech', 'nil_cat' => nil, 'empty_cat_var' => '   ' },
      { site: @site, page: @current_page_for_exclusion_test }
    )
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
    @last_util_args_to_post_list = nil
  end

  def render_tag(markup, context = @context, util_return_data = @mock_tech_posts_data)
    output = ''
    PostListUtils.stub :get_posts_by_category, lambda { |args_hash|
      @last_util_args_to_post_list = args_hash
      util_return_data
    } do
      ArticleCardUtils.stub :render, ->(post, _ctx) { "<!-- Card for: #{post.data['title']} -->\n" } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = Liquid::Template.parse("{% display_category_posts #{markup} %}").render!(context)
        end
      end
    end
    output
  end

  def test_syntax_error_missing_topic
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_category_posts %}') # No topic
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

  # --- Tests for positional arguments (now expecting SyntaxError) ---
  def test_syntax_error_for_positional_topic_literal
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% display_category_posts 'Tech' %}")
    end
    expected_message = "Expected named arguments (e.g., key='value'). Found unexpected token near ''Tech''"
    assert_match expected_message, err.message
  end

  def test_syntax_error_for_positional_topic_variable
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% display_category_posts page_category %}')
    end
    expected_message = "Expected named arguments (e.g., key='value'). Found unexpected token near 'page_category'"
    assert_match expected_message, err.message
  end
  # --- End positional argument error tests ---

  def test_renders_posts_for_literal_topic
    output = render_tag("topic='Tech'")
    assert_match(/<div class="card-grid">/, output)
    assert_match(/<!-- Card for: Tech Post Alpha -->/, output)
    assert_match(/<!-- Card for: Tech Post Beta -->/, output)
    assert_equal 'Tech', @last_util_args_to_post_list[:category_name]
    assert_nil @last_util_args_to_post_list[:exclude_url]
  end

  def test_renders_posts_for_variable_topic
    output = render_tag('topic=page_category')
    assert_match(/<div class="card-grid">/, output)
    assert_match(/<!-- Card for: Tech Post Alpha -->/, output)
    assert_equal 'Tech', @last_util_args_to_post_list[:category_name]
  end

  def test_exclude_current_page_true
    render_tag("topic='Tech' exclude_current_page=true")
    assert_equal @current_page_for_exclusion_test.url, @last_util_args_to_post_list[:exclude_url]
  end

  def test_exclude_current_page_false
    render_tag("topic='Tech' exclude_current_page=false")
    assert_nil @last_util_args_to_post_list[:exclude_url]
  end

  def test_exclude_current_page_variable_true
    @context['do_exclude'] = true
    render_tag("topic='Tech' exclude_current_page=do_exclude")
    assert_equal @current_page_for_exclusion_test.url, @last_util_args_to_post_list[:exclude_url]
  end

  def test_exclude_current_page_variable_string_true
    @context['do_exclude_str'] = 'true'
    render_tag("topic='Tech' exclude_current_page=do_exclude_str")
    assert_equal @current_page_for_exclusion_test.url, @last_util_args_to_post_list[:exclude_url]
  end

  def test_exclude_current_page_default_is_false
    render_tag("topic='Tech'") # exclude_current_page is not provided
    assert_nil @last_util_args_to_post_list[:exclude_url]
  end

  def test_logs_error_if_topic_resolves_to_empty_string_literal
    @site.config['plugin_logging']['DISPLAY_CATEGORY_POSTS'] = true
    output = render_tag("topic='   '") # Topic resolves to empty string after strip
    expected_log_pattern = /<!-- \[ERROR\] DISPLAY_CATEGORY_POSTS_FAILURE: Reason='Argument &#39;topic&#39; resolved to an empty string\.'\s*topic_markup='&#39;   &#39;'\s*SourcePage='current\.md' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<div class="card-grid">/, output)
  end

  def test_logs_error_if_topic_resolves_to_empty_from_variable
    @site.config['plugin_logging']['DISPLAY_CATEGORY_POSTS'] = true
    output = render_tag('topic=empty_cat_var') # empty_cat_var is "   "
    expected_log_pattern = /<!-- \[ERROR\] DISPLAY_CATEGORY_POSTS_FAILURE: Reason='Argument &#39;topic&#39; resolved to an empty string\.'\s*topic_markup='empty_cat_var'\s*SourcePage='current\.md' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<div class="card-grid">/, output)
  end

  def test_logs_error_if_topic_resolves_to_nil_from_variable
    @site.config['plugin_logging']['DISPLAY_CATEGORY_POSTS'] = true
    output = render_tag('topic=nil_cat')
    expected_log_pattern = /<!-- \[ERROR\] DISPLAY_CATEGORY_POSTS_FAILURE: Reason='Argument &#39;topic&#39; resolved to an empty string\.'\s*topic_markup='nil_cat'\s*SourcePage='current\.md' -->/
    assert_match(expected_log_pattern, output)
    refute_match(/<div class="card-grid">/, output)
  end

  def test_outputs_log_messages_from_util_if_no_posts
    output = render_tag("topic='NoPostsCategory'", @context, @mock_empty_posts_data)
    assert_match(/<!-- No posts log -->/, output)
    refute_match(/<div class="card-grid">/, output)
  end
end
