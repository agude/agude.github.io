# frozen_string_literal: true

require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for series pages.
      # Creates structured data for book series listing pages.
      module SeriesPageLdGenerator
        def self.generate_hash(document, site)
          data = base_data_hash
          add_name(data, document)
          add_url(data, document, site)
          add_description(data, document)
          add_about(data, document)
          add_author(data, site)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private_class_method def self.base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'CollectionPage',
          }
        end

        private_class_method def self.add_name(data, document)
          title = document.data['title']
          return unless title && !title.strip.empty?

          data['name'] = "#{title} - Book Reviews"
        end

        private_class_method def self.add_url(data, document, site)
          url = Jekyll::Infrastructure::UrlUtils.absolute_url(document.url, site)
          data['url'] = url if url && !url.strip.empty?
        end

        private_class_method def self.add_description(data, document)
          description = document.data['description']
          return unless description && !description.strip.empty?

          cleaned = Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(description)
          data['description'] = cleaned unless cleaned.empty?
        end

        private_class_method def self.add_about(data, document)
          series_name = document.data['title']
          return unless series_name && !series_name.strip.empty?

          data['about'] = {
            '@type' => 'BookSeries',
            'name' => series_name,
          }
        end

        private_class_method def self.add_author(data, site)
          author_entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(site)
          data['author'] = author_entity if author_entity
        end
      end
    end
  end
end
