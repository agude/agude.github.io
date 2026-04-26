# frozen_string_literal: true

require_relative '../json_ld_builder'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD Person schema for resume/about pages.
      module PersonLdGenerator
        def self.generate_hash(document, site)
          experience = document.data['experience']
          education = document.data['education']
          current_employer = experience&.dig(0, 'company')

          Jekyll::SEO::JsonLdBuilder.build('Person', document: document, site: site) do |schema|
            schema.author_identity_from_site
            schema.url
            schema.job_title document.data['job_title']
            schema.description
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
