# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/html_attributes'

# Tests for HtmlAttributes: attribute names and values of one start tag.
class TestHtmlAttributes < Minitest::Test
  def attributes(tag)
    Jekyll::Infrastructure::HtmlAttributes.parse(tag)
  end

  def test_quote_styles_and_valueless_attribute
    expected = { 'a' => '1', 'b' => '2', 'c' => '3', 'hidden' => nil }
    assert_equal expected, attributes(%(<div a="1" b='2' c=3 hidden>))
  end

  def test_names_are_lowercased_and_first_occurrence_wins
    assert_equal({ 'role' => 'one' }, attributes('<pre ROLE="one" role="two">'))
  end

  def test_text_inside_quoted_value_is_not_an_attribute
    assert_equal({ 'title' => 'The role= token' }, attributes('<pre title="The role= token">'))
  end

  def test_values_are_entity_decoded
    assert_equal({ 'alt' => 'A & B' }, attributes('<img alt="A &amp; B" />'))
  end

  def test_tag_name_is_not_an_attribute
    assert_empty attributes('<pre>')
    assert_empty attributes('<br/>')
    assert_equal({ 'class' => 'x' }, attributes("<pre\n  class=\"x\"\n>"))
  end

  # --- remove ---

  def test_remove_drops_the_attribute_and_its_leading_space
    assert_equal '<img src="/a.png" alt="A" />',
                 Jekyll::Infrastructure::HtmlAttributes.remove('<img src="/a.png" sizes="auto, 80px" alt="A" />', 'sizes')
  end

  def test_remove_leaves_text_inside_another_value
    tag = %(<img alt="chart sizes=large" SIZES='80px' title=sizes>)
    assert_equal '<img alt="chart sizes=large" title=sizes>', Jekyll::Infrastructure::HtmlAttributes.remove(tag, 'sizes')
  end
end
