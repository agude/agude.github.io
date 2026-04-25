# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Person schema for resume/about pages.
      module PersonLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('Person', document: document, site: site) do |schema|
            schema.name site.config.dig('author', 'name')
            schema.url
            schema.job_title document.data['job_title']
            schema.works_for document.data['works_for']
            schema.description
            schema.social_links_from_site
          end
        end
      end
    end
  end
end
