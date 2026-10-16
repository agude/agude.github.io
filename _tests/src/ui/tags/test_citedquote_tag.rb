# frozen_string_literal: true

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
        'nil_var' => nil,
      },
      { site: @site, page: create_doc({ 'path' => 'test_page.md' }, '/test.html') },
    )

    @silent_logger_stub = silent_logger
  end

  # Helper to render the block tag
  def render_tag(markup, content, context = @context)
    template = Liquid::Template.parse("{% citedquote #{markup} %}#{content}{% endcitedquote %}")
    Jekyll.stub :logger, @silent_logger_stub do
      template.render!(context)
    end
  end

  # --- Tests for initialize (Argument Parsing - Syntax Errors) ---

  def parse_error(markup)
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse("{% citedquote #{markup} %}text{% endcitedquote %}")
    end.message
  end

  def test_syntax_error_when_no_citation_params_provided
    assert_equal "Liquid syntax error: Syntax Error in 'citedquote' tag: At least one citation parameter " \
                 'is required. Use markdown > for unattributed quotes.',
                 parse_error('')
  end

  def test_syntax_error_for_invalid_argument_format
    assert_equal "Liquid syntax error: Syntax Error in 'citedquote': Invalid argument syntax near 'invalid_format'.",
                 parse_error('invalid_format')
  end

  def test_syntax_error_for_equals_without_value
    assert_equal "Liquid syntax error: Syntax Error in 'citedquote': Invalid argument syntax near 'author_last='.",
                 parse_error('author_last=')
  end

  def test_syntax_error_for_unknown_argument
    assert_equal "Liquid syntax error: Syntax Error in 'citedquote': Unknown argument 'title'.",
                 parse_error('author_last="Doe" title="Article"')
  end

  def test_syntax_error_for_duplicate_argument
    assert_equal "Liquid syntax error: Syntax Error in 'citedquote': Duplicate argument 'author_last'.",
                 parse_error('author_last="Doe" author_last="Roe"')
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
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |_cont, params, _site|
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
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |_cont, params, _site|
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
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |_cont, params, _site|
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

  # --- Tests for render (Argument Resolution and Delegation) ---
  #
  # HTML structure is tested against the real renderer in
  # test_citedquote_utils.rb.

  def test_render_delegates_to_citedquote_utils_with_resolved_params
    markup = 'author_last="Doe" work_title="Test Article"'
    content = 'Quote content here'
    expected_params = {
      author_last: 'Doe',
      work_title: 'Test Article',
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, params, site|
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
      work_title: 'Page Title Variable',
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, params, site|
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
      work_title: 'Test',
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |_cont, params, _site|
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
      author_last: 'Doe',
      author_first: 'John',
      author_handle: '@jdoe',
      work_title: 'Work',
      container_title: 'Container',
      editor: 'Ed',
      edition: '2nd',
      volume: 'X',
      number: '1',
      publisher: 'Pub',
      date: '2023',
      first_page: '10',
      last_page: '20',
      page: '15',
      doi: '10.123',
      url: 'http://example.com',
      access_date: 'Today',
    }

    captured_args = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |_cont, params, _site|
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
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, _params, _site|
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
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, _params, _site|
                                               captured_content = cont
                                               '<figure>mock</figure>'
                                             } do
      render_tag('author_last="Doe"', content)
    end

    assert_equal content, captured_content
  end

  # --- Markdown Mode Tests ---

  def test_markdown_mode_renders_blockquote
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse(
      '{% citedquote author_last="Doe" work_title="Test" %}Quote content{% endcitedquote %}',
    )
    output = template.render!(md_context)
    assert_includes output, '> Quote content'
    assert_includes output, '> ---'
    assert_includes output, '*Test*'
  end

  def test_markdown_mode_multiline_content
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse(
      "{% citedquote author_last=\"Doe\" %}Line one\nLine two{% endcitedquote %}",
    )
    output = template.render!(md_context)
    assert_includes output, '> Line one'
    assert_includes output, '> Line two'
  end

  # --- Tests for Content Dedenting (HTML Mode) ---

  def test_render_dedents_uniformly_indented_content
    content = "\n    Line one\n    Line two\n"

    captured_content = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, _params, _site|
                                               captured_content = cont
                                               '<figure>mock</figure>'
                                             } do
      render_tag('author_last="Doe"', content)
    end

    # 4-space common indent should be stripped
    assert_equal "\nLine one\nLine two\n", captured_content
  end

  def test_render_dedents_preserving_relative_indentation
    content = "\n    Base line\n        Indented line\n    Base again\n"

    captured_content = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, _params, _site|
                                               captured_content = cont
                                               '<figure>mock</figure>'
                                             } do
      render_tag('author_last="Doe"', content)
    end

    # Common indent (4 spaces) stripped; relative indent (extra 4) preserved
    assert_equal "\nBase line\n    Indented line\nBase again\n", captured_content
  end

  def test_render_no_dedent_when_content_at_column_zero
    content = "Already at column zero\nSecond line"

    captured_content = nil
    Jekyll::UI::Quotes::CitedQuoteUtils.stub :render,
                                             lambda { |cont, _params, _site|
                                               captured_content = cont
                                               '<figure>mock</figure>'
                                             } do
      render_tag('author_last="Doe"', content)
    end

    assert_equal content, captured_content
  end

  # --- Tests for Markdown Mode Dedenting and Re-indentation ---

  def test_markdown_mode_dedents_indented_content
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse(
      "{% citedquote author_last=\"Doe\" %}\n    Line one\n    Line two\n{% endcitedquote %}",
    )
    output = template.render!(md_context)

    # Both content lines should be dedented in the blockquote
    assert_includes output, '> Line one'
    assert_includes output, '> Line two'
    refute_includes output, '>     Line two'
  end

  def test_markdown_mode_reindents_output_for_footnote_context
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse(
      "{% citedquote author_last=\"Doe\" %}\n    Line one\n    Line two\n{% endcitedquote %}",
    )
    output = template.render!(md_context)
    lines = output.lines.map(&:rstrip)

    # First line: no indent (template literal provides it in real usage)
    assert_match(/^> /, lines.first)
    # Subsequent non-empty lines: 4-space indent (matching detected content indent)
    lines[1..].each do |line|
      next if line.strip.empty?

      assert_match(/^    /, line, "Expected 4-space indent: #{line.inspect}")
    end
  end

  def test_markdown_mode_no_reindent_when_content_at_column_zero
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    template = Liquid::Template.parse(
      "{% citedquote author_last=\"Doe\" %}Line one\nLine two{% endcitedquote %}",
    )
    output = template.render!(md_context)

    # No re-indentation when content has no common indent
    output.lines.each do |line|
      refute_match(/^    /, line, "Expected no indent: #{line.inspect}")
    end
  end

  def test_markdown_mode_footnote_integration
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    # Simulate a footnote: [^fn]: followed by the tag indented 4 spaces
    template = Liquid::Template.parse(
      "[^fn]:\n    {% citedquote author_last=\"Doe\" %}\n    Quote text here\n    {% endcitedquote %}",
    )
    output = template.render!(md_context)
    lines = output.lines.map(&:rstrip)

    # All non-empty lines after [^fn]: should be indented 4 spaces
    # to remain inside the footnote scope
    lines[1..].each do |line|
      next if line.strip.empty?

      assert_match(
        /^    /,
        line,
        "Footnote continuation line must be indented 4 spaces: #{line.inspect}",
      )
    end
  end

  # --- Tests for Mixed Indentation (inline first line) ---

  def markdown_context
    create_context({}, { site: @site, page: create_doc({}, '/test.html'), render_mode: :markdown })
  end

  def render_unstubbed(source, context)
    Jekyll.stub :logger, @silent_logger_stub do
      Liquid::Template.parse(source).render!(context)
    end
  end

  def test_html_mode_keeps_inline_first_line_whole
    output = render_unstubbed(
      "{% citedquote author_last=\"Doe\" %}First line\n    Indented line{% endcitedquote %}", @context,
    )
    assert_includes output, 'First line'
    assert_includes output, 'Indented line'
    refute_match(/(?<!Firs)t line/, output)
  end

  def test_markdown_mode_keeps_inline_first_line_whole
    output = render_unstubbed(
      "{% citedquote author_last=\"Doe\" %}First line\n    Indented line{% endcitedquote %}", markdown_context,
    )
    assert_includes output, '> First line'
    assert_includes output, '> Indented line'
  end

  def test_markdown_mode_inline_footnote_reindents_continuation_lines
    output = render_unstubbed(
      "[^fn]: {% citedquote author_last=\"Doe\" %}Quote first\n    Quote second\n    {% endcitedquote %}",
      markdown_context,
    )
    lines = output.lines.map(&:rstrip)

    assert_equal '[^fn]: > Quote first', lines.first
    assert_includes lines, '    > Quote second'
    lines[1..].each do |line|
      next if line.strip.empty?

      assert_match(/^    /, line, "Footnote continuation line must be indented 4 spaces: #{line.inspect}")
    end
  end

  def test_less_indented_later_line_loses_no_characters
    source = "{% citedquote author_last=\"Doe\" %}\n    Alpha line\n    Beta line\nGamma line\n{% endcitedquote %}"

    html = render_unstubbed(source, @context)
    markdown = render_unstubbed(source, markdown_context)

    assert_includes html, 'Gamma line'
    assert_includes markdown, '> Gamma line'
    assert_includes markdown, 'Alpha line'
  end
end
