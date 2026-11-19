# frozen_string_literal: true

require 'test_helper'
require 'src/infrastructure/html_attributes'
require 'support/property_test'

# Tests for HtmlAttributes: attribute names and values of one start tag.
class TestHtmlAttributes < Minitest::Test
  include PropertyTestSupport

  Attributes = Jekyll::Infrastructure::HtmlAttributes
  G = PropCheck::Generators

  TARGET_NAMES = %w[sizes role data-note].freeze
  ATTRIBUTE_NAMES = %w[alt title ROLE role sizes SIZES data-note DATA-NOTE class hidden].freeze
  QUOTED_VALUE_TABLE = [
    ['right > now', 'right > now'],
    ['A &amp; B', 'A & B'],
    ['&#39;quoted&#39;', "'quoted'"],
    ['&lt;img&gt;', '<img>'],
    ['&#x2F;', '/'],
  ].freeze
  UNQUOTED_VALUES = %w[80px no-wrap x_y plain].freeze
  SEPARATORS = [' ', "\n  ", "\t"].freeze
  TAG_NAMES = %w[img pre div].freeze
  PROPERTY_SEED = 0xA771_2026
  PROPERTY_RUNS = 100

  AttributeEntry = Struct.new(:name, :raw_value, :expected_value, :separator, :quote, keyword_init: true) do
    def render
      source = raw_value.nil? ? name : "#{name}=#{quote}#{raw_value}#{quote}"
      "#{separator}#{source}"
    end
  end
  AttributeCase = Struct.new(
    :tag,
    :target,
    :expected_attributes,
    :expected_removed,
    :attribute_entries,
    keyword_init: true,
  )

  def self.build_attribute_entry(name_index, mode, value_index, separator_index)
    name = ATTRIBUTE_NAMES.fetch(name_index)
    separator = SEPARATORS.fetch(separator_index)

    case mode
    when 0
      AttributeEntry.new(name: name, separator: separator)
    when 1, 2
      raw_value, expected_value = QUOTED_VALUE_TABLE.fetch(value_index)
      quote = mode == 1 ? '"' : "'"
      AttributeEntry.new(
        name: name,
        raw_value: raw_value,
        expected_value: expected_value,
        separator: separator,
        quote: quote,
      )
    else
      value = UNQUOTED_VALUES.fetch(value_index % UNQUOTED_VALUES.length)
      AttributeEntry.new(name: name, raw_value: value, expected_value: value, separator: separator)
    end
  end

  def self.build_case(target_index, entity_index, closing_index, extra_entries)
    target = TARGET_NAMES.fetch(target_index)
    first_raw, first_expected = QUOTED_VALUE_TABLE.fetch(entity_index)
    second_index = (entity_index + 1) % QUOTED_VALUE_TABLE.length
    second_raw, second_expected = QUOTED_VALUE_TABLE.fetch(second_index)
    first = AttributeEntry.new(
      name: target.upcase,
      raw_value: first_raw,
      expected_value: first_expected,
      separator: ' ',
      quote: '"',
    )
    second = AttributeEntry.new(
      name: target,
      raw_value: second_raw,
      expected_value: second_expected,
      separator: "\n  ",
      quote: "'",
    )
    lookalike_value = "#{target}=neighbor"
    lookalike = AttributeEntry.new(
      name: 'title',
      raw_value: lookalike_value,
      expected_value: lookalike_value,
      separator: ' ',
      quote: '"',
    )
    entries = [first, second, lookalike] + extra_entries
    opening = "<#{TAG_NAMES.fetch(target_index)}"
    closing = closing_index.zero? ? '>' : ' />'
    tag = opening + entries.map(&:render).join + closing

    expected_attributes = entries.each_with_object({}) do |entry, attributes|
      key = entry.name.downcase
      attributes[key] = entry.expected_value unless attributes.key?(key)
    end
    expected_removed = opening + entries.reject { |entry| entry.name.casecmp?(target) }.map(&:render).join + closing

    AttributeCase.new(
      tag: tag,
      target: target,
      expected_attributes: expected_attributes,
      expected_removed: expected_removed,
      attribute_entries: entries,
    )
  end

  ENTRY_GENERATOR = G.tuple(
    G.choose(0...ATTRIBUTE_NAMES.length),
    G.choose(0..3),
    G.choose(0...QUOTED_VALUE_TABLE.length),
    G.choose(0...SEPARATORS.length),
  ).map do |name_index, mode, value_index, separator_index|
    TestHtmlAttributes.build_attribute_entry(name_index, mode, value_index, separator_index)
  end

  ATTRIBUTE_CASE_GENERATOR = G.tuple(
    G.choose(0...TARGET_NAMES.length),
    G.choose(0...QUOTED_VALUE_TABLE.length),
    G.choose(0..1),
    G.array(ENTRY_GENERATOR),
  ).map do |target_index, entity_index, closing_index, extra_entries|
    TestHtmlAttributes.build_case(target_index, entity_index, closing_index, extra_entries)
  end

  def attributes(tag)
    Attributes.parse(tag)
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

  def test_unquoted_attribute_keeps_a_trailing_slash
    assert_equal({ 'src' => '/files/example.png/' }, attributes('<img src=/files/example.png/>'))
    assert_equal({ 'src' => '/files/example.png' }, attributes('<img src=/files/example.png />'))
  end

  def test_append_keeps_a_self_closing_delimiter_after_a_quoted_value
    assert_equal '<img alt="plot" width="1"/>', Attributes.append('<img alt="plot"/>', ' width="1"')
  end

  def test_property_appends_attributes_after_the_final_value
    endings = [
      ['', '/>'],
      ['alt=plot', '>'],
      ['alt=plot/', '>'],
      ['alt=plot', ' />'],
      ['alt="plot"', '/>'],
      ['alt="plot marker=foo /"', '/>'],
      ["alt='日本語/'", '/>'],
      ['alt=plot hidden', '/>'],
    ]
    input = G.tuple(G.choose(0...endings.length), G.choose(1..4096))

    check_property(input, seed: PROPERTY_SEED) do |index, width|
      attribute, closing = endings.fetch(index)
      prefix = attribute.empty? ? '<img' : "<img #{attribute}"
      added = %( width="#{width}")

      assert_equal "#{prefix}#{added}#{closing}", Attributes.append("#{prefix}#{closing}", added)
    end
  end

  # --- remove ---

  def test_remove_drops_the_attribute_and_its_leading_space
    assert_equal '<img src="/a.png" alt="A" />',
                 Attributes.remove('<img src="/a.png" sizes="auto, 80px" alt="A" />', 'sizes')
  end

  def test_remove_leaves_text_inside_another_value
    tag = %(<img alt="chart sizes=large" SIZES='80px' title=sizes>)
    assert_equal '<img alt="chart sizes=large" title=sizes>', Attributes.remove(tag, 'sizes')
  end

  def test_explicit_entity_table_matches_decoded_attribute_values
    QUOTED_VALUE_TABLE.each do |spelling, decoded|
      assert_equal({ 'data-value' => decoded }, attributes(%(<img data-value="#{spelling}">)))
    end
  end

  def test_generated_attributes_match_structured_expectations_and_remove_every_duplicate
    coverage = { duplicate_targets: 0, quoted_lookalikes: 0, entity_spellings: 0 }
    check_property(ATTRIBUTE_CASE_GENERATOR, seed: PROPERTY_SEED, runs: PROPERTY_RUNS) do |input|
      target_entries = input.attribute_entries.select { |entry| entry.name.casecmp?(input.target) }
      lookalikes = input.attribute_entries.select do |entry|
        entry.name.casecmp?('title') && entry.expected_value.to_s.include?("#{input.target}=")
      end
      coverage[:duplicate_targets] += 1 if target_entries.length >= 2
      coverage[:quoted_lookalikes] += 1 unless lookalikes.empty?
      coverage[:entity_spellings] += 1 if input.attribute_entries.any? do |entry|
        QUOTED_VALUE_TABLE.any? { |spelling, _decoded| entry.raw_value == spelling }
      end

      assert_equal input.expected_attributes, attributes(input.tag), "tag: #{input.tag.inspect}"
      assert_equal input.expected_removed,
                   Attributes.remove(input.tag, input.target),
                   "remove #{input.target.inspect} from #{input.tag.inspect}"
    end

    assert_equal property_cases(PROPERTY_RUNS), coverage[:duplicate_targets]
    assert_equal property_cases(PROPERTY_RUNS), coverage[:quoted_lookalikes]
    assert_equal property_cases(PROPERTY_RUNS), coverage[:entity_spellings]
  end
end
