# frozen_string_literal: true

require_relative '../../../../ui/ratings/rating_utils'
require_relative '../../../../ui/cards/markdown_card_utils'
require_relative '../../../card_grid'
require_relative '../../core/book_card_renderer'

module Jekyll
  module Books
    module Ranking
      module RankedBooks
        # Renders ranked books grouped by rating in HTML and Markdown.
        #
        # Takes structured rating group data and generates the final HTML
        # including navigation and rating group sections.
        class Renderer
          MdCards = Jekyll::UI::Cards::MarkdownCardUtils
          private_constant :MdCards

          def initialize(context, rating_groups)
            @context = context
            @rating_groups = rating_groups
          end

          def render
            return '' if @rating_groups.empty?

            output = generate_nav(@rating_groups.map { |group| group[:rating] })

            @rating_groups.each do |group|
              output << render_group_header(group[:rating])
              output << Jekyll::Content::CardGrid.render(group[:books]) do |book|
                "#{Jekyll::Books::Core::BookCardRenderer.render(book, @context)}\n"
              end
            end

            output
          end

          def render_markdown
            @rating_groups.flat_map do |group|
              heading = "## #{MdCards.format_stars(group[:rating])}"
              cards = group[:books].map do |book|
                MdCards.render_card_md(MdCards.book_doc_to_card_data(book), book: true)
              end
              [heading, *cards]
            end.join("\n")
          end

          private

          def generate_nav(ratings)
            links = ratings.map do |r|
              text = r == 1 ? "#{r}&nbsp;Star" : "#{r}&nbsp;Stars"
              "<a href=\"#rating-#{r}\">#{text}</a>"
            end

            "<nav class=\"alpha-jump-links\">\n  #{links.join(' &middot; ')}\n</nav>\n"
          end

          def render_group_header(rating)
            h2_id = "rating-#{rating}"
            "<h2 class=\"book-list-headline\" id=\"#{h2_id}\">" \
              "#{Jekyll::UI::Ratings::RatingUtils.render_rating_stars(rating, 'span')}" \
              "</h2>\n"
          end
        end
      end
    end
  end
end
