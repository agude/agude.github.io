# frozen_string_literal: true

require 'jekyll'
require 'liquid'

require_relative '../backlinks/finder'
require_relative '../backlinks/renderer'

# Renders a list of book reviews that mention the current book.
#
# Displays backlinks from other book reviews that reference this book either
# directly or via series mentions.
#
# Usage in Liquid templates:
module Jekyll
  #   {% book_backlinks %}
  module Books
    module Tags
      # Liquid tag for rendering backlinks to book reviews.
      # Displays a list of book reviews that mention the current book.
      class BookBacklinksTag < Liquid::Tag
        # Renders the list of books linking back to the current page.
        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Books::Backlinks::Finder.new(site, page)
          result = finder.find

          return result[:logs] if result[:backlinks].empty?

          result[:logs] + Jekyll::Books::Backlinks::Renderer.new(context, page, result[:backlinks]).render
        end
      end
    end
  end
end

Liquid::Template.register_tag('book_backlinks', Jekyll::Books::Tags::BookBacklinksTag)
