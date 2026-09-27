# frozen_string_literal: true

require_relative '../infrastructure/front_matter_utils'
require_relative '../infrastructure/text_processing_utils'
require_relative '../infrastructure/url_utils'

module Jekyll
  module SEO
    # Resolves credited book authors to the canonical author-page entities.
    class BookAuthorEntityResolver
      def self.resolve(document, site)
        author_names = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(
          document&.data&.[]('book_authors'),
        )
        return if author_names.empty?

        entities = author_names.map { |name| resolve_author(name, document, site) }
        entities.length == 1 ? entities.first : entities
      end

      def self.resolve_author(credited_name, document, site)
        author_data = find_author_data(credited_name, site)
        unless author_data
          raise Jekyll::Errors::FatalException,
                "JSON-LD Book for #{document_url(document)}: " \
                "could not resolve author page for #{credited_name.inspect}."
        end

        author_url = Jekyll::Infrastructure::UrlUtils.absolute_url(author_data['url'], site)
        entity = {
          '@type' => 'Person',
          '@id' => author_url,
          'url' => author_url,
          'name' => credited_name,
        }
        same_as_urls = author_data['same_as_urls']
        entity['sameAs'] = same_as_urls if same_as_urls&.any?
        entity
      end
      private_class_method :resolve_author

      def self.find_author_data(name, site)
        normalized_name = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(name)
        site&.data&.dig('link_cache', 'authors', normalized_name)
      end
      private_class_method :find_author_data

      def self.document_url(document)
        document&.url || document&.path || 'unknown'
      end
      private_class_method :document_url
    end
  end
end
