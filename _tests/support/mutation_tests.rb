# frozen_string_literal: true

require 'open3'
require_relative 'property_test_suites'
require_relative 'mutation_dispositions'

# Mutant requires this file before selecting tests. Minitest runs under Mutant
# so its own autorun and coverage hooks stay disabled in the worker processes.
if $PROGRAM_NAME == __FILE__
  target = ENV.fetch('MUTATION_TEST_TARGET')
  mode = PropertyTestSuites.test_mode(ENV.fetch('MUTATION_TEST_TESTS', 'all'))
  subjects = PropertyTestSuites.subjects(PropertyTestSuites.fetch(target))

  # Check the matched count before mutating: an expression that matches
  # nothing produces no mutants and no error.
  output, status = Open3.capture2e('mutant', 'environment', 'subject', 'list', '--', *subjects)
  abort "mutant environment subject list failed for #{target.inspect}:\n#{output}" unless status.success?

  actual = PropertyTestSuites.parse_subject_count(output)
  abort "Could not read the subject count from mutant output:\n#{output}" if actual.nil?

  error = PropertyTestSuites.subject_count_error(target, actual)
  abort error if error

  puts "Mutant matched #{actual} subjects for suite #{target.inspect} (declared #{actual}, tests #{mode})."
  $stdout.flush
  # Mutant exits nonzero whenever a mutant survives, so its status alone
  # cannot say whether the run passes. The session file gives the survivors.
  paths_before = MutationDispositions.session_paths
  _pid, status = Process.wait2(Process.spawn('mutant', 'run', '--', *subjects))

  session_path = MutationDispositions.new_session(paths_before)
  abort "mutant run wrote no session file (exit status #{status.exitstatus})" if session_path.nil?

  outcomes = MutationDispositions.outcomes(MutationDispositions.read_session(session_path))
  if mode == 'examples'
    # Examples-only runs cannot match the dispositions, so they report survivors only.
    puts MutationDispositions.mutation_lines('SURVIVOR (examples only, not gated)', outcomes.survivors)
    puts "Examples-only run: #{outcomes.survivors.length} survivors, #{outcomes.timeouts.length} timed out."
    exit 0
  end

  report = MutationDispositions.evaluate(target, outcomes, MutationDispositions.load_entries)
  puts MutationDispositions.report_lines(report)
  unexplained = !status.success? && outcomes.survivors.empty?
  puts "mutant exited #{status.exitstatus} with no survivors." if unexplained
  exit(report.passed? && !unexplained ? 0 : 1)
else
  require 'mutant/minitest/coverage'

  suite = PropertyTestSuites.fetch(ENV.fetch('MUTATION_TEST_TARGET'))
  files = PropertyTestSuites.mutation_files(suite, PropertyTestSuites.test_mode(ENV.fetch('MUTATION_TEST_TESTS', 'all')))
  PropertyTestSuites.load_tests(files)
  files.each_value do |tests|
    tests.each do |test_class, subjects|
      subjects.each { |subject| Object.const_get(test_class).cover(subject) }
    end
  end
end
