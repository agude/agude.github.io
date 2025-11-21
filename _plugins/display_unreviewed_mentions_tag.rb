# frozen_string_literal: true

# _plugins/display_unreviewed_mentions_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Displays a ranked list of unreviewed books mentioned in the site.
  #
  # Shows books that have been referenced but don't have review pages yet,
  # ranked by mention count.
  #
  # Usage in Liquid templates:
  #   {% display_unreviewed_mentions %}
  class DisplayUnreviewedMentionsTag < Liquid::Tag
    def render(context)
      UnreviewedMentionsRenderer.new(context).render
    end

    # Helper class to handle rendering logic
    class UnreviewedMentionsRenderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
      end

      def render
        return handle_missing_prerequisites unless valid_prerequisites?

        tracker = @site.data['mention_tracker']
        books_cache = @site.data['link_cache']['books']
        existing_book_titles = Set.new(books_cache.keys)

        ranked_list = build_ranked_list(tracker, existing_book_titles)

        return '<p>No unreviewed works have been mentioned yet.</p>' if ranked_list.empty?

        render_ranked_list(ranked_list)
      end

      private

      def valid_prerequisites?
        @site && @site.data['mention_tracker'] && @site.data.dig('link_cache', 'books')
      end

      def handle_missing_prerequisites
        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'UNREVIEWED_MENTIONS',
          reason: "Prerequisites missing: mention_tracker or link_cache['books'] not found.",
          level: :error
        )
      end

      def build_ranked_list(tracker, existing_book_titles)
        items = tracker.map do |normalized_title, data|
          next if existing_book_titles.include?(normalized_title)

          display_title = find_display_title(data, normalized_title)

          {
            title: display_title,
            count: data[:sources].size
          }
        end
        items.compact.sort_by { |item| -item[:count] }
      end

      def find_display_title(data, normalized_title)
        data[:original_titles].max_by { |_, count| count }&.first || normalized_title
      end

      def render_ranked_list(ranked_list)
        output = +"<ol class=\"ranked-list\">\n"
        ranked_list.each do |item|
          output << render_list_item(item)
        end
        output << '</ol>'
        output
      end

      def render_list_item(item)
        mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
        title_html = CGI.escapeHTML(item[:title])
        "  <li><cite>#{title_html}</cite> " \
          "<span class=\"mention-count\">(#{mention_text})</span></li>\n"
      end
    end
  end
end

Liquid::Template.register_tag('display_unreviewed_mentions', Jekyll::DisplayUnreviewedMentionsTag)
