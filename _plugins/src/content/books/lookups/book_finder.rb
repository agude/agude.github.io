# frozen_string_literal: true

# _plugins/logic/card_lookups/book_finder.rb

module Jekyll
  module Books
    module Lookups
      # Finds a book document by normalized title.
      #
      # Searches the books collection for a book with a matching title,
      # using case-insensitive and whitespace-normalized comparison.
      # Returns a hash with :book (the found document or nil) and :error
      # (nil on success, or a hash with :type on failure).
      class BookFinder
        def initialize(site:, title:)
          @site = site
          @title = title
        end

        def find
          return error_result(:invalid_input) unless @site && @title

          target_title_normalized = normalize_title(@title)
          return error_result(:invalid_input) unless target_title_normalized

          book = @site.collections['books'].docs.find do |b|
            next if b.data['published'] == false

            normalize_title(b.data['title']) == target_title_normalized
          end

          return error_result(:not_found) unless book

          { book: book, error: nil }
        end

        private

        def normalize_title(title)
          return nil unless title

          normalized = title.to_s.gsub(/\s+/, ' ').strip.downcase
          normalized.empty? ? nil : normalized
        end

        def error_result(type)
          { book: nil, error: { type: type } }
        end
      end
    end
  end
end
