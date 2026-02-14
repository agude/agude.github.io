# frozen_string_literal: true

# _plugins/logic/book_lists/series_finder.rb
require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Lists
      # Finds books that belong to a specific series.
      #
      # Handles validation, filtering, and sorting of books by series name.
      class SeriesFinder
        include Jekyll::Books::Lists::Shared

        def initialize(site:, series_name_filter:, context:)
          @site = site
          @series_name_filter = series_name_filter
          @context = context
        end

        # Finds and returns books for the specified series.
        # @return [Hash] Contains :books (Array of Document), :series_name (String), :log_messages (String).
        def find
          error = validate_collection({ series_name: @series_name_filter }, key: :books)
          return error if error

          all_books = all_published_books(include_archived: false)
          books_in_series = filter_series_books(all_books, @series_name_filter)
          log_msg = generate_series_log(books_in_series, @series_name_filter)

          { books: books_in_series, series_name: @series_name_filter, log_messages: log_msg }
        end

        private

        def filter_series_books(all_books, series_name)
          return [] if series_name.nil? || series_name.to_s.strip.empty?

          normalized = series_name.to_s.strip.downcase
          all_books.select { |book| book.data['series']&.strip&.downcase == normalized }
                   .sort_by { |book| series_sort_key(book) }
        end

        def series_sort_key(book)
          [
            parse_book_number(book.data['book_number']),
            Jekyll::Infrastructure::TextProcessingUtils.normalize_title(
              book.data['title'].to_s,
              strip_articles: true,
            ),
          ]
        end

        def generate_series_log(books, series_name)
          return log_empty_series_name(series_name) if series_name.nil? || series_name.to_s.strip.empty?
          return log_no_books_in_series(series_name) if books.empty?

          String.new
        end

        def log_empty_series_name(series_name)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: 'BOOK_LIST_SERIES_DISPLAY',
            reason: 'Series name filter was empty or nil.',
            identifiers: { SeriesFilterInput: series_name || 'N/A' },
            level: :warn,
          ).dup
        end

        def log_no_books_in_series(series_name)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: 'BOOK_LIST_SERIES_DISPLAY',
            reason: 'No books found for the specified series.',
            identifiers: { SeriesFilter: series_name },
            level: :info,
          ).dup
        end
      end
    end
  end
end
