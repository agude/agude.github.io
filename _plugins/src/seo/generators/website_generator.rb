# frozen_string_literal: true

require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD WebSite schema for the homepage.
      # Creates structured data to help search engines understand site structure.
      module WebsiteLdGenerator
        def self.generate_hash(_document, site)
          data = base_data_hash
          add_name(data, site)
          add_url(data, site)
          add_description(data, site)
          add_author_and_publisher(data, site)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private_class_method def self.base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'WebSite',
          }
        end

        private_class_method def self.add_name(data, site)
          name = site.config['title']
          data['name'] = name if name && !name.strip.empty?
        end

        private_class_method def self.add_url(data, site)
          url = Jekyll::Infrastructure::UrlUtils.absolute_url('', site)
          data['url'] = url if url && !url.strip.empty?
        end

        private_class_method def self.add_description(data, site)
          description = site.config['description']
          data['description'] = description if description && !description.strip.empty?
        end

        private_class_method def self.add_author_and_publisher(data, site)
          author_entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(site)
          data['author'] = author_entity if author_entity

          publisher_entity = Jekyll::SEO::JsonLdUtils.build_site_person_entity(site, include_site_url: true)
          data['publisher'] = publisher_entity if publisher_entity
        end
      end
    end
  end
end
