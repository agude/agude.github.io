# frozen_string_literal: true

# _plugins/utils/book_card_utils.rb
require_relative 'book_card_renderer'

module Jekyll
  module Books
    module Core
      # Utility module for rendering book review cards.
      #
      # Generates card output for book reviews with cover images, titles, authors,
      # ratings, and descriptions. Supports both HTML and markdown output.
      module BookCardUtils
        DEFAULT_TITLE_FOR_BOOK_CARD = 'Untitled Book'

        # Renders a book card.
        #
        # @param book_object [Jekyll::Document] The book document.
        # @param context [Liquid::Context] The Liquid context.
        # @param display_title_override [String, nil] Optional title override.
        # @param subtitle [String, nil] Optional subtitle.
        # @param format [Symbol, nil] Output format (:html or :markdown).
        #   If nil, determined from context (markdown_mode? check).
        def self.render(book_object, context, display_title_override: nil, subtitle: nil, format: nil)
          Jekyll::Books::Core::BookCardRenderer.new(
            book_object, context, display_title_override, subtitle, format: format
          ).render
        end
      end
    end
  end
end
