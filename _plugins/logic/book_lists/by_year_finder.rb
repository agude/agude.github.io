# frozen_string_literal: true

# _plugins/logic/book_lists/by_year_finder.rb
require_relative '../../utils/plugin_logger_utils'

module Jekyll
  module BookLists
    # Finds and structures all books grouped by publication year.
    #
    # Handles validation, grouping books by year, and sorting years
    # (most recent first) with books within each year sorted by date (most recent first).
    class ByYearFinder
      def initialize(site:, context:)
        @site = site
        @context = context
      end

      # Finds and structures all books grouped by publication year.
      # @return [Hash] Contains :year_groups (Array of Hashes), :log_messages (String).
      def find
        error = validate_collection
        return error if error

        all_books = get_all_published_books(include_archived: true)
        if all_books.empty?
          return return_info('ALL_BOOKS_BY_YEAR_DISPLAY',
                             'No published books found to group by year.',
                             key: :year_groups)
        end

        year_groups_list = group_books_by_year(all_books)
        { year_groups: year_groups_list, log_messages: String.new }
      end

      private

      def validate_collection
        return nil if books_collection_exists?

        return_error(
          "Required 'books' collection not found in site configuration.",
          key: :year_groups
        )
      end

      def books_collection_exists?
        @site&.collections&.key?('books')
      end

      def return_error(reason, key: nil)
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'BOOK_LIST_UTIL',
          reason: reason,
          identifiers: { filter_type: 'all_books_by_year' },
          level: :error
        )
        { key || :books => [], log_messages: log.dup }
      end

      def return_info(tag_type, reason, key:)
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: tag_type,
          reason: reason,
          identifiers: {},
          level: :info
        )
        { key => [], log_messages: log.dup }
      end

      def get_all_published_books(include_archived: false)
        books = @site.collections['books'].docs.reject { |book| book.data['published'] == false }
        return books if include_archived

        books.reject { |book| book.data['canonical_url']&.start_with?('/') }
      end

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
