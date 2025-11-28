# frozen_string_literal: true

# _plugins/display_books_by_author_then_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/book_lists/all_books_by_author_finder'
require_relative 'logic/book_lists/renderers/by_author_then_series_renderer'

module Jekyll
  # Liquid Tag to display all books, grouped first by author (alphabetically),
  # then by series (alphabetically), with books in series sorted by book_number (numerically).
  # Standalone books for each author are also listed alphabetically by title.
  #
  # Usage: {% display_books_by_author_then_series %}
  #
  # This tag accepts no arguments.
  class DisplayBooksByAuthorThenSeriesTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # No arguments to parse for this tag.
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      finder = Jekyll::BookLists::AllBooksByAuthorFinder.new(site: context.registers[:site], context: context)
      data = finder.find

      output = data[:log_messages] || ''
      output << Jekyll::BookLists::ByAuthorThenSeriesRenderer.new(context, data).render
    end
  end
end

Liquid::Template.register_tag('display_books_by_author_then_series', Jekyll::DisplayBooksByAuthorThenSeriesTag)
