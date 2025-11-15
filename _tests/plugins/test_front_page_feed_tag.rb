# _tests/plugins/test_front_page_feed_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/front_page_feed_tag'
require 'time'

class TestFrontPageFeedTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {}
    @site.config['plugin_logging']['FRONT_PAGE_FEED'] = true # Enable logging for this tag for tests

    # Mock items - ensure they have data, url, collection.label, and date
    # Dates are crucial for FeedUtils sorting
    @post1 = create_doc({ 'title' => 'Recent Post', 'date' => Time.parse('2024-05-28 10:00:00 UTC') }, '/post1.html',
                        'content', nil, MockCollection.new(nil, 'posts'))
    @book1 = create_doc({ 'title' => 'Recent Book', 'date' => Time.parse('2024-05-27 10:00:00 UTC') }, '/book1.html',
                        'content', nil, MockCollection.new(nil, 'books'))
    @post2 = create_doc({ 'title' => 'Older Post', 'date' => Time.parse('2024-05-26 10:00:00 UTC') }, '/post2.html',
                        'content', nil, MockCollection.new(nil, 'posts'))
    @book2 = create_doc({ 'title' => 'Older Book', 'date' => Time.parse('2024-05-20 10:00:00 UTC') }, '/book2.html',
                        'content', nil, MockCollection.new(nil, 'books'))
    @post3 = create_doc({ 'title' => 'Very Old Post', 'date' => Time.parse('2024-05-15 10:00:00 UTC') }, '/post3.html',
                        'content', nil, MockCollection.new(nil, 'posts'))
    @book3_oldest = create_doc({ 'title' => 'Very Old Book', 'date' => Time.parse('2024-05-10 10:00:00 UTC') },
                               '/book3.html', 'content', nil, MockCollection.new(nil, 'books'))

    @mock_feed_items_default_limit = [@post1, @book1, @post2, @book2, @post3] # Top 5
    @mock_feed_items_limit_3 = [@post1, @book1, @post2] # Top 3

    @context = create_context(
      { 'page_limit' => 3 },
      { site: @site, page: create_doc({ 'path' => 'current_feed_page.md' }, '/current_feed_page.html') }
    )
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
    @last_feed_util_args = nil # To capture args passed to FeedUtils
  end

  # Helper to render the tag, stubs FeedUtils and card rendering utils.
  def render_tag(markup = '', context = @context, feed_util_return_data = @mock_feed_items_default_limit)
    output = ''
    # Stub FeedUtils.get_combined_feed_items to control its output and capture args
    FeedUtils.stub :get_combined_feed_items, lambda { |args_hash|
      @last_feed_util_args = args_hash
      feed_util_return_data # Return the pre-defined data for the test
    } do
      # Stub card rendering utils to return simple identifiable strings
      ArticleCardUtils.stub :render, ->(item, _ctx) { "<!-- ArticleCard for: #{item.data['title']} -->\n" } do
        BookCardUtils.stub :render, ->(item, _ctx) { "<!-- BookCard for: #{item.data['title']} -->\n" } do
          Jekyll.stub :logger, @silent_logger_stub do # Suppress console output from PluginLoggerUtils
            output = Liquid::Template.parse("{% front_page_feed #{markup} %}").render!(context)
          end
        end
      end
    end
    output
  end

  def test_renders_feed_with_default_limit
    output = render_tag # No limit argument, FeedUtils stub returns @mock_feed_items_default_limit

    assert_match(/<div class="card-grid">/, output)
    assert_match(/<!-- ArticleCard for: Recent Post -->/, output)
    assert_match(/<!-- BookCard for: Recent Book -->/, output)
    assert_match(/<!-- ArticleCard for: Older Post -->/, output)
    assert_match(/<!-- BookCard for: Older Book -->/, output)
    assert_match(/<!-- ArticleCard for: Very Old Post -->/, output)
    refute_match(/Very Old Book/, output) # Should be excluded by default limit of 5

    refute_nil @last_feed_util_args, 'FeedUtils.get_combined_feed_items should have been called'
    assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, @last_feed_util_args[:limit]
    assert_equal @site, @last_feed_util_args[:site]
  end

  def test_renders_feed_with_specified_limit_literal
    output = render_tag('limit=3', @context, @mock_feed_items_limit_3) # Pass data for limit 3

    assert_match(/<!-- ArticleCard for: Recent Post -->/, output)
    assert_match(/<!-- BookCard for: Recent Book -->/, output)
    assert_match(/<!-- ArticleCard for: Older Post -->/, output)
    refute_match(/Older Book/, output)
    refute_match(/Very Old Post/, output)

    refute_nil @last_feed_util_args
    assert_equal 3, @last_feed_util_args[:limit]
  end

  def test_renders_feed_with_specified_limit_variable
    render_tag('limit=page_limit', @context, @mock_feed_items_limit_3) # page_limit is 3
    refute_nil @last_feed_util_args
    assert_equal 3, @last_feed_util_args[:limit]
  end

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

  def test_handles_empty_feed_items_with_log
    output = render_tag('', @context, []) # FeedUtils returns empty array

    assert_match(/<!-- \[INFO\] FRONT_PAGE_FEED_FAILURE: Reason='No items found for the front page feed\.'\s*limit='#{Jekyll::FrontPageFeedTag::DEFAULT_LIMIT}'.*SourcePage='current_feed_page\.md' -->/,
                 output)
    refute_match(/<div class="card-grid">/, output)
  end

  def test_handles_unrecognized_item_type_with_log
    unknown_item = create_doc({ 'title' => 'Unknown Item', 'date' => Time.now }, '/unknown.html', 'content', nil,
                              MockCollection.new(nil, 'unknown_collection_label'))
    output = render_tag('', @context, [unknown_item]) # FeedUtils returns this one unknown item

    assert_match(/<div class="card-grid">/, output) # Grid is still created
    assert_match %r{<!-- \[WARN\] FRONT_PAGE_FEED_FAILURE: Reason='Unknown item type in feed\.'\s*item_title='Unknown Item'\s*item_url='/unknown\.html'\s*item_collection='unknown_collection_label'\s*SourcePage='current_feed_page\.md' -->},
                 output
    refute_match(/<!-- ArticleCard for: Unknown Item -->/, output)
    refute_match(/<!-- BookCard for: Unknown Item -->/, output)
    assert_match %r{</div>}, output # Grid is closed
  end

  def test_uses_default_limit_if_limit_arg_is_invalid_string
    render_tag("limit='abc'", @context, @mock_feed_items_default_limit) # Invalid limit value
    refute_nil @last_feed_util_args
    assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, @last_feed_util_args[:limit]
  end

  def test_uses_default_limit_if_limit_arg_is_zero_or_negative
    render_tag('limit=0', @context, @mock_feed_items_default_limit)
    refute_nil @last_feed_util_args
    assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, @last_feed_util_args[:limit]

    render_tag('limit=-5', @context, @mock_feed_items_default_limit)
    refute_nil @last_feed_util_args
    assert_equal Jekyll::FrontPageFeedTag::DEFAULT_LIMIT, @last_feed_util_args[:limit]
  end
end
