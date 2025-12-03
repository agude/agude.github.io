# frozen_string_literal: true

# _tests/plugins/test_front_page_feed_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/tags/front_page_feed_tag'
require 'time'

# Tests for FrontPageFeedTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between FeedUtils and Renderer.
class TestFrontPageFeedTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {}
    @site.config['plugin_logging']['FRONT_PAGE_FEED'] = true

    create_test_items
    @context = create_context(
      { 'page_limit' => 3 },
      { site: @site, page: create_doc({ 'path' => 'current_feed_page.md' }, '/current_feed_page.html') }
    )
    @silent_logger_stub = create_silent_logger_stub
  end

  def render_tag(markup = '')
    Liquid::Template.parse("{% front_page_feed #{markup} %}").render!(@context)
  end

  # --- Syntax Error Tests ---

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% front_page_feed foo=bar %}')
    end
    assert_match "Unknown argument 'foo'", err.message
  end

  def test_syntax_error_invalid_argument_format_no_equals
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% front_page_feed not_limit_equals_val %}')
    end
    assert_match "Invalid arguments. Use 'limit=N' or no arguments.", err.message
  end

  def test_syntax_error_extra_arguments_after_limit
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% front_page_feed limit=5 extra=true %}')
    end
    assert_match "Unexpected arguments after 'limit'", err.message
  end

  # --- Orchestration Tests ---

  def test_calls_feed_utils_and_renderer_with_default_limit
    captured_feed_args = nil
    mock_feed_items = [@post1, @book1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div class="card-grid">HTML</div>'

    FeedUtils.stub :get_combined_feed_items, lambda { |args|
      captured_feed_args = args
      mock_feed_items
    } do
      Jekyll::FrontPageFeed::Renderer.stub :new, lambda { |context, items|
        assert_equal @context, context
        assert_equal mock_feed_items, items
        mock_renderer
      } do
        output = render_tag

        assert_equal '<div class="card-grid">HTML</div>', output
        assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, captured_feed_args[:limit]
        assert_equal @site, captured_feed_args[:site]
        mock_renderer.verify
      end
    end
  end

  def test_calls_feed_utils_with_specified_limit_literal
    captured_feed_args = nil
    mock_feed_items = [@post1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    FeedUtils.stub :get_combined_feed_items, lambda { |args|
      captured_feed_args = args
      mock_feed_items
    } do
      Jekyll::FrontPageFeed::Renderer.stub :new, ->(_context, _items) { mock_renderer } do
        render_tag('limit=3')

        assert_equal 3, captured_feed_args[:limit]
        mock_renderer.verify
      end
    end
  end

  def test_calls_feed_utils_with_specified_limit_variable
    captured_feed_args = nil
    mock_feed_items = [@post1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    FeedUtils.stub :get_combined_feed_items, lambda { |args|
      captured_feed_args = args
      mock_feed_items
    } do
      Jekyll::FrontPageFeed::Renderer.stub :new, ->(_context, _items) { mock_renderer } do
        render_tag('limit=page_limit') # page_limit is 3

        assert_equal 3, captured_feed_args[:limit]
        mock_renderer.verify
      end
    end
  end

  def test_uses_default_limit_if_limit_arg_is_invalid_string
    captured_feed_args = nil
    mock_feed_items = [@post1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    FeedUtils.stub :get_combined_feed_items, lambda { |args|
      captured_feed_args = args
      mock_feed_items
    } do
      Jekyll::FrontPageFeed::Renderer.stub :new, ->(_context, _items) { mock_renderer } do
        render_tag("limit='abc'")

        assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, captured_feed_args[:limit]
        mock_renderer.verify
      end
    end
  end

  def test_uses_default_limit_if_limit_arg_is_zero_or_negative
    captured_feed_args = nil
    mock_feed_items = [@post1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    FeedUtils.stub :get_combined_feed_items, lambda { |args|
      captured_feed_args = args
      mock_feed_items
    } do
      Jekyll::FrontPageFeed::Renderer.stub :new, ->(_context, _items) { mock_renderer } do
        render_tag('limit=0')
        assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, captured_feed_args[:limit]
        mock_renderer.verify
      end
    end
  end

  def test_logs_info_when_feed_utils_returns_empty_array
    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, ''

    FeedUtils.stub :get_combined_feed_items, ->(_args) { [] } do
      Jekyll::FrontPageFeed::Renderer.stub :new, lambda { |_context, items|
        assert_equal [], items
        mock_renderer
      } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = render_tag

          expected_log_pattern = /\[INFO\] FRONT_PAGE_FEED_FAILURE: Reason='No items found for the front page feed\.'/
          assert_match(expected_log_pattern, output)
          mock_renderer.verify
        end
      end
    end
  end

  def test_concatenates_log_and_renderer_output
    [@post1]

    mock_renderer = Minitest::Mock.new
    mock_renderer.expect :render, '<div>HTML</div>'

    FeedUtils.stub :get_combined_feed_items, ->(_args) { [] } do
      Jekyll::FrontPageFeed::Renderer.stub :new, ->(_context, _items) { mock_renderer } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = render_tag

          # Should have both log and HTML (even though HTML is empty for empty feed)
          assert_match(/FRONT_PAGE_FEED_FAILURE/, output)
          mock_renderer.verify
        end
      end
    end
  end

  private

  def create_test_items
    @post1 = create_doc(
      { 'title' => 'Recent Post', 'date' => Time.parse('2024-05-28 10:00:00 UTC') },
      '/post1.html',
      'content',
      nil,
      MockCollection.new(nil, 'posts')
    )
    @book1 = create_doc(
      { 'title' => 'Recent Book', 'date' => Time.parse('2024-05-27 10:00:00 UTC') },
      '/book1.html',
      'content',
      nil,
      MockCollection.new(nil, 'books')
    )
  end

  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end
end
