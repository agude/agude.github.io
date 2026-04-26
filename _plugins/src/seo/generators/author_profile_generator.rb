# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Person schema for author profile pages.
      module AuthorProfileLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('Person', document: document, site: site) do |schema|
            schema.name document.data['title']
            schema.url
            schema.same_as document.data['same_as_urls']
            schema.description_from_fields(field_priority: %w[excerpt description])
            schema.alternate_names document.data['pen_names']
          end
        end
      end
    end
  end
end
