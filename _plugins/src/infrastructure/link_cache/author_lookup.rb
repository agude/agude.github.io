# frozen_string_literal: true

require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module LinkCache
      # Canonicalizes author names against the link cache's 'authors' section.
      #
      # The cache maps normalized names to author page data; the canonical
      # spelling is that page's title. Unknown authors fall back to the
      # stripped input so display still works for authors without pages.
      module AuthorLookup
        # @param name [String, nil] raw author name as written in front matter.
        # @param author_cache [Hash] the link cache 'authors' section
        #   (normalized name => { 'title' => canonical title, ... }).
        # @return [String, nil] canonical title if cached, stripped input if
        #   not, or nil for blank input.
        def self.canonical_author(name, author_cache)
          stripped = name.to_s.strip
          return nil if stripped.empty?

          normalized = TextProcessingUtils.normalize_title(stripped)
          data = author_cache[normalized]
          data ? data['title'] : stripped
        end
      end
    end
  end
end
