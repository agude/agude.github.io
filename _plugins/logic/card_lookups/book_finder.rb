# frozen_string_literal: true

# _plugins/logic/card_lookups/book_finder.rb

module Jekyll
  module CardLookups
    # Finds a book document by normalized title.
    #
    # Searches the books collection for a book with a matching title,
    # using case-insensitive and whitespace-normalized comparison.
    class BookFinder
      def self.find(site:, title:)
        return nil unless site && title

        target_title_normalized = normalize_title(title)
        return nil unless target_title_normalized

        site.collections['books'].docs.find do |book|
          next if book.data['published'] == false

          normalize_title(book.data['title']) == target_title_normalized
        end
      end

      def self.normalize_title(title)
        return nil unless title

        title.to_s.gsub(/\s+/, ' ').strip.downcase
      end

      private_class_method :normalize_title
    end
  end
end
