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
end
