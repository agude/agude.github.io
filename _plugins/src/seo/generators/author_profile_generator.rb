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
            page.node_id document.url
            page.url
            page.page_name document.data['title'], suffix: 'Book Reviews'
            page.description
            page.site_author
            page.is_part_of_website
            page.about_entity('Person') do |person|
              person.node_id document.url, kind: :person
              person.url
              person.name document.data['title']
              person.same_as document.data['same_as_urls'], wikidata_qid: document.data['wikidata_qid']
              person.alternate_names document.data['pen_names']
            end
          end
        end
      end
    end
  end
end
