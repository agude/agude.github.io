# frozen_string_literal: true

require_relative '../core/book_card_utils'

module Jekyll
  module Books
    module Related
      # Renders HTML output for a list of related books.
      #
      # This class handles the presentation logic for displaying related books.
      # It takes a list of book documents and generates the HTML structure.
      class Renderer
        def initialize(context, books)
          @context = context
          @books = books
        end

        def render
          return '' if @books.empty?

          build_related_books_html
        end

        private

        def build_related_books_html
          output = String.new("<aside class=\"related\">\n")
          output << "  <h2>Related Books</h2>\n"
          output << "  <div class=\"card-grid\">\n"
          @books.each { |book| output << Jekyll::Books::Core::BookCardUtils.render(book, @context) << "\n" }
          output << "  </div>\n"
          output << '</aside>'
        end
      end
    end
  end
end
