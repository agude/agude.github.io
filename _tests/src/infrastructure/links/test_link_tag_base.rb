# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/infrastructure/links/link_tag_base'

# Tests for Jekyll::Infrastructure::Links::LinkTagBase.
#
# Verifies the declarative option-table parsing (positional subject, :value
# and :flag options, unknown-argument and empty-subject errors) and the
# render_mode branching shared by all link tags, using a dummy subclass.
class TestLinkTagBase < Minitest::Test
  # Captures resolver calls so tests can assert on the arguments the base
  # class passes through.
  class FakeResolver
    class << self
      attr_accessor :last_instance
    end

    attr_reader :calls

    def initialize(_context)
      @calls = []
      self.class.last_instance = self
    end

    def resolve(*args, **kwargs)
      @calls << [:resolve, args, kwargs]
      '<span>html</span>'
    end

    def resolve_data(*args, **kwargs)
      @calls << [:resolve_data, args, kwargs]
      { status: :found, url: '/widgets/x.html', display_text: 'Widget X' }.freeze
    end
  end

  # Minimal subclass exercising every option type.
  class WidgetLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
    self.subject = 'widget name'
    self.resolver_class = FakeResolver
    self.option_spec = { link_text: :value, cite: :value, possessive: :flag }

    private

    def resolver_arguments(context)
      positional = [subject_value(context), option_value(:link_text, context), flag?(:possessive)]
      [positional, { cite: option_enabled?(:cite, context) }]
    end
  end

  # Subclass that does not implement the required resolver_arguments hook.
  class BareLinkTag < Jekyll::Infrastructure::Links::LinkTagBase
    self.subject = 'thing'
    self.resolver_class = FakeResolver
    self.option_spec = {}
  end

  Liquid::Template.register_tag('widget_link', WidgetLinkTag)
  Liquid::Template.register_tag('bare_link', BareLinkTag)

  def setup
    @site = create_site
    @context = create_context(
      { 'widget_var' => 'Variable Widget', 'false_var' => false },
      { site: @site, page: create_doc({}, '/current.html') },
    )
  end

  def render_tag(markup, context = @context)
    output = Liquid::Template.parse("{% widget_link #{markup} %}").render!(context)
    [output, FakeResolver.last_instance.calls.last]
  end

  # --- Parsing ---

  def test_parses_quoted_subject_and_defaults
    _output, (method, args, kwargs) = render_tag("'My Widget'")
    assert_equal :resolve, method
    assert_equal ['My Widget', nil, false], args
    assert_equal({ cite: true }, kwargs)
  end

  def test_parses_variable_subject
    _output, (_method, args, _kwargs) = render_tag('widget_var')
    assert_equal 'Variable Widget', args.first
  end

  def test_parses_options_in_any_order
    _output, (_method, args, kwargs) = render_tag("'W' possessive cite=false link_text='Text'")
    assert_equal ['W', 'Text', true], args
    assert_equal({ cite: false }, kwargs)
  end

  def test_repeated_value_option_takes_first_occurrence
    _output, (_method, args, _kwargs) = render_tag("'W' link_text='First' link_text='Second'")
    assert_equal 'First', args[1]
  end

  def test_option_enabled_false_variable
    _output, (_method, _args, kwargs) = render_tag("'W' cite=false_var")
    assert_equal({ cite: false }, kwargs)
  end

  def test_option_enabled_quoted_false_string
    _output, (_method, _args, kwargs) = render_tag("'W' cite='false'")
    assert_equal({ cite: false }, kwargs)
  end

  # --- Syntax errors ---

  def test_syntax_error_missing_subject
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse('{% widget_link %}') }
    assert_match 'Could not find widget name', err.message
  end

  def test_syntax_error_empty_quoted_subject
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% widget_link '' %}") }
    assert_match 'Widget name value is missing or empty', err.message
  end

  def test_syntax_error_whitespace_quoted_subject
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse('{% widget_link "   " %}') }
    assert_match 'Widget name value is missing or empty', err.message
  end

  def test_syntax_error_unknown_argument
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% widget_link 'W' bogus='x' %}") }
    assert_match "Unknown argument 'bogus='x''", err.message
  end

  def test_syntax_error_value_option_without_equals
    err = assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% widget_link 'W' link_text 'x' %}") }
    assert_match "Unknown argument 'link_text'", err.message
  end

  # --- Render branching ---

  def test_html_mode_delegates_to_resolve
    output, (method, _args, _kwargs) = render_tag("'My Widget'")
    assert_equal :resolve, method
    assert_equal '<span>html</span>', output
  end

  def test_markdown_mode_delegates_to_resolve_data_and_formats_link
    md_context = create_context(
      {},
      { site: @site, page: create_doc({}, '/current.html'), render_mode: :markdown },
    )
    output, (method, _args, _kwargs) = render_tag("'My Widget'", md_context)
    assert_equal :resolve_data, method
    assert_equal '[Widget X](/widgets/x.html)', output
  end

  def test_resolver_arguments_hook_is_required
    template = Liquid::Template.parse("{% bare_link 'X' %}")
    assert_raises(NotImplementedError) { template.render!(@context) }
  end
end
