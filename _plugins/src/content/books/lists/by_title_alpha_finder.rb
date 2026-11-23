# frozen_string_literal: true

require_relative 'shared'

module Jekyll
  module Books
    module Lists
      # Finds and structures all books grouped by the first letter of their normalized title.
      #
      # Handles validation, normalizing titles (removing articles), grouping by first letter,
      # and sorting books alphabetically within each letter group.
      class ByTitleAlphaFinder
        include Jekyll::Books::Lists::Shared

        # Finds and structures all books grouped by title's first letter.
        # @return [Hash] Contains :alpha_groups (Array of Hashes), :log_messages (String).
        def find
          find_groups(
            :alpha_groups,
            filter_type: 'all_books_by_title_alpha_group',
            empty_log: {
              tag_type: 'ALL_BOOKS_BY_TITLE_ALPHA_GROUP',
              reason: 'No published books found to group by title.',
            },
          ) do |books|
            group_books_by_alpha(books)
          end
        end

        private

        def group_books_by_alpha(books)
          books_with_meta = books.map { |book| create_book_alpha_meta(book) }

          sorted = books_with_meta.sort_by { |m| [m[:sort_title], m[:book].data['title'].to_s.downcase] }
          grouped = sorted.group_by { |m| m[:first_letter] }

          sort_alpha_groups(grouped)
        end

        def create_book_alpha_meta(book)
          sort_title = title_sort_key(book)
          first_letter = sort_title.empty? ? '#' : sort_title[0].upcase
          first_letter = '#' unless first_letter.match?(/[A-Z]/)
          { book: book, sort_title: sort_title, first_letter: first_letter }
        end

        def sort_alpha_groups(grouped)
          keys = grouped.keys.sort do |a, b|
            if a == '#' then -1
            elsif b == '#' then 1
            else
              a <=> b
            end
          end

          keys.map do |letter|
            { letter: letter, books: grouped[letter].map { |m| m[:book] } }
          end
        end
      end
    end
  end
end
