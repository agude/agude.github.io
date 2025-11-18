# frozen_string_literal: true
# _tests/plugins/test_related_posts_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_posts_tag'

class TestRelatedPostsTag < Minitest::Test
  DEFAULT_MAX_POSTS = Jekyll::RelatedPostsTag::DEFAULT_MAX_POSTS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_POSTS' => true }, # Enable logging for this tag
      'plugin_log_level' => 'debug' # Set console log level for tests
    }
    @test_time_now = Time.parse('2024-01-15 10:00:00 EST') # Fixed time for consistent date calculations

    # Helper to create mock post objects (Jekyll::Document mocks)
    def create_post_obj(title, cats, date_offset_days, path_suffix, url_suffix, published = true)
      create_doc(
        {
          'title' => title, 'categories' => cats,
          'date' => @test_time_now - (60 * 60 * 24 * date_offset_days), # Calculate date relative to @test_time_now
          'published' => published, 'path' => "path_to_#{path_suffix}.md",
          'image' => "img_#{path_suffix}.jpg", 'description' => "#{title} description."
        },
        "/#{url_suffix}.html"
      )
    end

    # --- Test Data Setup ---
    @post_curr = create_post_obj('Current Post', %w[Tech Review], 0, 'current', 'current')
    @post_review1 = create_post_obj('Review Post 1 (Very Recent)', ['Review'], 0.5, 'review1', 'review1')
    @post_tech1   = create_post_obj('Tech Post 1 (Recent)',        ['Tech'],   1,   'tech1', 'tech1')
    @post_uncat1  = create_post_obj('Uncat Post 1 (Recentish)', [], 2, 'uncat1', 'uncat1')
    @post_tech2   = create_post_obj('Tech Post 2 (Older)', %w[Tech Gadgets], 5, 'tech2', 'tech2')
    @post_gadgets1 = create_post_obj('Gadgets Post 1 (Oldest)', ['Gadgets'], 10, 'gadgets1', 'gadgets1')
    @post_future      = create_post_obj('Future Post',      ['Tech'], -5,  'future', 'future') # Date in the future
    @post_unpublished = create_post_obj('Unpublished Post', ['Tech'], 3,   'unpub', 'unpub', false) # Not published

    @all_posts_for_site_default = [
      @post_curr, @post_review1, @post_tech1, @post_uncat1,
      @post_tech2, @post_gadgets1, @post_future, @post_unpublished
    ]

    @site = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    @site.config['related_posts'] = [] # Default to no manually specified related posts

    @context = create_context({}, { site: @site, page: @post_curr })

    @mock_article_card_html_simple = "<div class='mock-card'>CARD</div>\n" # Simple stub for ArticleCardUtils.render
    # Silent logger stub for tests not focusing on logger output details
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Helper to render the tag with controlled time and logger
  def render_tag(context = @context, logger_override = @silent_logger_stub)
    output = ''
    Time.stub :now, @test_time_now do # Stub Time.now for consistent "now_unix" in tag
      Jekyll.stub :logger, logger_override do # Stub Jekyll.logger for testing console output
        output = Liquid::Template.parse('{% related_posts %}').render!(context)
      end
    end
    output
  end

  # --- Prerequisite Logging Tests ---
  # These tests verify that the tag logs errors correctly when essential context is missing.

  def test_logs_error_if_site_missing
    page_for_test = create_doc({ 'title' => 'Test Page', 'path' => 'prereq_test.md' }, '/prereq.html')
    bad_context = create_context({}, { page: page_for_test }) # Context without a site
    mock_jekyll_logger = Minitest::Mock.new
    # Expect PluginLoggerUtils's internal error message when site config is inaccessible
    mock_jekyll_logger.expect(:error, nil) do |p, m|
      p == 'PluginLogger:' && m.include?('Context, Site, or Site Config unavailable for logging. Original Call: RELATED_POSTS')
    end

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(bad_context, mock_jekyll_logger)
    end
    assert_equal '', output.strip, 'Output should be empty on prerequisite failure'
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_page_missing
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true # Ensure logging for this tag type is on
    bad_context = create_context({}, { site: site_for_test }) # Context without a page

    mock_jekyll_logger = Minitest::Mock.new
    expected_console_prefix = 'PluginLiquid:'
    # Reason string includes HTML escaped single quotes for 'page['url']'
    expected_console_message_body = "[ERROR] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page object, page[&#39;url&#39;] (cannot check, site or page missing).' PageURL='N/A' SourcePage='unknown_page'"

    mock_jekyll_logger.expect(:error, nil) do |prefix_arg, message_arg|
      prefix_arg == expected_console_prefix && message_arg == expected_console_message_body
    end

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(bad_context, mock_jekyll_logger)
    end

    # Verify HTML comment output (since environment is 'test', not 'production')
    assert_match %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page object, page\[&#39;url&#39;\] \(cannot check, site or page missing\)\.' PageURL='N/A' SourcePage='unknown_page' -->},
                 output
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_site_posts_docs_not_array
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true
    page_for_context = @post_curr
    context_for_test = create_context({}, { site: site_for_test, page: page_for_context })

    site_for_test.posts.docs = 'not_an_array' # Intentionally break site.posts.docs

    mock_jekyll_logger = Minitest::Mock.new
    mock_jekyll_logger.expect(:error, nil) do |_p, m|
      m.include?('Missing prerequisites: site.posts.docs (site.posts.docs is String, not Array)')
    end

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(context_for_test, mock_jekyll_logger)
    end

    assert_match %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: site\.posts\.docs \(site\.posts\.docs is String, not Array\)\.' PageURL='/current\.html' SourcePage='path_to_current\.md' -->},
                 output
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL', 'date' => @test_time_now, 'path' => 'no_url_page.md' }, nil) # Page with nil URL
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true
    context_no_url = create_context({}, { site: site_for_test, page: page_no_url })

    mock_jekyll_logger = Minitest::Mock.new
    mock_jekyll_logger.expect(:error, nil) do |_p, m|
      m.include?('Missing prerequisites: page[&#39;url&#39;] (present and not empty)')
    end

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(context_no_url, mock_jekyll_logger)
    end
    assert_match %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page\[&#39;url&#39;\] \(present and not empty\)\.' PageURL='N/A' SourcePage='no_url_page\.md' -->},
                 output
    mock_jekyll_logger.verify
  end

  # --- Selection Logic Tests ---
  # These tests verify the core logic of selecting and ordering related posts.

  def test_selects_by_category_first_and_sorts_by_date
    actual_titles_rendered = []
    output = ''
    # Expected: @post_review1 (Review, offset 0.5), @post_tech1 (Tech, offset 1), @post_tech2 (Tech, offset 5)
    # @post_curr has categories 'Tech', 'Review'.
    expected_titles_in_order = [@post_review1.data['title'], @post_tech1.data['title'], @post_tech2.data['title']]

    site_for_test = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    site_for_test.config['related_posts'] = [] # No manual overrides
    context_for_test = create_context({}, { site: site_for_test, page: @post_curr })

    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context_for_test)
    end

    assert_match %r{<h2>Related Posts</h2>}, output, "Header should be 'Related Posts' when categories match"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Should render default max posts'
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Posts not in correct order by category and date'
  end

  def test_uses_site_related_posts_as_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats') # Current page has no categories
    current_site_config = @site_config_base.dup
    # Manually specified related posts, should be sorted by date by the tag if used
    current_site_config['related_posts'] = [@post_uncat1, @post_gadgets1, @post_tech2] # Dates: uncat1 (2), tech2 (5), gadgets1 (10)

    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url } << page_no_cats
    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    actual_titles_rendered = []
    output = ''
    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context_no_cats)
    end

    assert_match %r{<h2>Recent Posts</h2>}, output, "Header should be 'Recent Posts' (no category match, fallback)"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Card count mismatch'
    # Expected order from site.config['related_posts'], sorted by date: uncat1, tech2, gadgets1
    expected_titles_in_order = [@post_uncat1.data['title'], @post_tech2.data['title'], @post_gadgets1.data['title']]
    assert_equal expected_titles_in_order, actual_titles_rendered,
                 "Post order mismatch from site.config['related_posts']"
  end

  def test_uses_recent_posts_as_absolute_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats') # Current page, no categories
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = [] # No manual related posts

    # Setup site posts for this specific test scenario
    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url }
    all_posts_for_this_test << @post_curr unless all_posts_for_this_test.map(&:url).include?(@post_curr.url)
    all_posts_for_this_test << page_no_cats

    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    actual_titles_rendered = []
    output = ''
    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context_no_cats)
    end

    assert_match %r{<h2>Recent Posts</h2>}, output, "Header should be 'Recent Posts' (absolute fallback)"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Card count mismatch'
    # Expected: Most recent posts excluding 'page_no_cats'.
    # @post_curr (offset 0), @post_review1 (offset 0.5), @post_tech1 (offset 1)
    expected_titles_in_order = [@post_curr.data['title'], @post_review1.data['title'], @post_tech1.data['title']]
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Post order mismatch for recent posts fallback'
  end

  def test_excludes_current_future_and_unpublished_posts
    actual_titles_rendered = []
    output = ''
    site_for_test = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    context_for_test = create_context({}, { site: site_for_test, page: @post_curr }) # @post_curr is the current page

    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context_for_test)
    end

    assert_match %r{<h2>Related Posts</h2>}, output # @post_curr has categories
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count
    # Expected posts are by category, excluding current, future, unpublished
    expected_titles_in_order = [@post_review1.data['title'], @post_tech1.data['title'], @post_tech2.data['title']]
    assert_equal expected_titles_in_order, actual_titles_rendered

    # Explicitly check exclusions
    refute_includes actual_titles_rendered, @post_curr.data['title'], 'Current post should be excluded'
    refute_includes actual_titles_rendered, @post_future.data['title'], 'Future post should be excluded'
    refute_includes actual_titles_rendered, @post_unpublished.data['title'], 'Unpublished post should be excluded'
  end

  def test_deduplicates_posts
    current_site_config = @site_config_base.dup
    # @post_tech1 is shared with category matches for @post_curr.
    # Order of related_posts_from_config: tech1 (1), uncat1 (2), gadgets1 (10)
    current_site_config['related_posts'] = [@post_tech1, @post_uncat1, @post_gadgets1].sort_by(&:date).reverse

    site_for_dedup_test = create_site(current_site_config, {}, [], @all_posts_for_site_default)
    context_for_dedup = create_context({}, { site: site_for_dedup_test, page: @post_curr })

    actual_titles_rendered = []
    output = ''
    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      actual_titles_rendered << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context_for_dedup)
    end

    assert_match %r{<h2>Related Posts</h2>}, output # @post_curr has categories
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count
    # Category matches for @post_curr: review1 (0.5), tech1 (1), tech2 (5)
    # site.config.related_posts: tech1 (1), uncat1 (2), gadgets1 (10)
    # Combined unique, respecting priority: review1, tech1, tech2.
    expected_titles_in_order = [@post_review1.data['title'], @post_tech1.data['title'], @post_tech2.data['title']]
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Posts not correctly deduplicated or ordered'
  end

  def test_returns_empty_string_if_no_related_posts_found
    # A page with no categories, and a site with only this page (and no site.config.related_posts)
    page_isolated = create_post_obj('Isolated Post', [], 0, 'iso', 'iso')
    minimal_site_config = @site_config_base.dup
    minimal_site_config['related_posts'] = []
    # Site contains only the 'isolated' page itself. After filtering out current page, no posts remain.
    minimal_site = create_site(minimal_site_config, {}, [], [page_isolated])
    minimal_context = create_context({}, { site: minimal_site, page: page_isolated })

    output = ''
    ArticleCardUtils.stub :render, lambda { |_p, _c|
      flunk 'ArticleCardUtils.render should not be called if no posts are found'
    } do
      output = render_tag(minimal_context)
    end
    assert_equal '', output.strip, 'Should return empty string when no related posts are found'
  end
end
