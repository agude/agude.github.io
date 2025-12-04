# frozen_string_literal: true

# _plugins/logic/book_lists/author_finder.rb
require_relative 'shared'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/front_matter_utils'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Finds and structures books by a specific author.
          #
          # Handles validation, filtering, structuring (standalone vs series),
          # and sorting of books by author name.
          class AuthorFinder
            include Jekyll::Books::Lists::Renderers::BookLists::Shared

            def initialize(site:, author_name_filter:, context:)
              @site = site
              @author_name_filter = author_name_filter
              @context = context
            end

            # Finds and structures books for the specified author.
            # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
            def find
              error = validate_collection({ author_name: @author_name_filter }, structure: true)
              return error if error

              author_books = fetch_books_for_author
              log_msg = generate_author_log(author_books)

              structured_data = structure_books_for_display(author_books)
              structured_data[:log_messages] = (structured_data[:log_messages] || '') + log_msg
              structured_data
            end

            private

            def fetch_books_for_author
              return [] if @author_name_filter.nil? || @author_name_filter.to_s.strip.empty?

              link_cache = @site.data['link_cache'] || {}
              author_cache = link_cache['authors'] || {}
              canonical_filter = get_canonical_author(@author_name_filter, author_cache)
              all_books = all_published_books(include_archived: false)

              all_books.select do |book|
                book_matches_author?(book, canonical_filter, author_cache)
              end
            end

            def book_matches_author?(book, canonical_filter, author_cache)
              authors = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
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
              Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
                context: @context,
                tag_type: 'BOOK_LIST_AUTHOR_DISPLAY',
                reason: 'Author name filter was empty or nil when fetching data.',
                identifiers: { AuthorFilterInput: @author_name_filter || 'N/A' },
                level: :warn
              ).dup
            end

            def log_no_books_for_author
              Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
                context: @context,
                tag_type: 'BOOK_LIST_AUTHOR_DISPLAY',
                reason: 'No books found for the specified author.',
                identifiers: { AuthorFilter: @author_name_filter },
                level: :info
              ).dup
            end
          end
        end
      end
    end
  end
end
