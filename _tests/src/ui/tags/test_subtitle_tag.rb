# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/subtitle_tag'

# Tests for Jekyll::UI::Tags::SubtitleTag Liquid tag.
class TestSubtitleTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  # --- HTML Mode ---

  def test_html_output_double_quotes
    output = Liquid::Template.parse('{% subtitle "Staff Engineer" %}').render!(@context)
    assert_equal '<div class="subtitle">Staff Engineer</div>', output
  end

  def test_html_output_single_quotes
    output = Liquid::Template.parse("{% subtitle 'Staff Engineer' %}").render!(@context)
    assert_equal '<div class="subtitle">Staff Engineer</div>', output
  end

  def test_html_variable_resolution
    @context['my_title'] = 'Data Scientist'
    output = Liquid::Template.parse('{% subtitle my_title %}').render!(@context)
    assert_equal '<div class="subtitle">Data Scientist</div>', output
  end

  # --- Markdown Mode ---

  def test_markdown_output
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% subtitle "Staff Engineer" %}').render!(md_context)
    assert_equal '**Staff Engineer**', output
  end

  def test_markdown_no_html
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% subtitle "Staff Engineer" %}').render!(md_context)
    refute_match(/<div/, output)
  end

  # --- Edge cases ---

  def test_nil_variable_renders_empty
    output = Liquid::Template.parse('{% subtitle nonexistent_var %}').render!(@context)
    assert_equal '', output
  end

  def test_syntax_error_no_argument
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse('{% subtitle %}')
    end
  end
end
