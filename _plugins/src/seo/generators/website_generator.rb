# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD WebSite schema for the homepage.
      module WebsiteLdGenerator
        def self.generate_hash(_document, site)
          Jekyll::SEO::JsonLdBuilder.build('WebSite', site: site) do |schema|
            schema.site_name
            schema.url ''
            schema.site_description
            schema.site_author
            schema.site_publisher
          end
        end
      end
    end
  end
end
