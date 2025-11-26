# frozen_string_literal: true

# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative 'logic/related_books/finder'
require_relative 'logic/related_books/renderer'

module Jekyll
  # Displays related book reviews based on series, author, and recency.
  #
  # Shows books from the same series, by the same authors, or recent reviews
  # to provide contextual recommendations.
  #
  # Usage in Liquid templates:
  #   {% related_books %}
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      finder = Jekyll::RelatedBooks::Finder.new(context, @max_books)
      result = finder.find

      return result[:logs] if result[:books].empty?

      renderer = Jekyll::RelatedBooks::Renderer.new(context, result[:books])
      html_output = renderer.render

      result[:logs] + html_output
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
