# frozen_string_literal: true

require_relative '../../test_helper'
require_relative '../../support/property_test'

# Generated checks for the supported whitespace-normalization grammar.
class TestMarkdownWhitespaceNormalizerProperties < Minitest::Test
  include PropertyTestSupport

  G = PropCheck::Generators
  Normalizer = Jekyll::Infrastructure::MarkdownWhitespaceNormalizer

  ProseLine = Struct.new(:text, :suffix, :suffix_kind, keyword_init: true)
  ProtectedBlock = Struct.new(:bytes, :kind, keyword_init: true)
  Fixture = Struct.new(:source, :expected, :protected_bytes, keyword_init: true)

  PROSE_TEXTS = %w[Opening paragraph. Later sentence. Markdown remains.].freeze
  CODE_LINES = ['value = 1  ', 'puts "kept"\t', '``` is content  '].freeze
  HTML_LINES = ['raw text  ', 'nested value\t', 'blank-safe content'].freeze
  COMMENT_LINES = ['comment text  ', '[not a link][inside]', 'tabbed text\t'].freeze

  def test_property_normalizes_generated_prose_around_protected_blocks_and_eof
    check_property(normalizer_fixture_generator, seed: 5401) do |fixture|
      normalized = Normalizer.normalize(fixture.source)

      assert_equal fixture.expected, normalized, fixture.source.inspect
      assert_includes normalized, fixture.protected_bytes, fixture.source.inspect
      assert_equal normalized, Normalizer.normalize(normalized), fixture.source.inspect
    end
  end

  def test_property_preserves_a_truncated_fence_at_eof_without_a_newline
    check_property(truncated_fence_fixture_generator, seed: 5402) do |fixture|
      normalized = Normalizer.normalize(fixture.source)

      refute fixture.source.end_with?("\n"), fixture.source.inspect
      assert_equal fixture.expected, normalized, fixture.source.inspect
      assert_equal normalized, Normalizer.normalize(normalized), fixture.source.inspect
    end
  end

  private

  def normalizer_fixture_generator
    fenced = fenced_block_generator
    indented = indented_block_generator
    html = html_block_generator
    comment = comment_block_generator

    G.one_of(
      complete_fixture_generator(fenced, 1..5),
      complete_fixture_generator(indented, 2..5),
      complete_fixture_generator(html, 1..5),
      complete_fixture_generator(comment, 1..5),
      truncated_fence_fixture_generator,
    )
  end

  def complete_fixture_generator(block_generator, before_gap_range)
    G.fixed_hash(
      leading_blank_lines: G.choose(0..3),
      before_line: hard_break_line_generator,
      before_gap: bounded_integer_generator(before_gap_range),
      protected_block: block_generator,
      after_gap: bounded_integer_generator(1..5),
      after_line: prose_line_generator,
      ending_newlines: G.choose(0..4),
    ).map do |values|
      build_fixture(values)
    end
  end

  def prose_line_generator
    G.tuple(
      choice_generator(PROSE_TEXTS),
      choice_generator(%i[none spaces tabs hard_break]),
      G.choose(0..4),
    ).map do |text, suffix_kind, suffix_count|
      suffix = case suffix_kind
               when :spaces
                 ' '
               when :tabs
                 "\t" * [suffix_count, 1].max
               when :hard_break
                 ' ' * [suffix_count, 2].max
               else
                 ''
               end

      ProseLine.new(text: text, suffix: suffix, suffix_kind: suffix_kind)
    end
  end

  def hard_break_line_generator
    G.tuple(choice_generator(PROSE_TEXTS), G.choose(0..4)).map do |text, suffix_count|
      ProseLine.new(text: text, suffix: ' ' * [suffix_count, 2].max, suffix_kind: :hard_break)
    end
  end

  def fenced_block_generator
    fence_pairs = [['```text', '```'], ['````ruby', '````'], ['~~~text', '~~~'], ['~~~~raw', '~~~~']]
    G.tuple(
      choice_generator(fence_pairs),
      G.array(choice_generator(CODE_LINES), min: 1, max: 4),
    ).map do |(opening, closing), code_lines|
      ProtectedBlock.new(bytes: [opening, *code_lines, closing].join("\n"), kind: :fenced_code)
    end
  end

  def indented_block_generator
    G.array(choice_generator(CODE_LINES), min: 1, max: 4).map do |code_lines|
      bytes = code_lines.map { |line| "    #{line}" }.join("\n")
      ProtectedBlock.new(bytes: bytes, kind: :indented_code)
    end
  end

  def html_block_generator
    G.array(choice_generator(HTML_LINES), min: 1, max: 4).map do |html_lines|
      ProtectedBlock.new(bytes: "<pre>\n#{html_lines.join("\n")}\n</pre>", kind: :raw_html)
    end
  end

  def comment_block_generator
    G.array(choice_generator(COMMENT_LINES), min: 1, max: 4).map do |comment_lines|
      ProtectedBlock.new(bytes: "<!--\n#{comment_lines.join("\n")}\n-->", kind: :html_comment)
    end
  end

  def truncated_fence_fixture_generator
    fence_openers = ['```text', '````ruby', '~~~text', '~~~~raw']
    G.fixed_hash(
      leading_blank_lines: G.choose(0..3),
      opening_fence: choice_generator(fence_openers),
      code_lines: G.array(choice_generator(CODE_LINES), min: 1, max: 4),
    ).map do |values|
      truncated_code = [values[:opening_fence], *values[:code_lines]].join("\n")
      expected = "Opening hard break  \n\n#{truncated_code}"
      source = "#{"\n" * values[:leading_blank_lines]}#{expected}"

      Fixture.new(source: source, expected: expected, protected_bytes: truncated_code)
    end
  end

  def build_fixture(values)
    before_line = values[:before_line]
    after_line = values[:after_line]
    protected_bytes = values[:protected_block].bytes
    ending_newlines = values[:ending_newlines]

    source = ("\n" * values[:leading_blank_lines]) +
             before_line.text + before_line.suffix +
             ("\n" * values[:before_gap]) +
             protected_bytes +
             ("\n" * values[:after_gap]) +
             after_line.text + after_line.suffix +
             ("\n" * ending_newlines)

    expected = expected_prose_line(before_line, terminated: true) +
               ("\n" * [values[:before_gap], 2].min) +
               protected_bytes +
               ("\n" * [values[:after_gap], 2].min) +
               expected_prose_line(after_line, terminated: ending_newlines.positive?) +
               (ending_newlines.positive? ? "\n" : '')

    Fixture.new(source: source, expected: expected, protected_bytes: protected_bytes)
  end

  def expected_prose_line(line, terminated:)
    suffix = line.suffix_kind == :hard_break && terminated ? line.suffix : ''
    line.text + suffix
  end

  def choice_generator(values)
    G.one_of(*values.map { |value| G.constant(value) })
  end

  def bounded_integer_generator(range)
    minimum = range.begin
    G.choose(0..(range.end - minimum)).map { |offset| offset + minimum }
  end
end
