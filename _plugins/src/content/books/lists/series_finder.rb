# frozen_string_literal: true

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

          # normalize_title also collapses internal whitespace/newlines, so
          # YAML folded scalars in front matter match single-line filters —
          # the same normalization the link cache and resolvers use.
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(series_name)
          matches = all_books.select do |book|
            Jekyll::Infrastructure::TextProcessingUtils.normalize_title(book.data['series'].to_s) == normalized
          end
          matches.sort_by { |book| series_sort_key(book) }
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
          if series_name.nil? || series_name.to_s.strip.empty?
            return log_filter_warning(
              tag_type: 'BOOK_LIST_SERIES_DISPLAY',
              reason: 'Series name filter was empty or nil.',
              identifiers: { SeriesFilterInput: series_name || 'N/A' },
            )
          end
          if books.empty?
            return log_no_results(
              tag_type: 'BOOK_LIST_SERIES_DISPLAY',
              reason: 'No books found for the specified series.',
              identifiers: { SeriesFilter: series_name },
            )
          end

          String.new
        end
      end
    end
  end
end
