# frozen_string_literal: true

# Validate each declared feed in _site/: it must exist, start with an XML
# declaration (not raw Liquid/HTML), parse as XML, have an Atom <feed> root,
# and contain entries. The list is declared rather than discovered, so a
# feed that stops being generated fails the check instead of dropping out of
# it.
require 'rexml'

EXPECTED_FEEDS = %w[_site/feed.xml _site/feed/books.xml].freeze
ATOM_NAMESPACE = 'http://www.w3.org/2005/Atom'

def check_feed(path)
  return 'FAILED — missing' unless File.file?(path)

  raw = File.read(path)
  return 'FAILED — starts with raw Liquid/HTML, not XML declaration' unless raw.start_with?('<?xml')

  root = REXML::Document.new(raw).root
  unless root&.name == 'feed' && root.namespace == ATOM_NAMESPACE
    return "FAILED — expected Atom <feed xmlns=\"#{ATOM_NAMESPACE}\">, got <#{root&.expanded_name}>"
  end

  entries = REXML::XPath.match(root, 'atom:entry', 'atom' => ATOM_NAMESPACE)
  return 'FAILED — feed contains no entries' if entries.empty?

  "OK (#{entries.length} entries)"
rescue REXML::ParseException => e
  "FAILED — not well-formed XML: #{e.message.lines.first&.strip}"
end

failed = false
EXPECTED_FEEDS.each do |path|
  result = check_feed(path)
  puts "#{path}: #{result}"
  failed ||= result.start_with?('FAILED')
end
exit 1 if failed
