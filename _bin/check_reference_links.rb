#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'
require_relative 'reference_link_scanner'

# Scan Markdown source for reference-style link problems; any result exits 1:
# - Undefined: [text][id] with no [id]: definition. Kramdown emits the
#   literal source text, so raw markdown ships to the page.
# - Duplicate: [id]: defined twice. Kramdown silently keeps the first, so
#   the second link points somewhere its author did not intend.
# - Orphaned:  [id]: with no full-form or shorthand reference. Usually means
#   a link was set up and never attached. Five such cases were found on this
#   site when the check was first written, which is why this is an error and
#   not a warning.
#
# Kramdown warnings are not a substitute: Jekyll drops them unless
# show_warnings is set, they are not fatal, and shorthand
# `[id]` references are ambiguous with editorial brackets. This check scans
# source Markdown because rendered HTML has no link for an unresolved
# reference, and strict Liquid checks variables rather than Markdown
# definitions. Put a definition after its full paragraph: in Kramdown a
# definition ends that paragraph. Scanner behavior belongs in
# reference_link_scanner.rb and its tests, not in this site-loading wrapper.

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
