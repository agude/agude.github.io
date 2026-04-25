# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD ProfilePage schema for linktree/profile pages.
      module ProfilePageLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('ProfilePage', document: document, site: site) do |schema|
            schema.name document.data['title']
            schema.url
            schema.description
            schema.main_entity_person_with_social
          end
        end
      end
    end
  end
end
