# _plugins/front_matter_validator.rb
require 'jekyll'
# Assuming FrontMatterUtils is in _plugins/utils/ and will be loaded by Jekyll.
# If you get NameError for FrontMatterUtils, uncomment:
# require_relative './utils/front_matter_utils'

module Jekyll
  module FrontMatterValidator
    # Default configuration
    DEFAULT_REQUIRED_FIELDS_CONFIG = {
      'books' => %w[title book_authors book_number], # As per your last update (rating not required)
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
      current_config = required_fields_config # Use the accessor method
      config_key = nil
      doc_type_for_log = ''
      is_post_collection = false # Flag to identify if we are dealing with 'posts' collection

      # Determine the configuration key based on whether it's a Document in a Collection or a Page with a layout
      if doc.is_a?(Jekyll::Document) && doc.collection && current_config.key?(doc.collection.label)
        config_key = doc.collection.label
        doc_type_for_log = "Document in collection '#{config_key}'"
        is_post_collection = (doc.collection.label == 'posts')
      elsif doc.is_a?(Jekyll::Page) && doc.data['layout'] && current_config.key?(doc.data['layout'])
        # Ensure it's a Page before checking layout for config, to avoid matching Documents that also have layouts
        config_key = doc.data['layout']
        doc_type_for_log = "Page with layout '#{config_key}'"
        # is_post_collection remains false for pages, as filename-derived dates are specific to collection Documents.
      end

      return unless config_key # If no relevant config key, skip validation

      required_fields = current_config[config_key]
      missing_or_empty_fields = []

      required_fields.each do |field_name|
        field_value = doc.data[field_name]
        is_field_blank = false

        if field_name == 'book_authors'
          authors_list = FrontMatterUtils.get_list_from_string_or_array(field_value)
          is_field_blank = authors_list.empty?
        elsif field_name == 'date' && is_post_collection # Only apply special date logic for 'posts' collection
          # For posts, Jekyll derives 'date' from filename if not in front matter.
          # doc.date attribute is the canonical one.
          is_field_blank = doc.date.nil? || !doc.date.is_a?(Time)
        else
          # Standard blank check for other fields or for 'date' in non-post collections/layouts
          is_field_blank = blank?(field_value)
        end

        missing_or_empty_fields << field_name if is_field_blank
      end

      return if missing_or_empty_fields.empty?

      doc_identifier = doc.data['path'] || doc.url || doc.relative_path || 'unknown path'
      error_message = "#{doc_type_for_log} '#{doc_identifier}' is missing or has empty required front matter fields: #{missing_or_empty_fields.join(', ')}."
      Jekyll.logger.error 'FrontMatter Error:', error_message
      raise Jekyll::Errors::FatalException, error_message
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
