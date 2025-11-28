# frozen_string_literal: true

require_relative '../../utils/book_data_utils'
require_relative '../../utils/plugin_logger_utils'
require_relative '../../utils/text_processing_utils'
require_relative '../../utils/front_matter_utils'

module Jekyll
  module BookLists
    # Shared helper methods for all BookList Finder classes.
    module Shared
      private

      # Validation and Prerequisite Checks
      def validate_collection(identifiers, structure: false, key: nil)
        return nil if @site&.collections&.key?('books')

        return_error("Required 'books' collection not found in site configuration.",
                     identifiers: identifiers, structure: structure, key: key)
      end

      def all_published_books(include_archived: false)
        books = @site.collections['books'].docs.reject { |book| book.data['published'] == false }
        return books if include_archived

        books.reject { |book| book.data['canonical_url']&.start_with?('/') }
      end

      # Author Helpers
      def get_canonical_author(name, author_cache)
        return nil if name.nil? || name.to_s.strip.empty?

        stripped = name.to_s.strip
        normalized = TextProcessingUtils.normalize_title(stripped)
        data = author_cache[normalized]
        data ? data['title'] : stripped
      end

      # Structuring and Sorting
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
        BookDataUtils.parse_book_number(book_number_raw)
      end

      # Logging
      def return_error(reason, identifiers:, structure: false, key: nil, tag_type: 'BOOK_LIST_UTIL')
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context, tag_type: tag_type, reason: reason,
          identifiers: identifiers, level: :error
        )
        log = log.dup
        return { standalone_books: [], series_groups: [], log_messages: log } if structure

        { key || :books => [], log_messages: log }
      end

      def return_info(tag_type, reason, key:)
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context, tag_type: tag_type, reason: reason, identifiers: {}, level: :info
        )
        { key => [], log_messages: log.dup }
      end
    end
  end
end
