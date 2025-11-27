# frozen_string_literal: true

# _plugins/logic/book_lists/all_books_finder.rb
require_relative '../../utils/plugin_logger_utils'
require_relative '../../utils/text_processing_utils'

module Jekyll
  module BookLists
    # Finds and structures all books for display.
    #
    # Handles validation and structuring (standalone vs series) of all published books.
    class AllBooksFinder
      def initialize(site:, context:)
        @site = site
        @context = context
      end

      # Finds and structures all published books.
      # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
      def find
        error = validate_collection
        return error if error

        all_books = get_all_published_books(include_archived: false)
        structure_books_for_display(all_books)
      end

      private

      def validate_collection
        return nil if books_collection_exists?

        return_error(
          "Required 'books' collection not found in site configuration.",
          structure: true
        )
      end

      def books_collection_exists?
        @site&.collections&.key?('books')
      end

      def return_error(reason, structure: false)
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'BOOK_LIST_UTIL',
          reason: reason,
          identifiers: { filter_type: 'all_books' },
          level: :error
        )
        log = log.dup
        return { standalone_books: [], series_groups: [], log_messages: log } if structure

        { books: [], log_messages: log }
      end

      def get_all_published_books(include_archived: false)
        books = @site.collections['books'].docs.reject { |book| book.data['published'] == false }
        return books if include_archived

        books.reject { |book| book.data['canonical_url']&.start_with?('/') }
      end

      def structure_books_for_display(books_to_process)
        standalone, series_books = partition_books(books_to_process)
        sorted_standalone = sort_books_by_title(standalone)
        series_groups = group_and_sort_series_books(series_books)

        { standalone_books: sorted_standalone, series_groups: series_groups, log_messages: String.new }
      end

      def partition_books(books)
        books.partition do |book|
          book.data['series'].nil? || book.data['series'].to_s.strip.empty?
        end
      end

      def sort_books_by_title(books)
        books.sort_by do |book|
          TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
        end
      end

      def group_and_sort_series_books(books)
        sorted = sort_series_books(books)
        grouped = sorted.group_by { |book| book.data['series'].to_s.strip }
        map_and_sort_series_groups(grouped)
      end

      def sort_series_books(books)
        books.sort_by do |book|
          [
            TextProcessingUtils.normalize_title(book.data['series'].to_s, strip_articles: true),
            parse_book_number(book.data['book_number']),
            TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
          ]
        end
      end

      def map_and_sort_series_groups(grouped)
        grouped.map { |name, list| { name: name, books: list } }
               .sort_by { |g| TextProcessingUtils.normalize_title(g[:name], strip_articles: true) }
      end

      def parse_book_number(book_number_raw)
        return Float::INFINITY if book_number_raw.nil? || book_number_raw.to_s.strip.empty?

        Float(book_number_raw.to_s)
      rescue ArgumentError
        Float::INFINITY
      end
    end
  end
end
