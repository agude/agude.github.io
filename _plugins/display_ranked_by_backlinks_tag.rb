# frozen_string_literal: true

# _plugins/display_ranked_by_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_link_util'

module Jekyll
  class DisplayRankedByBacklinksTag < Liquid::Tag
    def render(context)
      RankedByBacklinksRenderer.new(context).render
    end

    # Helper class to handle rendering logic
    class RankedByBacklinksRenderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
      end

      def render
        return handle_missing_prerequisites unless valid_prerequisites?

        backlinks_cache = @site.data['link_cache']['backlinks']
        books_cache = @site.data['link_cache']['books']

        url_to_book_map = build_url_to_book_map(books_cache)
        ranked_list = build_ranked_list(backlinks_cache, url_to_book_map)

        return '<p>No books have been mentioned yet.</p>' if ranked_list.empty?

        render_ranked_list(ranked_list)
      end

      private

      def valid_prerequisites?
        @site&.data&.dig('link_cache', 'backlinks') && @site.data.dig('link_cache', 'books')
      end

      def handle_missing_prerequisites
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'RANKED_BY_BACKLINKS',
          reason: 'Prerequisites missing: link_cache, backlinks, or books cache.',
          level: :error
        )
      end

      def build_url_to_book_map(books_cache)
        url_to_book_map = {}
        books_cache.values.flatten.each do |book_data|
          url_to_book_map[book_data['url']] ||= book_data
        end
        url_to_book_map
      end

      def build_ranked_list(backlinks_cache, url_to_book_map)
        items = backlinks_cache.map do |url, sources|
          book_data = url_to_book_map[url]
          next unless book_data

          {
            title: book_data['title'],
            url: url,
            count: sources.length
          }
        end
        items.compact.sort_by { |item| -item[:count] }
      end

      def render_ranked_list(ranked_list)
        output = +"<ol class=\"ranked-list\">\n"
        ranked_list.each do |item|
          book_link_html = BookLinkUtils.render_book_link_from_data(item[:title], item[:url], @context)
          mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
          output << "  <li>#{book_link_html} <span class=\"mention-count\">(#{mention_text})</span></li>\n"
        end
        output << '</ol>'
        output
      end
    end
  end
end

Liquid::Template.register_tag('display_ranked_by_backlinks', Jekyll::DisplayRankedByBacklinksTag)
