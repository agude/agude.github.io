# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/resume_skills_tag'

# Tests for Jekyll::UI::Tags::ResumeSkillsTag Liquid tag.
class TestResumeSkillsTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def render_tag(markup)
    Liquid::Template.parse("{% resume_skills #{markup} %}").render!(@context)
  end

  # --- HTML Mode ---

  def test_html_output
    output = render_tag('languages="Python, SQL" tools="NumPy, git"')
    assert_includes output, '<div class="resume-skills-grid">'
    assert_includes output, '<strong>Languages</strong>'
    assert_includes output, '<strong>Tools</strong>'
    assert_includes output, 'resume-languages'
    assert_includes output, 'resume-tools'
  end

  def test_html_values_in_output
    output = render_tag('languages="Python" tools="git"')
    assert_includes output, 'Python'
    assert_includes output, 'git'
    assert_includes output, 'resume-languages'
    assert_includes output, 'resume-tools'
  end

  # --- Markdown Mode ---

  def test_markdown_output
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse('{% resume_skills languages="Python, SQL" tools="NumPy, git" %}')
    output = template.render!(md_context)
    assert_includes output, '- **Languages**: Python, SQL'
    assert_includes output, '- **Tools**: NumPy, git'
  end

  def test_markdown_strips_html
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse(
      '{% resume_skills languages=\'Python, <span class="latex">LaTeX</span>\' tools="git" %}',
    )
    output = template.render!(md_context)
    assert_includes output, '- **Languages**: Python, LaTeX'
    refute_match(/<span/, output)
  end

  def test_markdown_no_html_tags
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse('{% resume_skills languages="Python" tools="git" %}')
    output = template.render!(md_context)
    refute_match(/<div/, output)
  end

  # --- Syntax errors ---

  def test_syntax_error_invalid_markup
    assert_raises(Liquid::SyntaxError) do
      Liquid::Template.parse('{% resume_skills garbage %}')
    end
  end
end
