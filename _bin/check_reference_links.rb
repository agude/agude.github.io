#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'

# Scan markdown source for reference-style link problems:
# - Undefined: [text][id] with no [id]: definition
# - Duplicate: multiple [id]: definitions with the same id
# - Orphaned: [id]: definition with no [text][id] reference
#
# Strips Liquid tags before checking so that template variables in URLs
# don't cause false positives.

def main
  errors = []
  warnings = []
  site = setup_site

  documents = site.pages + site.documents

  puts 'Checking all documents for reference link problems...'
  documents.each do |doc|
    next if doc.path.include?('vendor/')
    next unless doc.path.end_with?('.md', '.markdown')

    check_document(doc, errors, warnings)
  end

  warnings.each { |w| puts "warning: #{w}" }

  if errors.empty?
    puts 'Success: All documents passed reference link check.'
    exit 0
  else
    puts "\nReference link errors found:"
    errors.each { |e| puts "- #{e}" }
    exit 1
  end
end

def check_document(doc, errors, warnings)
  content = strip_liquid(doc.content)

  definitions = find_definitions(content)
  references = find_references(content)

  defined_ids = Set.new(definitions.map { |d| d[:id] })
  all_ref_ids = Set.new(
    references[:full].map { |r| r[:id].downcase } +
    references[:shorthand].map { |r| r[:id].downcase }
  )

  check_undefined(doc, references[:full], defined_ids, errors)
  check_duplicates(doc, definitions, errors)
  check_orphans(doc, definitions, all_ref_ids, warnings)
end

def check_undefined(doc, references, defined_ids, failures)
  references.each do |ref|
    next if defined_ids.include?(ref[:id].downcase)

    failures << "#{doc.relative_path}:#{ref[:line]}: " \
                "undefined reference link [#{ref[:id]}]"
  end
end

def check_duplicates(doc, definitions, failures)
  seen = {}
  definitions.each do |defn|
    if seen.key?(defn[:id])
      failures << "#{doc.relative_path}:#{defn[:line]}: " \
                  "duplicate link definition [#{defn[:id]}] " \
                  "(first defined on line #{seen[defn[:id]]})"
    else
      seen[defn[:id]] = defn[:line]
    end
  end
end

def check_orphans(doc, definitions, referenced_ids, failures)
  definitions.each do |defn|
    next if defn[:id].start_with?('^') # footnote definitions use different reference syntax
    next if referenced_ids.include?(defn[:id])

    failures << "#{doc.relative_path}:#{defn[:line]}: " \
                "orphaned link definition [#{defn[:id]}]"
  end
end

# Full-form reference links: [text][id] (text may span lines)
FULL_REF_RE = /\[([^\]]+)\]\[([^\]]+)\]/m
# Shorthand reference links: [id] alone (not followed by [, :, or ()
SHORTHAND_REF_RE = /\[([^\]]+)\](?!\[|:|\()/

def find_references(content)
  full = []
  shorthand = []
  lines = content.lines

  content.scan(FULL_REF_RE) do |_text, id|
    next if id.start_with?('^')

    match_pos = Regexp.last_match.begin(0)
    line = content[0..match_pos].count("\n") + 1
    full << { id: id, line: line }
  end

  lines.each_with_index do |line_text, i|
    next if non_footnote_definition_line?(line_text)

    line_text.scan(SHORTHAND_REF_RE) do |id,|
      next if id.start_with?('^')

      shorthand << { id: id, line: i + 1 }
    end
  end

  full.reject! { |r| non_footnote_definition_line?(lines[r[:line] - 1]) }
  { full: full, shorthand: shorthand }
end

def non_footnote_definition_line?(line)
  line&.match?(/\A\s{0,3}\[[^\^][^\]]*\]:\s/)
end

# Link definitions: [id]: URL (must start at column 0-3)
DEFINITION_RE = /^\s{0,3}\[([^\]]+)\]:\s+\S/

def find_definitions(content)
  defs = []
  content.each_line.with_index(1) do |line, lineno|
    if (m = line.match(DEFINITION_RE))
      defs << { id: m[1].downcase, line: lineno }
    end
  end
  defs
end

PLACEHOLDER_URL = 'https://placeholder.invalid'

def strip_liquid(content)
  result = content.dup
  result.gsub!(/\{%-?\s*comment\s*-?%\}.*?\{%-?\s*endcomment\s*-?%\}/m, '')
  result.gsub!(/\{%-?\s*capture\s+\w+\s*-?%\}.*?\{%-?\s*endcapture\s*-?%\}/m, '')
  result.gsub!(/^(\[[^\]]+\]:\s*)\{[%{].*$/) { "#{Regexp.last_match(1)}#{PLACEHOLDER_URL}" }
  result.gsub!(/\{\{.*?\}\}/, PLACEHOLDER_URL)
  result.gsub!(/\{%.*?%\}/m, '')
  result
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
