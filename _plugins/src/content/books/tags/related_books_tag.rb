# frozen_string_literal: true

require 'jekyll'
require 'liquid'

require_relative '../related/finder'
require_relative '../core/book_card_renderer'
require_relative '../../card_grid'

# Displays related book reviews based on series, author, and recency.
#
# Shows books from the same series, by the same authors, or recent reviews
# to provide contextual recommendations.
#
# Usage in Liquid templates:
module Jekyll
  #   {% related_books %}
  module Books
    module Tags
      # Liquid tag for displaying related book reviews.
      # Shows books from the same series, by the same authors, or recent reviews.
      class RelatedBooksTag < Liquid::Tag
        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Books::Related::Finder.new(site, page)
          result = finder.find

          result[:logs] + Jekyll::Content::CardGrid.render(result[:books], heading: '<h2>Related Books</h2>') do |book|
            "#{Jekyll::Books::Core::BookCardRenderer.render(book, context)}\n"
          end
        end
      end
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::Books::Tags::RelatedBooksTag)
