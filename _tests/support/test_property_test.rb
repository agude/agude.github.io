# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'property_test'

# Covers the failure message and replay command built by PropertyTestSupport.
class TestPropertyTest < Minitest::Test
  include PropertyTestSupport

  G = PropCheck::Generators
  INPUT = G.choose(0..9)
  BAD_VALUE = 7
  SEED = 1
  OTHER_SEED = 2
  PROPERTY_ENV_KEYS = %w[PROPERTY_SEED PROPERTY_CASES PROPERTY_TARGET PROPERTY_STATS MUTATION_TEST_TESTS].freeze

  # Runs the property with a seed that fails on BAD_VALUE. Returns the raised
  # assertion and every input seen, in order, including shrink attempts.
  def failing_run(seed, runs: 100)
    seen = []
    error = assert_raises(Minitest::Assertion) do
      run_seeded_property(INPUT, seed: seed, runs: runs) do |value|
        seen << value
        raise Minitest::Assertion, "bad value #{value}" if value == BAD_VALUE
      end
    end
    [error, seen]
  end

  def expected_replay(seed, cases)
    "make test-properties TARGET=<suite> FILTER=#{name} SEED=#{seed} CASES=#{cases}"
  end

  # Clears the PROPERTY_* variables for the block, then restores them.
  def with_property_env(overrides = {})
    saved = PROPERTY_ENV_KEYS.to_h { |key| [key, ENV.fetch(key, nil)] }
    PROPERTY_ENV_KEYS.each { |key| ENV.delete(key) }
    overrides.each { |key, value| ENV[key] = value }
    yield
  ensure
    saved&.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def test_failure_names_the_seed_and_the_first_failing_case
    with_property_env do
      error, seen = failing_run(SEED)
      successful = seen.index(BAD_VALUE)

      assert_operator successful, :>=, 1, 'seed must fail after at least one successful run'
      assert_equal successful, error.prop_check_info.fetch(:n_successful)
      assert_includes error.message, "after #{successful} successful property test runs"
      assert_includes error.message, "[property seed=#{SEED}] bad value #{BAD_VALUE}"
      assert_includes error.message.lines.map(&:chomp), expected_replay(SEED, successful + 1)
    end
  end

  def test_replay_with_one_more_case_than_successful_runs_reproduces_the_failure
    with_property_env do
      error, seen = failing_run(SEED)
      successful = seen.index(BAD_VALUE)
      assert_includes error.message, "SEED=#{SEED} CASES=#{successful + 1}"

      replayed = []
      run_seeded_property(INPUT, seed: SEED, runs: successful) { |value| replayed << value }
      assert_equal seen.first(successful), replayed
      refute_includes replayed, BAD_VALUE

      _, replay_seen = failing_run(SEED, runs: successful + 1)
      assert_equal successful, replay_seen.index(BAD_VALUE)
    end
  end

  def test_replay_uses_the_property_seed_override
    with_property_env('PROPERTY_SEED' => OTHER_SEED.to_s, 'PROPERTY_CASES' => '100') do
      seen = []
      error = assert_raises(Minitest::Assertion) do
        check_property(INPUT, seed: SEED) do |value|
          seen << value
          raise Minitest::Assertion, "bad value #{value}" if value == BAD_VALUE
        end
      end
      successful = seen.index(BAD_VALUE)

      assert_operator successful, :>=, 1, 'override seed must fail after at least one successful run'
      assert_includes error.message, "[property seed=#{OTHER_SEED}]"
      assert_includes error.message.lines.map(&:chomp), expected_replay(OTHER_SEED, successful + 1)
      refute_includes error.message, "SEED=#{SEED} "
    end
  end

  def test_replay_target_comes_from_property_target
    with_property_env('PROPERTY_TARGET' => 'link-cache') do
      error, = failing_run(SEED)

      assert_includes error.message.lines.map(&:chomp).join, 'make test-properties TARGET=link-cache FILTER='
    end
  end

  def test_other_errors_also_get_the_replay_command
    with_property_env do
      seen = []
      error = assert_raises(ArgumentError) do
        run_seeded_property(INPUT, seed: SEED) do |value|
          seen << value
          raise ArgumentError, 'boom' if value == BAD_VALUE
        end
      end
      successful = seen.index(BAD_VALUE)

      assert_operator successful, :>=, 1, 'seed must fail after at least one successful run'
      assert_includes error.message, 'boom'
      assert_includes error.message.lines.map(&:chomp), expected_replay(SEED, successful + 1)
    end
  end

  def test_check_property_is_skipped_in_examples_only_mutation_runs
    with_property_env('MUTATION_TEST_TESTS' => 'examples') do
      ran = false
      assert_raises(Minitest::Skip) do
        check_property(INPUT, seed: SEED) { ran = true }
      end

      refute ran
    end
  end

  def test_check_property_runs_when_the_mutation_flag_is_all
    with_property_env('MUTATION_TEST_TESTS' => 'all') do
      cases = 0
      check_property(INPUT, seed: SEED, runs: 5) { cases += 1 }

      assert_equal 5, cases
    end
  end

  def teardown
    PropertyStats.clear
    super
  end

  # Runs check_property and returns [outcome, inputs seen in order]. The
  # outcome is :passed, or the failure message when BAD_VALUE is seen.
  def run_recording(generator, runs:, fail_on: nil, classify: nil, interactions: [])
    seen = []
    check_property(generator, seed: SEED, runs: runs, classify: classify, interactions: interactions) do |value|
      seen << value
      raise Minitest::Assertion, "bad value #{value}" if value == fail_on
    end
    [:passed, seen]
  rescue Minitest::Assertion => e
    [e.message, seen]
  end

  def test_stats_count_distinct_inputs_and_interaction_cases
    with_property_env('PROPERTY_STATS' => '1') do
      seen = []
      classify = ->(value) { [value.even? ? 'even' : 'odd'] }
      check_property(INPUT, seed: SEED, runs: 100, classify: classify, interactions: %w[even odd never]) do |value|
        seen << value
      end

      record = PropertyStats.records.fetch(0)
      assert_equal "#{self.class.name}#test_stats_count_distinct_inputs_and_interaction_cases", record.test
      assert_equal 100, record.cases
      assert_equal seen.uniq.length, record.distinct
      assert_equal seen.count(&:even?), record.interactions.fetch('even')
      assert_equal seen.count(&:odd?), record.interactions.fetch('odd')
      assert_equal 0, record.interactions.fetch('never')
      assert_equal %w[even odd never], record.interactions.keys
    end
  end

  def test_stats_reject_an_undeclared_interaction_name
    with_property_env('PROPERTY_STATS' => '1') do
      assert_raises(ArgumentError) do
        check_property(INPUT, seed: SEED, runs: 5, classify: ->(_value) { ['undeclared'] }, interactions: []) { |v| v }
      end
    end
  end

  def test_stats_are_off_by_default_and_never_classify
    calls = 0
    classify = lambda do |_value|
      calls += 1
      []
    end
    with_property_env do
      check_property(INPUT, seed: SEED, runs: 20, classify: classify, interactions: []) { |v| v }
    end

    assert_equal 0, calls
    assert_empty PropertyStats.records
  end

  def test_stats_leave_the_generated_sequence_unchanged
    classify = ->(value) { [value.odd? ? 'odd' : 'even'] }
    off = with_property_env { run_recording(INPUT, runs: 100) }
    on = with_property_env('PROPERTY_STATS' => '1') do
      run_recording(INPUT, runs: 100, classify: classify, interactions: %w[odd even])
    end

    assert_equal :passed, off.first
    assert_equal off, on
    assert_equal 100, on.last.length
  end

  def test_stats_leave_a_failing_run_unchanged
    classify = ->(value) { [value.odd? ? 'odd' : 'even'] }
    off = with_property_env { run_recording(INPUT, runs: 100, fail_on: BAD_VALUE) }
    on = with_property_env('PROPERTY_STATS' => '1') do
      run_recording(INPUT, runs: 100, fail_on: BAD_VALUE, classify: classify, interactions: %w[odd even])
    end

    assert_includes off.first, "[property seed=#{SEED}] bad value #{BAD_VALUE}"
    assert_equal off, on
  end

  def test_report_lines_list_zero_count_interactions
    records = [
      PropertyStats::Record.new(
        test: 'TestExample#test_b',
        cases: 4,
        distinct: 3,
        interactions: { 'seen' => 2, 'never' => 0 },
      ),
      PropertyStats::Record.new(test: 'TestExample#test_a', cases: 1, distinct: 1, interactions: {}),
    ]

    expected = [
      'property-stats TestExample#test_a cases=1 distinct=1',
      'property-stats TestExample#test_b cases=4 distinct=3',
      'property-stats TestExample#test_b   interaction seen: 2',
      'property-stats TestExample#test_b   interaction never: 0',
    ]
    assert_equal expected, PropertyStats.report_lines(records)
  end

  def test_suite_is_derived_from_the_listing_test_class
    assert_equal 'html', PropertyTestSupport.suite_for_class('TestHtmlScan')
    assert_equal 'backlinks', PropertyTestSupport.suite_for_class('TestBacklinkBuilderProperties')
    assert_nil PropertyTestSupport.suite_for_class('TestNotInAnySuite')
  end
end
