#!/usr/bin/env ruby
# frozen_string_literal: true

require 'html-proofer'

options = {
  # v5 removed 'disable_external'. We must use ignore_urls to skip them.
  ignore_urls: [
    %r{/livereload.js},
    /^http/, # Regex to ignore all http/https links (external)
    # AT Protocol URIs in standard.site verification link tags; not
    # fetchable URLs, and their validity is enforced by the plugin's
    # URI pattern check and the atproto publish pipeline.
    %r{\Aat://},
  ],

  # v5 requires explicitly listing checks if you want to limit them.
  # Added Favicon and OpenGraph for broader validation coverage.
  checks: %w[Links Images Scripts Favicon OpenGraph],

  # Standard Jekyll defaults
  assume_extension: true,
  directory_index_file: 'index.html',

  # Require meaningful alt text on images (don't allow empty alt="")
  ignore_empty_alt: false,

  # Speed up by running in parallel
  parallel: { in_processes: 2 },
}

# HTMLProofer reports its own failures and calls exit(1) itself, so there is
# nothing to rescue: a `rescue RuntimeError` here would be dead code.
HTMLProofer.check_directory('./_site', options).run
