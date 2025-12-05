# frozen_string_literal: true

# _plugins/utils/json_ld_utils.rb
require_relative '../infrastructure/text_processing_utils' # For cleaning/truncating text
require_relative '../infrastructure/url_utils' # For absolute URLs

module Jekyll
  # Utility module for generating Schema.org JSON-LD structured data.
  module SEO
    # Utility module providing helper methods for building JSON-LD entities.
    # Contains methods for creating Person, ImageObject, Rating, and other schema entities.
    module JsonLdUtils
      # --- Person Schema Object Helpers ---

      # Generates a Schema.org Person object from site configuration.
      # Used for site-wide author/publisher.
      # @param site [Jekyll::Site] The Jekyll site object.
      # @param include_site_url [Boolean] If true, adds the site's root URL to the Person object.
      # @return [Hash, nil] The Ruby Hash representing the Person object, or nil if essential data is missing.
      # Renamed from get_site_person_object
      def self.build_site_person_entity(site, include_site_url: false)
        person_name = site.config.dig('author', 'name')
        return nil if person_name.to_s.strip.empty?

        person_data = _base_person_entity(person_name)
        _add_site_url_to_person(person_data, site) if include_site_url
        person_data
      end

      def self._base_person_entity(person_name)
        {
          '@type' => 'Person',
          'name' => person_name
        }
      end
      private_class_method :_base_person_entity

      def self._add_site_url_to_person(person_data, site)
        site_root_url = Jekyll::Infrastructure::UrlUtils.absolute_url('', site)
        person_data['url'] = site_root_url if site_root_url && !site_root_url.empty?
      end
      private_class_method :_add_site_url_to_person

      # Generates a Schema.org Person object from a document field (e.g., book_author).
      # @param person_name_raw [String] The raw name of the person.
      # @return [Hash, nil] The Ruby Hash representing the Person object, or nil if name is empty.
      # Renamed from get_document_person_object
      def self.build_document_person_entity(person_name_raw)
        person_name = person_name_raw.to_s.strip
        return nil if person_name.empty?

        {
          '@type' => 'Person',
          'name' => person_name
        }
      end

      # --- ImageObject Schema Object Helper ---

      # Generates a Schema.org ImageObject.
      # @param image_path_raw [String] The raw path to the image.
      # @param site [Jekyll::Site] The Jekyll site object.
      # @return [Hash, nil] The Ruby Hash representing the ImageObject, or nil if path is empty.
      # Renamed from get_image_object
      def self.build_image_object_entity(image_path_raw, site)
        image_path = image_path_raw.to_s.strip
        return nil if image_path.empty?

        {
          '@type' => 'ImageObject',
          'url' => Jekyll::Infrastructure::UrlUtils.absolute_url(image_path, site)
          # "height" and "width" could be added if a mechanism to fetch them exists
        }
      end

      # --- Content Extraction Helpers ---

      # Extracts and prepares descriptive text from a document based on a priority of fields.
      # @param document [Jekyll::Document] The Jekyll document.
      # @param field_priority [Array<String>] Ordered list of fields to check
      #   (e.g., ['excerpt', 'description', 'content']).
      # @param truncate_options [Hash, nil] Options for truncation (e.g., { words: 50, omission: "..." }).
      #                                     If nil, no truncation.
      # @return [String, nil] The cleaned (and optionally truncated) text, or nil if no suitable content found.
      def self.extract_descriptive_text(document, field_priority:, truncate_options: nil)
        html_content = _find_first_content(document, field_priority)
        return nil unless html_content

        cleaned_text = Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(html_content)
        return nil if cleaned_text.empty?

        _apply_truncation(cleaned_text, truncate_options)
      end

      def self._find_first_content(document, field_priority)
        field_priority.each do |field_key|
          content = _extract_field_content(document, field_key)
          return content if content && !content.strip.empty?
        end
        nil
      end

      def self._extract_field_content(document, field_key)
        case field_key
        when 'excerpt'
          _extract_excerpt_content(document)
        when 'content'
          _extract_content_field(document)
        else
          _extract_data_field(document, field_key)
        end
      end

      def self._extract_excerpt_content(document)
        excerpt = document.data['excerpt']
        excerpt.respond_to?(:output) ? excerpt.output : nil
      end
      private_class_method :_extract_excerpt_content

      def self._extract_content_field(document)
        # Prioritize data hash for 'content', fallback to direct attribute
        document.data.key?('content') ? document.data['content'].to_s : document.content
      end
      private_class_method :_extract_content_field

      def self._extract_data_field(document, field_key)
        document.data[field_key]&.to_s
      end
      private_class_method :_extract_data_field

      def self._apply_truncation(text, options)
        if options && options[:words]
          Jekyll::Infrastructure::TextProcessingUtils.truncate_words(text, options[:words], options[:omission] || '...')
        else
          text
        end
      end

      # --- Rating Schema Object Helper ---

      # Generates a Schema.org Rating object.
      # @param rating_value_raw The raw rating value.
      # @return [Hash, nil] The Ruby Hash representing the Rating object, or nil if rating is invalid.
      # Renamed
      def self.build_rating_entity(rating_value_raw, best_rating: '5', worst_rating: '1')
        rating_value = rating_value_raw.to_i
        return nil if rating_value <= 0

        {
          '@type' => 'Rating',
          'ratingValue' => rating_value.to_s,
          'bestRating' => best_rating.to_s,
          'worstRating' => worst_rating.to_s
        }
      end

      # --- BookSeries Schema Object Helper ---

      # Generates a Schema.org BookSeries object.
      # @param series_name_raw [String] The name of the series.
      # @param position_raw The position of the book in the series.
      # @return [Hash, nil] The Ruby Hash representing the BookSeries object, or nil if series name is empty.
      # Renamed
      def self.build_book_series_entity(series_name_raw, position_raw = nil)
        series_name = series_name_raw.to_s.strip
        return nil if series_name.empty?

        series_data = {
          '@type' => 'BookSeries',
          'name' => series_name
        }
        position = position_raw.to_i
        series_data['position'] = position.to_s if position.positive?

        series_data
      end

      # --- Utility Helpers ---

      # Cleans a Ruby Hash (representing a future JSON object) by removing keys
      # with nil values or empty strings/arrays.
      # Modifies the hash in place and also returns it.
      # @param data_hash [Hash] The hash to clean.
      # @return [Hash] The cleaned hash.
      # Renamed from cleanup_hash!
      def self.cleanup_data_hash!(data_hash)
        return data_hash unless data_hash.is_a?(Hash) # Guard clause for non-hash inputs

        data_hash.compact!
        data_hash.delete_if { |_, v| (v.is_a?(String) || v.is_a?(Array)) && v.empty? }

        data_hash.each_value do |value|
          cleanup_data_hash!(value) if value.is_a?(Hash) # Recurse for nested hashes
        end
        data_hash
      end
    end
  end
end
