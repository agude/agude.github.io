# frozen_string_literal: true

require 'prop_check'

# Seeded PropCheck runs used by the Ruby property suites.
module PropertyTestSupport
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

  def run_seeded_property(generator, seed:, runs: 100, &property)
    PropCheck.forall(seeded_property_generator(generator, seed))
             .with_config(n_runs: runs)
             .check do |input|
      property.call(input)
    rescue Minitest::Assertion => e
      raise Minitest::Assertion, "[property seed=#{seed}] #{e.message}"
    end
  end
end
