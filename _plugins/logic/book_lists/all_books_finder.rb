# frozen_string_literal: true

# _plugins/logic/book_lists/all_books_finder.rb
require_relative 'shared'

module Jekyll
  module BookLists
    # Finds and structures all books for display.
    #
    # Handles validation and structuring (standalone vs series) of all published books.
    class AllBooksFinder
      include Jekyll::BookLists::Shared

      def initialize(site:, context:)
        @site = site
        @context = context
      end

      # Finds and structures all published books.
      # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
      def find
        error = validate_collection({ filter_type: 'all_books' }, structure: true)
        return error if error

        all_books = all_published_books(include_archived: false)
        structure_books_for_display(all_books)
      end
    end
  end
end
