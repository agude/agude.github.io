# frozen_string_literal: true

# _tests/plugins/logic/front_page_feed/test_renderer.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/feed/renderer'

# Tests for Jekyll::Posts::Feed::FrontPageFeed::Renderer.
#
# Verifies that the Renderer correctly generates HTML structure and handles different item types.
class TestFrontPageFeedRenderer < Minitest::Test
  def setup
    @context = create_context({}, { page: create_doc({ 'path' => 'test.md' }, '/test.html') })
    @post = create_doc(
      { 'title' => 'Test Post' },
      '/post.html',
      'content',
      nil,
      MockCollection.new(nil, 'posts')
    )
    @book = create_doc(
      { 'title' => 'Test Book' },
      '/book.html',
      'content',
      nil,
      MockCollection.new(nil, 'books')
    )
    @unknown_item = create_doc(
      { 'title' => 'Unknown Item' },
      '/unknown.html',
      'content',
      nil,
      MockCollection.new(nil, 'unknown')
    )
  end

  def test_returns_empty_string_when_feed_items_empty
    renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [])
    output = renderer.render

    assert_equal '', output
  end

  def test_generates_correct_html_structure
    Jekyll::Posts::ArticleCardUtils.stub :render, ->(_item, _ctx) { '<div>Article Card</div>' } do
      renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@post])
      output = renderer.render

      assert_match(/<div class="card-grid">/, output)
      assert_match(%r{</div>}, output)
    end
  end

  def test_calls_article_card_utils_for_posts
    captured_args = []
    Jekyll::Posts::ArticleCardUtils.stub :render, lambda { |item, ctx|
      captured_args << { item: item, ctx: ctx }
      '<div>Article Card</div>'
    } do
      renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@post])
      renderer.render

      assert_equal 1, captured_args.length
      assert_equal @post, captured_args[0][:item]
      assert_equal @context, captured_args[0][:ctx]
    end
  end

  def test_calls_book_card_utils_for_books
    captured_args = []
    Jekyll::Books::Core::BookCardUtils.stub :render, lambda { |item, ctx|
      captured_args << { item: item, ctx: ctx }
      '<div>Book Card</div>'
    } do
      renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@book])
      renderer.render

      assert_equal 1, captured_args.length
      assert_equal @book, captured_args[0][:item]
      assert_equal @context, captured_args[0][:ctx]
    end
  end

  def test_renders_mixed_posts_and_books_in_order
    Jekyll::Posts::ArticleCardUtils.stub :render, lambda { |item, _ctx|
      "<div>Article: #{item.data['title']}</div>"
    } do
      Jekyll::Books::Core::BookCardUtils.stub :render, lambda { |item, _ctx|
        "<div>Book: #{item.data['title']}</div>"
      } do
        renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@post, @book])
        output = renderer.render

        # Verify both are present
        assert_match(/Article: Test Post/, output)
        assert_match(/Book: Test Book/, output)

        # Verify order
        post_idx = output.index('Test Post')
        book_idx = output.index('Test Book')
        assert post_idx < book_idx, 'Post should appear before Book'
      end
    end
  end

  def test_logs_warning_for_unknown_item_type
    @context.registers[:site] = create_site
    @context.registers[:site].config['plugin_logging'] ||= {}
    @context.registers[:site].config['plugin_logging']['FRONT_PAGE_FEED'] = true

    silent_logger = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end

    Jekyll.stub :logger, silent_logger do
      renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@unknown_item])
      output = renderer.render

      # Should still create the grid
      assert_match(/<div class="card-grid">/, output)

      # Should contain warning log
      assert_match(/\[WARN\] FRONT_PAGE_FEED_FAILURE/, output)
      assert_match(/Unknown item type in feed/, output)
      assert_match(/Unknown Item/, output)
    end
  end

  def test_wraps_all_items_in_single_card_grid
    Jekyll::Posts::ArticleCardUtils.stub :render, ->(_item, _ctx) { '<div>Card</div>' } do
      Jekyll::Books::Core::BookCardUtils.stub :render, ->(_item, _ctx) { '<div>Card</div>' } do
        renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@post, @book])
        output = renderer.render

        # Count occurrences of card-grid opening
        opening_count = output.scan('<div class="card-grid">').length
        assert_equal 1, opening_count, 'Should have exactly one card-grid opening tag'
      end
    end
  end

  def test_log_output_appears_before_html_output
    @context.registers[:site] = create_site
    @context.registers[:site].config['plugin_logging'] ||= {}
    @context.registers[:site].config['plugin_logging']['FRONT_PAGE_FEED'] = true

    silent_logger = Object.new.tap do |logger|
      def logger.warn(topic, message); end
    end

    Jekyll::Posts::ArticleCardUtils.stub :render, ->(_item, _ctx) { '<div>Article</div>' } do
      Jekyll.stub :logger, silent_logger do
        renderer = Jekyll::Posts::Feed::FrontPageFeed::Renderer.new(@context, [@unknown_item, @post])
        output = renderer.render

        # Find positions of log and HTML
        log_idx = output.index('FRONT_PAGE_FEED_FAILURE')
        grid_idx = output.index('<div class="card-grid">')

        assert log_idx < grid_idx, 'Log output should appear before HTML grid'
      end
    end
  end
end
