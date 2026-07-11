# frozen_string_literal: true

require_relative '../../core/book_card_renderer'

module Jekyll
  module Books
    module Lists
      module Renderers
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

            output = +"<ul class=\"card-grid\">\n"
            @books.each do |book|
              output << Jekyll::Books::Core::BookCardRenderer.render(book, @context) << "\n"
            end
            output << "</ul>\n"
            output
          end
        end
      end
    end
  end
end
