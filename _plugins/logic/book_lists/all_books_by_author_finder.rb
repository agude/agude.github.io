# frozen_string_literal: true

# _plugins/logic/book_lists/all_books_by_author_finder.rb
require_relative '../../utils/plugin_logger_utils'
require_relative '../../utils/text_processing_utils'
require_relative '../../utils/front_matter_utils'

module Jekyll
  module BookLists
    # Finds and structures all books grouped by author.
    #
    # Handles validation, grouping by canonical author, and structuring
    # (standalone vs series) for each author.
    class AllBooksByAuthorFinder
      def initialize(site:, context:)
        @site = site
        @context = context
      end

      # Finds and structures all books grouped by author.
      # @return [Hash] Contains :authors_data (Array of Hashes), :log_messages (String).
      def find
        error = validate_collection
        return error if error

        books_by_author = group_books_by_canonical_author
        authors_data_list = build_authors_data_list(books_by_author)
        log_msg = generate_all_authors_log(authors_data_list)

        { authors_data: authors_data_list, log_messages: log_msg }
      end

      private

      def validate_collection
        return nil if books_collection_exists?

        return_error(
          "Required 'books' collection not found in site configuration.",
          key: :authors_data
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
          identifiers: { filter_type: 'all_books_by_author' },
          level: :error
        )
        { key || :books => [], log_messages: log.dup }
      end

      def group_books_by_canonical_author
        link_cache = @site.data['link_cache'] || {}
        author_cache = link_cache['authors'] || {}
        books_map = {}

        get_all_published_books(include_archived: false).each do |book|
          add_book_to_author_map(book, author_cache, books_map)
        end
        books_map
      end

      def add_book_to_author_map(book, author_cache, books_map)
        FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors']).each do |name|
          canonical = get_canonical_author(name, author_cache)
          next unless canonical

          books_map[canonical] ||= []
          books_map[canonical] << book
        end
      end

      def build_authors_data_list(books_map)
        list = books_map.map do |name, books|
          structured = structure_books_for_display(books.uniq)
          {
            author_name: name,
            standalone_books: structured[:standalone_books],
            series_groups: structured[:series_groups]
          }
        end
        list.sort_by { |entry| entry[:author_name].downcase }
      end

      def generate_all_authors_log(data)
        return String.new unless data.empty?

        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'ALL_BOOKS_BY_AUTHOR_DISPLAY',
          reason: 'No published books with valid author names found.',
          identifiers: {},
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
