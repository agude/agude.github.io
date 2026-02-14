# frozen_string_literal: true

require_relative 'validator'
require_relative '../../../../infrastructure/plugin_logger_utils'
require_relative '../../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Ranking
      module RankedBooks
        # Processes a ranked books list into structured data.
        #
        # Takes a raw list of book titles, validates them (if not in production),
        # and transforms them into rating groups for rendering.
        class Processor
          def initialize(context, list_variable_markup)
            @context = context
            @site = context.registers[:site]
            @list_variable_markup = list_variable_markup
            @is_production = (@site.config['environment'] || 'development') == 'production'
            @log_messages = String.new
          end

          def process
            ranked_list = resolve_list
            return { rating_groups: [], log_messages: @log_messages } if ranked_list.empty?

            book_map = build_book_map
            validator = Validator.new(book_map, @list_variable_markup, @is_production)

            rating_groups = process_list(ranked_list, book_map, validator)

            { rating_groups: rating_groups, log_messages: @log_messages }
          rescue StandardError => e
            error_message = 'Jekyll::Books::Ranking::RankedBooks ' \
                            "Error processing '#{@list_variable_markup}': #{e.message} \n #{e.backtrace.join("\n  ")}"
            raise error_message
          end

          private

          def resolve_list
            list = @context[@list_variable_markup]
            unless list.is_a?(Array)
              msg = 'Jekyll::Books::Ranking::RankedBooks Error: ' \
                    "Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{list.class}"
              raise msg
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

            raise 'Jekyll::Books::Ranking::RankedBooks Error: ' \
                  "Collection 'books' not found in site configuration."
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

              validator.validate(title_raw, index, book)

              next unless valid_for_processing?(book, title_raw)

              rating = get_rating(book, title_raw)
              next unless rating

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

          def valid_for_processing?(book, title_raw)
            return true if book

            log_missing_book_in_production(title_raw) if @is_production
            false
          end

          def log_missing_book_in_production(title_raw)
            @log_messages << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
              context: @context,
              tag_type: 'DISPLAY_RANKED_BOOKS',
              reason: 'Book title from ranked list not found in lookup map (Production Mode).',
              identifiers: { Title: title_raw, ListVariable: @list_variable_markup },
              level: :error,
            )
          end

          def get_rating(book, title_raw)
            return Integer(book.data['rating']) unless @is_production

            Integer(book.data['rating'])
          rescue ArgumentError, TypeError
            log_invalid_rating_in_production(book, title_raw)
            nil
          end

          def log_invalid_rating_in_production(book, title_raw)
            @log_messages << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
              context: @context,
              tag_type: 'DISPLAY_RANKED_BOOKS',
              reason: 'Book has invalid non-integer rating (Production Mode).',
              identifiers: {
                Title: title_raw,
                Rating: book.data['rating'].inspect,
                ListVariable: @list_variable_markup,
              },
              level: :error,
            )
          end
        end
      end
    end
  end
end
