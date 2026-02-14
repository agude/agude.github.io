# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Normalizes whitespace in generated Markdown output.
    # Removes trailing whitespace, collapses excessive blank lines,
    # and ensures a single trailing newline.
    module MarkdownWhitespaceNormalizer
      def self.normalize(content)
        content
          .gsub(/[ \t]+$/, '')       # Remove trailing whitespace per line
          .gsub(/\n{3,}/, "\n\n")    # Collapse 3+ blank lines to 1
          .gsub(/\A\n+/, '')         # Remove leading blank lines
          .gsub(/\n+\z/, "\n")       # Single trailing newline
      end
    end
  end
end
