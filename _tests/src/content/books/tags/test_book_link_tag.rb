# frozen_string_literal: true

# _tests/plugins/test_book_link_tag.rb
require_relative '../../../../test_helper'
require_relative '../../../../../_plugins/src/content/books/tags/book_link_tag' # Load the tag

# Tests for Jekyll::Books::Tags::BookLinkTag Liquid tag.
#
# Verifies that the tag correctly renders book links with author disambiguation and cite toggle.
class TestBookLinkTag < Minitest::Test
  def setup
    # Setup for parsing tests
    @parsing_site = create_site
    @parsing_context = create_context(
      {
        'page_book_title' => 'Variable Book Title',
        'page_link_text' => 'Variable Link Text for Book',
        'page_author' => 'Variable Author',
        'page_cite' => false,
        'nil_var' => nil,
        'empty_string_var' => '',
      },
      { site: @parsing_site, page: create_doc({}, '/current.html') },
    )

    # --- Setup for Integration Test ---
    @integration_book = create_doc(
      { 'title' => 'Hyperion', 'published' => true, 'book_authors' => ['Dan Simmons'] },
      '/books/hyperion-simmons.html',
    )
    @integration_site = create_site(
      {},
      { 'books' => [@integration_book] },
      [], # No author pages needed for this simple test
    )
    @integration_site.config['plugin_logging']['RENDER_BOOK_LINK'] = true
    @integration_context = create_context(
      {},
      {
        site: @integration_site,
        page: create_doc(
          { 'path' => 'integration_test.md' },
          '/integration.html',
        ),
      },
    )
    @silent_logger_stub = Object.new.tap do |logger|
      def logger.warn(topic, message); end

      def logger.error(topic, message); end

      def logger.info(topic, message); end

      def logger.debug(topic, message); end
    end
  end

  # Helper to parse the tag and capture arguments passed to the utility
  def parse_and_capture_args(markup, context = @parsing_context)
    captured_args = nil
    # Stub the utility function to capture all arguments
    # The signature is (title, ctx, link_text, author, date, cite:)
    Jekyll::Books::Core::BookLinkUtils.stub :render_book_link,
                                            lambda { |title, ctx, link_text_override, author_filter, date_filter = nil, cite: true|
                                              captured_args = {
                                                title: title,
                                                context: ctx,
                                                link_text_override: link_text_override,
                                                author_filter: author_filter,
                                                date_filter: date_filter,
                                                cite: cite,
                                              }
                                              '<!-- Util called -->'
                                            } do
      template = Liquid::Template.parse("{% book_link #{markup} %}")
      output = template.render!(context)
      return output, captured_args
    end
  end

  # --- Syntax Error Tests (Initialize) ---
  def test_syntax_error_missing_book_title
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse('{% book_link %}')
    end
    assert_match 'Could not find book title', err.message
  end

  def test_render_book_title_empty_string_literal_passes_empty_to_util
    _output, captured_args = parse_and_capture_args("''")
    assert_equal '', captured_args[:title], "Tag should resolve '' to an empty string for the utility"
    assert_nil captured_args[:link_text_override]
  end

  def test_syntax_error_unknown_argument
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_link 'My Book' unknown_arg='test' %}")
    end
    assert_match "Unknown argument 'unknown_arg='test''", err.message
  end

  def test_syntax_error_malformed_link_text
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% book_link 'My Book' link_text 'bad' %}") # Missing =
    end
    assert_match "Unknown argument 'link_text'", err.message
  end

  # --- Argument Parsing and Delegation Tests (Render) ---
  def test_render_with_literal_title_only
    _output, captured_args = parse_and_capture_args("'The Great Gatsby'")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_nil captured_args[:link_text_override]
    assert_nil captured_args[:author_filter]
    assert_equal true, captured_args[:cite]
  end

  def test_render_with_variable_title_only
    _output, captured_args = parse_and_capture_args('page_book_title') # 'Variable Book Title'
    assert_equal 'Variable Book Title', captured_args[:title]
    assert_nil captured_args[:link_text_override]
    assert_nil captured_args[:author_filter]
    assert_equal true, captured_args[:cite]
  end

  def test_render_with_literal_title_and_literal_link_text
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' link_text='Gatsby'")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_equal 'Gatsby', captured_args[:link_text_override]
    assert_nil captured_args[:author_filter]
  end

  def test_render_with_literal_title_and_author
    _output, captured_args = parse_and_capture_args("'Ambiguous Title' author='An Author'")
    assert_equal 'Ambiguous Title', captured_args[:title]
    assert_nil captured_args[:link_text_override]
    assert_equal 'An Author', captured_args[:author_filter]
  end

  def test_render_with_literal_title_and_cite_false
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' cite=false")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_equal false, captured_args[:cite]
  end

  def test_render_with_cite_true_explicit
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' cite=true")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_equal true, captured_args[:cite]
  end

  def test_render_with_cite_false_as_quoted_string
    # cite='false' (string) should still be treated as false
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' cite='false'")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_equal false, captured_args[:cite]
  end

  def test_render_with_cite_nil_variable_defaults_to_true
    # When cite= references a nil variable, should default to true
    _output, captured_args = parse_and_capture_args("'The Great Gatsby' cite=nil_var")
    assert_equal 'The Great Gatsby', captured_args[:title]
    assert_equal true, captured_args[:cite]
  end

  def test_render_with_all_parameters_as_variables_including_cite
    _output, captured_args = parse_and_capture_args('page_book_title link_text=page_link_text author=page_author cite=page_cite')
    assert_equal 'Variable Book Title', captured_args[:title]
    assert_equal 'Variable Link Text for Book', captured_args[:link_text_override]
    assert_equal 'Variable Author', captured_args[:author_filter]
    assert_equal false, captured_args[:cite]
  end

  def test_render_with_arguments_in_different_order
    # Arguments should work regardless of order: author before link_text, cite in middle
    _output, captured_args = parse_and_capture_args("'Title' author='Author' cite=false link_text='Text'")
    assert_equal 'Title', captured_args[:title]
    assert_equal 'Text', captured_args[:link_text_override]
    assert_equal 'Author', captured_args[:author_filter]
    assert_equal false, captured_args[:cite]
  end

  def test_render_author_filter_resolves_to_nil
    _output, captured_args = parse_and_capture_args("'Some Book' author=nil_var")
    assert_equal 'Some Book', captured_args[:title]
    assert_nil captured_args[:author_filter]
  end

  def test_render_book_title_resolves_to_nil
    _output, captured_args = parse_and_capture_args('nil_var') # nil_var is nil
    assert_nil captured_args[:title]
  end

  def test_render_book_title_resolves_to_empty_string_from_variable
    _output, captured_args = parse_and_capture_args('empty_string_var') # empty_string_var is ''
    assert_equal '', captured_args[:title]
  end

  def test_integration_tag_and_util_work_together
    Jekyll.stub :logger, @silent_logger_stub do
      # Case 1: Correct author, should link with citation (default)
      template_correct = Liquid::Template.parse("{% book_link 'Hyperion' author='Dan Simmons' %}")
      output_correct = template_correct.render!(@integration_context)
      expected_output = '<a href="/books/hyperion-simmons.html"><cite class="book-title">Hyperion</cite></a>'
      assert_equal expected_output, output_correct

      # Case 2: Incorrect author, should NOT link and should log a warning
      template_incorrect = Liquid::Template.parse("{% book_link 'Hyperion' author='John Keats' %}")
      output_incorrect = template_incorrect.render!(@integration_context)
      expected_pattern = %r{<!-- \[WARN\] RENDER_BOOK_LINK_FAILURE: Reason='Book title exists, but not by the specified author.'.*?--><cite class="book-title">Hyperion</cite>}
      assert_match expected_pattern, output_incorrect

      # Case 3: cite=false, should render span.book-text instead of cite
      template_no_cite = Liquid::Template.parse("{% book_link 'Hyperion' author='Dan Simmons' cite=false %}")
      output_no_cite = template_no_cite.render!(@integration_context)
      expected_no_cite_output = '<a href="/books/hyperion-simmons.html"><span class="book-text">Hyperion</span></a>'
      assert_equal expected_no_cite_output, output_no_cite

      # Case 4: cite=false with MISSING book should still use span (not cite)
      template_missing = Liquid::Template.parse("{% book_link 'Nonexistent Book' cite=false %}")
      output_missing = template_missing.render!(@integration_context)
      assert_match %r{<span class="book-text">Nonexistent Book</span>}, output_missing
      refute_match(/<cite/, output_missing)

      # Case 5: cite=false with author mismatch (fallback) should still use span
      template_mismatch = Liquid::Template.parse("{% book_link 'Hyperion' author='Wrong Author' cite=false %}")
      output_mismatch = template_mismatch.render!(@integration_context)
      assert_match %r{<span class="book-text">Hyperion</span>}, output_mismatch
      refute_match(/<cite/, output_mismatch)
    end
  end

  # --- Markdown Mode Tests ---

  def test_markdown_mode_renders_markdown_link
    md_context = create_context(
      {},
      { site: @integration_site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    Jekyll.stub :logger, @silent_logger_stub do
      template = Liquid::Template.parse("{% book_link 'Hyperion' author='Dan Simmons' %}")
      output = template.render!(md_context)
      assert_equal '[_Hyperion_](/books/hyperion-simmons.html)', output
    end
  end

  def test_markdown_mode_not_found_renders_plain_text
    md_context = create_context(
      {},
      { site: @integration_site, page: create_doc({}, '/test.html'), render_mode: :markdown },
    )
    Jekyll.stub :logger, @silent_logger_stub do
      template = Liquid::Template.parse("{% book_link 'Nonexistent Book' %}")
      output = template.render!(md_context)
      assert_equal '_Nonexistent Book_', output
    end
  end
end
