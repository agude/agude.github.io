# frozen_string_literal: true

# _plugins/logic/book_lists/renderers/for_series_renderer.rb
require_relative '../../core/book_card_utils'

module Jekyll
  module BookLists
    # Renders books for a specific series in HTML format.
    #
    # Takes series book data and generates a card grid of all books in the series.
    class ForSeriesRenderer
      def initialize(context, data)
        @context = context
        @site = context.registers[:site]
        @books = data[:books] || []
      end

      def render
        return '' if @books.empty?

        output = +"<div class=\"card-grid\">\n"
        @books.each do |book|
          output << BookCardUtils.render(book, @context) << "\n"
        end
        output << "</div>\n"
        output
      end
    end
  end
end
