# frozen_string_literal: true

require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for category/topic pages.
      # Creates structured data for blog category listing pages.
      module CategoryPageLdGenerator
        def self.generate_hash(document, site)
          data = base_data_hash
          add_name(data, document)
          add_url(data, document, site)
          add_description(data, document)
          add_author(data, site)
          add_is_part_of(data, site)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private_class_method def self.base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'CollectionPage',
          }
        end

        private_class_method def self.add_name(data, document)
          title = document.data['category-title'] || document.data['title']
          return unless title && !title.strip.empty?

          data['name'] = "#{title} - Articles"
        end

        private_class_method def self.add_url(data, document, site)
          url = Jekyll::Infrastructure::UrlUtils.absolute_url(document.url, site)
          data['url'] = url if url && !url.strip.empty?
        end

        private_class_method def self.add_description(data, document)
          Jekyll::SEO::JsonLdUtils.add_cleaned_description(data, document)
        end

        private_class_method def self.add_author(data, site)
          author_entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(site)
          data['author'] = author_entity if author_entity
        end

        private_class_method def self.add_is_part_of(data, site)
          site_name = site.config['title']
          site_url = Jekyll::Infrastructure::UrlUtils.absolute_url('', site)
          return unless site_name && site_url

          data['isPartOf'] = {
            '@type' => 'WebSite',
            'name' => site_name,
            'url' => site_url,
          }
        end
      end
    end
  end
end
