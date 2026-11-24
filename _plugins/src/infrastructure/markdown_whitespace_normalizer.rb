# frozen_string_literal: true

require_relative 'markdown_code_region_parser'
require_relative 'markdown_html_region_parser'

module Jekyll
  module Infrastructure
    # Normalizes prose whitespace while preserving Markdown code and hard breaks.
    # @pattern Protect raw HTML regions and fenced, indented, and inline code
    #   before normalizing prose. Preserve code bytes and hard-break spaces,
    #   collapse excess blank lines, and trim prose line endings.
    # @gotcha Extend the placeholder prefix until it is absent from the source;
    #   otherwise literal text that looks like a temporary placeholder could
    #   be replaced with unrelated code or HTML.
    module MarkdownWhitespaceNormalizer
      CodeRegionParser = Jekyll::Infrastructure::MarkdownCodeRegionParser
      HtmlRegionParser = Jekyll::Infrastructure::MarkdownHtmlRegionParser
      STASH_PREFIX = '@@MDWHITESPACE'

      def self.normalize(content)
        stashed = {}
        placeholder_prefix = STASH_PREFIX
        placeholder_prefix += '_' while content.include?(placeholder_prefix)
        content = stash_ranges(content, HtmlRegionParser.protected_ranges(content), stashed, placeholder_prefix)
        body = stash_code_blocks(content, stashed, placeholder_prefix)
        body = normalize_prose(body)
        restore_code_blocks(body, stashed)
      end

      def self.stash_code_blocks(text, stashed, placeholder_prefix)
        ranges = CodeRegionParser.protected_code_ranges(text)
        stash_ranges(text, ranges, stashed, placeholder_prefix)
      end
      private_class_method :stash_code_blocks

      def self.stash_ranges(text, ranges, stashed, placeholder_prefix)
        return text if ranges.empty?

        output = []
        position = 0
        ranges.each do |start_index, end_index|
          output << text[position...start_index]
          output << stash_block(text[start_index...end_index], stashed, placeholder_prefix)
          position = end_index
        end
        output << text[position..]
        output.join
      end
      private_class_method :stash_ranges

      def self.stash_block(block, stashed, placeholder_prefix)
        ending = block[/\r?\n\z/] || ''
        protected_content = ending.empty? ? block : block[0...-ending.length]
        placeholder = "#{placeholder_prefix}_#{stashed.size}@@"
        stashed[placeholder] = protected_content
        "#{placeholder}#{ending}"
      end
      private_class_method :stash_block

      def self.normalize_prose(text)
        normalized = text.lines.map { |line| normalize_prose_line(line) }.join
        normalized.gsub!(/\n{3,}/, "\n\n")
        normalized.gsub!(/\A\n+/, '')
        normalized.gsub!(/\n+\z/, "\n")
        normalized
      end
      private_class_method :normalize_prose

      def self.normalize_prose_line(line)
        match = line.match(/[ \t]+(?=\r?\n|\z)/)
        return line unless match

        hard_break = !match.begin(0).zero? && line.end_with?("\n") && match[0].match?(/\A {2,}\z/)
        hard_break ? line : line.sub(/[ \t]+(?=\r?\n|\z)/, '')
      end
      private_class_method :normalize_prose_line

      def self.restore_code_blocks(text, stashed)
        stashed.to_a.reverse_each do |placeholder, original|
          text.gsub!(placeholder) { original }
        end
        text
      end
      private_class_method :restore_code_blocks
    end
  end
end
