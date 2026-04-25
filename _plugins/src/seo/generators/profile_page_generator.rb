# frozen_string_literal: true

require_relative '../json_ld_utils'
require_relative '../../infrastructure/url_utils'

module Jekyll
  module SEO
    module Generators
      # Generates JSON-LD ProfilePage schema for linktree/profile pages.
      # Creates structured data for pages that link to social profiles.
      module ProfilePageLdGenerator
        def self.generate_hash(document, site)
          data = base_data_hash
          add_name(data, document)
          add_url(data, document, site)
          add_description(data, document)
          add_main_entity(data, site)
          Jekyll::SEO::JsonLdUtils.cleanup_data_hash!(data)
        end

        private_class_method def self.base_data_hash
          {
            '@context' => 'https://schema.org',
            '@type' => 'ProfilePage',
          }
        end

        private_class_method def self.add_name(data, document)
          title = document.data['title']
          data['name'] = title if title && !title.strip.empty?
        end

        private_class_method def self.add_url(data, document, site)
          url = Jekyll::Infrastructure::UrlUtils.absolute_url(document.url, site)
          data['url'] = url if url && !url.strip.empty?
        end

        private_class_method def self.add_description(data, document)
          description = document.data['description']
          return unless description && !description.strip.empty?

          cleaned = Jekyll::Infrastructure::TextProcessingUtils.clean_text_from_html(description)
          data['description'] = cleaned unless cleaned.empty?
        end

        private_class_method def self.add_main_entity(data, site)
          author = site.config['author']
          return unless author.is_a?(Hash) && author['name']

          person = {
            '@type' => 'Person',
            'name' => author['name'],
          }

          same_as = build_social_links(author)
          person['sameAs'] = same_as if same_as.any?

          data['mainEntity'] = person
        end

        private_class_method def self.build_social_links(author)
          links = []
          links << "https://www.linkedin.com/in/#{author['linkedin']}" if author['linkedin']
          links << "https://github.com/#{author['github']}" if author['github']
          links << "https://bsky.app/profile/#{author['bluesky']}" if author['bluesky']
          links << "https://twitter.com/#{author['twitter']}" if author['twitter']
          links << "https://mastodon.social/@#{author['mastodon']}" if author['mastodon']
          links
        end
      end
    end
  end
end
