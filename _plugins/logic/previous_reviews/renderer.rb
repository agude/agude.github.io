# frozen_string_literal: true

# _plugins/logic/previous_reviews/renderer.rb
require_relative '../../utils/book_card_utils'

module Jekyll
  module PreviousReviews
    # Renders archived book reviews as HTML cards.
    #
    # Takes an array of review documents and generates a styled
    # aside containing book cards with review dates as subtitles.
    class Renderer
      def initialize(context, reviews)
        @context = context
        @reviews = reviews
      end

      def render
        return '' if @reviews.empty?

        output = String.new
        output << "<aside class=\"previous-reviews\">\n"
        output << "  <h2 class=\"book-review-headline\">Previous Reviews</h2>\n"
        output << "  <div class=\"card-grid\">\n"

        @reviews.each do |doc|
          subtitle = "Review from #{doc.date.strftime('%B %d, %Y')}"
          output << BookCardUtils.render(doc, @context, subtitle: subtitle)
        end

        output << "  </div>\n"
        output << '</aside>'
        output
      end
    end
  end
end
