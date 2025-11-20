# frozen_string_literal: true

# _plugins/front_matter_validator.rb
require 'jekyll'
# Assuming FrontMatterUtils is in _plugins/utils/ and will be loaded by Jekyll.
# If you get NameError for FrontMatterUtils, uncomment:
# require_relative './utils/front_matter_utils'

module Jekyll
  module FrontMatterValidator
    # Default configuration
    DEFAULT_REQUIRED_FIELDS_CONFIG = {
      'books' => %w[title book_authors book_number],
      'posts' => %w[title date]
      # Add other layouts or collection labels as needed:
      # 'my_layout' => ['field1', 'field2'],
      # 'my_collection' => ['fieldA', 'fieldB'],
    }.freeze

    # Class method to access the configuration.
    # This allows it to be stubbed for testing.
    def self.required_fields_config
      @required_fields_config_override || DEFAULT_REQUIRED_FIELDS_CONFIG
    end

    # Class method to temporarily override the config for testing.
    def self.override_config_for_test(new_config)
      @required_fields_config_override = new_config
    end

    # Class method to reset the override for testing.
    def self.reset_config_for_test
      @required_fields_config_override = nil
    end

    # Helper to check if a value is blank (nil, empty string, or whitespace only)
    # This is used for non-list fields.
    def self.blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    # The core validation logic for a document or page
    def self.validate_document(doc)
      config = required_fields_config
      config_key, doc_type_log, is_post_collection = determine_validation_context(doc, config)

      return unless config_key

      missing_fields = config[config_key].select do |field_name|
        field_missing?(doc, field_name, is_post_collection)
      end

      report_missing_fields(doc, doc_type_log, missing_fields)
    end

    # --- Private Helper Methods ---

    def self.determine_validation_context(doc, config)
      return document_context(doc, config) if document_with_collection?(doc, config)
      return page_context(doc, config) if page_with_layout?(doc, config)

      [nil, nil, false]
    end

    def self.document_with_collection?(doc, config)
      doc.is_a?(Jekyll::Document) && doc.collection && config.key?(doc.collection.label)
    end

    def self.page_with_layout?(doc, config)
      doc.is_a?(Jekyll::Page) && doc.data['layout'] && config.key?(doc.data['layout'])
    end

    def self.document_context(doc, config)
      label = doc.collection.label
      [label, "Document in collection '#{label}'", label == 'posts']
    end

    def self.page_context(doc, config)
      layout = doc.data['layout']
      [layout, "Page with layout '#{layout}'", false]
    end

    def self.field_missing?(doc, field_name, is_post_collection)
      value = doc.data[field_name]

      if field_name == 'book_authors'
        FrontMatterUtils.get_list_from_string_or_array(value).empty?
      elsif field_name == 'date' && is_post_collection
        # For posts, Jekyll derives 'date' from filename if not in front matter.
        # doc.date attribute is the canonical one.
        doc.date.nil? || !doc.date.is_a?(Time)
      else
        blank?(value)
      end
    end

    def self.report_missing_fields(doc, doc_type_log, missing_fields)
      return if missing_fields.empty?

      id = doc.data['path'] || doc.url || doc.relative_path || 'unknown path'
      msg = "#{doc_type_log} '#{id}' is missing or has empty required front matter fields: " \
            "#{missing_fields.join(', ')}."
      Jekyll.logger.error 'FrontMatter Error:', msg
      raise Jekyll::Errors::FatalException, msg
    end
  end

  # Use :pre_render for documents, as front matter and data should be fully resolved.
  Jekyll::Hooks.register :documents, :pre_render do |doc|
    # The logic within validate_document already checks if the doc's collection/layout
    # is configured in REQUIRED_FIELDS_CONFIG, so no need for extra filtering here
    # unless you want to exclude entire collections from even being passed to the validator.
    Jekyll::FrontMatterValidator.validate_document(doc)
  end

  # Using :pre_render for pages as well for consistency and to ensure data is fully available.
  Jekyll::Hooks.register :pages, :pre_render do |page|
    excluded_page_names = ['404.html', 'feed.xml', 'sitemap.xml', 'robots.txt']
    excluded_page_extensions = ['.json', '.css', '.js', '.scss', '.map'] # Added scss, map

    next if page.name.nil? # Some dynamically generated pages might have nil name
    next if excluded_page_names.include?(page.name)
    next if excluded_page_extensions.any? { |ext| page.name.end_with?(ext) }
    # Ensure page.data is a hash before proceeding, as some internal pages might not have it.
    next unless page.data.is_a?(Hash)
    # Further exclude common asset paths if they are processed as pages
    next if page.respond_to?(:dir) && page.dir.start_with?('/assets/', '/public/')

    Jekyll::FrontMatterValidator.validate_document(page)
  end
end
