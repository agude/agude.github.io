# frozen_string_literal: true

# _plugins/utils/book_card_utils.rb
require_relative 'book_card_renderer'

# Utility module for rendering book review cards in HTML.
#
# Generates card HTML for book reviews with cover images, titles, authors,
# ratings, and descriptions.
module BookCardUtils
  DEFAULT_TITLE_FOR_BOOK_CARD = 'Untitled Book'

  def self.render(book_object, context, display_title_override: nil, subtitle: nil)
    BookCardRenderer.new(book_object, context, display_title_override, subtitle).render
  end
end
