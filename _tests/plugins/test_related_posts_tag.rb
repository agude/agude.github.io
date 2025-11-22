# frozen_string_literal: true

# _tests/plugins/test_related_posts_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/related_posts_tag'

# Base test class with shared setup and helpers for RelatedPostsTag tests
class TestRelatedPostsTagBase < Minitest::Test
  DEFAULT_MAX_POSTS = Jekyll::RelatedPostsTag::DEFAULT_MAX_POSTS

  def setup
    @site_config_base = {
      'url' => 'http://example.com',
      'plugin_logging' => { 'RELATED_POSTS' => true },
      'plugin_log_level' => 'debug'
    }
    @test_time_now = Time.parse('2024-01-15 10:00:00 EST')

    setup_test_posts
    setup_site_and_context
    setup_mocks
  end

  private

  def setup_test_posts
    @post_curr = create_post_obj('Current Post', %w[Tech Review], 0, 'current', 'current')
    @post_review1 = create_post_obj('Review Post 1 (Very Recent)', ['Review'], 0.5, 'review1', 'review1')
    @post_tech1 = create_post_obj('Tech Post 1 (Recent)', ['Tech'], 1, 'tech1', 'tech1')
    @post_uncat1 = create_post_obj('Uncat Post 1 (Recentish)', [], 2, 'uncat1', 'uncat1')
    @post_tech2 = create_post_obj('Tech Post 2 (Older)', %w[Tech Gadgets], 5, 'tech2', 'tech2')
    @post_gadgets1 = create_post_obj('Gadgets Post 1 (Oldest)', ['Gadgets'], 10, 'gadgets1', 'gadgets1')
    @post_future = create_post_obj('Future Post', ['Tech'], -5, 'future', 'future')
    @post_unpublished = create_post_obj('Unpublished Post', ['Tech'], 3, 'unpub', 'unpub', published: false)

    @all_posts_for_site_default = [
      @post_curr, @post_review1, @post_tech1, @post_uncat1,
      @post_tech2, @post_gadgets1, @post_future, @post_unpublished
    ]
  end

  def setup_site_and_context
    @site = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    @site.config['related_posts'] = []
    @context = create_context({}, { site: @site, page: @post_curr })
  end

  def setup_mocks
    @mock_article_card_html_simple = "<div class='mock-card'>CARD</div>\n"
    @silent_logger_stub = create_silent_logger_stub
  end

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

  def create_silent_logger_stub
    Object.new.tap do |logger|
      def logger.warn(_topic, _message); end

      def logger.error(_topic, _message); end

      def logger.info(_topic, _message); end

      def logger.debug(_topic, _message); end
    end
  end

  def render_tag(context = @context, logger_override = @silent_logger_stub)
    output = ''
    Time.stub :now, @test_time_now do
      Jekyll.stub :logger, logger_override do
        output = Liquid::Template.parse('{% related_posts %}').render!(context)
      end
    end
    output
  end
end

