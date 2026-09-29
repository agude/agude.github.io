# frozen_string_literal: true

module Jekyll
  module Books
    module Ranking
      module RankedBooks
        # Validates a ranked books list for correctness.
        #
        # Ensures that:
        # 1. Each title exists in the books collection
        # 2. Each book has a valid integer rating
        # 3. Ratings are monotonically non-increasing
        class Validator
          def initialize(list_variable_markup)
            @list_variable_markup = list_variable_markup
            @prev_rating = Float::INFINITY
            @prev_title = nil
          end

          def validate(title_raw, index, book)
            validate_book_exists(title_raw, index, book)

            rating = parse_rating(book.data['rating'], title_raw, index)
            validate_monotonicity(rating, title_raw, index)

            @prev_rating = rating
            @prev_title = title_raw
            rating
          end

          private

          def validate_book_exists(title_raw, index, book)
            return if book

            msg = "Jekyll::Books::Ranking::RankedBooks Validation Error: Title '#{title_raw}' " \
                  "(position #{index + 1} in '#{@list_variable_markup}') " \
                  "not found in the 'books' collection."
            raise Jekyll::Errors::FatalException, msg
          end

          def validate_monotonicity(rating, title_raw, index)
            return unless rating > @prev_rating

            msg = 'Jekyll::Books::Ranking::RankedBooks Validation Error: ' \
                  "Monotonicity violation in '#{@list_variable_markup}'. \n  " \
                  "Title '#{title_raw}' (Rating: #{rating}) at position #{index + 1} \n  " \
                  "cannot appear after \n  " \
                  "Title '#{@prev_title}' (Rating: #{@prev_rating}) at position #{index}."
            raise Jekyll::Errors::FatalException, msg
          end

          def parse_rating(raw, title, index)
            Integer(raw)
          rescue ArgumentError, TypeError
            msg = "Jekyll::Books::Ranking::RankedBooks Validation Error: Title '#{title}' " \
                  "(position #{index + 1} in '#{@list_variable_markup}') " \
                  "has invalid non-integer rating: '#{raw.inspect}'."
            raise Jekyll::Errors::FatalException, msg
          end
        end
      end
    end
  end
end
