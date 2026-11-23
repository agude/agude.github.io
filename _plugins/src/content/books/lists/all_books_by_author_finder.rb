# frozen_string_literal: true

require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative '../../../infrastructure/link_cache/author_lookup'

module Jekyll
  module Books
    module Lists
      # Finds and structures all books grouped by author.
      #
      # Handles validation, grouping by canonical author, and structuring
      # (standalone vs series) for each author.
      class AllBooksByAuthorFinder
        include Jekyll::Books::Lists::Shared

        AuthorLookup = Jekyll::Infrastructure::LinkCache::AuthorLookup
        private_constant :AuthorLookup

        # Finds and structures all books grouped by author.
        # @return [Hash] Contains :authors_data (Array of Hashes), :log_messages (String).
        def find
          find_groups(
            :authors_data,
            filter_type: 'all_books_by_author',
            empty_log: {
              tag_type: 'ALL_BOOKS_BY_AUTHOR_DISPLAY',
              reason: 'No published books with valid author names found.',
            },
          ) do |books|
            build_authors_data_list(group_books_by_canonical_author(books))
          end
        end

        private

        def group_books_by_canonical_author(books)
          link_cache = @site.data['link_cache'] || {}
          author_cache = link_cache['authors'] || {}
          books_map = {}

          books.each do |book|
            add_book_to_author_map(book, author_cache, books_map)
          end
          books_map
        end

        def add_book_to_author_map(book, author_cache, books_map)
          authors = book.data['book_authors']
          Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(authors).each do |name|
            canonical = AuthorLookup.canonical_author(name, author_cache)
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
              series_groups: structured[:series_groups],
            }
          end
          list.sort_by { |entry| entry[:author_name].downcase }
        end
      end
    end
  end
end
