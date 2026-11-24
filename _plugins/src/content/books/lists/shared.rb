# frozen_string_literal: true

# Tested by: _tests/src/content/books/tags/test_display_book_lists_tag.rb
# Tested by: _tests/src/content/books/lists/test_all_books_finder.rb

require_relative '../core/book_data_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/front_matter_utils'

module Jekyll
  module Books
    module Lists
      # Shared helper methods for all BookList Finder classes.
      module Shared
        def initialize(site:, context:)
          @site = site
          @context = context
        end

        private

        # Validation and Prerequisite Checks
        def validate_collection(identifiers, structure: false, key: nil)
          return nil if @site&.collections&.key?('books')

          return_error(
            "Required 'books' collection not found in site configuration.",
            identifiers: identifiers,
            structure: structure,
            key: key,
          )
        end

        def all_published_books(include_archived: false)
          books = @site.collections['books'].docs.reject { |book| book.data['published'] == false }
          return books if include_archived

          books.reject { |book| book.data['canonical_url'] }
        end

        def find_groups(key, filter_type:, empty_log:, include_archived: false)
          error = validate_collection({ filter_type: filter_type }, key: key)
          return error if error

          groups = yield all_published_books(include_archived: include_archived)
          log = groups.empty? ? log_no_results(**empty_log) : String.new
          { key => groups, log_messages: log }
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
          books.sort_by { |book| title_sort_key(book) }
        end

        def title_sort_key(book)
          Jekyll::Infrastructure::TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
        end

        def group_and_sort_series_books(books)
          sorted = sort_series_books(books)
          grouped = sorted.group_by { |book| book.data['series'].to_s.strip }
          map_and_sort_series_groups(grouped)
        end

        def sort_series_books(books)
          books.sort_by do |book|
            [
              Jekyll::Infrastructure::TextProcessingUtils.normalize_title(
                book.data['series'].to_s,
                strip_articles: true,
              ),
              *series_sort_key(book),
            ]
          end
        end

        def series_sort_key(book)
          [Jekyll::Books::Core::BookDataUtils.parse_book_number(book.data['book_number']), title_sort_key(book)]
        end

        def map_and_sort_series_groups(grouped)
          grouped.map { |name, list| { name: name, books: list } }
                 .sort_by { |g| Jekyll::Infrastructure::TextProcessingUtils.normalize_title(g[:name], strip_articles: true) }
        end

        # Logging
        #
        # PluginLoggerUtils.log_liquid_failure always returns a new mutable
        # string, so no defensive copies are needed before appending.
        def return_error(reason, identifiers:, structure: false, key: nil, tag_type: 'BOOK_LIST_UTIL')
          log = Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: tag_type,
            reason: reason,
            identifiers: identifiers,
            level: :error,
          )
          return { standalone_books: [], series_groups: [], log_messages: log } if structure

          { key || :books => [], log_messages: log }
        end

        def log_filter_warning(tag_type:, reason:, identifiers:)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: tag_type,
            reason: reason,
            identifiers: identifiers,
            level: :warn,
          )
        end

        def log_no_results(tag_type:, reason:, identifiers: {})
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: tag_type,
            reason: reason,
            identifiers: identifiers,
            level: :info,
          )
        end
      end
    end
  end
end
