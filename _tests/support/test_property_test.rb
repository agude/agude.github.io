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
  PROPERTY_ENV_KEYS = %w[PROPERTY_SEED PROPERTY_CASES PROPERTY_TARGET].freeze

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

  def test_suite_is_derived_from_the_listing_test_class
    assert_equal 'html', PropertyTestSupport.suite_for_class('TestHtmlScan')
    assert_equal 'backlinks', PropertyTestSupport.suite_for_class('TestBacklinkBuilderProperties')
    assert_nil PropertyTestSupport.suite_for_class('TestNotInAnySuite')
  end
end
