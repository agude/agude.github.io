# frozen_string_literal: true

# Tested by: _tests/src/content/books/tags/test_display_ranked_by_backlinks_tag.rb
# Tested by: _tests/src/content/books/tags/test_display_unreviewed_mentions_tag.rb

require 'cgi'
require_relative '../core/book_link_resolver'

module Jekyll
  module Books
    module Ranking
      # Renders the authoring tags' ordered lists with per-work mention counts.
      module Renderer
        def self.render_backlinks(context, items)
          resolver = Jekyll::Books::Core::BookLinkResolver.new(context)
          render(items, '<p>No books have been mentioned yet.</p>') do |item|
            resolver.render_from_data(item[:title], item[:url])
          end
        end

        def self.render_unreviewed_mentions(items)
          render(items, '<p>No unreviewed works have been mentioned yet.</p>') do |item|
            "<cite>#{CGI.escapeHTML(item[:title])}</cite>"
          end
        end

        def self.render(items, empty_message)
          return empty_message if items.empty?

          output = +"<ol class=\"ranked-list\">\n"
          items.each do |item|
            count = item[:count]
            mention_text = count == 1 ? '1 mention' : "#{count} mentions"
            output << "  <li>#{yield(item)} <span class=\"mention-count\">(#{mention_text})</span></li>\n"
          end
          output << '</ol>'
        end
        private_class_method :render
      end
    end
  end
end
