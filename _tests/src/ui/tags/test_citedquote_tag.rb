# frozen_string_literal: true

# _tests/src/ui/tags/test_citedquote_tag.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/citedquote_tag'

# Tests for Jekyll::UI::Tags::CitedQuoteTag Liquid block tag.
#
# Verifies that the tag correctly renders attributed quotes with proper formatting.
class TestCitedQuoteTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_author' => 'PageAuthor',
        'page_title' => 'Page Title Variable',
        'nil_var' => nil
      },
      { site: @site, page: create_doc({ 'path' => 'test_page.md' }, '/test.html') }
    )

    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(_topic, _message); end
      def logger.error(_topic, _message); end
      def logger.info(_topic, _message); end
      def logger.debug(_topic, _message); end
      def logger.log_level=(_level); end
      def logger.progname=(_name); end
    end
  end

  # Helper to render the block tag
  def render_tag(markup, content, context = @context)
    template = Liquid::Template.parse("{% citedquote #{markup} %}#{content}{% endcitedquote %}")
    Jekyll.stub :logger, @silent_logger_stub do
      template.render!(context)
    end
  end

  # --- Tests for initialize (Argument Parsing - Syntax Errors) ---

  def test_syntax_error_when_no_citation_params_provided
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% citedquote %}Some quote text{% endcitedquote %}')
    end
    assert_match(/at least one citation parameter/i, err.message)
  end

  def test_syntax_error_for_invalid_argument_format
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% citedquote invalid_format %}text{% endcitedquote %}')
    end
    assert_match(/Invalid arguments/i, err.message)
  end

  def test_syntax_error_for_equals_without_value
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% citedquote author_last= %}text{% endcitedquote %}')
    end
    assert_match(/Invalid arguments/i, err.message)
  end

  def test_valid_with_single_param
    # Should not raise
    Liquid::Template.parse('{% citedquote author_last="Doe" %}text{% endcitedquote %}')
  end

  def test_valid_with_multiple_params
    # Should not raise
    Liquid::Template.parse('{% citedquote author_last="Doe" work_title="Article" %}text{% endcitedquote %}')
  end

  # --- Tests for Special Characters in Arguments ---

  def test_parses_apostrophe_in_double_quoted_value
    # Common case: Irish names like O'Malley
    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |_cont, params, _site|
      captured_args = params
      '<figure>mock</figure>'
    } do
      render_tag("author_last=\"O'Malley\"", 'Quote text')
    end

    assert_equal "O'Malley", captured_args[:author_last]
  end

  def test_parses_double_quote_in_single_quoted_value
    # Title containing double quotes
    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |_cont, params, _site|
      captured_args = params
      '<figure>mock</figure>'
    } do
      render_tag("work_title='A \"Quoted\" Title'", 'Quote text')
    end

    assert_equal 'A "Quoted" Title', captured_args[:work_title]
  end

  def test_parses_single_quote_in_double_quoted_value
    # Title containing single quotes
    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |_cont, params, _site|
      captured_args = params
      '<figure>mock</figure>'
    } do
      render_tag("work_title=\"The 'Best' Book\"", 'Quote text')
    end

    assert_equal "The 'Best' Book", captured_args[:work_title]
  end

  # --- Tests for render (Empty/Whitespace Content) ---

  def test_error_when_content_is_empty
    err = assert_raises Liquid::SyntaxError do
      render_tag('author_last="Doe"', '')
    end
    assert_match(/content is required/i, err.message)
  end

  def test_error_when_content_is_whitespace_only
    err = assert_raises Liquid::SyntaxError do
      render_tag('author_last="Doe"', '   ')
    end
    assert_match(/content is required/i, err.message)
  end

  # --- Tests for render (HTML Structure) ---

  def test_render_outputs_figure_wrapper
    mock_output = '<figure class="cited-quote"><blockquote><p>text</p></blockquote></figure>'

    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, mock_output do
      output = render_tag('author_last="Doe"', 'Some quote')
      assert_match(/<figure class="cited-quote">/, output)
    end
  end

  def test_render_outputs_blockquote
    mock_output = '<figure class="cited-quote"><blockquote><p>text</p></blockquote></figure>'

    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, mock_output do
      output = render_tag('author_last="Doe"', 'Some quote')
      assert_match(/<blockquote>/, output)
    end
  end

  def test_render_includes_cite_attribute_when_url_provided
    mock_output = '<figure class="cited-quote"><blockquote cite="http://example.com"><p>text</p></blockquote></figure>'

    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, mock_output do
      output = render_tag('author_last="Doe" url="http://example.com"', 'Some quote')
      assert_match(%r{cite="http://example\.com"}, output)
    end
  end

  def test_render_outputs_figcaption
    mock_output = '<figure class="cited-quote"><blockquote><p>text</p></blockquote>' \
                  '<figcaption>—<span class="citation">Doe.</span></figcaption></figure>'

    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, mock_output do
      output = render_tag('author_last="Doe"', 'Some quote')
      assert_match(/<figcaption>/, output)
    end
  end

  # --- Tests for render (Argument Resolution and Delegation) ---

  def test_render_delegates_to_citedquote_utils_with_resolved_params
    markup = 'author_last="Doe" work_title="Test Article"'
    content = 'Quote content here'
    expected_params = {
      author_last: 'Doe',
      work_title: 'Test Article'
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |cont, params, site|
      captured_args = { content: cont, params: params, site: site }
      '<figure>mock</figure>'
    } do
      render_tag(markup, content)
    end

    refute_nil captured_args, 'CitedQuoteUtils.render should have been called'
    assert_equal content, captured_args[:content]
    assert_equal expected_params, captured_args[:params]
    assert_equal @site, captured_args[:site]
  end

  def test_render_resolves_variable_arguments
    markup = 'author_last=page_author work_title=page_title'
    content = 'Quote content'
    expected_params = {
      author_last: 'PageAuthor',
      work_title: 'Page Title Variable'
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |cont, params, site|
      captured_args = { content: cont, params: params, site: site }
      '<figure>mock</figure>'
    } do
      render_tag(markup, content)
    end

    refute_nil captured_args
    assert_equal expected_params, captured_args[:params]
  end

  def test_render_resolves_nil_variable_correctly
    markup = 'author_last=nil_var work_title="Test"'
    expected_params = {
      author_last: nil,
      work_title: 'Test'
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |_cont, params, _site|
      captured_args = { params: params }
      '<figure>mock</figure>'
    } do
      render_tag(markup, 'content')
    end

    refute_nil captured_args
    assert_equal expected_params, captured_args[:params]
  end

  def test_render_passes_all_citation_params
    markup = "author_last='Doe' author_first='John' author_handle='@jdoe' " \
             "work_title='Work' container_title='Container' editor='Ed' " \
             "edition='2nd' volume='X' number='1' publisher='Pub' " \
             "date='2023' first_page='10' last_page='20' page='15' " \
             "doi='10.123' url='http://example.com' access_date='Today'"
    expected_params = {
      author_last: 'Doe', author_first: 'John', author_handle: '@jdoe',
      work_title: 'Work', container_title: 'Container', editor: 'Ed',
      edition: '2nd', volume: 'X', number: '1', publisher: 'Pub',
      date: '2023', first_page: '10', last_page: '20', page: '15',
      doi: '10.123', url: 'http://example.com', access_date: 'Today'
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |_cont, params, _site|
      captured_args = { params: params }
      '<figure>mock</figure>'
    } do
      render_tag(markup, 'content')
    end

    refute_nil captured_args
    assert_equal expected_params, captured_args[:params]
  end

  # --- Tests for render (Content Handling) ---

  def test_render_passes_content_with_html_preserved
    content = '<em>emphasized</em> and <strong>bold</strong>'

    captured_content = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |cont, _params, _site|
      captured_content = cont
      '<figure>mock</figure>'
    } do
      render_tag('author_last="Doe"', content)
    end

    assert_equal content, captured_content
  end

  def test_render_passes_content_with_line_breaks
    content = "Line one<br>\nLine two"

    captured_content = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render, lambda { |cont, _params, _site|
      captured_content = cont
      '<figure>mock</figure>'
    } do
      render_tag('author_last="Doe"', content)
    end

    assert_equal content, captured_content
  end
end
