# frozen_string_literal: true

require 'support/property_test'
require_relative '../../../support/backlink_builder_test_support'

# Generated operation histories and merge sequences checked against small
# reference models. The models are interpreted here, not by BacklinkBuilder.
class TestBacklinkBuilderProperties < BacklinkBuilderTestCase
  include PropertyTestSupport

  TARGETS = {
    a: { title: 'Target A', url: '/books/target-a.html' }.freeze,
    b: { title: 'Target B', url: '/books/target-b.html' }.freeze,
    c: { title: 'Target C', url: '/books/target-c.html' }.freeze,
  }.freeze

  # The only book in SERIES, so a series_link to it resolves to target :b.
  SERIES = 'Solo Series'
  SERIES_TARGET = :b

  VARIABLES = %w[ref alt note].freeze
  # [target, link tag] pairs a capture can bind, or nil for plain text.
  CAPTURE_LINKS = [%i[a book], %i[b book], %i[c book], [SERIES_TARGET, :series], nil].freeze

  # Rank of each link type in the merge. The order book > author >
  # short_story > series is transcribed from the documented priority
  # (book_link beats series_link in the tests); author vs short_story is not
  # covered by any test.
  TYPE_RANK = { 'series' => 1, 'short_story' => 2, 'author' => 3, 'book' => 4 }.freeze
  DIRECT_TYPES = %w[book short_story].freeze

  INTERACTIONS = %w[
    rebind_after_use
    plain_text_reset
    use_before_first_bind
    unused_capture
    direct_link_to_captured_target
    use_resolves_to_target
    series_link_capture
    book_and_series_same_target
    higher_priority_first
    lower_priority_first
  ].freeze

  # Pool of link types and URLs for direct add_link merges. The author URL is
  # an author page; the missing URL has no document, so it gets a backlink
  # but no forward link.
  LINK_TYPES = TYPE_RANK.keys.freeze
  ADD_LINK_SOURCE_URLS = ['/books/source-one.html', '/books/source-two.html'].freeze
  ADD_LINK_TARGET_URLS = [
    TARGETS.fetch(:a).fetch(:url),
    TARGETS.fetch(:b).fetch(:url),
    '/authors/author-c.html',
    '/books/missing.html',
  ].freeze
  DOCUMENTED_TARGET_URLS = (ADD_LINK_TARGET_URLS - ['/books/missing.html']).freeze
  POSITIONS = [0.0, 33.3, 66.7, 100.0].freeze
  MERGE_INTERACTIONS = [
    'higher_priority_first',
    'lower_priority_first',
    'equal_type_repeat',
    'nil_count_merge',
    *LINK_TYPES.map { |type| "type_#{type}_on_shared_target" },
  ].freeze

  # Names what a generated operation history exercises. Each name reads the
  # generated operations in order; the fixed histories in the test are not
  # classified because they are the same in every case.
  def self.history_interactions(operations)
    names = []
    used = {}
    bound = {}
    captured_targets = {}
    link_types = Hash.new { |hash, key| hash[key] = [] }
    operations.each_with_index do |op, index|
      variable = op[:variable]
      case op.fetch(:kind)
      when :capture, :rebind
        names << 'rebind_after_use' if op.fetch(:kind) == :rebind && used[variable]
        names << 'plain_text_reset' if op.fetch(:kind) == :rebind && op[:target].nil?
        names << 'unused_capture' unless used_before_next_bind?(operations, index, variable)
        bound[variable] = true
        next unless op[:target]

        captured_targets[op[:target]] = true
        names << 'series_link_capture' if op[:link] == :series
        link_types[op[:target]] << link_type(op)
      when :use
        names << 'use_before_first_bind' unless bound[variable]
        names << 'use_resolves_to_target' if bound[variable] && bound_target(operations, index, variable)
        used[variable] = true
      when :direct
        names << 'direct_link_to_captured_target' if captured_targets[op.fetch(:target)]
        link_types[op.fetch(:target)] << 'book'
      end
    end
    link_types.each_value { |types| names.push(*ordering_names(types)) }
    names.uniq
  end

  # Interactions for the link types merged into one target's entry, in
  # operation order.
  def self.ordering_names(types)
    names = []
    names << 'book_and_series_same_target' if types.uniq.sort == %w[book series]
    names << 'higher_priority_first' if ordered_pairs(types).any? { |a, b| TYPE_RANK.fetch(a) > TYPE_RANK.fetch(b) }
    names << 'lower_priority_first' if ordered_pairs(types).any? { |a, b| TYPE_RANK.fetch(a) < TYPE_RANK.fetch(b) }
    names
  end

  def self.ordered_pairs(items)
    items.each_with_index.flat_map { |earlier, index| items.drop(index + 1).map { |later| [earlier, later] } }
  end

  def self.link_type(operation)
    operation[:link] == :series ? 'series' : 'book'
  end

  # True when a `use` of `variable` follows `index` before the next bind of it.
  def self.used_before_next_bind?(operations, index, variable)
    operations.drop(index + 1).each do |op|
      next unless op[:variable] == variable

      return true if op.fetch(:kind) == :use
      return false if %i[capture rebind].include?(op.fetch(:kind))
    end
    false
  end

  # The target of the latest bind of `variable` before `index`.
  def self.bound_target(operations, index, variable)
    operations.take(index).reverse_each do |op|
      next unless op[:variable] == variable && %i[capture rebind].include?(op.fetch(:kind))

      return op[:target]
    end
    nil
  end

  # Names what one pair of add_link calls to the same source and target
  # exercises, in call order.
  def self.merge_interactions(calls)
    names = []
    calls.group_by { |call| [call.fetch(:source), call.fetch(:target)] }.each_value do |group|
      types = group.map { |call| call.fetch(:type) }
      pairs = ordered_pairs(group)
      names << 'higher_priority_first' if pairs.any? { |a, b| TYPE_RANK.fetch(a[:type]) > TYPE_RANK.fetch(b[:type]) }
      names << 'lower_priority_first' if pairs.any? { |a, b| TYPE_RANK.fetch(a[:type]) < TYPE_RANK.fetch(b[:type]) }
      names << 'equal_type_repeat' if pairs.any? { |a, b| a[:type] == b[:type] }
      names << 'nil_count_merge' if group.drop(1).any? { |call| call[:count].nil? }
      types.uniq.each { |type| names << "type_#{type}_on_shared_target" } if types.uniq.length > 1
    end
    names.uniq
  end

  def test_generated_histories_match_reference_model
    check_property(
      operation_trace_generator,
      seed: 410_318,
      classify: ->(operations) { self.class.history_interactions(operations) },
      interactions: INTERACTIONS,
    ) do |generated_operations|
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

  # add_link is the narrowest entry point that merges all four link types into
  # one (source, target) entry. Generated call sequences reach each pair in
  # both orders, so the merge must not depend on which call came first.
  def test_generated_add_link_merges_match_reference_model
    seen = Hash.new(0)
    check_property(
      add_link_sequence_generator,
      seed: 410_319,
      classify: ->(calls) { self.class.merge_interactions(calls) },
      interactions: MERGE_INTERACTIONS,
    ) do |calls|
      self.class.merge_interactions(calls).each { |name| seen[name] += 1 }
      site = build_add_link_site
      link_cache = apply_add_link_calls(site, calls)

      assert_add_link_records_match_model(link_cache, expected_add_link_records(calls))
    end

    %w[higher_priority_first lower_priority_first equal_type_repeat nil_count_merge].each do |name|
      assert_operator seen[name], :>, 0, "Generated merges never exercised #{name}"
    end
    LINK_TYPES.each do |type|
      assert_operator seen["type_#{type}_on_shared_target"], :>, 0, "Generated merges never shared a #{type} target"
    end
  end

  private

  def operation_trace_generator
    generators = PropCheck::Generators
    kind_generator = generators.one_of(*%i[capture rebind use direct].map { |kind| generators.constant(kind) })
    variable_generator = generators.one_of(*VARIABLES.map { |variable| generators.constant(variable) })
    link_generator = generators.choose(0...CAPTURE_LINKS.length)

    operation_generator = generators.tuple(kind_generator, variable_generator, link_generator).map do |kind, variable, index|
      link = CAPTURE_LINKS.fetch(index)
      case kind
      when :capture, :rebind
        operation(kind, variable:, target: link&.first, link: link&.last)
      when :use
        operation(:use, variable:)
      when :direct
        operation(:direct, target: link&.first || :c)
      end
    end

    generators.array(operation_generator, max: 8)
  end

  def add_link_sequence_generator
    generators = PropCheck::Generators
    source_generator = generators.choose(0...ADD_LINK_SOURCE_URLS.length)
    target_generator = generators.choose(0...ADD_LINK_TARGET_URLS.length)
    type_generator = generators.choose(0...LINK_TYPES.length)
    count_generator = generators.choose(0..3)
    position_generator = generators.choose(0...POSITIONS.length)

    call_generator = generators.tuple(
      source_generator,
      target_generator,
      type_generator,
      count_generator,
      position_generator,
      position_generator,
    ).map do |source, target, type, count, min_index, direct_index|
      {
        source: source,
        target: target,
        type: LINK_TYPES.fetch(type),
        count: count.zero? ? nil : count,
        min: POSITIONS.fetch(min_index),
        direct: direct_index.even? ? nil : POSITIONS.fetch(direct_index),
      }
    end

    generators.array(call_generator, max: 10)
  end

  def operation(kind, **attributes)
    { kind:, link: :book, **attributes }
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

  def series_page
    create_doc({ 'title' => SERIES, 'layout' => 'series_page' }, '/series/solo-series.html')
  end

  def build_site_for(histories)
    source_docs = histories.map do |url, operations|
      title = File.basename(url, '.html').tr('-', ' ')
      create_doc({ 'title' => title, 'published' => true }, url, render_operations(operations))
    end
    target_docs = TARGETS.map do |key, target|
      data = { 'title' => target.fetch(:title), 'published' => true }
      data['series'] = SERIES if key == SERIES_TARGET
      create_doc(data, target.fetch(:url), 'Target content.')
    end

    create_site({}, { 'books' => source_docs + target_docs }, [series_page])
  end

  def render_operations(operations)
    operations.map do |op|
      case op.fetch(:kind)
      when :capture, :rebind
        body = if op[:target]
                 render_link(op.fetch(:target), op.fetch(:link))
               else
                 'plain text'
               end
        "{% capture #{op.fetch(:variable)} %}#{body}{% endcapture %}"
      when :use
        "{{ #{op.fetch(:variable)} }}"
      when :direct
        render_link(op.fetch(:target), :book)
      else
        raise ArgumentError, "Unknown operation: #{op.inspect}"
      end
    end.join("\n")
  end

  def render_link(target, link)
    if link == :series
      raise ArgumentError, "series links must target #{SERIES_TARGET}" unless target == SERIES_TARGET

      %({% series_link "#{SERIES}" %})
    else
      "{% book_link \"#{TARGETS.fetch(target).fetch(:title)}\" %}"
    end
  end

  # Interpret the generated operations directly, without consulting Liquid or
  # BacklinkBuilder, to derive edge membership, link types, and usage scores.
  def reference_model(histories)
    histories.each_with_object({}) do |(source_url, operations), expected|
      bindings = {}
      captures = []
      uses = []
      direct_links = []

      operations.each do |op|
        case op.fetch(:kind)
        when :capture, :rebind
          if op[:target]
            captures << { target: op.fetch(:target), type: self.class.link_type(op) }
            bindings[op.fetch(:variable)] = captures.length - 1
          else
            bindings[op.fetch(:variable)] = nil
          end
        when :use
          uses << bindings[op.fetch(:variable)]
        when :direct
          direct_links << { target: op.fetch(:target), type: 'book' }
        else
          raise ArgumentError, "Unknown operation: #{op.inspect}"
        end
      end

      positions = Hash.new { |hash, key| hash[key] = [] }
      uses.each_with_index do |capture_index, index|
        next unless capture_index

        positions[capture_index] << (index.to_f / uses.length * 100).round(1)
      end

      links = Hash.new { |hash, key| hash[key] = [] }
      captures.each_with_index { |capture, index| links[capture.fetch(:target)] << [index, capture.fetch(:type)] }
      direct_links.each { |link| links[link.fetch(:target)] << [nil, link.fetch(:type)] }

      links.each do |target, entries|
        all_positions = entries.flat_map { |index, _type| index ? positions[index] : [] }
        direct_positions = entries.select { |index, type| index && DIRECT_TYPES.include?(type) }
                                  .flat_map { |index, _type| positions[index] }
        expected[[source_url, target_url(target)]] = {
          type: entries.map { |_index, type| type }.max_by { |type| TYPE_RANK.fetch(type) },
          count: all_positions.empty? ? nil : all_positions.length,
          min_position: all_positions.min,
          direct_min_position: direct_positions.min,
        }
      end
    end
  end

  def target_url(key)
    TARGETS.fetch(key).fetch(:url)
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

  def build_add_link_site
    sources = ADD_LINK_SOURCE_URLS.map do |url|
      create_doc({ 'title' => File.basename(url, '.html'), 'published' => true }, url, '')
    end
    targets = TARGETS.values.map do |target|
      create_doc({ 'title' => target.fetch(:title), 'published' => true }, target.fetch(:url), 'Target content.')
    end
    author = create_doc({ 'title' => 'Author C', 'layout' => 'author_page' }, '/authors/author-c.html', '')

    create_site({}, { 'books' => sources + targets }, [author])
  end

  # Runs the calls through BacklinkBuilder's add_link, the entry point that
  # merges every link type, and returns the finished link cache.
  def apply_add_link_calls(site, calls)
    link_cache = site.data.fetch('link_cache')
    maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
    builder = Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps)
    builder.build
    sources = ADD_LINK_SOURCE_URLS.map { |url| site.collections.fetch('books').docs.find { |doc| doc.url == url } }

    calls.each do |call|
      builder.send(
        :add_link,
        ADD_LINK_TARGET_URLS.fetch(call.fetch(:target)),
        sources.fetch(call.fetch(:source)),
        call.fetch(:type),
        call.fetch(:count),
        call.fetch(:min),
        call.fetch(:direct),
      )
    end
    builder.send(:finalize_links)
    link_cache
  end

  # One merged entry per (source, target): the highest-ranked type, counts
  # summed over non-nil counts, and the minimum of each non-nil position.
  def expected_add_link_records(calls)
    calls.group_by { |call| [call.fetch(:source), call.fetch(:target)] }.to_h do |(source, target), group|
      counts = group.filter_map { |call| call[:count] }
      [
        [ADD_LINK_SOURCE_URLS.fetch(source), ADD_LINK_TARGET_URLS.fetch(target)],
        {
          type: group.map { |call| call.fetch(:type) }.max_by { |type| TYPE_RANK.fetch(type) },
          count: counts.empty? ? nil : counts.sum,
          min_position: group.filter_map { |call| call[:min] }.min,
          direct_min_position: group.filter_map { |call| call[:direct] }.min,
        },
      ]
    end
  end

  def assert_add_link_records_match_model(link_cache, expected)
    documented = expected.select { |(_source, target), _entry| DOCUMENTED_TARGET_URLS.include?(target) }

    assert_equal expected, backlink_records(link_cache.fetch('backlinks')), 'Backlink merges differ from the model'
    assert_equal(
      documented,
      forward_records(link_cache.fetch('forward_links')),
      'Forward-link merges differ from the model',
    )
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
