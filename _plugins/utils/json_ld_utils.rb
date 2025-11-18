# _plugins/utils/json_ld_utils.rb
require_relative 'text_processing_utils' # For cleaning/truncating text
require_relative 'url_utils' # For absolute URLs

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

    person_data = {
      '@type' => 'Person',
      'name' => person_name
    }

    if include_site_url
      site_root_url = UrlUtils.absolute_url('', site)
      person_data['url'] = site_root_url if site_root_url && !site_root_url.empty?
    end
    person_data
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
      'url' => UrlUtils.absolute_url(image_path, site)
      # "height" and "width" could be added if a mechanism to fetch them exists
    }
  end

  # --- Content Extraction Helpers ---

  # Extracts and prepares descriptive text from a document based on a priority of fields.
  # @param document [Jekyll::Document] The Jekyll document.
  # @param field_priority [Array<String>] Ordered list of fields to check (e.g., ['excerpt', 'description', 'content']).
  # @param truncate_options [Hash, nil] Options for truncation (e.g., { words: 50, omission: "..." }).
  #                                     If nil, no truncation.
  # @return [String, nil] The cleaned (and optionally truncated) text, or nil if no suitable content found.
  def self.extract_descriptive_text(document, field_priority:, truncate_options: nil)
    html_content = ''
    field_priority.each do |field_key|
      source_content = nil
      # Use duck typing: check if it has an 'output' method we can call
      if field_key == 'excerpt' && document.data['excerpt'].respond_to?(:output)
        source_content = document.data['excerpt'].output
      elsif field_key == 'content' && document.data.key?('content') # Prioritize data hash for 'content'
        source_content = document.data['content'].to_s
      elsif field_key == 'content' # Fallback to direct attribute
        source_content = document.content
      elsif document.data[field_key] # For other front matter fields like 'description'
        source_content = document.data[field_key].to_s
      end

      if source_content && !source_content.strip.empty?
        html_content = source_content
        break
      end
    end

    return nil if html_content.empty?

    cleaned_text = TextProcessingUtils.clean_text_from_html(html_content)
    return nil if cleaned_text.empty?

    if truncate_options && truncate_options[:words]
      TextProcessingUtils.truncate_words(cleaned_text, truncate_options[:words], truncate_options[:omission] || '...')
    else
      cleaned_text
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
