# frozen_string_literal: true

# _plugins/logic/book_lists/by_year_finder.rb
require_relative 'shared'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Finds and structures all books grouped by publication year.
          #
          # Handles validation, grouping books by year, and sorting years
          # (most recent first) with books within each year sorted by date (most recent first).
          class ByYearFinder
            include Jekyll::Books::Lists::Renderers::BookLists::Shared

            def initialize(site:, context:)
              @site = site
              @context = context
            end

            # Finds and structures all books grouped by publication year.
            # @return [Hash] Contains :year_groups (Array of Hashes), :log_messages (String).
            def find
              error = validate_collection({ filter_type: 'all_books_by_year' }, key: :year_groups)
              return error if error

              all_books = all_published_books(include_archived: true)
              if all_books.empty?
                return return_info('ALL_BOOKS_BY_YEAR_DISPLAY',
                                   'No published books found to group by year.',
                                   key: :year_groups)
              end

              year_groups_list = group_books_by_year(all_books)
              { year_groups: year_groups_list, log_messages: String.new }
            end

            private

            def group_books_by_year(books)
              sorted = books.sort_by do |book|
                book.date.is_a?(Time) ? book.date : Time.now
              end.reverse

              grouped = sorted.group_by { |book| book.date.year.to_s }

              grouped.keys.sort.reverse.map do |year|
                { year: year, books: grouped[year] }
              end
            end
          end
        end
      end
    end
  end
end
