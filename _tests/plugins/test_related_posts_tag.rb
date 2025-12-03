# frozen_string_literal: true

# _tests/plugins/test_related_posts_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/src/content/posts/tags/related_posts_tag'
# Components are loaded via main tag file

# Tests for RelatedPostsTag Liquid tag and its components.
#
# This test suite is organized into three sections:
# 1. Finder tests - Test data retrieval logic directly
# 2. Renderer tests - Test HTML generation directly
# 3. Tag integration tests - Test the tag orchestration
class TestRelatedPostsTag < Minitest::Test
  DEFAULT_MAX_POSTS = Jekyll::RelatedPostsTag::DEFAULT_MAX_POSTS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_POSTS' => false },
      'plugin_log_level' => 'debug'
    }
    @test_time_now = Time.parse('2024-01-15 10:00:00 EST')

    # --- Test Posts ---
    @post_curr = create_post_obj('Current Post', %w[Tech Review], 0, 'current', 'current')
    @post_review1 = create_post_obj('Review Post 1', ['Review'], 0.5, 'review1', 'review1')
    @post_tech1 = create_post_obj('Tech Post 1', ['Tech'], 1, 'tech1', 'tech1')
    @post_uncat1 = create_post_obj('Uncat Post 1', [], 2, 'uncat1', 'uncat1')
    @post_tech2 = create_post_obj('Tech Post 2', %w[Tech Gadgets], 5, 'tech2', 'tech2')
    @post_gadgets1 = create_post_obj('Gadgets Post 1', ['Gadgets'], 10, 'gadgets1', 'gadgets1')
    @post_future = create_post_obj('Future Post', ['Tech'], -5, 'future', 'future')
    @post_unpublished = create_post_obj('Unpublished', ['Tech'], 3, 'unpub', 'unpub', published: false)

    @all_posts_for_site_default = [
      @post_curr, @post_review1, @post_tech1, @post_uncat1,
      @post_tech2, @post_gadgets1, @post_future, @post_unpublished
    ]

    # --- Site and Context ---
    @site = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    @site.config['related_posts'] = []
    @context = create_context({}, { site: @site, page: @post_curr })
  end

  # Helper to create a post object
  def create_post_obj(title, cats, date_offset_days, path_suffix, url_suffix, published: true)
    create_doc(
      {
        'title' => title,
        'categories' => cats,
        'date' => @test_time_now - (60 * 60 * 24 * date_offset_days),
        'published' => published,
        'path' => "path_to_#{path_suffix}.md",
        'image' => "img_#{path_suffix}.jpg",
        'description' => "#{title} description."
      },
      "/#{url_suffix}.html"
    )
  end

  # Helper to render the tag
  def render_tag(context)
    output = ''
    Time.stub :now, @test_time_now do
      output = Liquid::Template.parse('{% related_posts %}').render!(context)
    end
    output
  end

  # ========================================================================
  # Finder Tests - Test data retrieval logic directly
  # ========================================================================

  def test_finder_returns_correct_structure
    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(@context, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_kind_of Hash, result
    assert_kind_of String, result[:logs]
    assert_kind_of Array, result[:posts]
    assert_includes [true, false], result[:found_by_category]
  end

  def test_finder_selects_by_category_and_sorts_by_date
    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(@context, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_equal true, result[:found_by_category], 'Should find by category'
    assert_equal DEFAULT_MAX_POSTS, result[:posts].length
    expected_posts = [@post_review1, @post_tech1, @post_tech2]
    assert_equal expected_posts.map(&:url), result[:posts].map(&:url)
  end

  def test_finder_uses_site_related_posts_as_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats')
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = [@post_uncat1, @post_gadgets1, @post_tech2]

    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url }
    all_posts_for_this_test << page_no_cats
    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(context_no_cats, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_equal false, result[:found_by_category], 'Should not find by category'
    assert_equal DEFAULT_MAX_POSTS, result[:posts].length
    expected_posts = [@post_uncat1, @post_tech2, @post_gadgets1]
    assert_equal expected_posts.map(&:url), result[:posts].map(&:url)
  end

  def test_finder_uses_recent_posts_as_absolute_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats')
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = []

    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url }
    all_posts_for_this_test << @post_curr unless all_posts_for_this_test.map(&:url).include?(@post_curr.url)
    all_posts_for_this_test << page_no_cats

    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(context_no_cats, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_equal false, result[:found_by_category], 'Should not find by category'
    assert_equal DEFAULT_MAX_POSTS, result[:posts].length
    expected_posts = [@post_curr, @post_review1, @post_tech1]
    assert_equal expected_posts.map(&:url), result[:posts].map(&:url)
  end

  def test_finder_excludes_current_future_and_unpublished_posts
    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(@context, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    actual_urls = result[:posts].map(&:url)
    refute_includes actual_urls, @post_curr.url, 'Current post should be excluded'
    refute_includes actual_urls, @post_future.url, 'Future post should be excluded'
    refute_includes actual_urls, @post_unpublished.url, 'Unpublished post should be excluded'
  end

  def test_finder_deduplicates_posts
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = [@post_tech1, @post_uncat1, @post_gadgets1].sort_by(&:date).reverse

    site_for_dedup_test = create_site(current_site_config, {}, [], @all_posts_for_site_default)
    context_for_dedup = create_context({}, { site: site_for_dedup_test, page: @post_curr })

    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(context_for_dedup, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_equal DEFAULT_MAX_POSTS, result[:posts].length
    expected_posts = [@post_review1, @post_tech1, @post_tech2]
    assert_equal expected_posts.map(&:url), result[:posts].map(&:url)
  end

  def test_finder_returns_empty_when_no_posts_found
    page_isolated = create_post_obj('Isolated Post', [], 0, 'iso', 'iso')
    minimal_site_config = @site_config_base.dup
    minimal_site_config['related_posts'] = []
    minimal_site = create_site(minimal_site_config, {}, [], [page_isolated])
    minimal_context = create_context({}, { site: minimal_site, page: page_isolated })

    finder = nil
    result = nil
    Time.stub :now, @test_time_now do
      finder = Jekyll::CustomRelatedPosts::Finder.new(minimal_context, DEFAULT_MAX_POSTS)
      result = finder.find
    end

    assert_empty result[:posts]
    assert_equal false, result[:found_by_category]
  end

  def test_finder_logs_error_when_prerequisites_missing
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site = create_site(config, {}, [], [])
    context = create_context({}, { site: site })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' &&
        msg.include?('RELATED_POSTS_FAILURE') &&
        msg.include?('page object')
    end

    finder = nil
    result = nil
    Jekyll.stub :logger, mock_logger do
      Time.stub :now, @test_time_now do
        finder = Jekyll::CustomRelatedPosts::Finder.new(context, DEFAULT_MAX_POSTS)
        result = finder.find
      end
    end

    assert_empty result[:posts]
    assert_match(/RELATED_POSTS_FAILURE/, result[:logs])
    mock_logger.verify
  end

  # ========================================================================
  # Renderer Tests - Test HTML generation directly
  # ========================================================================

  def test_renderer_returns_empty_string_for_empty_posts
    renderer = Jekyll::CustomRelatedPosts::Renderer.new(@context, [], false)
    output = renderer.render

    assert_equal '', output
  end

  def test_renderer_generates_correct_html_structure_related_posts
    posts = [@post_review1, @post_tech1]

    renderer = Jekyll::CustomRelatedPosts::Renderer.new(@context, posts, true)
    output = nil

    ArticleCardUtils.stub :render, ->(p, _ctx) { "<div>#{p.data['title']}</div>\n" } do
      output = renderer.render
    end

    assert_match(/^<aside class="related">/, output)
    assert_match(%r{<h2>Related Posts</h2>}, output)
    assert_match(/<div class="card-grid">/, output)
    assert_match(/#{Regexp.escape(@post_review1.data['title'])}/, output)
    assert_match(/#{Regexp.escape(@post_tech1.data['title'])}/, output)
    assert_match(%r{</aside>$}, output)
  end

  def test_renderer_generates_correct_html_structure_recent_posts
    posts = [@post_uncat1, @post_tech2]

    renderer = Jekyll::CustomRelatedPosts::Renderer.new(@context, posts, false)
    output = nil

    ArticleCardUtils.stub :render, ->(p, _ctx) { "<div>#{p.data['title']}</div>\n" } do
      output = renderer.render
    end

    assert_match(/^<aside class="related">/, output)
    assert_match(%r{<h2>Recent Posts</h2>}, output)
    assert_match(/<div class="card-grid">/, output)
    assert_match(/#{Regexp.escape(@post_uncat1.data['title'])}/, output)
    assert_match(/#{Regexp.escape(@post_tech2.data['title'])}/, output)
    assert_match(%r{</aside>$}, output)
  end

  # ========================================================================
  # Tag Integration Tests - Test orchestration
  # ========================================================================

  def test_tag_orchestrates_finder_and_renderer_correctly
    output = nil
    actual_titles_rendered = []

    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      "<div class='card'>CARD</div>\n"
    } do
      output = render_tag(@context)
    end

    refute_empty output, 'Output should not be empty'
    assert_match %r{<h2>Related Posts</h2>}, output, "Header should be 'Related Posts'"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count
    expected_titles = [@post_review1.data['title'], @post_tech1.data['title'], @post_tech2.data['title']]
    assert_equal expected_titles, actual_titles_rendered
  end

  def test_tag_returns_empty_when_no_posts_found
    page_isolated = create_post_obj('Isolated Post', [], 0, 'iso', 'iso')
    minimal_site_config = @site_config_base.dup
    minimal_site_config['related_posts'] = []
    minimal_site = create_site(minimal_site_config, {}, [], [page_isolated])
    minimal_context = create_context({}, { site: minimal_site, page: page_isolated })

    output = ''
    ArticleCardUtils.stub :render, lambda { |_p, _c|
      flunk 'ArticleCardUtils.render should not be called'
    } do
      output = render_tag(minimal_context)
    end
    assert_equal '', output.strip
  end

  def test_tag_logs_error_when_site_missing
    page_for_test = create_doc({ 'title' => 'Test Page', 'path' => 'prereq_test.md' }, '/prereq.html')
    bad_context = create_context({}, { page: page_for_test })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |p, m|
      p == 'PluginLogger:' &&
        m.include?('Context, Site, or Site Config unavailable for logging. Original Call: RELATED_POSTS')
    end

    output = ''
    Jekyll.stub :logger, mock_logger do
      ArticleCardUtils.stub :render, '<div>CARD</div>' do
        output = render_tag(bad_context)
      end
    end

    assert_equal '', output.strip
    mock_logger.verify
  end

  def test_tag_logs_error_when_page_missing
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site_for_test = create_site(config, {}, [], [])
    bad_context = create_context({}, { site: site_for_test })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' &&
        msg.include?('RELATED_POSTS_FAILURE') &&
        msg.include?('page object')
    end

    output = ''
    Jekyll.stub :logger, mock_logger do
      ArticleCardUtils.stub :render, '<div>CARD</div>' do
        output = render_tag(bad_context)
      end
    end

    assert_match(/RELATED_POSTS_FAILURE/, output)
    mock_logger.verify
  end

  def test_tag_logs_error_when_page_url_missing
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    page_no_url = create_doc({ 'title' => 'No URL', 'date' => @test_time_now, 'path' => 'no_url_page.md' }, nil)
    site_for_test = create_site(config, {}, [], [])
    context_no_url = create_context({}, { site: site_for_test, page: page_no_url })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' &&
        msg.include?('RELATED_POSTS_FAILURE') &&
        msg.include?('page') &&
        msg.include?('url') &&
        msg.include?('present and not empty')
    end

    output = ''
    Jekyll.stub :logger, mock_logger do
      ArticleCardUtils.stub :render, '<div>CARD</div>' do
        output = render_tag(context_no_url)
      end
    end

    assert_match(/RELATED_POSTS_FAILURE/, output)
    mock_logger.verify
  end
end
