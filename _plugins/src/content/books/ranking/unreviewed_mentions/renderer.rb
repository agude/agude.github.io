# frozen_string_literal: true

require 'cgi'

module Jekyll
  module DisplayUnreviewedMentions
    # Renderer class - generates HTML for the ranked list of unreviewed mentions
    #
    # Takes a ranked list of mention data and produces the final HTML output.
    class Renderer
      def initialize(mentions)
        @mentions = mentions
      end

      # Generates the HTML output for the unreviewed mentions list
      #
      # @return [String] HTML string - either an ordered list or a "no mentions" message
      def render
        return '<p>No unreviewed works have been mentioned yet.</p>' if @mentions.empty?

        output = +"<ol class=\"ranked-list\">\n"
        @mentions.each do |item|
          output << render_list_item(item)
        end
        output << '</ol>'
        output
      end

      private

      def render_list_item(item)
        mention_text = item[:count] == 1 ? '1 mention' : "#{item[:count]} mentions"
        title_html = CGI.escapeHTML(item[:title])
        "  <li><cite>#{title_html}</cite> " \
          "<span class=\"mention-count\">(#{mention_text})</span></li>\n"
      end
    end
  end
end
