# frozen_string_literal: true

# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative '../related/finder'
require_relative '../related/renderer'

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
        DEFAULT_MAX_BOOKS = 3

        def initialize(tag_name, markup, tokens)
          super
          @max_books = DEFAULT_MAX_BOOKS
        end

        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          finder = Jekyll::Books::Related::Finder.new(site, page, @max_books)
          result = finder.find

          return result[:logs] if result[:books].empty?

          renderer = Jekyll::Books::Related::Renderer.new(context, result[:books])
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::Books::Tags::RelatedBooksTag)
