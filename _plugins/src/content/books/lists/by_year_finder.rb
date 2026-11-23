# frozen_string_literal: true

require_relative 'shared'

module Jekyll
  module Books
    module Lists
      # Finds and structures all books grouped by publication year.
      #
      # Handles validation, grouping books by year, and sorting years
      # (most recent first) with books within each year sorted by date (most recent first).
      class ByYearFinder
        include Jekyll::Books::Lists::Shared

        # Finds and structures all books grouped by publication year.
        # @return [Hash] Contains :year_groups (Array of Hashes), :log_messages (String).
        def find
          find_groups(
            :year_groups,
            filter_type: 'all_books_by_year',
            empty_log: {
              tag_type: 'ALL_BOOKS_BY_YEAR_DISPLAY',
              reason: 'No published books found to group by year.',
            },
            include_archived: true,
          ) do |books|
            group_books_by_year(books)
          end
        end

        private

        def group_books_by_year(books)
          # Jekyll guarantees doc.date is a Time (strict_front_matter would
          # have failed the build otherwise), so sort on it directly; a
          # non-Time date should crash, not silently sort as "now".
          sorted = books.sort_by(&:date).reverse

          grouped = sorted.group_by { |book| book.date.year.to_s }

          grouped.keys.sort.reverse.map do |year|
            { year: year, books: grouped[year] }
          end
        end
      end
    end
  end
end
