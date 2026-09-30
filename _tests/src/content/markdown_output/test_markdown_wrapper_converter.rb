# frozen_string_literal: true

require_relative '../../../test_helper'
require_relative '../../../../_plugins/src/content/markdown_output/markdown_wrapper_converter'

# Tests balanced conversion of supported span and div wrappers.
class TestMarkdownWrapperConverter < Minitest::Test
  WrapperConverter = Jekyll::MarkdownOutput::MarkdownWrapperConverter

  def test_supported_span_classes_preserve_the_contents
    %w[author-name book-series written-by nowrap band-name].each do |name|
      assert_equal 'Text', WrapperConverter.convert("<span class=\"#{name}\">Text</span>"), name
    end
  end

  def test_strips_nested_supported_spans
    input = '<span id="title" class="nowrap highlighted">Listen to ' \
            '<span class="band-name">The Beatles</span>.</span>'

    assert_equal 'Listen to The Beatles.', WrapperConverter.convert(input)
  end

  def test_keeps_unknown_outer_div_around_written_by_paragraphs
    input = '<div class="other"><div class="written-by">by Author</div>After.</div>'

    assert_equal "<div class=\"other\">\n\nby Author\n\nAfter.</div>", WrapperConverter.convert(input)
  end

  def test_strips_supported_chatgpt_divs_only
    input = '<div class="chatgpt-edit-block"><div class="chatgpt-output-only">Answer</div></div>'

    assert_equal 'Answer', WrapperConverter.convert(input)
  end

  def test_preserves_similar_tag_names_and_malformed_wrappers
    input = '<span-other class="nowrap">one</span-other> ' \
            '<div-other class="written-by">two</div-other> ' \
            '<span class="nowrap">open'

    assert_equal input, WrapperConverter.convert(input)
    [
      '<div class="written-by">by Author</span>',
      '<div class="other"><span class="band-name">Author</div>',
    ].each do |malformed|
      assert_equal malformed, WrapperConverter.convert(malformed)
    end
  end
end
