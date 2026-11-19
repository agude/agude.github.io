# frozen_string_literal: true

require 'tmpdir'
require_relative '../test_helper'
require_relative 'mutation_dispositions'

# Covers how `make test-mutations` matches Mutant survivors to dispositions.
class TestMutationDispositions < Minitest::Test
  SUBJECT = 'Jekyll::Infrastructure::HtmlAttributes.remove'
  SOURCE = "def self.remove(tag, name)\n  tag\nend"
  OTHER_SOURCE = "def self.remove(tag, name)\n  tag.strip\nend"

  # One mutant as Mutant writes it in a session file. Only `source` and the
  # outcome flags affect matching; the identification carries a line number,
  # as Mutant's does.
  def mutation(source, line: 10, test_result: true, timeout: false, process_abort: false, diff: nil)
    {
      'mutation_result' => {
        'mutation_identification' => "evil:#{SUBJECT}:/workspace/_plugins/src/x.rb:#{line}:abcde",
        'mutation_source' => source,
        'mutation_diff' => diff,
        'mutation_type' => 'evil',
      },
      'criteria_result' => {
        'test_result' => test_result,
        'timeout' => timeout,
        'process_abort' => process_abort,
      },
    }
  end

  def session(*mutations, subject: SUBJECT)
    {
      'subject_results' => [
        { 'expression_syntax' => subject, 'coverage_results' => mutations },
      ],
    }
  end

  def entry(subject: SUBJECT, key: MutationDispositions.key_for(SOURCE), suite: 'html', disposition: 'equivalent')
    MutationDispositions::Entry.new(
      suite: suite,
      subject: subject,
      key: key,
      disposition: disposition,
      reason: 'A reason.',
    )
  end

  def outcomes(*mutations)
    MutationDispositions.outcomes(session(*mutations))
  end

  def test_key_is_sixteen_hex_digits_of_the_mutated_source
    key = MutationDispositions.key_for(SOURCE)

    assert_match(/\A\h{16}\z/, key)
    assert_equal key, MutationDispositions.key_for(SOURCE)
    refute_equal key, MutationDispositions.key_for(OTHER_SOURCE)
  end

  def test_key_is_stable_when_an_unrelated_line_moves
    # Mutant's identification carries the line number, so a line shift
    # changes it. The key must not change with it.
    before = outcomes(mutation(SOURCE, line: 10, test_result: false))
    after = outcomes(mutation(SOURCE, line: 42, test_result: false))

    assert_equal before.survivors.map(&:key), after.survivors.map(&:key)
    refute_equal before.survivors.first.identification, after.survivors.first.identification
  end

  def test_key_changes_when_the_mutated_code_changes
    assert_equal outcomes(mutation(SOURCE, test_result: false)).survivors.first.key,
                 outcomes(mutation(SOURCE, line: 99, test_result: false)).survivors.first.key
    refute_equal outcomes(mutation(SOURCE, test_result: false)).survivors.first.key,
                 outcomes(mutation(OTHER_SOURCE, test_result: false)).survivors.first.key
  end

  def test_outcomes_separate_survivors_from_kills_and_timeouts
    result = outcomes(
      mutation(SOURCE, line: 1, test_result: false),
      mutation(OTHER_SOURCE, line: 2, test_result: true),
      mutation(SOURCE, line: 3, test_result: false, timeout: true),
      mutation(OTHER_SOURCE, line: 4, test_result: false, process_abort: true),
    )

    assert_equal 1, result.survivors.length
    assert_equal MutationDispositions.key_for(SOURCE), result.survivors.first.key
    assert_equal 1, result.timeouts.length
    assert_equal MutationDispositions.key_for(SOURCE), result.timeouts.first.key
  end

  def test_survivor_with_a_listed_subject_and_key_is_matched
    report = MutationDispositions.evaluate(
      'html',
      outcomes(mutation(SOURCE, test_result: false)),
      [entry],
    )

    assert_empty report.unlisted
    assert_empty report.stale
    assert report.passed?
  end

  def test_unlisted_survivor_fails_the_run_and_its_diff_is_reported
    diff = "@@ -1,3 +1,3 @@\n-tag\n+tag.strip\n"
    report = MutationDispositions.evaluate(
      'html',
      outcomes(mutation(SOURCE, test_result: false, diff: diff)),
      [],
    )
    lines = MutationDispositions.report_lines(report)

    refute report.passed?
    assert_equal 1, report.unlisted.length
    assert_includes lines, "UNLISTED SURVIVOR #{SUBJECT} #{MutationDispositions.key_for(SOURCE)}"
    assert_includes lines, '  | -tag'
    assert_includes lines, 'Mutation dispositions: FAILED'
  end

  def test_listed_entry_with_no_matching_survivor_is_stale_and_fails
    report = MutationDispositions.evaluate('html', outcomes, [entry])
    lines = MutationDispositions.report_lines(report)

    refute report.passed?
    assert_equal 1, report.stale.length
    assert_empty report.unlisted
    assert(lines.any? { |line| line.start_with?('STALE DISPOSITION') && line.include?(SUBJECT) })
  end

  def test_entry_for_a_killed_mutant_is_stale
    report = MutationDispositions.evaluate('html', outcomes(mutation(SOURCE, test_result: true)), [entry])

    refute report.passed?
    assert_equal 1, report.stale.length
  end

  def test_entries_for_other_suites_are_not_checked
    report = MutationDispositions.evaluate(
      'html',
      outcomes,
      [entry(suite: 'markdown')],
    )

    assert report.passed?
    assert_empty report.stale
  end

  def test_timeouts_are_listed_separately_and_do_not_fail_the_run
    report = MutationDispositions.evaluate(
      'html',
      outcomes(mutation(SOURCE, test_result: false, timeout: true)),
      [],
    )
    lines = MutationDispositions.report_lines(report)

    assert report.passed?
    assert_empty report.unlisted
    assert(lines.any? { |line| line.start_with?('TIMED OUT') && line.include?(MutationDispositions.key_for(SOURCE)) })
    assert_includes lines, 'Mutation dispositions: PASSED'
  end

  def test_checked_in_dispositions_load_and_name_real_subjects
    entries = MutationDispositions.load_entries

    refute_empty entries
    assert(entries.all? { |item| PropertyTestSuites::SUITES.key?(item.suite) })
    assert(entries.all? { |item| MutationDispositions::DISPOSITIONS.include?(item.disposition) })
  end

  # Writes `text` to a temporary dispositions file and loads it.
  def load_text(text)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'dispositions.yml')
      File.write(path, text)
      MutationDispositions.load_entries(path)
    end
  end

  def valid_row(overrides = {})
    fields = {
      'suite' => 'html',
      'subject' => SUBJECT,
      'key' => MutationDispositions.key_for(SOURCE),
      'disposition' => 'equivalent',
      'reason' => 'A reason.',
    }.merge(overrides)
    "- #{fields.map { |name, value| "#{name}: #{value.inspect}" }.join("\n  ")}\n"
  end

  def test_loader_accepts_a_valid_entry
    entries = load_text(valid_row)

    assert_equal 1, entries.length
    assert_equal 'equivalent', entries.first.disposition
  end

  def test_loader_rejects_an_unknown_suite
    error = assert_raises(ArgumentError) { load_text(valid_row('suite' => 'nope')) }

    assert_includes error.message, 'unknown suite'
  end

  def test_loader_rejects_a_subject_outside_its_suite
    error = assert_raises(ArgumentError) { load_text(valid_row('subject' => 'Jekyll::Nope.call')) }

    assert_includes error.message, 'is not a subject of suite "html"'
  end

  def test_loader_rejects_a_malformed_key
    error = assert_raises(ArgumentError) { load_text(valid_row('key' => 'abc')) }

    assert_includes error.message, 'key must be 16 hex digits'
  end

  def test_loader_rejects_an_unquoted_numeric_key
    error = assert_raises(ArgumentError) { load_text("- suite: html\n  subject: #{SUBJECT}\n  key: 1234567890123456\n  disposition: equivalent\n  reason: x\n") }

    assert_includes error.message, 'key must be 16 hex digits'
  end

  def test_loader_rejects_an_unknown_disposition
    error = assert_raises(ArgumentError) { load_text(valid_row('disposition' => 'killed')) }

    assert_includes error.message, 'disposition must be one of'
  end

  def test_loader_rejects_an_empty_reason
    error = assert_raises(ArgumentError) { load_text(valid_row('reason' => '  ')) }

    assert_includes error.message, 'reason must be a non-empty string'
  end

  def test_loader_rejects_a_missing_field
    text = "- suite: html\n  subject: #{SUBJECT}\n  key: '#{MutationDispositions.key_for(SOURCE)}'\n  reason: x\n"
    error = assert_raises(ArgumentError) { load_text(text) }

    assert_includes error.message, 'is missing disposition'
  end

  def test_loader_rejects_a_duplicate_entry
    error = assert_raises(ArgumentError) { load_text(valid_row + valid_row) }

    assert_includes error.message, 'duplicate disposition'
  end

  def test_read_session_accepts_gzip_and_plain_json
    Dir.mktmpdir do |dir|
      plain = File.join(dir, 'plain.json')
      gzipped = File.join(dir, 'gzipped.json.gz')
      File.write(plain, JSON.generate(session(mutation(SOURCE))))
      Zlib::GzipWriter.open(gzipped) { |gz| gz.write(JSON.generate(session(mutation(SOURCE)))) }

      assert_equal MutationDispositions.read_session(plain), MutationDispositions.read_session(gzipped)
    end
  end
end
