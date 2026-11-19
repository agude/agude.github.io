# frozen_string_literal: true

require 'open3'
require_relative 'property_test_suites'

# Mutant requires this file before selecting tests. Minitest runs under Mutant
# so its own autorun and coverage hooks stay disabled in the worker processes.
if $PROGRAM_NAME == __FILE__
  target = ENV.fetch('MUTATION_TEST_TARGET')
  subjects = PropertyTestSuites.subjects(PropertyTestSuites.fetch(target))

  # Check the matched count before mutating: an expression that matches
  # nothing produces no mutants and no error.
  output, status = Open3.capture2e('mutant', 'environment', 'subject', 'list', '--', *subjects)
  abort "mutant environment subject list failed for #{target.inspect}:\n#{output}" unless status.success?

  actual = PropertyTestSuites.parse_subject_count(output)
  abort "Could not read the subject count from mutant output:\n#{output}" if actual.nil?

  error = PropertyTestSuites.subject_count_error(target, actual)
  abort error if error

  puts "Mutant matched #{actual} subjects for suite #{target.inspect} (declared #{actual})."
  $stdout.flush # exec does not flush Ruby's buffered stdout.
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
