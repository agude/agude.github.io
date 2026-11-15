#!/usr/bin/env ruby
# frozen_string_literal: true

# Proves that main's second build differs from the gated first build only by
# the `site.standard.document` link tags the publish step adds. The site
# gates ran against the first build; this check carries their result over
# to the artifact that deploys, without running them again.
#
# Both builds must use the same `time:` config, or every page's build
# timestamp differs.
#
# Usage: check_rebuild_diff.rb FIRST_SITE SECOND_SITE
module RebuildDiff
  DOCUMENT_LINK = / ?<link rel="site\.standard\.document" href="[^"]*">/n

  def self.files(root)
    Dir.glob('**/*', File::FNM_DOTMATCH, base: root).select { |path| File.file?(File.join(root, path)) }.sort
  end

  # @return [Array<String>] One message per unexpected difference.
  def self.errors(first, second)
    first_files = files(first)
    second_files = files(second)
    errors = (first_files - second_files).map { |path| "only in the first build: #{path}" }
    errors.concat((second_files - first_files).map { |path| "only in the second build: #{path}" })
    (first_files & second_files).each do |path|
      before = File.binread(File.join(first, path))
      after = File.binread(File.join(second, path))
      errors << "the first build already has a document link tag: #{path}" if before.match?(DOCUMENT_LINK)
      next if before == after

      errors << "differs beyond document link tags: #{path}" unless after.gsub(DOCUMENT_LINK, '') == before
    end
    errors
  end
end

if $PROGRAM_NAME == __FILE__
  abort 'usage: check_rebuild_diff.rb FIRST_SITE SECOND_SITE' unless ARGV.length == 2
  ARGV.each { |dir| abort "not a directory: #{dir}" unless File.directory?(dir) }

  errors = RebuildDiff.errors(*ARGV)
  if errors.empty?
    puts "OK: #{RebuildDiff.files(ARGV[1]).length} files match apart from document link tags"
  else
    warn "Rebuild changed more than document link tags (#{errors.length}):"
    errors.first(50).each { |error| warn "  #{error}" }
    exit 1
  end
end
