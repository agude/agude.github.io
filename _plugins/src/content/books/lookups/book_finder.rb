# frozen_string_literal: true

# _plugins/logic/card_lookups/book_finder.rb

require 'date'

module Jekyll
  module Books
    module Lookups
      # Finds a book document by normalized title and optional date.
      #
      # Searches the books collection for a book with a matching title,
      # using case-insensitive and whitespace-normalized comparison.
      # If a date is provided, filters to only books with that exact date.
      # Returns a hash with :book (the found document or nil) and :error
      # (nil on success, or a hash with :type on failure).
      class BookFinder
        def initialize(site:, title:, date: nil)
          @site = site
          @title = title
          @date = date
        end

        def find
          return error_result(:invalid_input) unless @site && @title

          target_title_normalized = normalize_title(@title)
          return error_result(:invalid_input) unless target_title_normalized

          candidates = find_candidates_by_title(target_title_normalized)

          if @date
            find_by_date(candidates)
          else
            find_first_match(candidates)
          end
        end

        private

        def find_candidates_by_title(target_title_normalized)
          @site.collections['books'].docs.select do |b|
            next if b.data['published'] == false

            normalize_title(b.data['title']) == target_title_normalized
          end
        end

        def find_by_date(candidates)
          target_date = parse_date(@date)
          return error_result(:invalid_date) unless target_date

          book = candidates.find { |b| dates_match?(b.data['date'], target_date) }
          return error_result(:date_not_found) unless book

          { book: book, error: nil }
        end

        def find_first_match(candidates)
          book = candidates.first
          return error_result(:not_found) unless book

          { book: book, error: nil }
        end

        def parse_date(date_input)
          return date_input if date_input.is_a?(Date)

          Date.parse(date_input.to_s)
        rescue ArgumentError
          nil
        end

        def dates_match?(book_date, target_date)
          return false unless book_date

          book_date_normalized = normalize_date(book_date)
          book_date_normalized == target_date
        rescue ArgumentError
          false
        end

        def normalize_date(date_input)
          case date_input
          when Date
            date_input
          when Time
            date_input.to_date
          else
            Date.parse(date_input.to_s)
          end
        end

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
