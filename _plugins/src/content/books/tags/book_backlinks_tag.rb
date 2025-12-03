# frozen_string_literal: true

# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative '../backlinks/finder'
require_relative '../backlinks/renderer'

module Jekyll
  # Renders a list of book reviews that mention the current book.
  #
  # Displays backlinks from other book reviews that reference this book either
  # directly or via series mentions.
  #
  # Usage in Liquid templates:
  #   {% book_backlinks %}
  class BookBacklinksTag < Liquid::Tag
    # Renders the list of books linking back to the current page.
    def render(context)
      finder = Jekyll::BookBacklinks::Finder.new(context)
      result = finder.find

      page = context.registers[:page]
      return result[:logs] if result[:backlinks].empty?

      renderer = Jekyll::BookBacklinks::Renderer.new(context, page, result[:backlinks])
      html_output = renderer.render

      result[:logs] + html_output
    end
  end
end

Liquid::Template.register_tag('book_backlinks', Jekyll::BookBacklinksTag)
