# frozen_string_literal: true

# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

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
          finder = Jekyll::Books::Backlinks::BookBacklinks::Finder.new(context)
          result = finder.find

          page = context.registers[:page]
          return result[:logs] if result[:backlinks].empty?

          renderer = Jekyll::Books::Backlinks::BookBacklinks::Renderer.new(context, page, result[:backlinks])
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('book_backlinks', Jekyll::Books::Tags::BookBacklinksTag)
