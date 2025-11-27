# frozen_string_literal: true

# _plugins/logic/book_lists/author_finder.rb
require_relative '../../utils/plugin_logger_utils'
require_relative '../../utils/text_processing_utils'
require_relative '../../utils/front_matter_utils'

module Jekyll
  module BookLists
    # Finds and structures books by a specific author.
    #
    # Handles validation, filtering, structuring (standalone vs series),
    # and sorting of books by author name.
    class AuthorFinder
      def initialize(site:, author_name_filter:, context:)
        @site = site
        @author_name_filter = author_name_filter
        @context = context
      end

      # Finds and structures books for the specified author.
      # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
      def find
        error = validate_collection
        return error if error

        author_books = fetch_books_for_author
        log_msg = generate_author_log(author_books)

        structured_data = structure_books_for_display(author_books)
        structured_data[:log_messages] = (structured_data[:log_messages] || '') + log_msg
        structured_data
      end

      private

      def validate_collection
        return nil if books_collection_exists?

        return_error(
          "Required 'books' collection not found in site configuration.",
          identifiers: { author_name: @author_name_filter },
          structure: true
        )
      end

      def books_collection_exists?
        @site&.collections&.key?('books')
      end

      def return_error(reason, identifiers: {}, structure: false)
        log = PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'BOOK_LIST_UTIL',
          reason: reason,
          identifiers: identifiers,
          level: :error
        )
        log = log.dup
        return { standalone_books: [], series_groups: [], log_messages: log } if structure

        { books: [], log_messages: log }
      end

      def fetch_books_for_author
        return [] if @author_name_filter.nil? || @author_name_filter.to_s.strip.empty?

        link_cache = @site.data['link_cache'] || {}
        author_cache = link_cache['authors'] || {}
        canonical_filter = get_canonical_author(@author_name_filter, author_cache)
        all_books = get_all_published_books(include_archived: false)

        all_books.select do |book|
          book_matches_author?(book, canonical_filter, author_cache)
        end
      end

      def book_matches_author?(book, canonical_filter, author_cache)
        authors = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
        authors.any? do |name|
          c_name = get_canonical_author(name, author_cache)
          c_name && canonical_filter && c_name.casecmp(canonical_filter).zero?
        end
      end

      def generate_author_log(books)
        return log_empty_author_name if @author_name_filter.nil? || @author_name_filter.to_s.strip.empty?
        return log_no_books_for_author if books.empty?

        String.new
      end

      def log_empty_author_name
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'BOOK_LIST_AUTHOR_DISPLAY',
          reason: 'Author name filter was empty or nil when fetching data.',
          identifiers: { AuthorFilterInput: @author_name_filter || 'N/A' },
          level: :warn
        ).dup
      end

      def log_no_books_for_author
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'BOOK_LIST_AUTHOR_DISPLAY',
          reason: 'No books found for the specified author.',
          identifiers: { AuthorFilter: @author_name_filter },
          level: :info
        ).dup
      end

      def get_canonical_author(name, author_cache)
        return nil if name.nil? || name.to_s.strip.empty?

        stripped = name.to_s.strip
        normalized = TextProcessingUtils.normalize_title(stripped)
        data = author_cache[normalized]
        data ? data['title'] : stripped
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
