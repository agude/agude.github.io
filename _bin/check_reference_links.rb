#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'
require_relative 'reference_link_scanner'

# Scan markdown source for reference-style link problems:
# - Undefined: [text][id] with no [id]: definition   -> error
# - Duplicate: [id]: defined twice                   -> error (Kramdown
#   silently keeps the first definition, so the second link is wrong)
# - Orphaned:  [id]: with no reference                -> warning
#
# Kramdown itself warns about undefined references, but Jekyll drops those
# warnings unless show_warnings is set, they are never fatal, and they fire
# on shorthand [id] references, which are indistinguishable from editorial
# brackets in prose. The scanning logic lives in reference_link_scanner.rb.

def main
  site = setup_site
  errors = []
  warnings = []

  puts 'Checking all documents for reference link problems...'
  (site.pages + site.documents).each do |doc|
    next if doc.path.include?('vendor/')
    next unless doc.path.end_with?('.md', '.markdown')

    check_document(doc, errors, warnings)
  end

  report(errors, warnings)
end

def check_document(doc, errors, warnings)
  offset = ReferenceLinkScanner.content_line_offset(doc.path, doc.content)
  result = ReferenceLinkScanner.scan(doc.content, line_offset: offset)

  result[:errors].each { |e| errors << format_problem(doc, e) }
  result[:warnings].each { |w| warnings << format_problem(doc, w) }
end

def format_problem(doc, problem)
  "#{doc.relative_path}:#{problem[:line]}: #{problem[:message]}"
end

def report(errors, warnings)
  warnings.each { |warning| puts "warning: #{warning}" }

  if errors.empty?
    puts 'Success: All documents passed reference link check.'
    exit 0
  end

  puts "\nReference link errors found:"
  errors.each { |error| puts "- #{error}" }
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
