# frozen_string_literal: true

require_relative '../../src/ui/ratings/rating_utils'
require_relative '../../utils/book_card_utils'

module Jekyll
  module DisplayRankedBooks
    # Renders HTML output for ranked books grouped by rating.
    #
    # Takes structured rating group data and generates the final HTML
    # including navigation and rating group sections.
    class Renderer
      def initialize(context, rating_groups)
        @context = context
        @rating_groups = rating_groups
      end

      def render
        return '' if @rating_groups.empty?

        output = String.new
        output << generate_nav(@rating_groups.map { |g| g[:rating] })

        @rating_groups.each do |group|
          output << render_group_header(group[:rating])
          output << "<div class=\"card-grid\">\n"
          group[:books].each do |book|
            output << BookCardUtils.render(book, @context) << "\n"
          end
          output << "</div>\n"
        end

        output
      end

      private

      def generate_nav(ratings)
        return '' if ratings.empty?

        links = ratings.map do |r|
          text = r == 1 ? "#{r}&nbsp;Star" : "#{r}&nbsp;Stars"
          "<a href=\"#rating-#{r}\">#{text}</a>"
        end

        "<nav class=\"alpha-jump-links\">\n  #{links.join(' &middot; ')}\n</nav>\n"
      end

      def render_group_header(rating)
        h2_id = "rating-#{rating}"
        "<h2 class=\"book-list-headline\" id=\"#{h2_id}\">" \
          "#{RatingUtils.render_rating_stars(rating, 'span')}" \
          "</h2>\n"
      end
    end
  end
end
