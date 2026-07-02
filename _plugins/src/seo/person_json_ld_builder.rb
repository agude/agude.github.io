# frozen_string_literal: true

require_relative 'json_ld_builder'

module Jekyll
  module SEO
    # Extends JsonLdBuilder with person/resume-specific schema.org methods.
    # Used by PersonGenerator, ProfilePageGenerator, and AuthorProfileGenerator.
    class PersonJsonLdBuilder < JsonLdBuilder
      def job_title(value)
        set_if_present('jobTitle', value)
      end

      def given_name(value)
        set_if_present('givenName', value)
      end

      def family_name(value)
        set_if_present('familyName', value)
      end

      def honorific_prefix(value)
        set_if_present('honorificPrefix', value)
      end

      def pronouns(value)
        set_if_present('pronouns', value)
      end

      def author_identity_from_site
        author = @site&.config&.[]('author') || {}
        name author['name']
        given_name author['first']
        family_name author['last']
        alternate_names author['alternate_names']
        honorific_prefix author['honorific_prefix']
        pronouns author['pronouns']
        image_url @site&.config&.[]('logo')
      end

      def works_for(org_name)
        return unless org_name && !org_name.to_s.strip.empty?

        @data['worksFor'] = {
          '@type' => 'Organization',
          'name' => org_name.to_s.strip,
        }
      end

      def alumni_of(experience_list, education_list)
        orgs = []

        if experience_list.is_a?(Array) && experience_list.length > 1
          experience_list[1..].each do |job|
            name = job['company']
            next unless name && !name.to_s.strip.empty?

            orgs << { '@type' => 'Organization', 'name' => name.to_s.strip }
          end
        end

        if education_list.is_a?(Array)
          education_list.each do |edu|
            name = edu['company']
            next unless name && !name.to_s.strip.empty?

            orgs << { '@type' => 'EducationalOrganization', 'name' => name.to_s.strip }
          end
        end

        @data['alumniOf'] = orgs if orgs.any?
      end

      def has_occupation(experience_list) # rubocop:disable Naming/PredicatePrefix
        return unless experience_list.is_a?(Array) && experience_list.any?

        roles = experience_list.flat_map do |job|
          positions = job['positions']
          next [] unless positions.is_a?(Array)

          positions.filter_map do |pos|
            title = pos['title']
            dates = pos['dates']
            next unless title

            start_date, end_date = parse_date_range(dates)
            role = {
              '@type' => 'Role',
              'hasOccupation' => { '@type' => 'Occupation', 'name' => title.to_s.strip },
            }
            role['startDate'] = start_date if start_date
            role['endDate'] = end_date if end_date
            role
          end
        end
        @data['hasOccupation'] = roles if roles.any?
      end

      def has_credential(education_list) # rubocop:disable Naming/PredicatePrefix
        return unless education_list.is_a?(Array) && education_list.any?

        credentials = education_list.flat_map do |edu|
          school = edu['company']
          positions = edu['positions']
          next [] unless school && positions.is_a?(Array)

          positions.filter_map do |pos|
            degree = pos['title']
            next unless degree

            {
              '@type' => 'EducationalOccupationalCredential',
              'credentialCategory' => 'degree',
              'name' => degree.to_s.strip,
              'recognizedBy' => { '@type' => 'EducationalOrganization', 'name' => school.to_s.strip },
            }
          end
        end
        @data['hasCredential'] = credentials if credentials.any?
      end

      def knows_about(skills_hash)
        return unless skills_hash.is_a?(Hash)

        items = []
        %w[languages tools].each do |key|
          val = skills_hash[key]
          next unless val

          cleaned = val.to_s.gsub(/<[^>]+>/, '').strip
          items.concat(cleaned.split(',').map(&:strip).reject(&:empty?))
        end
        @data['knowsAbout'] = items.uniq if items.any?
      end

      def social_links_from_site
        author = @site&.config&.[]('author') || {}
        links = Jekyll::SEO::JsonLdUtils.build_social_links(author)
        @data['sameAs'] = links if links.any?
      end

      def main_entity_person_with_social
        author = @site&.config&.[]('author')
        return unless author.is_a?(Hash) && author['name']

        person = { '@type' => 'Person', 'name' => author['name'] }
        links = Jekyll::SEO::JsonLdUtils.build_social_links(author)
        person['sameAs'] = links if links.any?
        @data['mainEntity'] = person
      end

      def alternate_names(names)
        list = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(names)
        @data['alternateName'] = list if list.any?
      end
    end
  end
end
