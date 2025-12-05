# frozen_string_literal: true

# _plugins/logic/ranked_by_backlinks/renderer.rb
require_relative '../core/book_link_util'

module Jekyll
  module Books
    module Ranking
      module RankedByBacklinks
        # Renders a ranked list of books as HTML.
        #
        # Takes an array of ranked book data and generates an ordered list
        # with book links and mention counts.
        class Renderer
          def initialize(context, ranked_list)
            @context = context
            @ranked_list = ranked_list
          end

          def render
            return '<p>No books have been mentioned yet.</p>' if @ranked_list.empty?

            output = +"<ol class=\"ranked-list\">\n"

            @ranked_list.each do |item|
              book_link_html = Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(item[:title],
                                                                                             item[:url], @context)
              mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
              output << "  <li>#{book_link_html} <span class=\"mention-count\">(#{mention_text})</span></li>\n"
            end

            output << '</ol>'
            output
          end
        end
      end
    end
  end
end
