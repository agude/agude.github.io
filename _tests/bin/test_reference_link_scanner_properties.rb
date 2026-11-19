# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../support/property_test'
require_relative '../../_bin/reference_link_scanner'

# Generated checks for reference-link findings and original source line offsets.
class TestReferenceLinkScannerProperties < Minitest::Test
  include PropertyTestSupport

  G = PropCheck::Generators
  Record = Struct.new(:kind, :id, :text, keyword_init: true)
  OpaqueFragment = Struct.new(:kind, :text, keyword_init: true)
  Fixture = Struct.new(:content, :line_offset, :expected, keyword_init: true)

  FINDING_INTERACTIONS = {
    'undefined reference link' => 'finding:undefined_reference',
    'duplicate link definition' => 'finding:duplicate_definition',
    'orphaned link definition' => 'finding:orphaned_definition',
  }.freeze
  INTERACTIONS = [
    *FINDING_INTERACTIONS.values,
    'finding:all_three_kinds',
    'opaque:matched_fence',
    'opaque:multiline_liquid_output',
    'opaque:multiline_liquid_tag',
    'opaque:liquid_comment',
    'opaque:inline_code',
    'reference:wrapped_label',
    'reference:implicit_collapsed',
    'reference:uppercase_id',
    'eof_without_newline',
    'line_offset_nonzero',
  ].freeze

  # Names what a generated fixture exercises. Findings come from the model's
  # expected output; the rest is read from the generated content.
  def self.fixture_interactions(fixture)
    names = fixture.expected.filter_map do |finding|
      FINDING_INTERACTIONS.find { |prefix, _name| finding[:message].start_with?(prefix) }&.last
    end.uniq
    names << 'finding:all_three_kinds' if names.length == FINDING_INTERACTIONS.length
    content = fixture.content
    names << 'opaque:matched_fence' if content.match?(/^(?:`{3,}|~{3,})text$/)
    names << 'opaque:multiline_liquid_output' if content.include?("{{\n  [liquid_output_")
    names << 'opaque:multiline_liquid_tag' if content.include?('{% assign ')
    names << 'opaque:liquid_comment' if content.include?('{% comment %}')
    names << 'opaque:inline_code' if content.include?('Code: `[inline_')
    names << 'reference:wrapped_label' if content.include?("[Link label\nfor ")
    names << 'reference:implicit_collapsed' if content.include?("][]\n")
    names << 'reference:uppercase_id' if content.match?(/\[(?:DEFINED|DUPLICATE|UNDEFINED|SHORTHAND)_\d+\]/)
    names << 'eof_without_newline' unless content.end_with?("\n")
    names << 'line_offset_nonzero' if fixture.line_offset.positive?
    names
  end

  def test_property_reports_independent_reference_issues_with_source_offsets
    check_property(
      reference_fixture_generator,
      seed: 6401,
      classify: ->(fixture) { self.class.fixture_interactions(fixture) },
      interactions: INTERACTIONS,
    ) do |fixture|
      actual = ReferenceLinkScanner.scan(fixture.content, line_offset: fixture.line_offset)

      assert_equal fixture.expected, actual, fixture.content.inspect
    end
  end

  private

  def reference_fixture_generator
    G.fixed_hash(
      suffix: G.choose(0..999),
      line_offset: G.choose(0..20),
      upper_case_flags: G.array(boolean_generator, min: 8, max: 8),
      definition_indents: G.array(G.choose(0..3), min: 5, max: 5),
      implicit_defined_reference: boolean_generator,
      wrapped_reference: boolean_generator,
      extra_reference_kinds: G.array(G.choose(0..2), min: 0, max: 5),
      opaque_before: G.array(opaque_fragment_generator, min: 0, max: 4),
      opaque_between: G.array(opaque_fragment_generator, min: 0, max: 4),
      opaque_after: G.array(opaque_fragment_generator, min: 0, max: 4),
      eof_newline: boolean_generator,
    ).map { |values| build_reference_fixture(values) }
  end

  def boolean_generator
    G.one_of(G.constant(true), G.constant(false))
  end

  def opaque_fragment_generator
    G.one_of(
      matched_fence_generator,
      multiline_liquid_output_generator,
      multiline_liquid_tag_generator,
      liquid_comment_generator,
      inline_code_generator,
    )
  end

  def matched_fence_generator
    fence_markers = ['```', '````', '~~~', '~~~~']
    G.tuple(choice_generator(fence_markers), G.choose(0..999)).map do |marker, token|
      hidden_id = "fence_hidden_#{token}"
      text = "#{marker}text\n[hidden][#{hidden_id}]\n[hidden_#{token}]: https://example.test/hidden\n#{marker}\n"
      OpaqueFragment.new(kind: :matched_fence, text: text)
    end
  end

  def multiline_liquid_output_generator
    G.choose(0..999).map do |token|
      text = "{{\n  [liquid_output_#{token}][missing_output_#{token}]\n}}\n"
      OpaqueFragment.new(kind: :multiline_liquid_output, text: text)
    end
  end

  def multiline_liquid_tag_generator
    G.choose(0..999).map do |token|
      text = "{% assign hidden_#{token} =\n  \"[liquid_tag_#{token}][missing_tag_#{token}]\"\n%}\n"
      OpaqueFragment.new(kind: :multiline_liquid_tag, text: text)
    end
  end

  def liquid_comment_generator
    G.choose(0..999).map do |token|
      text = "{% comment %}\n[comment_#{token}][missing_comment_#{token}]\n[comment_only_#{token}]: https://example.test/comment\n{% endcomment %}\n"
      OpaqueFragment.new(kind: :liquid_comment, text: text)
    end
  end

  def inline_code_generator
    G.choose(0..999).map do |token|
      text = "Code: `[inline_#{token}][missing_inline_#{token}]` and continue.\n"
      OpaqueFragment.new(kind: :inline_code, text: text)
    end
  end

  def build_reference_fixture(values)
    suffix = values[:suffix]
    ids = {
      defined: "defined_#{suffix}",
      duplicate: "duplicate_#{suffix}",
      orphan: "orphan_#{suffix}",
      shorthand: "shorthand_#{suffix}",
      undefined: "undefined_#{suffix}",
    }
    spellings = ids.each_with_index.to_h do |(key, id), index|
      [key, values[:upper_case_flags][index] ? id.upcase : id]
    end

    references = [
      full_reference_record(
        ids[:defined],
        spellings[:defined],
        implicit: values[:implicit_defined_reference],
        wrapped: values[:wrapped_reference],
      ),
      full_reference_record(ids[:duplicate], spellings[:duplicate]),
      full_reference_record(ids[:undefined], spellings[:undefined]),
      Record.new(kind: :shorthand_reference, id: ids[:shorthand], text: "[#{spellings[:shorthand]}]\n"),
    ]
    reference_ids = [ids[:defined], ids[:duplicate], ids[:undefined]]
    extra_references = values[:extra_reference_kinds].map do |kind|
      id = reference_ids.fetch(kind)
      full_reference_record(id, id.upcase)
    end
    references.concat(extra_references)

    definitions = [
      definition_record(ids[:defined], spellings[:defined], values[:definition_indents][0], 1),
      definition_record(ids[:duplicate], spellings[:duplicate], values[:definition_indents][1], 2),
      definition_record(ids[:duplicate], spellings[:duplicate], values[:definition_indents][2], 3),
      definition_record(ids[:orphan], spellings[:orphan], values[:definition_indents][3], 4),
      definition_record(ids[:shorthand], spellings[:shorthand], values[:definition_indents][4], 5),
    ]

    records = []
    records.concat(values[:opaque_before].map { |fragment| opaque_record(fragment) })
    records.concat(references)
    records << mandatory_fence_record(suffix)
    records.concat(values[:opaque_between].map { |fragment| opaque_record(fragment) })
    records << mandatory_multiline_liquid_record(suffix)
    records.concat(definitions)
    records.concat(values[:opaque_after].map { |fragment| opaque_record(fragment) })

    content = records.map(&:text).join
    content = content.delete_suffix("\n") unless values[:eof_newline]
    Fixture.new(
      content: content,
      line_offset: values[:line_offset],
      expected: expected_findings(records, values[:line_offset]),
    )
  end

  def full_reference_record(id, spelling, implicit: false, wrapped: false)
    text = if implicit
             "[#{spelling}][]\n"
           elsif wrapped
             "[Link label\nfor #{id}][#{spelling}]\n"
           else
             "[Link label for #{id}][#{spelling}]\n"
           end
    Record.new(kind: :full_reference, id: id, text: text)
  end

  def definition_record(id, spelling, indentation, number)
    text = "#{' ' * indentation}[#{spelling}]: https://example.test/link-#{number}\n"
    Record.new(kind: :definition, id: id, text: text)
  end

  def opaque_record(fragment)
    Record.new(kind: :opaque, id: nil, text: fragment.text)
  end

  def mandatory_fence_record(suffix)
    marker = suffix.even? ? '```' : '~~~~'
    hidden_id = "required_fence_hidden_#{suffix}"
    text = "#{marker}text\n[hidden][#{hidden_id}]\n#{marker}\n"
    opaque_record(OpaqueFragment.new(kind: :matched_fence, text: text))
  end

  def mandatory_multiline_liquid_record(suffix)
    text = "{% assign required_hidden_#{suffix} =\n  \"[liquid_hidden_#{suffix}][missing_required_#{suffix}]\"\n%}\n"
    opaque_record(OpaqueFragment.new(kind: :multiline_liquid_tag, text: text))
  end

  def expected_findings(records, line_offset)
    positioned = []
    line = 1
    records.each do |record|
      positioned << [record, line]
      line += record.text.count("\n")
    end

    definitions = positioned.select { |record, _| record.kind == :definition }
    references = positioned.select do |record, _|
      %i[full_reference shorthand_reference].include?(record.kind)
    end
    defined_ids = definitions.map { |record, _| record.id }.uniq
    used_ids = references.map { |record, _| record.id }.uniq

    undefined = references.filter_map do |record, source_line|
      next unless record.kind == :full_reference && !defined_ids.include?(record.id)

      finding(source_line, "undefined reference link [#{record.id}]", line_offset)
    end

    first_definition_line = {}
    duplicates = definitions.filter_map do |record, source_line|
      first_line = first_definition_line[record.id]
      if first_line
        finding(
          source_line,
          "duplicate link definition [#{record.id}] (first defined on line #{first_line + line_offset})",
          line_offset,
        )
      else
        first_definition_line[record.id] = source_line
        nil
      end
    end

    orphans = definitions.filter_map do |record, source_line|
      next if used_ids.include?(record.id)

      finding(source_line, "orphaned link definition [#{record.id}]", line_offset)
    end

    (undefined + duplicates + orphans).sort_by { |problem| problem[:line] }
  end

  def finding(source_line, message, line_offset)
    { line: source_line + line_offset, message: message }
  end

  def choice_generator(values)
    G.one_of(*values.map { |value| G.constant(value) })
  end
end
