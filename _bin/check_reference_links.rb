#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'
require_relative 'reference_link_scanner'

# Scan markdown source for reference-style link problems, all of them fatal:
# - Undefined: [text][id] with no [id]: definition. Kramdown emits the
#   literal source text, so raw markdown ships to the page.
# - Duplicate: [id]: defined twice. Kramdown silently keeps the first, so
#   the second link points somewhere its author did not intend.
# - Orphaned:  [id]: with no reference. Usually means a link was set up and
#   never attached — the prose renders as plain text with nothing to show
#   for it. Five such cases were found on this site when the check was
#   first written, which is why this is an error and not a warning.
#
# Kramdown itself warns about undefined references, but Jekyll drops those
# warnings unless show_warnings is set, they are never fatal, and they fire
# on shorthand [id] references, which are indistinguishable from editorial
# brackets in prose. The scanning logic lives in reference_link_scanner.rb.

def main
  site = setup_site
  problems = []

  puts 'Checking all documents for reference link problems...'
  (site.pages + site.documents).each do |doc|
    next if doc.path.include?('vendor/')
    next unless doc.path.end_with?('.md', '.markdown')

    problems.concat(check_document(doc))
  end

  report(problems)
end

def check_document(doc)
  offset = ReferenceLinkScanner.content_line_offset(doc.path, doc.content)
  ReferenceLinkScanner.scan(doc.content, line_offset: offset)
                      .map { |problem| format_problem(doc, problem) }
end

def format_problem(doc, problem)
  "#{doc.relative_path}:#{problem[:line]}: #{problem[:message]}"
end

def report(problems)
  if problems.empty?
    puts 'Success: All documents passed reference link check.'
    exit 0
  end

  puts "\nReference link errors found:"
  problems.each { |problem| puts "- #{problem}" }
  exit 1
end

def setup_site
  original_stdout = $stdout.clone
  original_stderr = $stderr.clone
  $stdout.reopen(File::NULL, 'w')
  $stderr.reopen(File::NULL, 'w')

  site = nil
  begin
    config = Jekyll.configuration({})
    config['plugin_log_level'] = 'error'
    site = Jekyll::Site.new(config)
    site.reset
    site.read
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  site
end

main
