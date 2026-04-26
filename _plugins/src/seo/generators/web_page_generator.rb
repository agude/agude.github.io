# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD WebPage schema for supplementary content pages.
      # Used for pages that accompany blog posts (e.g., files/, examples/).
      module WebPageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('WebPage', document: document, site: site) do |schema|
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
