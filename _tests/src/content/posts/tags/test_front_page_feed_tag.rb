# frozen_string_literal: true

# _tests/plugins/test_front_page_feed_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/tags/front_page_feed_tag'
require 'time'

# Tests for Jekyll::Posts::Tags::FrontPageFeedTag Liquid tag.
#
# Stubs FeedUtils (the data source) but lets the real Renderer run,
# stubbing only ArticleCardRenderer/BookCardRenderer as leaf dependencies.
# This tests the tag's parsing, limit resolution, empty-feed logging,
# and Renderer integration.
class TestFrontPageFeedTag < Minitest::Test
  def setup
    @site = create_site({ 'url' => 'http://example.com' })
    @site.config['plugin_logging'] ||= {}
    @site.config['plugin_logging']['FRONT_PAGE_FEED'] = true

    create_test_items
    @context = create_context(
      { 'page_limit' => 3 },
      { site: @site, page: create_doc({ 'path' => 'current_feed_page.md' }, '/current_feed_page.html') },
    )
    @silent_logger_stub = silent_logger
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

  def test_syntax_error_malformed_argument_with_valid_later
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% front_page_feed junk limit=5 %}')
    end
    assert_match 'Malformed arguments', err.message
  end

  # --- Orchestration Tests ---

  def test_renders_card_grid_with_feed_items
    stub_feed_and_cards([@post1, @book1]) do
      output = render_tag

      assert_includes output, '<div class="card-grid">'
      assert_includes output, '[article:Recent Post]'
      assert_includes output, '[book:Recent Book]'
      assert_includes output, "</div>\n"
    end
  end

  def test_passes_nil_limit_by_default
    captured_args = nil

    stub_cards do
      Jekyll::Posts::FeedUtils.stub :get_combined_feed_items,
                                    lambda { |args|
                                      captured_args = args
                                      [@post1]
                                    } do
        render_tag

        assert_nil captured_args[:limit], 'Tag should pass nil so FeedUtils reads config'
        assert_equal @site, captured_args[:site]
      end
    end
  end

  def test_passes_literal_limit
    captured_args = nil

    stub_cards do
      Jekyll::Posts::FeedUtils.stub :get_combined_feed_items,
                                    lambda { |args|
                                      captured_args = args
                                      [@post1]
                                    } do
        render_tag('limit=3')

        assert_equal 3, captured_args[:limit]
      end
    end
  end

  def test_passes_variable_limit
    captured_args = nil

    stub_cards do
      Jekyll::Posts::FeedUtils.stub :get_combined_feed_items,
                                    lambda { |args|
                                      captured_args = args
                                      [@post1]
                                    } do
        render_tag('limit=page_limit') # page_limit is 3

        assert_equal 3, captured_args[:limit]
      end
    end
  end

  def test_passes_nil_limit_for_invalid_string
    captured_args = nil

    stub_cards do
      Jekyll::Posts::FeedUtils.stub :get_combined_feed_items,
                                    lambda { |args|
                                      captured_args = args
                                      [@post1]
                                    } do
        render_tag("limit='abc'")

        assert_nil captured_args[:limit], 'Invalid limit should pass nil so FeedUtils reads config'
      end
    end
  end

  def test_passes_nil_limit_for_non_positive
    [0, -1].each do |bad_limit|
      captured_args = nil

      stub_cards do
        Jekyll::Posts::FeedUtils.stub :get_combined_feed_items,
                                      lambda { |args|
                                        captured_args = args
                                        [@post1]
                                      } do
          render_tag("limit=#{bad_limit}")

          assert_nil captured_args[:limit], "limit=#{bad_limit} should pass nil so FeedUtils reads config"
        end
      end
    end
  end

  def test_logs_info_and_renders_empty_when_feed_is_empty
    stub_cards do
      Jekyll::Posts::FeedUtils.stub :get_combined_feed_items, ->(_args) { [] } do
        Jekyll.stub :logger, @silent_logger_stub do
          output = render_tag

          assert_match(/FRONT_PAGE_FEED_FAILURE/, output)
          assert_match(/No items found for the front page feed/, output)
        end
      end
    end
  end

  def test_renders_only_posts_in_posts_only_feed
    stub_feed_and_cards([@post1]) do
      output = render_tag

      assert_includes output, '[article:Recent Post]'
      refute_includes output, '[book:'
    end
  end

  def test_renders_only_books_in_books_only_feed
    stub_feed_and_cards([@book1]) do
      output = render_tag

      assert_includes output, '[book:Recent Book]'
      refute_includes output, '[article:'
    end
  end

  # --- Markdown mode ---

  def test_markdown_mode_renders_article_card_links
    md_context = create_context(
      {},
      { site: @site, page: create_doc({ 'path' => 'index.md' }, '/index.html'), render_mode: :markdown },
    )
    output = ''
    Jekyll::Posts::FeedUtils.stub :get_combined_feed_items, ->(_args) { [@post1, @book1] } do
      Jekyll.stub :logger, @silent_logger_stub do
        output = Liquid::Template.parse('{% front_page_feed %}').render!(md_context)
      end
    end
    assert_includes output, '- [Recent Post](/post1.html)'
    assert_includes output, '- [Recent Book](/book1.html)'
    refute_match(/<div/, output)
  end

  private

  def create_test_items
    @post1 = create_doc(
      { 'title' => 'Recent Post', 'date' => Time.parse('2024-05-28 10:00:00 UTC') },
      '/post1.html',
      'content',
      nil,
      MockCollection.new(nil, 'posts'),
    )
    @book1 = create_doc(
      { 'title' => 'Recent Book', 'date' => Time.parse('2024-05-27 10:00:00 UTC') },
      '/book1.html',
      'content',
      nil,
      MockCollection.new(nil, 'books'),
    )
  end

  def stub_cards(&block)
    Jekyll::Posts::ArticleCardRenderer.stub(
      :render,
      ->(post, _context) { "[article:#{post.data['title']}]" },
    ) do
      Jekyll::Books::Core::BookCardRenderer.stub(
        :render,
        ->(book, _context) { "[book:#{book.data['title']}]" },
        &block
      )
    end
  end

  def stub_feed_and_cards(feed_items, &block)
    stub_cards do
      Jekyll::Posts::FeedUtils.stub(:get_combined_feed_items, ->(_args) { feed_items }, &block)
    end
  end
end
