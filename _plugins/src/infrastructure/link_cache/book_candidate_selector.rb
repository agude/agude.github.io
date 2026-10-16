# frozen_string_literal: true

require_relative 'author_lookup'

module Jekyll
  module Infrastructure
    module LinkCache
      # Chooses the cached book a {% book_link %} points to, among the
      # candidates that share its title.
      #
      # BookLinkResolver (rendering) and LinkTagTargetResolver (backlinks)
      # both call it, so a rendered link and its backlink follow one author
      # rule. It is pure: callers do their own logging and raise their own
      # errors.
      module BookCandidateSelector
        # @param candidates [Array<Hash>] the non-empty cached books with the
        #   title, archived reviews already removed, each with 'authors'.
        # @param author_filter [String, nil] the `author=` value. It is
        #   stripped; nil or blank means no filter.
        # @param author_cache [Hash, nil] the link cache 'authors' section;
        #   nil is treated as empty.
        # @return [Hash, Symbol] the chosen book; :author_mismatch when no
        #   candidate is by the filtered author; :ambiguous when there are
        #   several candidates and no filter.
        def self.select_book(candidates, author_filter, author_cache)
          author = author_filter.to_s.strip
          return candidates.length > 1 ? :ambiguous : candidates.first if author.empty?

          cache = author_cache || {}
          wanted = AuthorLookup.canonical_author(author, cache)
          candidates.find { |book| written_by?(book, wanted, cache) } || :author_mismatch
        end

        # Compares canonical names, so a pen name matches its author.
        def self.written_by?(book, wanted, author_cache)
          Array(book['authors']).any? do |name|
            canonical = AuthorLookup.canonical_author(name, author_cache)
            canonical&.casecmp(wanted)&.zero?
          end
        end
        private_class_method :written_by?
      end
    end
  end
end
