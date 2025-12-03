# frozen_string_literal: true

# _plugins/logic/book_lists/all_books_by_author_finder.rb
require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/front_matter_utils'

module Jekyll
  module BookLists
    # Finds and structures all books grouped by author.
    #
    # Handles validation, grouping by canonical author, and structuring
    # (standalone vs series) for each author.
    class AllBooksByAuthorFinder
      include Jekyll::BookLists::Shared

      def initialize(site:, context:)
        @site = site
        @context = context
      end

      # Finds and structures all books grouped by author.
      # @return [Hash] Contains :authors_data (Array of Hashes), :log_messages (String).
      def find
        error = validate_collection({ filter_type: 'all_books_by_author' }, key: :authors_data)
        return error if error

        books_by_author = group_books_by_canonical_author
        authors_data_list = build_authors_data_list(books_by_author)
        log_msg = generate_all_authors_log(authors_data_list)

        { authors_data: authors_data_list, log_messages: log_msg }
      end

      private

      def group_books_by_canonical_author
        link_cache = @site.data['link_cache'] || {}
        author_cache = link_cache['authors'] || {}
        books_map = {}

        all_published_books(include_archived: false).each do |book|
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
    end
  end
end
