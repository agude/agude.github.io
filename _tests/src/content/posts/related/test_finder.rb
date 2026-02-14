# frozen_string_literal: true

require_relative '../../../../test_helper'

# Tests for Jekyll::Posts::Related::Finder
#
# Verifies that related posts are correctly found based on category matching.
class TestRelatedPostsFinder < Minitest::Test
  def setup
    @current_post = create_doc(
      { 'title' => 'Current Post', 'categories' => ['tech'] },
      '/posts/current.html'
    )
    @current_post.define_singleton_method(:date) { Time.now - 86_400 }

    @related_post = create_doc(
      { 'title' => 'Related Post', 'categories' => ['tech'], 'published' => true },
      '/posts/related.html'
    )
    @related_post.define_singleton_method(:date) { Time.now - 172_800 }

    @unrelated_post = create_doc(
      { 'title' => 'Unrelated Post', 'categories' => ['cooking'], 'published' => true },
      '/posts/unrelated.html'
    )
    @unrelated_post.define_singleton_method(:date) { Time.now - 259_200 }
  end

  def create_site_with_posts(posts)
    site = create_site({}, {})
    posts_collection = Struct.new(:docs).new(posts)
    site.define_singleton_method(:posts) { posts_collection }
    site
  end

  def test_finds_related_by_category
    site = create_site_with_posts([@current_post, @related_post, @unrelated_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    assert result[:found_by_category]
    # Category match first, then fills remaining slots with recent posts
    assert_equal 2, result[:posts].length
    assert_equal '/posts/related.html', result[:posts].first.url
    assert_equal '/posts/unrelated.html', result[:posts].last.url
  end

  def test_excludes_current_post
    site = create_site_with_posts([@current_post, @related_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    urls = result[:posts].map(&:url)
    refute_includes urls, '/posts/current.html'
  end

  def test_falls_back_to_recent_when_no_category_match
    no_category_post = create_doc(
      { 'title' => 'No Category', 'categories' => [], 'published' => true },
      '/posts/no-cat.html'
    )
    no_category_post.define_singleton_method(:date) { Time.now - 86_400 }

    site = create_site_with_posts([no_category_post, @unrelated_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['unique'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    refute result[:found_by_category]
    refute_empty result[:posts]
  end

  def test_respects_max_posts_limit
    posts = (1..10).map do |i|
      post = create_doc(
        { 'title' => "Post #{i}", 'categories' => ['tech'], 'published' => true },
        "/posts/#{i}.html"
      )
      post.define_singleton_method(:date) { Time.now - (i * 86_400) }
      post
    end

    site = create_site_with_posts(posts)
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 3)
    result = finder.find

    assert_equal 3, result[:posts].length
  end

  def test_excludes_unpublished_posts
    unpublished = create_doc(
      { 'title' => 'Draft', 'categories' => ['tech'], 'published' => false },
      '/posts/draft.html'
    )
    unpublished.define_singleton_method(:date) { Time.now - 86_400 }

    site = create_site_with_posts([unpublished, @related_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    urls = result[:posts].map(&:url)
    refute_includes urls, '/posts/draft.html'
  end

  def test_excludes_future_posts
    future = create_doc(
      { 'title' => 'Future', 'categories' => ['tech'], 'published' => true },
      '/posts/future.html'
    )
    future.define_singleton_method(:date) { Time.now + 86_400 }

    site = create_site_with_posts([future, @related_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    urls = result[:posts].map(&:url)
    refute_includes urls, '/posts/future.html'
  end

  def test_logs_when_site_missing
    context = create_context({}, { site: nil, page: { 'url' => '/posts/x.html' } })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLogger:' && msg.include?('RELATED_POSTS')
    end

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = finder.find
    end

    # When site is missing, logger returns empty string (no site config for HTML comments)
    assert_empty result[:posts]
    mock_logger.verify
  end

  def test_logs_when_page_missing
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site = create_site(config, {})
    posts_collection = Struct.new(:docs).new([@related_post])
    site.define_singleton_method(:posts) { posts_collection }
    context = create_context({}, { site: site, page: nil })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, [String, String])

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = finder.find
    end

    assert_match(/RELATED_POSTS_FAILURE/, result[:logs])
    assert_empty result[:posts]
  end

  def test_logs_when_page_url_empty
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site = create_site(config, {})
    posts_collection = Struct.new(:docs).new([@related_post])
    site.define_singleton_method(:posts) { posts_collection }
    page = { 'url' => '', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil, [String, String])

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = nil
    Jekyll.stub :logger, mock_logger do
      result = finder.find
    end

    assert_match(/RELATED_POSTS_FAILURE/, result[:logs])
  end

  def test_sorts_by_date_descending
    older = create_doc(
      { 'title' => 'Older', 'categories' => ['tech'], 'published' => true },
      '/posts/older.html'
    )
    older.define_singleton_method(:date) { Time.now - 259_200 }

    newer = create_doc(
      { 'title' => 'Newer', 'categories' => ['tech'], 'published' => true },
      '/posts/newer.html'
    )
    newer.define_singleton_method(:date) { Time.now - 86_400 }

    site = create_site_with_posts([older, newer])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    assert_equal '/posts/newer.html', result[:posts].first.url
  end

  def test_excludes_posts_without_date
    # Tests line 108: `return false unless post.date`
    no_date_post = create_doc(
      { 'title' => 'No Date', 'categories' => ['tech'], 'published' => true },
      '/posts/no-date.html'
    )
    no_date_post.define_singleton_method(:date) { nil }

    site = create_site_with_posts([no_date_post, @related_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    urls = result[:posts].map(&:url)
    refute_includes urls, '/posts/no-date.html'
    assert_includes urls, '/posts/related.html'
  end

  def test_site_posts_detail_when_docs_not_array
    # Tests line 77: site.posts.docs is not Array
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site = create_site(config, {})
    # Create posts object where docs is not an Array
    posts_obj = Struct.new(:docs).new('not_an_array')
    site.define_singleton_method(:posts) { posts_obj }
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?('not Array')
    end

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    Jekyll.stub :logger, mock_logger do
      result = finder.find
      assert_match(/site\.posts\.docs is String, not Array/, result[:logs])
    end
    mock_logger.verify
  end

  def test_site_posts_detail_when_posts_lacks_docs
    # Tests line 79: site.posts does not have .docs
    config = { 'plugin_logging' => { 'RELATED_POSTS' => true } }
    site = create_site(config, {})
    # Create posts object without docs method
    posts_obj = Object.new
    site.define_singleton_method(:posts) { posts_obj }
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    mock_logger = Minitest::Mock.new
    mock_logger.expect(:error, nil) do |prefix, msg|
      prefix == 'PluginLiquid:' && msg.include?('does not have .docs')
    end

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    Jekyll.stub :logger, mock_logger do
      result = finder.find
      assert_match(/site\.posts does not have \.docs/, result[:logs])
    end
    mock_logger.verify
  end

  def test_excludes_objects_without_required_methods
    # Tests line 105: `return false unless post.respond_to?(:data) && post.respond_to?(:url) && post.respond_to?(:date)`
    # Create an object that doesn't respond to :data
    invalid_post = Object.new
    invalid_post.define_singleton_method(:url) { '/posts/invalid.html' }
    invalid_post.define_singleton_method(:date) { Time.now - 86_400 }
    # Intentionally NOT defining :data method

    site = create_site_with_posts([invalid_post, @related_post])
    page = { 'url' => '/posts/current.html', 'categories' => ['tech'] }
    context = create_context({}, { site: site, page: page })

    finder = Jekyll::Posts::Related::Finder.new(context.registers[:site], context.registers[:page], 5)
    result = finder.find

    # The invalid_post should be excluded, only @related_post should be in results
    urls = result[:posts].map(&:url)
    refute_includes urls, '/posts/invalid.html'
    assert_includes urls, '/posts/related.html'
  end
end
