# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/inline_svg_validator'

# Tests for InlineSvgValidator: every inline <svg> is hidden or named.
class TestInlineSvgValidator < Minitest::Test
  Validator = Jekyll::Infrastructure::InlineSvgValidator

  def validate(html)
    Validator.validate(html, source: 'linktree.md')
  end

  def test_hidden_svg_passes
    assert_nil validate('<a href="/"><svg class="globe" aria-hidden="true"><path d="M0"/></svg> Site</a>')
  end

  def test_named_image_svg_passes
    assert_nil validate('<svg role="img" aria-label="Logo"></svg>')
  end

  def test_unhidden_svg_fails_and_names_its_class
    error = assert_raises(Jekyll::Errors::FatalException) { validate('<svg class="globe" viewBox="0 0 1 1"></svg>') }
    assert_includes error.message, '<svg class="globe">'
    assert_includes error.message, 'linktree.md'
  end

  def test_svg_without_class_is_described
    error = assert_raises(Jekyll::Errors::FatalException) { validate('<svg></svg>') }
    assert_includes error.message, '<svg> with no class'
  end

  def test_false_and_valueless_aria_hidden_fail
    ['<svg aria-hidden="false"></svg>', '<svg aria-hidden></svg>'].each do |html|
      assert_raises(Jekyll::Errors::FatalException) { validate(html) }
    end
  end

  def test_role_img_needs_a_non_empty_label
    ['<svg role="img"></svg>', '<svg role="img" aria-label="  "></svg>'].each do |html|
      assert_raises(Jekyll::Errors::FatalException) { validate(html) }
    end
  end

  def test_attribute_text_inside_quoted_value_does_not_count
    assert_raises(Jekyll::Errors::FatalException) { validate(%(<svg data-x='aria-hidden="true"'></svg>)) }
  end

  def test_svg_in_comment_and_script_is_ignored
    assert_nil validate('<!-- <svg></svg> --><script>"<svg>"</script>')
  end

  def test_applies_only_to_html_with_svg
    item = ->(ext, output) { Struct.new(:output_ext, :output).new(ext, output) }
    assert Validator.applies_to?(item.call('.html', '<svg aria-hidden="true">'))
    refute Validator.applies_to?(item.call('.html', '<p>x</p>'))
    refute Validator.applies_to?(item.call('.xml', '<svg>'))
  end
end
