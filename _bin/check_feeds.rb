# frozen_string_literal: true

# Validate every feed XML file in _site/: must start with an XML
# declaration (not raw Liquid/HTML), parse as XML, and contain entries.
require 'rexml'

feeds = Dir.glob('_site/**/*.xml').select do |f|
  content = File.read(f, 512)
  content.include?('<feed') || content.include?('<rss')
end
abort 'FAILED — no feed XML files found in _site' if feeds.empty?

feeds.each do |path|
  print "#{path}: "
  raw = File.read(path)
  abort 'FAILED — starts with raw Liquid/HTML, not XML declaration' unless raw.start_with?('<?xml')
  doc = REXML::Document.new(raw)
  entries = REXML::XPath.match(doc, '//*[local-name()="entry"]')
  abort 'FAILED — feed contains no entries' if entries.empty?
  puts "OK (#{entries.length} entries)"
end
