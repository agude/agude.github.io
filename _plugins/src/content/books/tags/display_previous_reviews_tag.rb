# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../reviews/finder'
require_relative '../core/book_card_renderer'
require_relative '../../card_grid'

# Displays previous reviews of the same book sorted by date.
#
# Finds all book reviews that share the same canonical URL and displays
# them chronologically.
#
# Usage in Liquid templates:
module Jekyll
  #   {% display_previous_reviews %}
  module Books
    module Tags
      # Liquid tag for displaying previous reviews of the same book.
      # Shows all reviews that share the same canonical URL, sorted chronologically.
      class DisplayPreviousReviewsTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_previous_reviews': This tag does not accept any arguments."
        end

        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Books::Reviews::Finder.new(site, page)
          result = finder.find

          heading = '<h2 class="previous-reviews-headline">Previous Reviews</h2>'
          reviews = result[:reviews]
          grid = Jekyll::Content::CardGrid.render(reviews, heading: heading, aside_class: 'previous-reviews') do |doc|
            subtitle = "Review from #{doc.date.strftime('%B %d, %Y')}"
            Jekyll::Books::Core::BookCardRenderer.render(doc, context, subtitle: subtitle)
          end
          result[:logs] + grid
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_previous_reviews', Jekyll::Books::Tags::DisplayPreviousReviewsTag)
