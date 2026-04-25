# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD CollectionPage schema for series pages.
      module SeriesPageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('CollectionPage', document: document, site: site) do |schema|
            schema.name_with_suffix 'Book Reviews'
            schema.url
            schema.description
            schema.about 'BookSeries', document.data['title']
            schema.site_author
          end
        end
      end
    end
  end
end
