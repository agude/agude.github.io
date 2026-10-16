# frozen_string_literal: true

require_relative '../test_helper'
require 'yaml'

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
  # the git index, neither of which exists inside the test container. It is
  # tested on the host instead, by _scripts/tests/test_pre_commit.py (run by
  # `make test-scripts`), with stub docker and uv executables.
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

  # Every step's `run:` command across all jobs, with shell comments removed.
  # Comments and step names are not commands, so naming a script there does
  # not wire it up.
  def run_commands(workflow_yaml)
    jobs = YAML.safe_load(workflow_yaml).fetch('jobs')
    jobs.values.flat_map { |job| job.fetch('steps', []) }
        .filter_map { |step| step['run'] }
        .map { |command| strip_shell_comments(command) }
  end

  # Shell starts a comment at a `#` that begins a word. Quotes are not parsed,
  # so a quoted " #" is also cut; that can only make a wired script look
  # unwired, which fails loudly.
  def strip_shell_comments(command)
    command.lines.map { |line| line.sub(/(?:^|\s)#.*/, '') }.join
  end

  def unwired_checkers(scripts, workflow_yaml)
    commands = run_commands(workflow_yaml)
    scripts.reject { |script| commands.any? { |command| command.include?("_bin/#{script}") } }
  end

  def test_unwired_checkers_ignores_comments_and_step_names
    workflow_yaml = <<~YAML
      # _bin/check_commented.rb is described here but never run.
      on: push
      jobs:
        test:
          runs-on: ubuntu-latest
          steps:
            - name: Run _bin/check_named.rb
              run: echo skipped
            - run: bundle exec ruby _bin/check_wired.rb
    YAML
    scripts = %w[check_commented.rb check_named.rb check_wired.rb]

    assert_equal %w[check_commented.rb check_named.rb], unwired_checkers(scripts, workflow_yaml)
  end

  def test_unwired_checkers_ignores_shell_comments
    workflow_yaml = <<~YAML
      on: push
      jobs:
        test:
          runs-on: ubuntu-latest
          steps:
            - run: |
                # bundle exec ruby _bin/check_line_comment.rb
                echo skipped
            - run: |
                echo skipped # _bin/check_trailing_comment.rb
            - run: |
                echo "#" && bundle exec ruby _bin/check_wired.rb
                bundle exec ruby _bin/check_also_wired.rb # gate
    YAML
    scripts = %w[check_also_wired.rb check_line_comment.rb check_trailing_comment.rb check_wired.rb]

    assert_equal %w[check_line_comment.rb check_trailing_comment.rb],
                 unwired_checkers(scripts, workflow_yaml)
  end

  def test_every_checker_runs_in_ci
    unwired = unwired_checkers(checker_scripts, File.read(WORKFLOW))

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
