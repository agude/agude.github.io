# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative '../test_helper'
require_relative 'mutation_run'

# Covers the seed and scratch-copy setup of `make test-mutations`.
class TestMutationRun < Minitest::Test
  def test_seed_reads_a_non_negative_integer
    assert_equal 7, MutationRun.seed({ 'MUTATION_SEED' => '7' })
    assert_equal 0, MutationRun.seed({ 'MUTATION_SEED' => '0' })
  end

  def test_seed_rejects_a_missing_or_malformed_value
    assert_raises(ArgumentError) { MutationRun.seed({}) }
    ['', '-1', '1.5', 'abc', ' 3', '3 '].each do |raw|
      assert_raises(ArgumentError, raw.inspect) { MutationRun.seed({ 'MUTATION_SEED' => raw }) }
    end
  end

  def test_apply_seed_sets_minitest_seed_and_keeps_it_under_or_assign
    original = Minitest.seed
    MutationRun.apply_seed(123)

    assert_equal 123, Minitest.seed
    # mutant-minitest assigns its random seed with `||=`, so a set seed stays.
    Minitest.seed ||= 999
    assert_equal 123, Minitest.seed
  ensure
    Minitest.seed = original
  end

  def test_copied_entries_leave_out_caches_build_output_and_results
    Dir.mktmpdir do |root|
      %w[_plugins _tests _site vendor .jekyll-cache _coverage .mutant .git .worktrees].each do |name|
        FileUtils.mkdir_p(File.join(root, name))
      end
      File.write(File.join(root, '_config.yml'), '')
      File.write(File.join(root, '.mutant.yml'), '')

      assert_equal ['.mutant.yml', '_config.yml', '_plugins', '_tests'], MutationRun.copied_entries(root)
    end
  end

  def test_with_copy_runs_in_a_copy_and_leaves_the_checkout_alone
    Dir.mktmpdir do |root|
      File.write(File.join(root, 'marker.txt'), 'original')
      FileUtils.mkdir_p(File.join(root, '.mutant', 'results'))
      before = Dir.pwd
      copy = nil

      MutationRun.with_copy(root) do |dir|
        copy = dir
        assert_equal File.realpath(dir), File.realpath(Dir.pwd)
        assert File.exist?('marker.txt')
        refute File.exist?('.mutant')
        # Simulates a mutant that writes into the working directory.
        File.write('manifest.json', '{}')
      end

      assert_equal before, Dir.pwd
      refute File.exist?(File.join(root, 'manifest.json'))
      assert_equal 'original', File.read(File.join(root, 'marker.txt'))
      refute Dir.exist?(copy)
    end
  end

  def test_with_copy_returns_the_block_value
    Dir.mktmpdir do |root|
      assert_equal 42, MutationRun.with_copy(root) { 42 }
    end
  end

  def test_with_copy_removes_the_copy_when_the_block_raises
    copy = nil
    Dir.mktmpdir do |root|
      error = assert_raises(RuntimeError) do
        MutationRun.with_copy(root) do |dir|
          copy = dir
          raise 'boom'
        end
      end

      assert_equal 'boom', error.message
      refute Dir.exist?(copy)
    end
  end

  def test_keep_session_copies_the_session_into_the_checkout_results
    Dir.mktmpdir do |root|
      Dir.mktmpdir do |other|
        session = File.join(other, 'session.json.gz')
        File.write(session, 'data')

        kept = MutationRun.keep_session(session, root)

        assert_equal File.join(root, '.mutant', 'results', 'session.json.gz'), kept
        assert_equal 'data', File.read(kept)
      end
    end
  end
end
