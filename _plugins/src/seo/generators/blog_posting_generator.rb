# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD BlogPosting schema for blog posts.
      module BlogPostingLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::JsonLdBuilder.build('BlogPosting', license: true, document: document, site: site) do |schema|
            schema.headline document.data['title']
            schema.site_author
            schema.site_publisher
            schema.dates
            schema.image document.data['image']
            schema.url
            schema.main_entity_of_page
            schema.description_from_fields(field_priority: %w[excerpt description], truncate_words: 50)
            schema.article_body
            schema.keywords(document.data['categories'], document.data['tags'])
            schema.encoding document.data['markdown_alternate_href']
            schema.require! :headline, :url
          end
        end
      end
    end
  end
end
