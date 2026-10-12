# frozen_string_literal: true

require 'jekyll'
require_relative '../infrastructure/typography_utils'
require_relative '../infrastructure/front_matter_utils'

module Jekyll
  # Namespace for SEO-related plugins and utilities.
  module SEO
    # Extension to Jekyll that provides front matter validation functionality.
    # Validates required front matter fields for Jekyll documents and pages.
    #
    # Ensures that collections and layouts have all required front matter
    # fields defined before rendering, raising fatal errors for missing fields.
    #
    # @validator Missing required front matter fields for a collection, and
    #   a malformed or duplicated `wikidata_qid` on a book or author page.
    module FrontMatterValidator
      # Default configuration
      DEFAULT_REQUIRED_FIELDS_CONFIG = {
        'books' => %w[title book_authors book_number wikidata_qid],
        'posts' => %w[title date],
        'author_page' => %w[title wikidata_qid],
        # Add other layouts or collection labels as needed:
        # 'my_layout' => ['field1', 'field2'],
        # 'my_collection' => ['fieldA', 'fieldB'],
      }.freeze

      # A Wikidata item ID: "Q" and a number without leading zeros.
      WIKIDATA_QID_PATTERN = /\AQ[1-9][0-9]*\z/

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
        validate_title_entities(doc)
        validate_wikidata(doc, doc_type_log) if config[config_key].include?('wikidata_qid')
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

      def self.document_context(doc, _config)
        label = doc.collection.label
        [label, "Document in collection '#{label}'", label == 'posts']
      end

      def self.page_context(doc, _config)
        layout = doc.data['layout']
        [layout, "Page with layout '#{layout}'", false]
      end

      def self.field_missing?(doc, field_name, is_post_collection)
        value = doc.data[field_name]

        if field_name == 'book_authors'
          Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(value).empty?
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

        msg = "#{doc_type_log} '#{doc_id(doc)}' is missing or has empty required front matter fields: " \
              "#{missing_fields.join(', ')}."
        fail_validation(msg)
      end

      # Scans the title field for HTML named entities that prepare_display_title
      # does not restore after HTML-escaping, which causes them to render as
      # literal text (e.g. &mdash; displays as "&mdash;").
      # Numeric entities (&#8212; / &#x2014;) are out of scope — nobody writes
      # them in YAML front matter in practice.
      # Note: this check is gated on config_key, so unconfigured collections are
      # not scanned (same gap as the required-field check above it).
      def self.validate_title_entities(doc)
        title = doc.data['title']
        return unless title.is_a?(String)

        allowed = Jekyll::Infrastructure::TypographyUtils::ALLOWED_TITLE_ENTITIES
        violations = title.scan(/&([a-zA-Z][a-zA-Z0-9]*);/).flatten
                          .reject { |e| allowed.include?(e) }
        return if violations.empty?

        entity_list = violations.map { |e| "&#{e};" }.join(', ')
        msg = "Title in '#{doc_id(doc)}' contains HTML entities that will be double-escaped and " \
              "rendered as literal text: #{entity_list}. Use the character directly or a " \
              "typography shorthand (e.g. '---' for em dash, '--' for en dash)."
        fail_validation(msg)
      end

      # `wikidata_qid` is the only source of the Wikidata link. Rejects a
      # malformed QID (broken link), a non-list same_as_urls (read as a list
      # downstream), and a Wikidata URL in same_as_urls (a second copy).
      # Runs after the required-field check, so the QID is not blank.
      def self.validate_wikidata(doc, doc_type_log)
        id = doc_id(doc)
        qid = doc.data['wikidata_qid']
        unless qid.to_s.match?(WIKIDATA_QID_PATTERN)
          msg = "#{doc_type_log} '#{id}' has wikidata_qid #{qid.to_s.inspect}, which is not a Wikidata item ID " \
                '(Q followed by a number, e.g. Q190159).'
          fail_validation(msg)
        end

        urls = doc.data['same_as_urls']
        unless urls.nil? || urls.is_a?(Array)
          fail_validation("#{doc_type_log} '#{id}' same_as_urls must be a list, got #{urls.inspect}.")
        end

        wikidata_urls = Array(urls).map(&:to_s).select { |u| u.include?('wikidata.org') }
        return if wikidata_urls.empty?

        msg = "#{doc_type_log} '#{id}' lists Wikidata in same_as_urls (#{wikidata_urls.join(', ')}). " \
              'Remove it: the build generates the Wikidata link from wikidata_qid.'
        fail_validation(msg)
      end

      def self.doc_id(doc)
        doc.data['path'] || doc.url || doc.relative_path || 'unknown path'
      end

      def self.fail_validation(msg)
        Jekyll.logger.error 'FrontMatter Error:', msg
        raise Jekyll::Errors::FatalException, msg
      end
    end

    # Use :pre_render for documents, as front matter and data should be fully resolved.
    Jekyll::Hooks.register :documents, :pre_render do |doc|
      # The logic within validate_document already checks if the doc's collection/layout
      # is configured in REQUIRED_FIELDS_CONFIG, so no need for extra filtering here
      # unless you want to exclude entire collections from even being passed to the validator.
      Jekyll::SEO::FrontMatterValidator.validate_document(doc)
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

      Jekyll::SEO::FrontMatterValidator.validate_document(page)
    end
  end
end
