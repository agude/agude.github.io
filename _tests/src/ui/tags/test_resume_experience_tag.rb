# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/ui/tags/resume_experience_tag'

# Tests for Jekyll::UI::Tags::ResumeExperienceTag Liquid tag.
class TestResumeExperienceTag < Minitest::Test
  def setup
    @site = create_site
    @context = create_context({}, { site: @site })
  end

  def render_tag(markup)
    Liquid::Template.parse("{% resume_experience #{markup} %}").render!(@context)
  end

  # --- HTML Mode ---

  def test_html_basic_entry
    output = render_tag('company="Acme Corp" location="Remote" position="Engineer" dates="2020--2023"')
    assert_includes output, '<div class="resume-header-grid">'
    assert_includes output, '<div class="resume-company"><h3>Acme Corp</h3></div>'
    assert_includes output, '<div class="resume-location">Remote</div>'
    assert_includes output, '<div class="resume-position">Engineer</div>'
    assert_includes output, '<div class="resume-dates">'
    assert_includes output, '</div>'
  end

  def test_html_dates_in_output
    output = render_tag('company="Acme" location="NYC" position="Dev" dates="2020--2023"')
    assert_includes output, '2020--2023'
    assert_includes output, 'resume-dates'
  end

  def test_html_with_second_position
    output = render_tag(
      'company="Acme" location="Remote" position="Senior" dates="2023--Present" ' \
      'position_2="Junior" dates_2="2020--2023"',
    )
    # Both positions present
    assert_match(/Senior/, output)
    assert_match(/Junior/, output)
    # Second position also has dates
    occurrences = output.scan('resume-position').length
    assert_equal 2, occurrences
  end

  def test_html_without_second_position
    output = render_tag('company="Acme" location="Remote" position="Engineer" dates="2020--2023"')
    occurrences = output.scan('resume-position').length
    assert_equal 1, occurrences
  end

  # --- Markdown Mode ---

  def test_markdown_basic_entry
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse(
      '{% resume_experience company="Acme Corp" location="Remote" position="Engineer" dates="2020--2023" %}',
    )
    output = template.render!(md_context)
    assert_includes output, '### Acme Corp'
    assert_includes output, '**Engineer** | _2020--2023_ | Remote'
  end

  def test_markdown_with_second_position
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse(
      '{% resume_experience company="Acme" location="NYC" position="Senior" dates="2023--Present" ' \
      'position_2="Junior" dates_2="2020--2023" %}',
    )
    output = template.render!(md_context)
    assert_includes output, '### Acme'
    assert_includes output, '**Senior** | _2023--Present_ | NYC'
    assert_includes output, '**Junior** | _2020--2023_'
  end

  def test_markdown_no_html_tags
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse(
      '{% resume_experience company="Acme" location="Remote" position="Dev" dates="2020--2023" %}',
    )
    output = template.render!(md_context)
    refute_match(/<div/, output)
  end

  # --- Variable resolution ---

  def test_variable_resolution
    @context['my_company'] = 'Dynamic Corp'
    output = render_tag('company=my_company location="Remote" position="Dev" dates="2020--2023"')
    assert_includes output, 'Dynamic Corp'
  end

  # --- Syntax errors ---

  def parse_error(markup)
    assert_raises(Liquid::SyntaxError) { Liquid::Template.parse("{% resume_experience #{markup} %}") }.message
  end

  def test_syntax_error_missing_required_param
    assert_equal "Liquid syntax error: Syntax Error in 'resume_experience': Required argument 'location' is missing.",
                 parse_error('company="Acme" position="Dev"')
  end

  def test_syntax_error_unknown_argument
    assert_equal "Liquid syntax error: Syntax Error in 'resume_experience': Unknown argument 'title'.",
                 parse_error('company="Acme" location="Remote" position="Dev" title="Lead"')
  end

  def test_syntax_error_duplicate_argument
    assert_equal "Liquid syntax error: Syntax Error in 'resume_experience': Duplicate argument 'dates'.",
                 parse_error('company="Acme" location="Remote" position="Dev" dates="2020" dates="2021"')
  end

  def test_empty_required_value_raises_at_render
    markup = 'company="Acme" location=missing_var position=""'
    err = assert_raises(Liquid::SyntaxError) { render_tag(markup) }
    assert_equal "Liquid syntax error: Syntax Error in 'resume_experience': Missing required argument " \
                 "'location' in '#{markup}'",
                 err.message
  end

  # --- Optional dates ---

  def test_html_without_dates
    output = render_tag('company="Acme" location="Remote" position="Dev"')
    assert_includes output, '<div class="resume-header-grid">'
    assert_includes output, 'resume-position'
  end

  def test_markdown_without_dates
    md_context = create_context({}, { site: @site, render_mode: :markdown })
    template = Liquid::Template.parse(
      '{% resume_experience company="Acme" location="Remote" position="Dev" %}',
    )
    output = template.render!(md_context)
    assert_includes output, '**Dev** | Remote'
    refute_includes output, '__'
  end

  def test_syntax_error_invalid_markup
    assert_equal "Liquid syntax error: Syntax Error in 'resume_experience': " \
                 "Invalid argument syntax near 'not_valid_syntax'.",
                 parse_error('not_valid_syntax')
  end
end
