# frozen_string_literal: true

require_relative '../person_json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD for author pages: a CollectionPage of the site
      # owner's reviews, `about` the book author. The author wrote the books,
      # not the site, so the page is not their profile (Google's ProfilePage
      # requires a person affiliated with the site). Page text stays on the
      # page node; the Person carries only identity.
      module AuthorProfileLdGenerator
        def self.generate_hash(document, site)
          Jekyll::SEO::PersonJsonLdBuilder.build('CollectionPage', document: document, site: site) do |page|
            title = document.data['title'].to_s.strip
            page.node_id document.url
            page.url
            page.name "#{title} - Book Reviews" unless title.empty?
            page.description
            page.site_author
            page.is_part_of_website
            page.about_entity('Person') do |person|
              person.node_id document.url, kind: :person
              person.url
              person.name title
              person.same_as document.data['same_as_urls']
              person.alternate_names document.data['pen_names']
            end
          end
        end
      end
    end
  end
end
