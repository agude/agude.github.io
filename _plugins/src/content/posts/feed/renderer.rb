# frozen_string_literal: true

# _plugins/logic/front_page_feed/renderer.rb
require_relative '../article_card_utils'
require_relative '../../books/core/book_card_utils'
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Posts
    module Feed
      # Renders a combined feed of posts and books as HTML cards.
      #
      # Takes an array of feed items (posts and books) and generates a card grid
      # with appropriate card types for each item.
      class Renderer
        def initialize(context, feed_items)
          @context = context
          @feed_items = feed_items
        end

        def render
          return '' if @feed_items.empty?

          output = +"<div class=\"card-grid\">\n"
          log_output = +''

          @feed_items.each do |item|
            if book?(item)
              output << Jekyll::Books::Core::BookCardUtils.render(item, @context) << "\n"
            elsif post?(item)
              output << Jekyll::Posts::ArticleCardUtils.render(item, @context) << "\n"
            else
              log_output << log_unknown_item(item) << "\n"
            end
          end

          output << "</div>\n"
          log_output + output
        end

        private

        def book?(item)
          item.respond_to?(:collection) && item.collection&.label == 'books'
        end

        def post?(item)
          item.respond_to?(:collection) && item.collection&.label == 'posts'
        end

        def log_unknown_item(item)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: 'FRONT_PAGE_FEED',
            reason: 'Unknown item type in feed.',
            identifiers: build_unknown_item_identifiers(item),
            level: :warn,
          )
        end

        def build_unknown_item_identifiers(item)
          {
            item_title: item.data['title'] || 'N/A',
            item_url: item.url || 'N/A',
            item_collection: item.collection&.label || 'N/A',
          }
        end
      end
    end
  end
end
