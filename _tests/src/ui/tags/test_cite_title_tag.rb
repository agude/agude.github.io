# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/movie_title_tag'

# Tests for Jekyll::UI::Tags::CiteTitleTag base class, using MovieTitleTag as
# the concrete implementation.
class TestCiteTitleTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  # --- HTML Mode ---

  def test_html_output_double_quotes
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(@context)
    assert_equal '<cite class="movie-title">The Matrix</cite>', output
  end

  def test_html_output_single_quotes
    output = Liquid::Template.parse("{% movie_title 'The Matrix' %}").render!(@context)
    assert_equal '<cite class="movie-title">The Matrix</cite>', output
  end

  def test_html_variable_resolution
    @context['my_movie'] = 'Blade Runner'
    output = Liquid::Template.parse('{% movie_title my_movie %}').render!(@context)
    assert_equal '<cite class="movie-title">Blade Runner</cite>', output
  end

  # --- Markdown Mode ---

  def test_markdown_output
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(md_context)
    assert_equal '_The Matrix_', output
  end

  def test_markdown_no_html
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    output = Liquid::Template.parse('{% movie_title "The Matrix" %}').render!(md_context)
    refute_match(/<cite/, output)
  end

  # --- Edge Cases ---

  def test_nil_variable_renders_empty
    output = Liquid::Template.parse('{% movie_title nonexistent_var %}').render!(@context)
    assert_equal '', output
  end

  def test_syntax_error_no_argument
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse('{% movie_title %}')
    end
  end
end
