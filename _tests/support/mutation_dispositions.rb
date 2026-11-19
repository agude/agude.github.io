# frozen_string_literal: true

require 'digest'
require 'json'
require 'yaml'
require 'zlib'
require_relative 'property_test_suites'

# Decides whether a `make test-mutations` run passes. Mutant leaves a mutant
# alive when no test fails on it; a run passes only when every alive mutant is
# listed in mutation_dispositions.yml with a reason.
#
# Mutant writes each run to .mutant/results/<session>.json.gz. Its
# `mutation_source` holds the whole mutated method, with no line numbers, so a
# digest of it keys a mutation across unrelated line moves. The key changes
# when the method's code changes, which makes the old reason stop matching.
module MutationDispositions
  FILE = File.expand_path('mutation_dispositions.yml', __dir__)
  RESULTS_GLOB = '.mutant/results/*.json{,.gz}'
  DISPOSITIONS = %w[equivalent out_of_scope].freeze
  FIELDS = %w[suite subject key disposition reason].freeze
  KEY_PATTERN = /\A\h{16}\z/

  # One mutant from a session. `identification` and `diff` are for people
  # reading the report; only `subject` and `key` take part in matching.
  Mutation = Struct.new(:subject, :key, :identification, :diff, keyword_init: true)
  # One listed entry from the dispositions file.
  Entry = Struct.new(:suite, :subject, :key, :disposition, :reason, keyword_init: true)
  # The outcome of one run for one suite. `unlisted` and `stale` fail the run.
  Outcomes = Struct.new(:survivors, :timeouts, keyword_init: true)
  Report = Struct.new(:suite, :outcomes, :listed, :unlisted, :stale, keyword_init: true) do
    def passed?
      unlisted.empty? && stale.empty?
    end
  end

  # The matching key for a mutant, from its mutated method source.
  def self.key_for(mutation_source)
    Digest::SHA256.hexdigest(mutation_source)[0, 16]
  end

  # Session files in .mutant/results that exist now.
  def self.session_paths
    Dir.glob(RESULTS_GLOB)
  end

  # The session file that a run added, or nil when it added none.
  def self.new_session(paths_before)
    (session_paths - paths_before).max_by { |path| File.mtime(path) }
  end

  # Parses a Mutant session file, gzip compressed or plain JSON.
  def self.read_session(path)
    content = File.binread(path)
    content = Zlib.gunzip(content) if content.start_with?("\x1F\x8B".b)
    JSON.parse(content)
  end

  # Survivors and timeouts in a parsed session. Mutant counts a mutant as
  # killed when a test fails, the process aborts, or it times out, so only
  # the rest survive. A timeout is listed on its own and does not fail a run.
  def self.outcomes(session)
    survivors = []
    timeouts = []
    session.fetch('subject_results').each do |subject_result|
      subject = subject_result.fetch('expression_syntax')
      subject_result.fetch('coverage_results').each do |coverage|
        mutation = coverage.fetch('mutation_result')
        criteria = coverage.fetch('criteria_result')
        entry = Mutation.new(
          subject: subject,
          key: key_for(mutation.fetch('mutation_source')),
          identification: mutation.fetch('mutation_identification'),
          diff: mutation['mutation_diff'] || mutation.fetch('mutation_source'),
        )
        if criteria['timeout']
          timeouts << entry
        elsif !criteria['test_result'] && !criteria['process_abort']
          survivors << entry
        end
      end
    end
    Outcomes.new(survivors: survivors, timeouts: timeouts)
  end

  # Reads and checks the dispositions file. Raises ArgumentError on the first
  # invalid entry, so a typo cannot quietly leave a survivor unlisted.
  def self.load_entries(path = FILE)
    data = YAML.safe_load_file(path) || []
    raise ArgumentError, "#{path} must hold a list of entries" unless data.is_a?(Array)

    entries = data.each_with_index.map { |raw, index| build_entry(raw, index) }
    seen = {}
    entries.each do |entry|
      identity = [entry.suite, entry.subject, entry.key]
      raise ArgumentError, "duplicate disposition for #{identity.join(' ')}" if seen.key?(identity)

      seen[identity] = true
    end
    entries
  end

  def self.build_entry(raw, index)
    label = "entry #{index + 1}"
    raise ArgumentError, "#{label} must be a mapping" unless raw.is_a?(Hash)

    missing = FIELDS - raw.keys
    extra = raw.keys - FIELDS
    raise ArgumentError, "#{label} is missing #{missing.join(', ')}" unless missing.empty?
    raise ArgumentError, "#{label} has unknown fields #{extra.join(', ')}" unless extra.empty?

    suite, subject, key, disposition, reason = FIELDS.map { |field| raw.fetch(field) }
    raise ArgumentError, "#{label}: unknown suite #{suite.inspect}" unless PropertyTestSuites::SUITES.key?(suite)

    suite_subjects = PropertyTestSuites.subjects(PropertyTestSuites::SUITES.fetch(suite))
    unless suite_subjects.include?(subject)
      raise ArgumentError, "#{label}: #{subject.inspect} is not a subject of suite #{suite.inspect}"
    end
    unless key.is_a?(String) && KEY_PATTERN.match?(key)
      raise ArgumentError, "#{label}: key must be 16 hex digits in quotes, got #{key.inspect}"
    end
    unless DISPOSITIONS.include?(disposition)
      raise ArgumentError, "#{label}: disposition must be one of #{DISPOSITIONS.join(', ')}"
    end
    unless reason.is_a?(String) && !reason.strip.empty?
      raise ArgumentError, "#{label}: reason must be a non-empty string"
    end

    Entry.new(suite: suite, subject: subject, key: key, disposition: disposition, reason: reason)
  end

  # Matches one run's survivors against the entries for `suite`. A survivor
  # passes when an entry has its subject and key. An entry with no survivor is
  # stale. Entries for other suites are not checked.
  def self.evaluate(suite, outcomes, entries)
    listed = entries.select { |entry| entry.suite == suite }
    by_identity = listed.to_h { |entry| [[entry.subject, entry.key], entry] }
    survivor_identities = outcomes.survivors.map { |mutation| [mutation.subject, mutation.key] }

    unlisted = outcomes.survivors.reject { |mutation| by_identity.key?([mutation.subject, mutation.key]) }
    stale = listed.reject { |entry| survivor_identities.include?([entry.subject, entry.key]) }
    Report.new(suite: suite, outcomes: outcomes, listed: listed, unlisted: unlisted, stale: stale)
  end

  # Lines for a mutant list: subject, key, Mutant's identification, and diff.
  def self.mutation_lines(heading, mutations)
    mutations.flat_map do |mutation|
      [
        "#{heading} #{mutation.subject} #{mutation.key}",
        "  #{mutation.identification}",
        *mutation.diff.to_s.lines.map { |line| "  | #{line.chomp}" },
      ]
    end
  end

  def self.report_lines(report)
    survivors = report.outcomes.survivors
    listed_count = survivors.length - report.unlisted.length
    counts = DISPOSITIONS.map do |disposition|
      "#{disposition} #{report.listed.count { |entry| entry.disposition == disposition }}"
    end
    lines = [
      "Mutation dispositions for suite #{report.suite.inspect}: #{survivors.length} survivors, " \
      "#{listed_count} listed (#{counts.join(', ')}), #{report.unlisted.length} unlisted, " \
      "#{report.stale.length} stale, #{report.outcomes.timeouts.length} timed out.",
    ]
    lines.concat(mutation_lines('UNLISTED SURVIVOR', report.unlisted))
    report.stale.each do |entry|
      lines << "STALE DISPOSITION #{entry.subject} #{entry.key} (#{entry.disposition}): no survivor has this key."
    end
    lines.concat(mutation_lines('TIMED OUT (counted as killed, not gated)', report.outcomes.timeouts))
    lines << (report.passed? ? 'Mutation dispositions: PASSED' : 'Mutation dispositions: FAILED')
    lines
  end
end
