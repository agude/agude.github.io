#!/usr/bin/env ruby
# frozen_string_literal: true

require 'digest'
require 'fileutils'

# Retains conversion data while discarding output and incremental state.
# Run only through Makefile targets, before Jekyll starts.
module BuildCache
  MODES = %w[production serve serve-drafts profile].freeze

  def self.prepare(root, mode)
    raise ArgumentError, "Unknown build mode: #{mode}" unless MODES.include?(mode)

    cache_dir = File.join(root, '.jekyll-cache', mode)
    stamp = "#{cache_dir}.fingerprint"
    fingerprint = dependency_fingerprint(root)
    FileUtils.rm_rf(cache_dir) unless File.file?(stamp) && File.read(stamp) == fingerprint
    FileUtils.mkdir_p(cache_dir)
    File.write(stamp, fingerprint)
    # Jekyll 4.4 accepts cache_dir in YAML, not as a command-line option.
    File.write("#{cache_dir}.yml", "cache_dir: .jekyll-cache/#{mode}\n")

    # Incremental dependencies omit cross-document plugin inputs. Retaining
    # metadata could skip pages whose backlinks or related books changed.
    FileUtils.rm_f(File.join(root, '.jekyll-metadata'))
    FileUtils.rm_rf(File.join(root, '_site'))
  end

  def self.dependency_fingerprint(root)
    paths = %w[Gemfile.lock Dockerfile .ruby-version]
    paths.concat(Dir.glob('_config*.yml', base: root))
    plugin_paths = Dir.glob('_plugins/**/*', File::FNM_DOTMATCH, base: root)
    paths.concat(plugin_paths.select { |path| File.file?(File.join(root, path)) })
    digest = Digest::SHA256.new
    paths.sort.each do |path|
      digest << "#{path.bytesize}:#{path}"
      digest << Digest::SHA256.file(File.join(root, path)).hexdigest
    end
    digest.hexdigest
  end
end

BuildCache.prepare(Dir.pwd, ARGV.fetch(0)) if $PROGRAM_NAME == __FILE__
