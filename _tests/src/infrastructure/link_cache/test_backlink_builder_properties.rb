# frozen_string_literal: true

require 'support/property_test'
require_relative '../../../support/backlink_builder_test_support'

# Generated operation histories checked against a small reference model.
class TestBacklinkBuilderProperties < BacklinkBuilderTestCase
  include PropertyTestSupport

  TARGETS = {
    a: { title: 'Target A', url: '/books/target-a.html' }.freeze,
    b: { title: 'Target B', url: '/books/target-b.html' }.freeze,
    c: { title: 'Target C', url: '/books/target-c.html' }.freeze,
  }.freeze

  VARIABLES = %w[ref alt note].freeze
  CAPTURE_TARGETS = [:a, :b, :c, nil].freeze

  def test_generated_histories_match_reference_model
    check_property(operation_trace_generator, seed: 410_318) do |generated_operations|
      histories = {
        '/books/lifecycle.html' => lifecycle_operations,
        '/books/generated.html' => [operation(:direct, target: :c), *generated_operations],
        '/books/prefix.html' => generated_operations.take(generated_operations.length / 2),
        '/books/no-op.html' => no_op_operations,
        '/books/unused-capture.html' => [operation(:capture, variable: 'unused', target: :c)],
      }
      site = build_site_for(histories)

      assert_histories_match_model(site, histories)
      assert_lifecycle_counts(site)
    end
  end

  private

  def operation_trace_generator
    generators = PropCheck::Generators
    kind_generator = generators.one_of(*%i[capture rebind use direct].map { |kind| generators.constant(kind) })
    variable_generator = generators.one_of(*VARIABLES.map { |variable| generators.constant(variable) })
    target_generator = generators.one_of(*CAPTURE_TARGETS.map { |target| generators.constant(target) })

    operation_generator = generators.tuple(kind_generator, variable_generator, target_generator).map do |kind, variable, target|
      case kind
      when :capture, :rebind
        operation(kind, variable:, target:)
      when :use
        operation(:use, variable:)
      when :direct
        operation(:direct, target: target || :c)
      end
    end

    generators.array(operation_generator, max: 8)
  end

  def operation(kind, **attributes)
    { kind:, **attributes }
  end

  def lifecycle_operations
    [
      operation(:use, variable: 'ref'),
      operation(:capture, variable: 'ref', target: :a),
      operation(:use, variable: 'ref'),
      operation(:rebind, variable: 'ref', target: nil),
      operation(:use, variable: 'ref'),
      operation(:capture, variable: 'ref', target: :b),
      operation(:use, variable: 'ref'),
    ]
  end

  def no_op_operations
    [
      operation(:use, variable: 'before_bind'),
      operation(:rebind, variable: 'before_bind', target: nil),
      operation(:use, variable: 'before_bind'),
      operation(:use, variable: 'never_bound'),
    ]
  end

  def build_site_for(histories)
    source_docs = histories.map do |url, operations|
      title = File.basename(url, '.html').tr('-', ' ')
      create_doc({ 'title' => title, 'published' => true }, url, render_operations(operations))
    end
    target_docs = TARGETS.map do |_key, target|
      create_doc(
        { 'title' => target.fetch(:title), 'published' => true },
        target.fetch(:url),
        'Target content.',
      )
    end

    create_site({}, { 'books' => source_docs + target_docs })
  end

  def render_operations(operations)
    operations.map do |op|
      case op.fetch(:kind)
      when :capture, :rebind
        body = if op[:target]
                 title = TARGETS.fetch(op.fetch(:target)).fetch(:title)
                 "{% book_link \"#{title}\" %}"
               else
                 'plain text'
               end
        "{% capture #{op.fetch(:variable)} %}#{body}{% endcapture %}"
      when :use
        "{{ #{op.fetch(:variable)} }}"
      when :direct
        title = TARGETS.fetch(op.fetch(:target)).fetch(:title)
        "{% book_link \"#{title}\" %}"
      else
        raise ArgumentError, "Unknown operation: #{op.inspect}"
      end
    end.join("\n")
  end

  # Interpret the generated operations directly, without consulting Liquid or
  # BacklinkBuilder, to derive edge membership and usage scores.
  def reference_model(histories)
    histories.each_with_object({}) do |(source_url, operations), expected|
      bindings = {}
      target_positions = {}
      uses = []

      operations.each do |op|
        case op.fetch(:kind)
        when :capture, :rebind
          target = op[:target]
          target_positions[target] ||= [] if target
          bindings[op.fetch(:variable)] = target
        when :use
          uses << bindings[op.fetch(:variable)]
        when :direct
          target_positions[op.fetch(:target)] ||= []
        else
          raise ArgumentError, "Unknown operation: #{op.inspect}"
        end
      end

      uses.each_with_index do |target, index|
        next unless target

        target_positions.fetch(target) << (index.to_f / uses.length * 100).round(1)
      end

      target_positions.each do |target, positions|
        expected[[source_url, TARGETS.fetch(target).fetch(:url)]] = {
          type: 'book',
          count: positions.empty? ? nil : positions.length,
          min_position: positions.min,
          direct_min_position: positions.min,
        }
      end
    end
  end

  def assert_histories_match_model(site, histories)
    expected = reference_model(histories)
    cache = site.data.fetch('link_cache')
    forward_links = cache.fetch('forward_links')
    backlinks = cache.fetch('backlinks')

    forward_pairs = forward_links.flat_map do |source_url, entries|
      entries.map { |entry| [source_url, entry.fetch(:target).url] }
    end
    backlink_pairs = backlinks.flat_map do |target_url, entries|
      entries.map { |entry| [entry.fetch(:source).url, target_url] }
    end

    assert_equal expected.keys.sort, forward_pairs.sort, 'Forward-link edge set differs from the model'
    assert_equal expected.keys.sort, backlink_pairs.sort, 'Backlink edge set differs from the model'
    assert_equal expected, forward_records(forward_links), 'Forward-link counts or positions differ from the model'
    assert_equal expected, backlink_records(backlinks), 'Backlink counts or positions differ from the model'
  end

  def forward_records(forward_links)
    forward_links.each_with_object({}) do |(source_url, entries), records|
      entries.each do |entry|
        pair = [source_url, entry.fetch(:target).url]
        records[pair] = score(entry)
      end
    end
  end

  def backlink_records(backlinks)
    backlinks.each_with_object({}) do |(target_url, entries), records|
      entries.each do |entry|
        pair = [entry.fetch(:source).url, target_url]
        records[pair] = score(entry)
      end
    end
  end

  def score(entry)
    {
      type: entry.fetch(:type),
      count: entry.fetch(:count),
      min_position: entry.fetch(:min_position),
      direct_min_position: entry.fetch(:direct_min_position),
    }
  end

  def assert_lifecycle_counts(site)
    links = site.data.fetch('link_cache').fetch('forward_links').fetch('/books/lifecycle.html')
    counts = links.to_h { |entry| [entry.fetch(:target).url, entry.fetch(:count)] }

    assert_equal 1, counts.fetch(TARGETS.fetch(:a).fetch(:url))
    assert_equal 1, counts.fetch(TARGETS.fetch(:b).fetch(:url))
  end
end
