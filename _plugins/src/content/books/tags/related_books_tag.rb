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
        def render(context)
          site = context.registers[:site]
          page = context.registers[:page]
          # context['content'] contains the fully rendered page content when this tag
          # runs from a layout. This is used to score book mentions by count/position.
          rendered_content = context['content']
          finder = Jekyll::Books::Related::Finder.new(site, page, nil, rendered_content)
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
