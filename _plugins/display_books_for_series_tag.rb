# frozen_string_literal: true

# _plugins/display_books_for_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'
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
      BooksForSeriesRenderer.new(context, @series_name_markup).render
    end

    # Helper class to handle rendering logic
    class BooksForSeriesRenderer
      def initialize(context, series_name_markup)
        @context = context
        @site = context.registers[:site]
        @series_name_markup = series_name_markup
      end

      def render
        series_name_input = TagArgumentUtils.resolve_value(@series_name_markup, @context)

        data = if series_name_input && !series_name_input.to_s.strip.empty?
                 get_series_data(series_name_input.to_s)
               else
                 get_series_data(series_name_input)
               end

        render_output(data)
      end

      private

      def get_series_data(series_name_filter)
        BookListUtils.get_data_for_series_display(
          site: @site,
          series_name_filter: series_name_filter,
          context: @context
        )
      end

      def render_output(data)
        output = data[:log_messages] || ''
        return output if data[:books].empty?

        output << "<div class=\"card-grid\">\n"
        data[:books].each do |book|
          output << BookCardUtils.render(book, @context) << "\n"
        end
        output << "</div>\n"
        output
      end
    end
  end
  Liquid::Template.register_tag('display_books_for_series', DisplayBooksForSeriesTag)
end
