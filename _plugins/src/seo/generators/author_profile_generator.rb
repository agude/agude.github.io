# frozen_string_literal: true

# _plugins/utils/json_ld_generators/author_profile_generator.rb
require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'
require_relative '../../infrastructure/front_matter_utils'
require 'jekyll' # For logger

module Jekyll
  # Generates JSON-LD Person schema for author profile pages.
  module SEO
    module Generators
      # Utility module for generating JSON-LD Person schema for author profiles.
      # Creates structured data for author profile pages.
      module AuthorProfileLdGenerator
        def self.generate_hash(document, site)
          data = _base_data_hash
          _add_name(data, document)
          _add_url(data, document, site)
          _add_same_as_links(data, document)
          _add_description(data, document)
          _add_alternate_name(data, document)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        # Creates the base data structure for Person schema.
        #
        # @return [Hash] The base data hash with @context and @type.
        def self._base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'Person'
          }
        end

        # Adds the author name to the data hash.
        #
        # @param data [Hash] The data hash to modify.
        # @param document [Jekyll::Document] The document containing author data.
        def self._add_name(data, document)
          author_name = document.data['title']
          data['name'] = author_name if author_name && !author_name.strip.empty?
        end

        # Adds the author page URL to the data hash.
        #
        # @param data [Hash] The data hash to modify.
        # @param document [Jekyll::Document] The document containing author data.
        # @param site [Jekyll::Site] The Jekyll site object.
        def self._add_url(data, document, site)
          author_page_url = Jekyll::Infrastructure::UrlUtils.absolute_url(document.url, site)
          data['url'] = author_page_url if author_page_url
        end

        # Adds sameAs links to the data hash from front matter.
        #
        # @param data [Hash] The data hash to modify.
        # @param document [Jekyll::Document] The document containing author data.
        def self._add_same_as_links(data, document)
          same_as_links_from_fm = document.data['same_as_urls'] || []

          if same_as_links_from_fm.is_a?(Array)
            _process_same_as_array(data, same_as_links_from_fm)
          elsif same_as_links_from_fm
            _log_invalid_same_as(document)
          end
        end

        # Processes and filters sameAs links array.
        #
        # @param data [Hash] The data hash to modify.
        # @param links [Array] The array of links to process.
        def self._process_same_as_array(data, links)
          filtered_links = links.map(&:to_s).map(&:strip).compact.reject(&:empty?)
          data['sameAs'] = filtered_links if filtered_links.any?
        end

        # Logs a warning when same_as_urls is not an array.
        #
        # @param document [Jekyll::Document] The document with invalid data.
        def self._log_invalid_same_as(document)
          doc_identifier = document.url || document.path || document.relative_path
          Jekyll.logger.warn 'JSON-LD:',
                             "Front matter 'same_as_urls' for '#{doc_identifier}' is not an Array, skipping sameAs."
        end

        # Adds description to the data hash.
        #
        # @param data [Hash] The data hash to modify.
        # @param document [Jekyll::Document] The document containing author data.
        def self._add_description(data, document)
          description = Jekyll::SEO::JsonLdUtils.extract_descriptive_text(
            document,
            field_priority: %w[excerpt description]
          )
          data['description'] = description if description
        end

        # Adds alternate names (pen names) to the data hash.
        #
        # @param data [Hash] The data hash to modify.
        # @param document [Jekyll::Document] The document containing author data.
        def self._add_alternate_name(data, document)
          pen_names_list = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(document.data['pen_names'])
          data['alternateName'] = pen_names_list if pen_names_list.any?
        end
      end
    end
  end
end
