# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for series pages.
      module SeriesPageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('CollectionPage', document: document, site: site) do |schema|
            schema.page_name document.data['title'], suffix: 'Book Reviews'
            schema.url
            schema.description
            schema.about_book_series document.data['title']
            schema.site_author
            schema.is_part_of_website
          end
        end
      end
    end
  end
end
