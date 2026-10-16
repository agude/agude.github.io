# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module LinkCache
      # Chooses the cached location a {% short_story_link %} points to.
      #
      # ShortStoryResolver (rendering) and LinkTagTargetResolver (backlinks)
      # both call it, so a rendered link and its backlink follow one rule.
      # It is pure: callers do their own logging.
      module ShortStoryLocationSelector
        # The rules, in order:
        # 1. The only location whose book is canonical (maps to itself in
        #    `canonical_map`). Archived reviews map to their canonical page.
        # 2. The first location, when every location is in the same book.
        # 3. The location whose parent book title matches `book_filter`,
        #    ignoring case.
        #
        # @param locations [Array<Hash>] the non-empty cached locations of one
        #   story, each with 'url' and 'parent_book_title'.
        # @param canonical_map [Hash, nil] the link cache
        #   'url_to_canonical_map'; nil is treated as an empty map.
        # @param book_filter [String, nil] the `from_book=` value. It is
        #   stripped; nil or blank means no filter.
        # @return [Hash, Symbol] the chosen location; :not_found_in_book when
        #   the filter matches no location; :ambiguous when no rule applies
        #   and there is no filter.
        def self.select_location(locations, canonical_map, book_filter)
          canonical = sole_canonical_location(locations, canonical_map || {})
          return canonical if canonical
          return locations.first if locations.map { |loc| loc['url'] }.uniq.length == 1

          filter = book_filter.to_s.strip
          return :ambiguous if filter.empty?

          locations.find { |loc| loc['parent_book_title'].casecmp(filter).zero? } || :not_found_in_book
        end

        def self.sole_canonical_location(locations, canonical_map)
          canonical = locations.select { |loc| canonical_map[loc['url']] == loc['url'] }
          canonical.first if canonical.length == 1
        end
        private_class_method :sole_canonical_location
      end
    end
  end
end
