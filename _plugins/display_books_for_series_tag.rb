# frozen_string_literal: true

# _plugins/display_books_for_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/book_lists/series_finder'
require_relative 'logic/book_lists/renderers/for_series_renderer'
require_relative 'utils/tag_argument_utils'

# Jekyll namespace for custom plugins.
module Jekyll
  # Displays book cards for all books in a specific series.
  #
  # Usage in Liquid templates:
  #   {% display_books_for_series "The Lord of the Rings" %}
  #   {% display_books_for_series page.series %}
  class DisplayBooksForSeriesTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @series_name_markup = markup.strip
      return unless @series_name_markup.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'display_books_for_series': Series name (string literal or variable) is required."
    end

    def render(context)
      series_name_input = TagArgumentUtils.resolve_value(@series_name_markup, context)

      series_filter = if series_name_input && !series_name_input.to_s.strip.empty?
                        series_name_input.to_s
                      else
                        series_name_input
                      end

      finder = Jekyll::BookLists::SeriesFinder.new(
        site: context.registers[:site],
        series_name_filter: series_filter,
        context: context
      )
      data = finder.find

      output = +(data[:log_messages] || '')
      output << Jekyll::BookLists::ForSeriesRenderer.new(context, data).render
    end
  end
  Liquid::Template.register_tag('display_books_for_series', DisplayBooksForSeriesTag)
end
