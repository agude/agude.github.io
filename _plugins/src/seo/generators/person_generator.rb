# frozen_string_literal: true

require_relative '../person_json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD for the resume: the site owner's ProfilePage, with
      # the owner's Person as mainEntity. Every author/publisher reference
      # on the site points at that Person's @id (author.url + #person).
      module PersonLdGenerator
        def self.generate_hash(document, site)
          experience = document.data['experience']
          education = document.data['education']
          current_employer = experience&.dig(0, 'company')

          Jekyll::SEO::PersonJsonLdBuilder.build('ProfilePage', document: document, site: site) do |page|
            page.node_id document.url
            page.url
            page.name document.data['title']
            page.description
            page.is_part_of_website
            page.main_entity('Person') do |schema|
              schema.author_identity_from_site
              schema.site_owner_identity
              schema.job_title document.data['job_title']
              schema.image site.config['logo']
              schema.social_links_from_site
              schema.works_for current_employer
              schema.alumni_of experience, education
              schema.has_occupation experience
              schema.has_credential education
              schema.knows_about document.data['skills']
            end
          end
        end
      end
    end
  end
end
