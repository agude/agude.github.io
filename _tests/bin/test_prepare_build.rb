# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../_bin/prepare_build'
require 'tmpdir'

# Conversion caches are safe only with full renders and dependency invalidation.
class TestPrepareBuild < Minitest::Test
  def setup
    @root = Dir.mktmpdir('build-cache')
    %w[Gemfile.lock Dockerfile .ruby-version _config.yml _config_docker.yml _plugins/nested/example.rb].each do |path|
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, 'initial')
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def cache_marker(mode = 'production')
    File.join(@root, '.jekyll-cache', mode, 'converted')
  end

  def seed_cache(mode = 'production')
    BuildCache.prepare(@root, mode)
    File.write(cache_marker(mode), 'cached conversion')
  end

  def test_preserves_conversions_but_removes_output_and_incremental_state
    seed_cache
    FileUtils.mkdir_p(File.join(@root, '_site'))
    File.write(File.join(@root, '_site', 'obsolete.html'), 'obsolete')
    File.write(File.join(@root, '.jekyll-metadata'), 'old dependencies')

    BuildCache.prepare(@root, 'production')

    assert_equal 'cached conversion', File.read(cache_marker)
    refute_path_exists File.join(@root, '_site')
    refute_path_exists File.join(@root, '.jekyll-metadata')
  end

  def test_invalidates_on_every_dependency_type_even_with_unchanged_mtime
    %w[Gemfile.lock Dockerfile .ruby-version _config.yml _config_docker.yml _plugins/nested/example.rb].each do |path|
      seed_cache
      full = File.join(@root, path)
      old_mtime = File.mtime(full)
      File.write(full, "#{File.read(full)}changed")
      File.utime(old_mtime, old_mtime, full)

      BuildCache.prepare(@root, 'production')

      refute_path_exists cache_marker, "Cache survived change to #{path}"
    end
  end

  def test_invalidates_on_added_and_removed_plugins_and_configs
    %w[_plugins/new.rb _plugins/.settings _config_extra.yml].each do |path|
      seed_cache
      full = File.join(@root, path)
      File.write(full, 'new dependency')
      BuildCache.prepare(@root, 'production')
      refute_path_exists cache_marker

      seed_cache
      File.unlink(full)
      BuildCache.prepare(@root, 'production')
      refute_path_exists cache_marker
    end
  end

  def test_modes_retain_independent_caches
    BuildCache::MODES.each { |mode| seed_cache(mode) }
    BuildCache::MODES.reverse_each { |mode| BuildCache.prepare(@root, mode) }

    BuildCache::MODES.each { |mode| assert_path_exists cache_marker(mode) }
  end

  def test_writes_the_mode_specific_jekyll_config
    BuildCache::MODES.each do |mode|
      BuildCache.prepare(@root, mode)

      config = YAML.safe_load_file(File.join(@root, '.jekyll-cache', "#{mode}.yml"))
      assert_equal({ 'cache_dir' => ".jekyll-cache/#{mode}" }, config)
    end
  end

  def test_content_changes_leave_conversion_data_available
    seed_cache
    FileUtils.mkdir_p(File.join(@root, '_books'))
    File.write(File.join(@root, '_books', 'review.md'), 'Changed title and rating')

    BuildCache.prepare(@root, 'production')

    assert_path_exists cache_marker
  end

  def test_rejects_unknown_modes_before_deleting_anything
    seed_cache

    assert_raises(ArgumentError) { BuildCache.prepare(@root, '../escape') }
    assert_path_exists cache_marker
  end
end
