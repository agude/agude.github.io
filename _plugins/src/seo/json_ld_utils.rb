# frozen_string_literal: true

require_relative '../infrastructure/text_processing_utils' # For cleaning/truncating text
require_relative '../infrastructure/url_utils' # For absolute URLs

module Jekyll
  # Utility module for generating Schema.org JSON-LD structured data.
  module SEO
    # Utility module providing helper methods for building JSON-LD entities.
    # Contains methods for creating Person, ImageObject, Rating, and other schema entities.
    module JsonLdUtils
      CC_BY_SA_LICENSE_URL = 'https://creativecommons.org/licenses/by-sa/4.0/'

      # Entity kinds whose name, as a fragment, turns a page URL into the
      # identifier of the thing the page describes. The bare page URL
      # identifies the web page itself; one URI must not name both a page and
      # a book or person (W3C, "Cool URIs for the Semantic Web").
      ENTITY_KINDS = %i[book person series website].freeze

      # --- Identity Helpers ---

      # @param page_url [String] Absolute URL of the page describing the entity.
      # @param kind [Symbol] One of ENTITY_KINDS.
      # @return [String, nil] The entity's @id, or nil if page_url is blank.
      def self.entity_id(page_url, kind)
        raise ArgumentError, "unknown entity kind #{kind.inspect}" unless ENTITY_KINDS.include?(kind)

        url = page_url.to_s.strip
        url.empty? ? nil : "#{url}##{kind}"
      end

      # `@id` and `url` of the site owner, from `author.url` in _config.yml.
      # Every author/publisher reference to the owner carries these, so all
      # of them name one node.
      def self.site_owner_ref(site)
        path = site.config.dig('author', 'url').to_s.strip
        raise Jekyll::Errors::FatalException, 'JSON-LD: _config.yml author.url is required.' if path.empty?

        url = Jekyll::Infrastructure::UrlUtils.absolute_url(path, site)
        { '@id' => entity_id(url, :person), 'url' => url }
      end

      # --- Person Schema Object Helpers ---

      # Generates a Schema.org Person object from site configuration.
      # Used for site-wide author/publisher.
      # @param site [Jekyll::Site] The Jekyll site object.
      # @return [Hash, nil] The Person object, or nil if author.name is blank.
      def self.build_site_person_entity(site)
        person_name = site.config.dig('author', 'name')
        return nil if person_name.to_s.strip.empty?

        { '@type' => 'Person', 'name' => person_name }.merge(site_owner_ref(site))
      end

      # Generates a Schema.org Person object from a document field (e.g., book_author).
      # @param person_name_raw [String] The raw name of the person.
      # @return [Hash, nil] The Ruby Hash representing the Person object, or nil if name is empty.
      # Renamed from get_document_person_object
      def self.build_document_person_entity(person_name_raw)
        person_name = person_name_raw.to_s.strip
        return nil if person_name.empty?

        {
          '@type' => 'Person',
          'name' => person_name,
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
          'url' => Jekyll::Infrastructure::UrlUtils.absolute_url(image_path, site),
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
          'worstRating' => worst_rating.to_s,
        }
      end

      # --- BookSeries Schema Object Helper ---

      # Generates a Schema.org BookSeries object. It never carries `position`:
      # every book in the series references the same node, so the book's
      # place in the series belongs on the Book (see format_series_position).
      # @param series_name_raw [String] The name of the series.
      # @param page_url [String, nil] Absolute URL of the series page. When
      #   given, the entity gets `url` and its #series @id.
      # @return [Hash, nil] The BookSeries object, or nil if series name is empty.
      def self.build_book_series_entity(series_name_raw, page_url = nil)
        series_name = series_name_raw.to_s.strip
        return nil if series_name.empty?

        series_data = { '@type' => 'BookSeries' }
        series_id = entity_id(page_url, :series)
        if series_id
          series_data['@id'] = series_id
          series_data['url'] = page_url.to_s.strip
        end
        series_data['name'] = series_name
        series_data
      end

      # Formats a book's number within its series for schema.org `position`.
      # Fractional numbers (4.5 for a novella between books 4 and 5) are kept;
      # truncating them would give two books the same position.
      # @return [String, nil] nil for missing, non-numeric, or non-positive values.
      def self.format_series_position(raw)
        number = Float(raw.to_s.strip, exception: false)
        return nil unless number&.positive?

        number == number.floor ? number.to_i.to_s : number.to_s
      end

      # --- MediaObject Schema Object Helper ---

      # Generates a Schema.org MediaObject for a Markdown alternate of this page.
      # @param markdown_href [String] The relative path to the Markdown file.
      # @param site [Jekyll::Site] The Jekyll site object.
      # @return [Hash, nil] The Ruby Hash representing the MediaObject, or nil if href is empty.
      def self.build_markdown_encoding_entity(markdown_href, site)
        href = markdown_href.to_s.strip
        return nil if href.empty?

        {
          '@type' => 'MediaObject',
          'encodingFormat' => 'text/markdown',
          'contentUrl' => Jekyll::Infrastructure::UrlUtils.absolute_url(href, site),
        }
      end

      # --- Social Links Helper ---

      # Builds an array of social profile URLs from author config.
      # @param author [Hash] The author config hash from site.config['author'].
      # @return [Array<String>] Array of social profile URLs.
      def self.build_social_links(author)
        return [] unless author.is_a?(Hash)

        links = []
        links << "https://www.linkedin.com/in/#{author['linkedin']}" if author['linkedin']
        links << "https://github.com/#{author['github']}" if author['github']
        links << "https://bsky.app/profile/#{author['bluesky']}" if author['bluesky']
        links << "https://twitter.com/#{author['twitter']}" if author['twitter']
        if author['mastodon'] && author['mastodon_instance']
          links << "https://#{author['mastodon_instance']}/@#{author['mastodon']}"
        end
        links
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
