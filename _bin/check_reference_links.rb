#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'

# Scan markdown source for reference-style links ([text][id]) whose
# definitions ([id]: URL) are missing or malformed. Strips Liquid tags
# before checking so that template variables don't cause false positives.

def main
  failures = []
  site = setup_site

  documents = site.pages + site.documents

  puts 'Checking all documents for undefined reference links...'
  documents.each do |doc|
    next if doc.path.include?('vendor/')
    next unless doc.path.end_with?('.md', '.markdown')

    check_document(doc, failures)
  end

  if failures.empty?
    puts 'Success: All documents passed reference link check.'
    exit 0
  else
    puts "\nUndefined reference links found:"
    failures.each { |f| puts "- #{f}" }
    exit 1
  end
end

def check_document(doc, failures)
  content = strip_liquid(doc.content)

  definitions = find_definitions(content)
  references = find_references(content)

  references.each do |ref|
    next if definitions.include?(ref[:id].downcase)

    failures << "#{doc.relative_path}:#{ref[:line]}: " \
                "undefined reference link [#{ref[:id]}]"
  end
end

# Full-form reference links: [text][id] (text may span lines)
REFERENCE_RE = /\[([^\]]+)\]\[([^\]]+)\]/m

def find_references(content)
  refs = []
  content.scan(REFERENCE_RE) do |_text, id|
    next if id.start_with?('^') # footnote, not a reference link

    match_pos = Regexp.last_match.begin(0)
    line = content[0..match_pos].count("\n") + 1
    refs << { id: id, line: line }
  end

  # Remove matches that fall on definition lines
  refs.reject { |r| content.lines[r[:line] - 1]&.match?(/\A\s{0,3}\[([^\]]+)\]:/) }
end

# Link definitions: [id]: URL (must start at column 0-3)
DEFINITION_RE = /^\s{0,3}\[([^\]]+)\]:\s+\S/

def find_definitions(content)
  defs = Set.new
  content.each_line do |line|
    if (m = line.match(DEFINITION_RE))
      defs.add(m[1].downcase)
    end
  end
  defs
end

PLACEHOLDER_URL = 'https://placeholder.invalid'

def strip_liquid(content)
  result = content.dup
  result.gsub!(/\{%-?\s*comment\s*-?%\}.*?\{%-?\s*endcomment\s*-?%\}/m, '')
  result.gsub!(/\{%-?\s*capture\s+\w+\s*-?%\}.*?\{%-?\s*endcapture\s*-?%\}/m, '')
  result.gsub!(/^(\[[^\]]+\]:\s*)\{[%{].*$/) { "#{$1}#{PLACEHOLDER_URL}" }
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
