# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for generic pages.
      module PageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('CollectionPage', document: document, site: site) do |schema|
            schema.name document.data['title']
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
