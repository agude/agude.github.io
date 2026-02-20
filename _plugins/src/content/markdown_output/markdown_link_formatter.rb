# frozen_string_literal: true

module Jekyll
  module MarkdownOutput
    # Formats a resolved link data hash as a Markdown link.
    # Used by all 4 link tags (book, author, series, short_story)
    # when rendering in Markdown mode.
    module MarkdownLinkFormatter
      def self.format_link(data, italic: false)
        text = data[:display_text] || ''
        text = "_#{text}_" if italic && !text.empty?
        return text if data[:status] != :found || data[:url].nil?

        "[#{escape_link_text(text)}](#{escape_url(data[:url])})"
      end

      def self.escape_link_text(text)
        text.to_s.gsub(/[\\\[\]]/) { |m| "\\#{m}" }
      end

      def self.escape_url(url)
        url.to_s.gsub(/[\\()]/) { |m| "\\#{m}" }
      end

      private_class_method :escape_link_text, :escape_url
    end
  end
end
