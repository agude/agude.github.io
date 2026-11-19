# frozen_string_literal: true

require_relative 'property_test_suites'

# Mutant requires this file before selecting tests. Minitest runs under Mutant
# so its own autorun and coverage hooks stay disabled in the worker processes.
if $PROGRAM_NAME == __FILE__
  suite = PropertyTestSuites.fetch(ENV.fetch('MUTATION_TEST_TARGET'))
  subjects = suite.values.flat_map(&:values).flatten.uniq
  exec('mutant', 'run', '--', *subjects)
else
  require 'mutant/minitest/coverage'

  suite = PropertyTestSuites.fetch(ENV.fetch('MUTATION_TEST_TARGET'))
  PropertyTestSuites.load_tests(suite)
  suite.each_value do |tests|
    tests.each do |test_class, subjects|
      subjects.each { |subject| Object.const_get(test_class).cover(subject) }
    end
  end
end
