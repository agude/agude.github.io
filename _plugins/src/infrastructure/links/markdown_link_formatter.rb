# frozen_string_literal: true

require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module Links
      # Formats a resolved link data hash as a Markdown link.
      module MarkdownLinkFormatter
        MdText = Jekyll::Infrastructure::TextProcessingUtils

        def self.format_link(data, italic: false, self_link: false)
          text = data[:display_text] || ''
          text = "_#{text}_" if italic && !text.empty?
          return text if data[:status] != :found || data[:url].nil?
          return text if self_link

          "[#{MdText.escape_link_text(text)}](#{MdText.escape_url(data[:url])})"
        end
      end
    end
  end
end
