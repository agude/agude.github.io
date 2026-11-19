# frozen_string_literal: true

require 'prop_check'

# Running property_test_suites.rb as the entry point defines the constants
# before any test file loads; requiring it again would redefine them.
require_relative 'property_test_suites' unless defined?(PropertyTestSuites)

# Seeded PropCheck runs used by the Ruby property suites.
#
# Case K depends on the K-1 cases before it, so a failure is replayed by
# rerunning the same seed for more cases than PropCheck reports successful.
module PropertyTestSupport
  # Returns the suite that lists `class_name`, or nil when no suite or more than
  # one suite lists it.
  def self.suite_for_class(class_name)
    suites = PropertyTestSuites::SUITES.select do |_target, files|
      files.each_value.any? { |classes| classes.key?(class_name) }
    end
    suites.keys.one? ? suites.keys.first : nil
  end

  def check_property(generator, seed:, runs: 100, &property)
    run_seeded_property(generator, seed: Integer(ENV.fetch('PROPERTY_SEED', seed)), runs: property_cases(runs), &property)
  end

  def property_cases(default = 100)
    cases = Integer(ENV.fetch('PROPERTY_CASES', default))
    raise ArgumentError, 'PROPERTY_CASES must be positive' unless cases.positive?

    cases
  end

  def seeded_property_generator(generator, seed)
    random = Random.new(seed)
    PropCheck::Generator.new do |**options|
      generator.generate(**options, rng: random)
    end
  end

  # Runs the property and, on failure, appends a replay command. The replay
  # reruns `seed` for `n_successful + 1` cases, the first failing case.
  def run_seeded_property(generator, seed:, runs: 100, &property)
    PropCheck.forall(seeded_property_generator(generator, seed))
             .with_config(n_runs: runs)
             .check do |input|
      property.call(input)
    rescue Minitest::Assertion => e
      raise Minitest::Assertion, "[property seed=#{seed}] #{e.message}"
    end
  rescue StandardError, Minitest::Assertion => e
    raise unless e.respond_to?(:prop_check_info)

    # Exception#exception returns a copy that keeps the prop_check_info singleton.
    replay = replay_command(seed, e.prop_check_info.fetch(:n_successful))
    raise e.exception("#{e.message}\n#{replay}")
  end

  def replay_command(seed, successful_runs)
    [
      'make test-properties',
      "TARGET=#{replay_target}",
      "FILTER=#{replay_method}",
      "SEED=#{seed}",
      "CASES=#{successful_runs + 1}",
    ].join(' ')
  end

  # The Makefile sets PROPERTY_TARGET. Without it (plain `make test`), find the
  # suite that lists this test class.
  def replay_target
    env_target = ENV.fetch('PROPERTY_TARGET', '')
    return env_target unless env_target.empty?

    PropertyTestSupport.suite_for_class(self.class.name) || '<suite>'
  end

  def replay_method
    respond_to?(:name) && name ? name : '<test_method>'
  end
end
