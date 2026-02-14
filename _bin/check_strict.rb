#!/usr/bin/env ruby
# frozen_string_literal: true

require 'jekyll'

# This script ensures that all documents can be rendered under Jekyll's strict
# mode for Liquid. It helps catch undeclared variables in page content by
# programmatically overriding the site's Liquid configuration.

def main
  failures = []
  site = setup_site_with_strict_config
  documents = site.pages + site.documents
  excluded_files = ['feed.xml', 'feed/books.xml', 'sitemap.xml']

  puts 'Checking all documents for strict Liquid compliance...'
  documents.each do |doc|
    next if doc.path.include?('vendor/')
    next if excluded_files.include?(doc.relative_path)

    begin
      # The renderer will use the strict config already loaded into the site object
      renderer = Jekyll::Renderer.new(site, doc, site.site_payload)
      renderer.run
    rescue Liquid::UndefinedVariable => e
      failures << "Strict rendering failed for '#{doc.relative_path}': #{e.message}"
    rescue StandardError => e
      failures << "An unexpected error occurred for '#{doc.relative_path}': #{e.class} - #{e.message}"
    end
  end

  if failures.empty?
    puts 'Success: All documents passed strict rendering check.'
    exit 0
  else
    puts "\nFound Liquid rendering errors in strict mode:"
    failures.each { |f| puts "- #{f}" }
    exit 1
  end
end

def setup_site_with_strict_config
  original_stdout = $stdout.clone
  original_stderr = $stderr.clone
  $stdout.reopen(File::NULL, 'w')
  $stderr.reopen(File::NULL, 'w')

  site = nil
  begin
    # Load the default config and then override it with strict settings
    config = Jekyll.configuration({})
    config['plugin_log_level'] = 'error'
    config['liquid'] = {
      'error_mode' => 'strict',
      'strict_variables' => true,
      'strict_filters' => true,
      'strict_front_matter' => true,
    }

    site = Jekyll::Site.new(config)
    site.reset
    site.read
    site.converters.keep_if { |c| c.respond_to?(:matches) }
    site.generate
  ensure
    $stdout.reopen(original_stdout)
    $stderr.reopen(original_stderr)
  end
  site
end

main
