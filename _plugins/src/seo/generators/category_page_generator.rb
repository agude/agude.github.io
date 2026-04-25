# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for category/topic pages.
      module CategoryPageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('CollectionPage', document: document, site: site) do |schema|
            title = document.data['category-title'] || document.data['title']
            schema.name "#{title} - Articles" if title && !title.strip.empty?
            schema.url
            schema.description
            schema.site_author
            schema.is_part_of_website
          end
        end
      end
    end
  end
end
