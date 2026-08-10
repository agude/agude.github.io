# frozen_string_literal: true

require_relative '../test_helper'

# Meta-guard for the CI gates in _bin/. A checker that nothing runs, or that
# nothing tests, is worse than no checker at all: it looks like coverage on
# the org chart and catches nothing. These assertions fail the moment a new
# `check_*` script is added without wiring it into CI and _tests/bin/.
class TestBinScriptsAreWiredUp < Minitest::Test
  REPO_ROOT = File.expand_path('../..', __dir__)
  BIN_DIR = File.join(REPO_ROOT, '_bin')
  TESTS_DIR = __dir__
  WORKFLOW = File.join(REPO_ROOT, '.github/workflows/jekyll.yml')

  # pre-commit.sh is a local git hook, not a CI gate: it drives Docker and
  # the git index, neither of which exists inside the test container.
  UNTESTED = ['pre-commit.sh'].freeze

  def checker_scripts
    Dir.glob(File.join(BIN_DIR, 'check_*')).map { |path| File.basename(path) }.sort
  end

  def test_every_checker_has_a_test_file
    missing = checker_scripts.reject do |script|
      File.exist?(File.join(TESTS_DIR, "test_#{File.basename(script, '.*')}.rb"))
    end

    assert_empty missing,
                 "_bin checkers with no _tests/bin/test_<name>.rb:\n  #{missing.join("\n  ")}"
  end

  def test_every_checker_runs_in_ci
    workflow = File.read(WORKFLOW)
    unwired = checker_scripts.reject { |script| workflow.include?("_bin/#{script}") }

    assert_empty unwired,
                 "_bin checkers never invoked by .github/workflows/jekyll.yml:\n  #{unwired.join("\n  ")}"
  end

  def test_every_bin_script_the_workflow_names_exists
    workflow = File.read(WORKFLOW)
    referenced = workflow.scan(%r{_bin/([\w.-]+)}).flatten.uniq
    missing = referenced.reject { |script| File.exist?(File.join(BIN_DIR, script)) }

    assert_empty missing,
                 "CI invokes _bin scripts that do not exist:\n  #{missing.join("\n  ")}"
    refute_empty referenced, 'Expected the workflow to invoke at least one _bin script'
  end

  def test_untested_list_only_names_scripts_that_exist
    # Keeps the exemption list from silently outliving the file it exempts.
    stale = UNTESTED.reject { |script| File.exist?(File.join(BIN_DIR, script)) }

    assert_empty stale, "UNTESTED names scripts that no longer exist: #{stale.join(', ')}"
  end
end
