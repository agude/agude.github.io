#!/usr/bin/env ruby
require 'html-proofer'

options = {
  # v5 removed 'disable_external'. We must use ignore_urls to skip them.
  ignore_urls: [
    %r{/livereload.js},
    /^http/ # Regex to ignore all http/https links (external)
  ],

  # v5 requires explicitly listing checks if you want to limit them
  checks: %w[Links Images Scripts],

  # Standard Jekyll defaults
  assume_extension: true,
  directory_index_file: 'index.html',

  # Speed up by running in parallel
  parallel: { in_processes: 2 }
}

begin
  HTMLProofer.check_directory('./_site', options).run
rescue RuntimeError => e
  puts "\n HTMLProofer found errors!"
  puts e.message
  exit 1
end
