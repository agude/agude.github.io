# frozen_string_literal: true

# _tests/plugins/test_citation_tag.rb
require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/citation_tag' # Load the tag

# Tests for Jekyll::UI::Tags::CitationTag Liquid tag.
#
# Verifies that the tag correctly renders book citations with proper formatting.
class TestCitationTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context(
      {
        'page_author_last' => 'PageLast',
        'page_author_first' => 'PageFirst',
        'page_title' => 'Page Title Variable',
        'nil_var' => nil
      },
      { site: @site }
    )
  end

  # Helper to render the tag
  def render_tag(markup_inside_tag, context = @context)
    Liquid::Template.parse("{% citation #{markup_inside_tag} %}").render!(context)
  end

  # --- Tests for initialize (Argument Parsing - Syntax Errors) ---
  # These test if Liquid::Template.parse raises SyntaxError, which means initialize failed.

  def test_initialize_syntax_error_for_invalid_arguments_near
    markup = "author_last=\"Doe\" title='Article' bad_arg_format"
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% citation #{markup} %}")
    end
    assert_match "Invalid arguments near 'bad_arg_format'", err.message
  end

  def test_initialize_syntax_error_for_equals_without_value
    markup = 'author_last='
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% citation #{markup} %}")
    end
    assert_match(/Syntax Error in 'citation' tag: Invalid arguments near 'author_last=' in 'author_last='/,
                 err.message)
  end

  def test_initialize_syntax_error_for_value_without_key_equals
    markup = '"JustAValue"' # Not key=value
    err = assert_raises Liquid::SyntaxError do
      Liquid::Template.parse("{% citation #{markup} %}")
    end
    assert_match "Invalid arguments near '\"JustAValue\"'", err.message
  end

  # --- Tests for render (Value Resolution and Delegation) ---
  # These tests implicitly verify that initialize parsed correctly if render behaves.

  def test_render_parses_and_resolves_quoted_string_arguments
    markup = "author_last=\"Doe\" work_title='An Article'"
    expected_resolved_params = {
      author_last: 'Doe',
      work_title: 'An Article'
    }
    mock_output_html = '<cite>Doe, An Article</cite>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup)
      assert_equal mock_output_html, output
    end

    refute_nil captured_args, 'Jekyll::UI::Citations::CitationUtils.format_citation_html should have been called'
    assert_equal expected_resolved_params, captured_args[:params]
    assert_equal @site, captured_args[:site]
  end

  def test_render_parses_and_resolves_unquoted_variable_arguments
    markup = 'author_last=page_author_last work_title=page_title'
    expected_resolved_params = {
      author_last: 'PageLast',
      work_title: 'Page Title Variable'
    }
    mock_output_html = '<span>Resolved Vars Citation</span>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup)
      assert_equal mock_output_html, output
    end

    refute_nil captured_args
    assert_equal expected_resolved_params, captured_args[:params]
    assert_equal @site, captured_args[:site]
  end

  def test_render_parses_and_resolves_mixed_arguments_and_spacing
    markup = "  author_last = \"Doe\"   work_title=page_title editor = 'The Editor'  "
    expected_resolved_params = {
      author_last: 'Doe',
      work_title: 'Page Title Variable',
      editor: 'The Editor'
    }
    mock_output_html = '<span>Mixed Args Citation</span>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup)
      assert_equal mock_output_html, output
    end

    refute_nil captured_args
    assert_equal expected_resolved_params, captured_args[:params]
  end

  def test_render_resolves_nil_variable_correctly
    markup = "author_last=nil_var work_title='Test'" # nil_var resolves to nil
    expected_resolved_params = {
      author_last: nil,
      work_title: 'Test'
    }
    mock_output_html = '<span>Nil Var Citation</span>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup)
      assert_equal mock_output_html, output
    end

    refute_nil captured_args
    assert_equal expected_resolved_params, captured_args[:params]
  end

  def test_render_with_all_possible_param_types_delegates_correctly
    markup = "author_last='Doe' author_first='John' author_handle='@jdoe' " \
             "work_title='Work' container_title='Container' editor='Ed' " \
             "edition='2nd' volume='X' number='1' publisher='Pub' " \
             "date='2023' first_page='10' last_page='20' page='15' " \
             "doi='10.123' url='http://example.com' access_date='Today'"
    expected_resolved_params = {
      author_last: 'Doe', author_first: 'John', author_handle: '@jdoe',
      work_title: 'Work', container_title: 'Container', editor: 'Ed',
      edition: '2nd', volume: 'X', number: '1', publisher: 'Pub',
      date: '2023', first_page: '10', last_page: '20', page: '15',
      doi: '10.123', url: 'http://example.com', access_date: 'Today'
    }
    mock_output_html = '<span>Full Citation</span>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup)
      assert_equal mock_output_html, output
    end

    refute_nil captured_args
    assert_equal expected_resolved_params, captured_args[:params]
    assert_equal @site, captured_args[:site]
  end

  def test_render_no_arguments_passed_to_tag
    markup = '' # Empty markup string for the tag's content
    expected_resolved_params = {}
    mock_output_html = '<span>Empty Citation</span>'

    captured_args = nil
    Jekyll::UI::Citations::CitationUtils.stub :format_citation_html, lambda { |params, site|
      captured_args = { params: params, site: site }
      mock_output_html
    } do
      output = render_tag(markup) # Pass the empty markup here
      assert_equal mock_output_html, output
    end

    refute_nil captured_args
    assert_equal expected_resolved_params, captured_args[:params]
  end
end
