# _tests/plugins/test_article_card_lookup_tag.rb
require_relative '../test_helper'
require_relative '../../_plugins/article_card_lookup_tag'

class TestArticleCardLookupTag < Minitest::Test

  def setup
    # Mock posts - Ensure URLs have leading slash for consistency
    @post1 = create_doc({ 'title' => 'Post One', 'image' => 'img1.jpg' }, '/blog/post-one.html')
    @post2 = create_doc({ 'title' => 'Post Two', 'description' => 'Desc Two' }, '/blog/post-two.html')
    @post3 = create_doc({ 'title' => 'Post Three With Slash' }, '/blog/post-three.html')

    # Mock site with posts
    @site = create_site({}, {}, [], [@post1, @post2, @post3])
    @context = create_context({ 'page' => { 'url' => '/current.html' } }, { site: @site, page: create_doc({}, '/current.html') })

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end; def logger.error(topic, message); end
      def logger.info(topic, message); end;  def logger.debug(topic, message); end
      def logger.log_level=(level); end;    def logger.progname=(name); end
    end
  end

  # Helper to render the tag
  def render_tag(markup)
    output = "" # Initialize to prevent NameError if stubbing fails early
    Jekyll.stub :logger, @silent_logger_stub do # Silence console output from PluginLoggerUtils
      output = Liquid::Template.parse("{% article_card_lookup #{markup} %}").render!(@context)
    end
    output
  end

  # --- Test Cases ---

  def test_lookup_with_url_parameter_quoted
    mock_output = "<div class='mock-card'>Post One Card</div>"
    captured_args = nil # Variable to store captured arguments

    # Define a proc/lambda to capture arguments and return the mock value
    stub_logic = ->(post_arg, context_arg) {
      captured_args = [post_arg, context_arg] # Capture arguments
      mock_output # Return the desired value
    }

    # Stub the utility method
    ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('url="/blog/post-one.html"')
      assert_equal mock_output, output # Verify tag returns stubbed value
    end

    # Assertions *after* the stub block using captured_args
    refute_nil captured_args, "ArticleCardUtils.render should have been called"
    assert_instance_of MockDocument, captured_args[0], "First argument should be a MockDocument"
    assert_equal @post1.url, captured_args[0].url
    assert_equal @context, captured_args[1]
  end

  def test_lookup_with_url_parameter_unquoted_variable
    @context['my_post_url'] = '/blog/post-two.html'
    mock_output = "<div class='mock-card'>Post Two Card</div>"
    captured_args = nil

    stub_logic = ->(post_arg, context_arg) {
      captured_args = [post_arg, context_arg]
      mock_output
    }

    ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('url=my_post_url')
      assert_equal mock_output, output
    end

    refute_nil captured_args, "ArticleCardUtils.render should have been called"
    assert_instance_of MockDocument, captured_args[0], "First argument should be a MockDocument"
    assert_equal @post2.url, captured_args[0].url
    assert_equal @context, captured_args[1]
  end

  def test_lookup_with_positional_url_quoted
    mock_output = "<div class='mock-card'>Post One Card Positional</div>"
    captured_args = nil

    stub_logic = ->(post_arg, context_arg) {
      captured_args = [post_arg, context_arg]
      mock_output
    }

    ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('"/blog/post-one.html"')
      assert_equal mock_output, output
    end

    refute_nil captured_args, "ArticleCardUtils.render should have been called"
    assert_instance_of MockDocument, captured_args[0], "First argument should be a MockDocument"
    assert_equal @post1.url, captured_args[0].url
    assert_equal @context, captured_args[1]
  end

  def test_lookup_with_positional_url_variable
    @context['my_post_url'] = '/blog/post-two.html'
    mock_output = "<div class='mock-card'>Post Two Card Positional Var</div>"
    captured_args = nil

    stub_logic = ->(post_arg, context_arg) {
      captured_args = [post_arg, context_arg]
      mock_output
    }

    ArticleCardUtils.stub :render, stub_logic do
      output = render_tag('my_post_url')
      assert_equal mock_output, output
    end

    refute_nil captured_args, "ArticleCardUtils.render should have been called"
    assert_instance_of MockDocument, captured_args[0], "First argument should be a MockDocument"
    assert_equal @post2.url, captured_args[0].url
    assert_equal @context, captured_args[1]
  end

  def test_lookup_url_without_leading_slash_input
    # Test input URL is 'blog/post-three.html', tag should add leading '/'
    mock_output = "<div class='mock-card'>Post Three Card</div>"
    captured_args_pos = nil
    captured_args_named = nil

    stub_logic_pos = ->(post_arg, context_arg) {
      captured_args_pos = [post_arg, context_arg]
      mock_output
    }
    stub_logic_named = ->(post_arg, context_arg) {
      captured_args_named = [post_arg, context_arg]
      mock_output
    }

    # Test positional - Input is "blog/post-three.html"
    ArticleCardUtils.stub :render, stub_logic_pos do
      output_pos = render_tag('"blog/post-three.html"')
      assert_equal mock_output, output_pos
    end

    refute_nil captured_args_pos, "ArticleCardUtils.render (positional) should have been called"
    assert_instance_of MockDocument, captured_args_pos[0], "First argument (positional) should be a MockDocument"
    assert_equal @post3.url, captured_args_pos[0].url # Should match '/blog/post-three.html'
    assert_equal @context, captured_args_pos[1]

    # Test named - Input is "blog/post-three.html"
    ArticleCardUtils.stub :render, stub_logic_named do
      output_named = render_tag('url="blog/post-three.html"')
      assert_equal mock_output, output_named
    end

    refute_nil captured_args_named, "ArticleCardUtils.render (named) should have been called"
    assert_instance_of MockDocument, captured_args_named[0], "First argument (named) should be a MockDocument"
    assert_equal @post3.url, captured_args_named[0].url # Should match '/blog/post-three.html'
    assert_equal @context, captured_args_named[1]
  end

  # --- Tests where stub should NOT be called ---
  def test_lookup_post_not_found
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url="/blog/nonexistent.html"') # render_tag now handles Jekyll.stub
    # Corrected Regex to include [WARN] and allow for flexible spacing
    assert_match %r{<!-- \[WARN\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='Could not find post'\s+URL='/blog/nonexistent.html'.* -->}, output
  end

  def test_lookup_url_resolves_to_empty
     @context['empty_url_var'] = ''
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url=empty_url_var')
    # Corrected Regex
    assert_match %r{<!-- \[WARN\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='URL markup resolved to empty'.* -->}, output
  end

  def test_lookup_url_resolves_to_nil
    @context['nil_url_var'] = nil
    @site.config['plugin_logging']['ARTICLE_CARD_LOOKUP'] = true
    output = render_tag('url=nil_url_var')
    # Corrected Regex
    assert_match %r{<!-- \[WARN\] ARTICLE_CARD_LOOKUP_FAILURE: Reason='URL markup resolved to empty'.* -->}, output
  end

  # --- Syntax Error Tests (no changes needed here) ---
  def test_syntax_error_missing_url
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% article_card_lookup %}")
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

end
