# frozen_string_literal: true

require_relative '../../infrastructure/links/link_resolver_skeleton'

module Jekyll
  module Authors
    # Helper class to handle author link resolution logic.
    class AuthorLinkResolver
      include Jekyll::Infrastructure::Links::LinkResolverSkeleton

      CACHE_SECTION = 'authors'
      TAG_TYPE = 'RENDER_AUTHOR_LINK'
      ENTITY_NAME = 'author'
      EMPTY_INPUT_STATUS = :empty_name
      EMPTY_INPUT_REASON = 'Input author name resolved to empty after normalization.'
      EMPTY_INPUT_KEY = :NameInput
      NOT_FOUND_KEY = :Name
      SPAN_CLASS = 'author-name'

      def resolve_data(name_raw, override, possessive, link: true)
        super(name_raw, override, link: link, possessive: possessive ? true : false)
      end

      private

      # Pen names link to the canonical author page while preserving the
      # credited name. A normalized match for the canonical name uses its title.
      def determine_display_text(entry, input, normalized)
        if entry && normalized == Text.normalize_title(entry['title'])
          entry['title']
        else
          input.strip
        end
      end

      def no_site_html(data)
        CGI.escapeHTML(data[:display_text])
      end
    end
  end
end
