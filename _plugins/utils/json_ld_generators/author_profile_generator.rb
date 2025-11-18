# frozen_string_literal: true
# _plugins/utils/json_ld_generators/author_profile_generator.rb
require_relative '../json_ld_utils'
require_relative '../url_utils'
require_relative '../front_matter_utils'
require 'jekyll' # For logger

module AuthorProfileLdGenerator
  def self.generate_hash(document, site)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'Person'
    }

    # Essential: Author Name (from page title)
    author_name = document.data['title']
    data['name'] = author_name if author_name && !author_name.strip.empty?

    # Essential: URL of this author page
    author_page_url = UrlUtils.absolute_url(document.url, site)
    data['url'] = author_page_url if author_page_url

    # Recommended: sameAs links (from front matter list 'same_as_urls')
    same_as_links_from_fm = document.data['same_as_urls'] || [] # Read the list, default to empty

    # Validate that it's an array and filter out nil/empty strings
    if same_as_links_from_fm.is_a?(Array)
      filtered_links = same_as_links_from_fm.map(&:to_s).map(&:strip).compact.reject(&:empty?)
      data['sameAs'] = filtered_links if filtered_links.any?
    elsif same_as_links_from_fm # Log if key exists but isn't an array
      doc_identifier = document.url || document.path || document.relative_path
      Jekyll.logger.warn 'JSON-LD:',
                         "Front matter 'same_as_urls' for '#{doc_identifier}' is not an Array, skipping sameAs."
    end

    # Optional: Description
    description = JsonLdUtils.extract_descriptive_text(
      document,
      field_priority: %w[excerpt description]
    )
    data['description'] = description if description

    # Add pen names as alternateName
    pen_names_list = FrontMatterUtils.get_list_from_string_or_array(document.data['pen_names'])
    data['alternateName'] = pen_names_list if pen_names_list.any?

    # Clean final hash
    JsonLdUtils.cleanup_data_hash!(data)
  end
end
