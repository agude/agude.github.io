# frozen_string_literal: true

require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Person schema for resume/about pages.
      # Creates structured data for personal profile pages.
      module PersonLdGenerator
        def self.generate_hash(document, site)
          data = base_data_hash
          add_name(data, site)
          add_url(data, document, site)
          add_job_title(data, document)
          add_works_for(data, document)
          add_description(data, document)
          add_same_as(data, site)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private_class_method def self.base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'Person',
          }
        end

        private_class_method def self.add_name(data, site)
          name = site.config.dig('author', 'name')
          data['name'] = name if name && !name.strip.empty?
        end

        private_class_method def self.add_url(data, document, site)
          url = Jekyll::Infrastructure::UrlUtils.absolute_url(document.url, site)
          data['url'] = url if url && !url.strip.empty?
        end

        private_class_method def self.add_job_title(data, document)
          job_title = document.data['job_title']
          data['jobTitle'] = job_title if job_title && !job_title.strip.empty?
        end

        private_class_method def self.add_works_for(data, document)
          works_for = document.data['works_for']
          return unless works_for && !works_for.strip.empty?

          data['worksFor'] = {
            '@type' => 'Organization',
            'name' => works_for,
          }
        end

        private_class_method def self.add_description(data, document)
          Jekyll::SEO::JsonLdUtils.add_cleaned_description(data, document)
        end

        private_class_method def self.add_same_as(data, site)
          author = site.config['author'] || {}
          links = Jekyll::SEO::JsonLdUtils.build_social_links(author)
          data['sameAs'] = links if links.any?
        end
      end
    end
  end
end
