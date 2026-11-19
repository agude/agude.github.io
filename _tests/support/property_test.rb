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

  # Runs a seeded property. With `classify:`, a lambda that returns the names
  # of the interactions an input exercises, and `interactions:`, every name
  # the report must list (even at zero), stats are collected when
  # PROPERTY_STATS is set (make test-properties STATS=1). Stats are read-only:
  # they never change the generated inputs, seeds, or pass/fail results, and
  # the classifier runs only when stats are on.
  def check_property(generator, seed:, runs: 100, classify: nil, interactions: [], &property)
    cases = property_cases(runs)
    recorder = PropertyStats::Recorder.new(self, classify, interactions) if PropertyStats.enabled?
    run_seeded_property(generator, seed: Integer(ENV.fetch('PROPERTY_SEED', seed)), runs: cases) do |input|
      property.call(input)
      recorder&.observe(input)
    end
  ensure
    recorder&.finish
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

# Opt-in per-property report: distinct inputs and interaction counts.
#
# A failing run records only the cases that completed before the failure.
# Counts are per case: an input that exercises a name adds one to its count,
# even if other inputs produced the same value.
module PropertyStats
  Record = Struct.new(:test, :cases, :distinct, :interactions, keyword_init: true)

  # Collects one property's stats while its check runs.
  class Recorder
    def initialize(owner, classify, interactions)
      @test = "#{owner.class.name}##{owner.name}"
      @classify = classify
      @declared = interactions.to_a
      @counts = @declared.to_h { |name| [name, 0] }
      @inputs = Set.new
      @cases = 0
      PropertyStats.install_hook
    end

    def observe(input)
      @cases += 1
      @inputs << input
      return unless @classify

      Array(@classify.call(input)).uniq.each do |name|
        raise ArgumentError, "#{@test}: undeclared interaction #{name.inspect}" unless @counts.key?(name)

        @counts[name] += 1
      end
    end

    def finish
      PropertyStats.records << Record.new(
        test: @test,
        cases: @cases,
        distinct: @inputs.size,
        interactions: @counts,
      )
    end
  end

  @records = []
  @hook_installed = false

  class << self
    attr_reader :records

    def enabled?
      value = ENV.fetch('PROPERTY_STATS', '')
      !value.empty? && value != '0'
    end

    def clear
      @records.clear
    end

    # Report lines for `records`, sorted by test name so the order is stable.
    def report_lines(records = @records)
      records.sort_by(&:test).flat_map do |record|
        header = "property-stats #{record.test} cases=#{record.cases} distinct=#{record.distinct}"
        counts = record.interactions.map do |name, count|
          "property-stats #{record.test}   interaction #{name}: #{count}"
        end
        [header, *counts]
      end
    end

    def install_hook
      return if @hook_installed

      @hook_installed = true
      Minitest.after_run do
        lines = PropertyStats.report_lines
        puts lines.join("\n") if PropertyStats.enabled? && !lines.empty?
      end
    end
  end
end
