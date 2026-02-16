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

        "[#{text}](#{data[:url]})"
      end
    end
  end
end
