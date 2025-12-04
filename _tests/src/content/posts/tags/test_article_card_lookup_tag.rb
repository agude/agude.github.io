# frozen_string_literal: true

# _tests/plugins/test_article_card_lookup_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/posts/tags/article_card_lookup_tag'

# Tests for Jekyll::Posts::Tags::ArticleCardLookupTag Liquid tag.
#
# Verifies that the tag correctly orchestrates between argument parsing,
# ArticleFinder, and Jekyll::Posts::ArticleCardUtils.
class TestArticleCardLookupTag < Minitest::Test
  def setup
    setup_mock_posts
    setup_site_and_context
    @silent_logger_stub = create_silent_logger
  end

  private

  # Helper to set up mock posts
  def setup_mock_posts
    @post1 = create_doc({ 'title' => 'Post One', 'image' => 'img1.jpg' }, '/blog/post-one.html')
    @post2 = create_doc({ 'title' => 'Post Two', 'description' => 'Desc Two' }, '/blog/post-two.html')
    @post3 = create_doc({ 'title' => 'Post Three With Slash' }, '/blog/post-three.html')
  end

  # Helper to set up site and context
  def setup_site_and_context
    @site = create_site({ 'url' => 'http://example.com' }, {}, [], [@post1, @post2, @post3])
    @context = create_context({ 'page' => { 'url' => '/current.html', 'path' => 'current.html' } },
                              { site: @site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })
  end

  # Helper to create a silent logger stub
  def create_silent_logger
    Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end

      def logger.log_level=(level); end

      def logger.progname=(name); end
    end
  end

  # Helper to create a stub that captures arguments (returns container and stub)
  def create_capturing_stub(mock_output)
    captured = { args: nil } # Use hash to allow mutation in lambda
    stub_logic = lambda { |post_arg, context_arg|
      captured[:args] = [post_arg, context_arg]
      mock_output
    }
    [stub_logic, captured]
  end

  # Helper to assert captured arguments
  def assert_captured_args(captured_container, expected_url, label = '')
    captured_args = captured_container[:args]
    label_suffix = label.empty? ? '' : " (#{label})"
    refute_nil captured_args, "Jekyll::Posts::ArticleCardUtils.render#{label_suffix} should have been called"
    assert_instance_of MockDocument, captured_args[0], "First argument#{label_suffix} should be a MockDocument"
    assert_equal expected_url, captured_args[0].url
    assert_equal @context, captured_args[1]
  end

  public

  # Helper to render the tag
  def render_tag(markup)
    output = '' # Initialize to prevent NameError if stubbing fails early
    Jekyll.stub :logger, @silent_logger_stub do # Silence console output from Jekyll::Infrastructure::PluginLoggerUtils
      output = Liquid::Template.parse("{% article_card_lookup #{markup} %}").render!(@context)
    end
    output
  end

  # --- Test Cases ---

  def test_lookup_with_url_parameter_quoted
    mock_output = "<div class='mock-card'>Post One Card</div>"
    stub_logic, captured = create_capturing_stub(mock_output)

    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('url="/blog/post-one.html"')
      assert_equal mock_output, output
    end

    assert_captured_args(captured, @post1.url)
  end

  def test_lookup_with_url_parameter_unquoted_variable
    @context['my_post_url'] = '/blog/post-two.html'
    mock_output = "<div class='mock-card'>Post Two Card</div>"
    stub_logic, captured = create_capturing_stub(mock_output)

    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('url=my_post_url')
      assert_equal mock_output, output
    end

    assert_captured_args(captured, @post2.url)
  end

  def test_lookup_with_positional_url_quoted
    mock_output = "<div class='mock-card'>Post One Card Positional</div>"
    stub_logic, captured = create_capturing_stub(mock_output)

    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('"/blog/post-one.html"')
      assert_equal mock_output, output
    end

    assert_captured_args(captured, @post1.url)
  end

  def test_lookup_with_positional_url_variable
    @context['my_post_url'] = '/blog/post-two.html'
    mock_output = "<div class='mock-card'>Post Two Card Positional Var</div>"
    stub_logic, captured = create_capturing_stub(mock_output)

    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('my_post_url')
      assert_equal mock_output, output
    end

    assert_captured_args(captured, @post2.url)
  end

  def test_lookup_url_without_leading_slash_input
    # Test input URL is 'blog/post-three.html', tag should add leading '/'
    mock_output = "<div class='mock-card'>Post Three Card</div>"

    # Test positional - Input is "blog/post-three.html"
    stub_logic_pos, captured_pos = create_capturing_stub(mock_output)
    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic_pos do
      output_pos = render_tag('"blog/post-three.html"')
      assert_equal mock_output, output_pos
    end
    assert_captured_args(captured_pos, @post3.url, 'positional')

    # Test named - Input is "blog/post-three.html"
    stub_logic_named, captured_named = create_capturing_stub(mock_output)
    Jekyll::Posts::ArticleCardUtils.stub :render, stub_logic_named do
      output_named = render_tag('url="blog/post-three.html"')
      assert_equal mock_output, output_named
    end
    assert_captured_args(captured_named, @post3.url, 'named')
  end

  # --- Tests where stub should NOT be called ---
  def test_lookup_post_not_found
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url="/blog/nonexistent.html"')
    expected_pattern = %r{<!-- \[WARN\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Could not find post\.'\s*URL='/blog/nonexistent.html'\s*SourcePage='current\.html' -->}
    assert_match expected_pattern, output
  end

  def test_lookup_url_resolves_to_empty
    @context['empty_url_var'] = ''
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url=empty_url_var')
    expected_pattern = /<!-- \[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='URL markup resolved to empty or nil\.'\s*Markup='empty_url_var'\s*SourcePage='current\.html' -->/
    assert_match expected_pattern, output
  end

  def test_lookup_url_resolves_to_nil
    @context['nil_url_var'] = nil
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url=nil_url_var')
    expected_pattern = /<!-- \[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='URL markup resolved to empty or nil\.'\s*Markup='nil_url_var'\s*SourcePage='current\.html' -->/
    assert_match expected_pattern, output
  end

  def test_lookup_cannot_iterate_site_posts
    # In create_site, posts_data is used to initialize MockCollection.new(posts_data, 'posts')
    # So, site.posts will be a MockCollection. site.posts.docs will be the string.
    bad_site = create_site({ 'url' => 'http://example.com' }, {}, [], 'not_an_array_or_collection_docs')
    bad_context = create_context({ 'page' => { 'path' => 'current.html' } },
                                 { site: bad_site, page: create_doc({ 'path' => 'current.html' }, '/current.html') })
    bad_site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true

    output = ''
    Jekyll.stub :logger, @silent_logger_stub do
      output = Liquid::Template.parse("{% article_card_lookup url='/blog/post-one.html' %}").render!(bad_context)
    end
    expected_pattern = %r{<!-- \[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Cannot iterate site\.posts\.docs\. It is missing, not an Array, or site\.posts is invalid\.'\s*URL='/blog/post-one\.html'\s*PostsDocsType='String'\s*SourcePage='current\.html' -->}
    assert_match expected_pattern, output
  end

  def test_lookup_article_card_utils_render_error
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    # Stub Jekyll::Posts::ArticleCardUtils.render to raise an error
    Jekyll::Posts::ArticleCardUtils.stub :render, ->(_post, _ctx) { raise StandardError, 'Card render failed!' } do
      output = render_tag('url="/blog/post-one.html"')
      expected_pattern = %r{<!-- \[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Error calling CardUtils\.render utility: Card render failed!'\s*URL='/blog/post-one\.html'\s*ErrorClass='StandardError'\s*ErrorMessage='Card render failed!'\s*SourcePage='current\.html' -->}
      assert_match expected_pattern, output
    end
  end

  # --- Syntax Error Tests ---
  def test_syntax_error_missing_url
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% article_card_lookup %}')
    end
    assert_match(/Could not find URL value/, err.message)
  end

  def test_syntax_error_extra_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% article_card_lookup url='/p1.html' extra=bad %}")
    end
    assert_match(/Unknown argument\(s\)/, err.message)

    err2 = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% article_card_lookup '/p1.html' extra=bad %}")
    end
    assert_match(/Unknown argument\(s\)/, err2.message)
  end

  # --- Orchestration Tests ---

  def test_calls_article_finder_with_correct_arguments
    captured_args = {}
    mock_result = { post: @post1, url: '/blog/post-one.html', error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, lambda { |args|
      captured_args = args
      mock_finder
    } do
      Jekyll::Posts::ArticleCardUtils.stub :render, ->(_post, _ctx) { '<div>Card</div>' } do
        render_tag('url="/blog/post-one.html"')

        assert_equal @site, captured_args[:site]
        assert_equal '"/blog/post-one.html"', captured_args[:url_markup]
        assert_equal @context, captured_args[:context]
        mock_finder.verify
      end
    end
  end

  def test_calls_article_card_utils_when_finder_succeeds
    captured_post = nil
    captured_context = nil
    mock_result = { post: @post1, url: '/blog/post-one.html', error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::Posts::ArticleCardUtils.stub :render, lambda { |post, ctx|
        captured_post = post
        captured_context = ctx
        '<div>Card</div>'
      } do
        render_tag('url="/blog/post-one.html"')

        assert_equal @post1, captured_post
        assert_equal @context, captured_context
        mock_finder.verify
      end
    end
  end

  def test_returns_output_from_article_card_utils
    mock_output = '<div class="custom-article">Custom Article HTML</div>'
    mock_result = { post: @post1, url: '/blog/post-one.html', error: nil }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, ->(_args) { mock_finder } do
      Jekyll::Posts::ArticleCardUtils.stub :render, ->(_post, _ctx) { mock_output } do
        output = render_tag('url="/blog/post-one.html"')

        assert_equal mock_output, output
        mock_finder.verify
      end
    end
  end

  def test_logs_error_when_finder_returns_url_error
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    mock_result = { post: nil, url: nil, error: { type: :url_error } }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, ->(_args) { mock_finder } do
      output = render_tag('url=empty_var')

      expected_pattern = /\[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='URL markup resolved to empty or nil\.'/
      assert_match expected_pattern, output
      mock_finder.verify
    end
  end

  def test_logs_error_when_finder_returns_collection_error
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    mock_result = { post: nil, url: '/blog/post.html', error: { type: :collection_error, details: 'String' } }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, ->(_args) { mock_finder } do
      output = render_tag('url="/blog/post.html"')

      expected_pattern = /\[ERROR\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Cannot iterate site\.posts\.docs/
      assert_match expected_pattern, output
      assert_match(/PostsDocsType='String'/, output)
      mock_finder.verify
    end
  end

  def test_logs_warn_when_finder_returns_post_not_found
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    mock_result = { post: nil, url: nil, error: { type: :post_not_found, details: '/blog/missing.html' } }

    mock_finder = Minitest::Mock.new
    mock_finder.expect :find, mock_result

    Jekyll::Posts::Lookups::ArticleFinder.stub :new, ->(_args) { mock_finder } do
      output = render_tag('url="/blog/missing.html"')

      expected_pattern = /\[WARN\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Could not find post\.'/
      assert_match expected_pattern, output
      assert_match(%r{URL='/blog/missing\.html'}, output)
      mock_finder.verify
    end
  end
end
