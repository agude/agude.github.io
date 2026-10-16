# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/cite_title_tag'

# Tests for the Jekyll::UI::Tags::CiteTitleTag base class: argument parsing
# and both render modes. Uses a test-only subclass, so these cases belong
# to the base class alone. Each subclass's test file checks only its
# registered name and CSS class.
class TestCiteTitleTag < Minitest::Test
  # Minimal concrete subclass for exercising the base class.
  class SampleTitleTag < Jekyll::UI::Tags::CiteTitleTag
    def self.css_class
      'sample-title'
    end
  end

  Liquid::Template.register_tag('sample_title', SampleTitleTag)

  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  # --- HTML Mode ---

  def test_html_output_double_quotes
    output = Liquid::Template.parse('{% sample_title "The Matrix" %}').render!(@context)
    assert_equal '<cite class="sample-title">The Matrix</cite>', output
  end

  def test_html_output_single_quotes
    output = Liquid::Template.parse("{% sample_title 'The Matrix' %}").render!(@context)
    assert_equal '<cite class="sample-title">The Matrix</cite>', output
  end

  def test_html_variable_resolution
    @context['my_movie'] = 'Blade Runner'
    output = Liquid::Template.parse('{% sample_title my_movie %}').render!(@context)
    assert_equal '<cite class="sample-title">Blade Runner</cite>', output
  end

  # --- Markdown Mode ---

  def test_markdown_output
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% sample_title "The Matrix" %}').render!(md_context)
    assert_equal '_The Matrix_', output
  end

  # --- Edge Cases ---

  def test_nil_variable_renders_empty
    output = Liquid::Template.parse('{% sample_title nonexistent_var %}').render!(@context)
    assert_equal '', output
  end

  def test_syntax_error_no_argument
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse('{% sample_title %}')
    end
  end
end
