# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module Text
      # Shared text processing utilities for generating valid Markdown.
      module MarkdownTextUtils
        # Escapes characters that break Markdown link text: backslash, [, ], (, and ).
        def self.escape_link_text(text)
          text.to_s.gsub(/[\\\[\]()]/) { |m| "\\#{m}" }
        end

        # Escapes characters that break Markdown link URLs: backslash, (, and ).
        def self.escape_url(url)
          url.to_s.gsub(/[\\()]/) { |m| "\\#{m}" }
        end
      end
    end
  end
end
