# frozen_string_literal: true

require_relative '../test_helper'
require_relative 'property_test_suites'

# Covers the Mutant subject-count guard used by `make test-mutations`.
class TestPropertyTestSuites < Minitest::Test
  def test_every_suite_declares_a_subject_count
    assert_equal PropertyTestSuites::SUITES.keys.sort, PropertyTestSuites::DECLARED_SUBJECT_COUNTS.keys.sort
  end

  def test_subjects_are_deduplicated_across_test_files
    # HtmlAttributes.append is covered by three html test files.
    subjects = PropertyTestSuites.subjects(PropertyTestSuites.fetch('html'))

    assert_equal 1, subjects.count('Jekyll::Infrastructure::HtmlAttributes.append')
  end

  def test_parse_subject_count_reads_the_header_line
    output = "Subjects in environment: 3\nJekyll::A.b\nJekyll::A.c\nJekyll::A#d\n"

    assert_equal 3, PropertyTestSuites.parse_subject_count(output)
  end

  def test_parse_subject_count_is_nil_without_the_header
    assert_nil PropertyTestSuites.parse_subject_count("unexpected output\n")
  end

  def test_subject_count_error_is_nil_when_counts_match
    declared = PropertyTestSuites::DECLARED_SUBJECT_COUNTS.fetch('html')

    assert_nil PropertyTestSuites.subject_count_error('html', declared)
  end

  def test_subject_count_error_names_suite_expected_and_actual
    declared = PropertyTestSuites::DECLARED_SUBJECT_COUNTS.fetch('backlinks')
    message = PropertyTestSuites.subject_count_error('backlinks', declared - 1)

    assert_includes message, 'suite "backlinks"'
    assert_includes message, "expected #{declared} subjects"
    assert_includes message, "Mutant matched #{declared - 1}"
  end

  def test_test_mode_accepts_all_and_examples
    assert_equal 'all', PropertyTestSuites.test_mode('all')
    assert_equal 'examples', PropertyTestSuites.test_mode('examples')
  end

  def test_test_mode_rejects_other_values
    error = assert_raises(ArgumentError) { PropertyTestSuites.test_mode('props') }

    assert_includes error.message, 'Unknown TESTS value "props"'
  end

  def test_examples_only_flag_comes_from_the_mutation_test_tests_variable
    refute PropertyTestSuites.examples_only?({})
    refute PropertyTestSuites.examples_only?({ 'MUTATION_TEST_TESTS' => 'all' })
    assert PropertyTestSuites.examples_only?({ 'MUTATION_TEST_TESTS' => 'examples' })
  end

  def test_all_mode_keeps_every_test_file
    suite = PropertyTestSuites.fetch('html')

    assert_equal suite, PropertyTestSuites.mutation_files(suite, 'all')
  end

  def test_examples_mode_drops_every_properties_file
    PropertyTestSuites::SUITES.each do |target, suite|
      files = PropertyTestSuites.mutation_files(suite, 'examples').keys

      assert_empty files.select { |path| path.end_with?('_properties') }, "examples mode kept properties in #{target}"
      assert_equal suite.keys.reject { |path| path.end_with?('_properties') }, files
    end
  end

  def test_examples_mode_still_covers_every_subject_with_an_example_test
    # Examples-only runs must not leave a subject with no test that can kill
    # its mutants.
    PropertyTestSuites::SUITES.each do |target, suite|
      examples = PropertyTestSuites.mutation_files(suite, 'examples')
      covered = examples.values.flat_map { |tests| tests.values.flatten }

      PropertyTestSuites.subjects(suite).each do |subject|
        assert_includes covered, subject, "examples mode covers no test for #{subject} in #{target}"
      end
    end
  end
end