# Tests for prerequisite validation and error logging
class TestRelatedPostsTagPrerequisites < TestRelatedPostsTagBase
  def test_logs_error_if_site_missing
    page_for_test = create_doc({ 'title' => 'Test Page', 'path' => 'prereq_test.md' }, '/prereq.html')
    bad_context = create_context({}, { page: page_for_test })
    mock_jekyll_logger = create_mock_logger_for_site_missing

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(bad_context, mock_jekyll_logger)
    end
    assert_equal '', output.strip, 'Output should be empty on prerequisite failure'
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_page_missing
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true
    bad_context = create_context({}, { site: site_for_test })

    mock_jekyll_logger = create_mock_logger_for_page_missing

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(bad_context, mock_jekyll_logger)
    end

    assert_page_missing_error_in_output(output)
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_site_posts_docs_not_array
    _, context_for_test = setup_broken_posts_docs_test

    mock_jekyll_logger = create_mock_logger_for_posts_docs_not_array

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(context_for_test, mock_jekyll_logger)
    end

    assert_posts_docs_error_in_output(output)
    mock_jekyll_logger.verify
  end

  def test_logs_error_if_page_url_missing
    page_no_url = create_doc({ 'title' => 'No URL', 'date' => @test_time_now, 'path' => 'no_url_page.md' }, nil)
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true
    context_no_url = create_context({}, { site: site_for_test, page: page_no_url })

    mock_jekyll_logger = create_mock_logger_for_url_missing

    output = ''
    ArticleCardUtils.stub :render, @mock_article_card_html_simple do
      output = render_tag(context_no_url, mock_jekyll_logger)
    end
    assert_url_missing_error_in_output(output)
    mock_jekyll_logger.verify
  end

  private

  def create_mock_logger_for_site_missing
    mock = Minitest::Mock.new
    mock.expect(:error, nil) do |p, m|
      p == 'PluginLogger:' &&
        m.include?('Context, Site, or Site Config unavailable for logging. Original Call: RELATED_POSTS')
    end
    mock
  end

  def create_mock_logger_for_page_missing
    expected_prefix = 'PluginLiquid:'
    expected_body = "[ERROR] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page object, " \
                    "page[&#39;url&#39;] (cannot check, site or page missing).' " \
                    "PageURL='N/A' SourcePage='unknown_page'"

    mock = Minitest::Mock.new
    mock.expect(:error, nil) do |prefix_arg, message_arg|
      prefix_arg == expected_prefix && message_arg == expected_body
    end
    mock
  end

  def create_mock_logger_for_posts_docs_not_array
    mock = Minitest::Mock.new
    mock.expect(:error, nil) do |_p, m|
      m.include?('Missing prerequisites: site.posts.docs (site.posts.docs is String, not Array)')
    end
    mock
  end

  def create_mock_logger_for_url_missing
    mock = Minitest::Mock.new
    mock.expect(:error, nil) do |_p, m|
      m.include?('Missing prerequisites: page[&#39;url&#39;] (present and not empty)')
    end
    mock
  end

  def setup_broken_posts_docs_test
    site_for_test = create_site(@site_config_base.dup)
    site_for_test.config['plugin_logging']['RELATED_POSTS'] = true
    page_for_context = @post_curr
    context_for_test = create_context({}, { site: site_for_test, page: page_for_context })
    site_for_test.posts.docs = 'not_an_array'
    [site_for_test, context_for_test]
  end

  def assert_page_missing_error_in_output(output)
    pattern = %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page object, page\[&#39;url&#39;\] \(cannot check, site or page missing\)\.' PageURL='N/A' SourcePage='unknown_page' -->}
    assert_match pattern, output
  end

  def assert_posts_docs_error_in_output(output)
    pattern = %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: site\.posts\.docs \(site\.posts\.docs is String, not Array\)\.' PageURL='/current\.html' SourcePage='path_to_current\.md' -->}
    assert_match pattern, output
  end

  def assert_url_missing_error_in_output(output)
    pattern = %r{<!-- \[ERROR\] RELATED_POSTS_FAILURE: Reason='Missing prerequisites: page\[&#39;url&#39;\] \(present and not empty\)\.' PageURL='N/A' SourcePage='no_url_page\.md' -->}
    assert_match pattern, output
  end
end

# Tests for post selection and ordering logic
class TestRelatedPostsTagSelection < TestRelatedPostsTagBase
  def test_selects_by_category_first_and_sorts_by_date
    actual_titles_rendered = []
    expected_titles_in_order = [
      @post_review1.data['title'],
      @post_tech1.data['title'],
      @post_tech2.data['title']
    ]

    site_for_test = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    site_for_test.config['related_posts'] = []
    context_for_test = create_context({}, { site: site_for_test, page: @post_curr })

    output = render_with_title_tracking(context_for_test, actual_titles_rendered)

    assert_match %r{<h2>Related Posts</h2>}, output, "Header should be 'Related Posts' when categories match"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Should render default max posts'
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Posts not in correct order by category and date'
  end

  def test_uses_site_related_posts_as_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats')
    actual_titles_rendered = []

    _, context_no_cats = setup_fallback_test(page_no_cats)
    output = render_with_title_tracking(context_no_cats, actual_titles_rendered)

    assert_match %r{<h2>Recent Posts</h2>}, output, "Header should be 'Recent Posts' (no category match, fallback)"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Card count mismatch'
    expected_titles_in_order = [
      @post_uncat1.data['title'],
      @post_tech2.data['title'],
      @post_gadgets1.data['title']
    ]
    assert_equal expected_titles_in_order, actual_titles_rendered,
                 "Post order mismatch from site.config['related_posts']"
  end

  def test_uses_recent_posts_as_absolute_fallback
    page_no_cats = create_post_obj('No Cats Post', [], 0, 'no_cats', 'no-cats')
    actual_titles_rendered = []

    _, context_no_cats = setup_absolute_fallback_test(page_no_cats)
    output = render_with_title_tracking(context_no_cats, actual_titles_rendered)

    assert_match %r{<h2>Recent Posts</h2>}, output, "Header should be 'Recent Posts' (absolute fallback)"
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count, 'Card count mismatch'
    expected_titles_in_order = [
      @post_curr.data['title'],
      @post_review1.data['title'],
      @post_tech1.data['title']
    ]
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Post order mismatch for recent posts fallback'
  end

  def test_excludes_current_future_and_unpublished_posts
    actual_titles_rendered = []
    site_for_test = create_site(@site_config_base.dup, {}, [], @all_posts_for_site_default)
    context_for_test = create_context({}, { site: site_for_test, page: @post_curr })

    output = render_with_title_tracking(context_for_test, actual_titles_rendered)

    assert_match %r{<h2>Related Posts</h2>}, output
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count
    expected_titles_in_order = [
      @post_review1.data['title'],
      @post_tech1.data['title'],
      @post_tech2.data['title']
    ]
    assert_equal expected_titles_in_order, actual_titles_rendered

    assert_exclusions(actual_titles_rendered)
  end

  def test_deduplicates_posts
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = [@post_tech1, @post_uncat1, @post_gadgets1].sort_by(&:date).reverse

    site_for_dedup_test = create_site(current_site_config, {}, [], @all_posts_for_site_default)
    context_for_dedup = create_context({}, { site: site_for_dedup_test, page: @post_curr })

    actual_titles_rendered = []
    output = render_with_title_tracking(context_for_dedup, actual_titles_rendered)

    assert_match %r{<h2>Related Posts</h2>}, output
    assert_equal DEFAULT_MAX_POSTS, actual_titles_rendered.count
    expected_titles_in_order = [
      @post_review1.data['title'],
      @post_tech1.data['title'],
      @post_tech2.data['title']
    ]
    assert_equal expected_titles_in_order, actual_titles_rendered, 'Posts not correctly deduplicated or ordered'
  end

  def test_returns_empty_string_if_no_related_posts_found
    page_isolated = create_post_obj('Isolated Post', [], 0, 'iso', 'iso')
    minimal_site_config = @site_config_base.dup
    minimal_site_config['related_posts'] = []
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

  private

  def render_with_title_tracking(context, titles_array)
    output = ''
    ArticleCardUtils.stub :render, lambda { |post_obj, _ctx|
      titles_array << post_obj.data['title']
      @mock_article_card_html_simple
    } do
      output = render_tag(context)
    end
    output
  end

  def setup_fallback_test(page_no_cats)
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = [@post_uncat1, @post_gadgets1, @post_tech2]

    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url }
    all_posts_for_this_test << page_no_cats
    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    [site_for_this_test, context_no_cats]
  end

  def setup_absolute_fallback_test(page_no_cats)
    current_site_config = @site_config_base.dup
    current_site_config['related_posts'] = []

    all_posts_for_this_test = @all_posts_for_site_default.dup.reject { |p| p.url == page_no_cats.url }
    all_posts_for_this_test << @post_curr unless all_posts_for_this_test.map(&:url).include?(@post_curr.url)
    all_posts_for_this_test << page_no_cats

    site_for_this_test = create_site(current_site_config, {}, [], all_posts_for_this_test)
    context_no_cats = create_context({}, { site: site_for_this_test, page: page_no_cats })

    [site_for_this_test, context_no_cats]
  end

  def assert_exclusions(actual_titles_rendered)
    refute_includes actual_titles_rendered, @post_curr.data['title'], 'Current post should be excluded'
    refute_includes actual_titles_rendered, @post_future.data['title'], 'Future post should be excluded'
    refute_includes actual_titles_rendered, @post_unpublished.data['title'], 'Unpublished post should be excluded'
  end
end
