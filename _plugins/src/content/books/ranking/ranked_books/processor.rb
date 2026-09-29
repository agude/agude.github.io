# frozen_string_literal: true

require_relative 'validator'
require_relative '../../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Ranking
      module RankedBooks
        # Processes a ranked books list into structured data.
        #
        # Takes a raw list of book titles, validates them,
        # and transforms them into rating groups for rendering.
        class Processor
          def initialize(context, list_variable_markup)
            @context = context
            @site = context.registers[:site]
            @list_variable_markup = list_variable_markup
          end

          def process
            ranked_list = resolve_list
            return { rating_groups: [], log_messages: '' } if ranked_list.empty?

            book_map = build_book_map
            validator = Validator.new(@list_variable_markup)

            rating_groups = process_list(ranked_list, book_map, validator)

            { rating_groups: rating_groups, log_messages: '' }
          rescue Jekyll::Errors::FatalException
            raise
          rescue StandardError => e
            raise Jekyll::Errors::FatalException,
                  "Ranked books: Error processing '#{@list_variable_markup}': #{e.message}"
          end

          private

          def resolve_list
            list = @context[@list_variable_markup]
            unless list.is_a?(Array)
              msg = 'Jekyll::Books::Ranking::RankedBooks Error: ' \
                    "Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{list.class}"
              raise Jekyll::Errors::FatalException, msg
            end

            list
          end

          def build_book_map
            raise_unless_books_collection_exists

            @site.collections['books'].docs.each_with_object({}) do |book, map|
              add_book_to_map(book, map)
            end
          end

          def raise_unless_books_collection_exists
            return if @site.collections.key?('books')

            raise Jekyll::Errors::FatalException,
                  "Ranked books: Collection 'books' not found in site configuration."
          end

          def add_book_to_map(book, map)
            return if book.data['published'] == false

            title = book.data['title']
            return unless title && !title.to_s.strip.empty?

            normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title, strip_articles: false)
            map[normalized] = book
          end

          def process_list(ranked_list, book_map, validator)
            groups = []
            current_rating = nil
            current_books = []

            ranked_list.each_with_index do |title_raw, index|
              book = find_book(title_raw, book_map)

              rating = validator.validate(title_raw, index, book)

              if rating != current_rating
                groups << { rating: current_rating, books: current_books } if current_rating && current_books.any?
                current_rating = rating
                current_books = []
              end

              current_books << book
            end

            groups << { rating: current_rating, books: current_books } if current_rating && current_books.any?
            groups
          end

          def find_book(title_raw, book_map)
            normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(
              title_raw,
              strip_articles: false,
            )
            book_map[normalized]
          end

        end
      end
    end
  end
end
