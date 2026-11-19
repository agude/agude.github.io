# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

# Setup for a `make test-mutations` run: the Minitest seed that fixes test
# order, and a scratch copy of the checkout that Mutant runs in. Mutant and
# the mutated code write relative to the working directory, so a run in the
# checkout could leave files there (a mutant that makes the image manifest
# path relative writes manifest.json into the working directory).
module MutationRun
  # Top-level entries left out of the copy. Caches, build output and version
  # control are never read by a test. `.mutant` is left out so the copy
  # starts with no session files; the runner copies its own session back.
  COPY_EXCLUDES = %w[.git .worktrees .mutant .jekyll-cache _site _coverage vendor].freeze

  # The seed from MUTATION_SEED, which the Makefile sets (default 1). Raises
  # ArgumentError when it is missing or is not a non-negative integer.
  def self.seed(env = ENV)
    raw = env.fetch('MUTATION_SEED') { raise ArgumentError, 'MUTATION_SEED is not set' }
    raise ArgumentError, "MUTATION_SEED must be a non-negative integer, got #{raw.inspect}" unless raw.match?(/\A\d+\z/)

    raw.to_i
  end

  # Sets the seed that orders tests in this process. mutant-minitest assigns a
  # random seed only when `Minitest.seed` is nil (`||=`), so a value set here
  # is kept. Minitest reads it in `runnable_methods`, where it calls
  # `srand Minitest.seed` before shuffling each class's test methods.
  def self.apply_seed(seed)
    require 'minitest'
    ::Minitest.seed = seed
  end

  # Top-level entry names of `root` that the copy takes, sorted.
  def self.copied_entries(root)
    Dir.children(root).reject { |name| COPY_EXCLUDES.include?(name) }.sort
  end

  # Copies the checkout at `root` into a new temporary directory, then yields
  # that copy's path with the working directory set to it. The copy is
  # removed afterwards, even when the block raises. Returns the block's value.
  def self.with_copy(root)
    copy = Dir.mktmpdir('mutation-run-')
    begin
      FileUtils.cp_r(copied_entries(root).map { |name| File.join(root, name) }, copy)
      Dir.chdir(copy) { yield copy }
    ensure
      FileUtils.rm_rf(copy)
    end
  end

  # Copies a session file from the scratch copy into `root/.mutant/results`,
  # where the run's results were kept before the copy. Returns the new path.
  def self.keep_session(session_path, root)
    dir = File.join(root, '.mutant', 'results')
    FileUtils.mkdir_p(dir)
    FileUtils.cp(session_path, dir)
    File.join(dir, File.basename(session_path))
  end
end
