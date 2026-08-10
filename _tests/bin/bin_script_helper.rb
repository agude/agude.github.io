# frozen_string_literal: true

require 'open3'
require 'tmpdir'
require 'fileutils'

# Support for testing the executable checkers in _bin/.
#
# These scripts are the CI gates: they glob the filesystem, shell out, and
# exit with a status. Unit-testing extracted helpers would not prove the
# thing CI actually runs still works, so each script is executed as a real
# subprocess against a throwaway fixture directory and asserted on its exit
# status and output.
#
# Scripts locate their inputs relative to the working directory (`_site/`,
# `_config.yml`), so `in_fixture_dir` chdirs the subprocess rather than the
# test process — parallel-safe and impossible to leak into the real repo.
module BinScriptHelper
  REPO_ROOT = File.expand_path('../..', __dir__)

  # Runs _bin/<script> with `dir` as its working directory.
  # Returns [combined stdout+stderr, Process::Status].
  def run_bin_script(script, dir)
    path = File.join(REPO_ROOT, '_bin', script)
    command = script.end_with?('.sh') ? ['bash', path] : [RbConfig.ruby, path]
    Open3.capture2e(*command, chdir: dir)
  end

  # Yields a fresh temporary directory containing an empty _site/.
  def in_fixture_dir
    Dir.mktmpdir('bin-script-test') do |dir|
      FileUtils.mkdir_p(File.join(dir, '_site'))
      yield dir
    end
  end

  # Writes `content` to `relative_path` inside the fixture, creating parents.
  def write_fixture(dir, relative_path, content)
    full = File.join(dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
    full
  end

  ATOM_FEED_HEADER = <<~XML
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>Test Feed</title>
  XML

  # A minimal but valid Atom feed with `count` entries.
  def atom_feed(count: 1)
    entries = Array.new(count) do |i|
      "  <entry><title>Post #{i}</title><id>tag:example.com,2026:#{i}</id></entry>\n"
    end
    "#{ATOM_FEED_HEADER}#{entries.join}</feed>\n"
  end

  # A minimal but valid HTML page.
  def html_page(body: '<p>Hello.</p>')
    <<~HTML
      <!DOCTYPE html>
      <html lang="en"><head><title>Test</title></head>
      <body>#{body}</body></html>
    HTML
  end
end
