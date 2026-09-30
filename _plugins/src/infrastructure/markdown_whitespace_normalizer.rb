# frozen_string_literal: true

require_relative 'markdown_fence_parser'

module Jekyll
  module Infrastructure
    # Normalizes prose whitespace while preserving Markdown code and hard breaks.
    # @pattern Protect code blocks before normalizing prose so source whitespace
    #   inside code fences and indented code remains unchanged.
    module MarkdownWhitespaceNormalizer
      FenceParser = Jekyll::Infrastructure::MarkdownFenceParser
      INDENTED_CODE_RE = /\A(?: {4}|\t)/
      LIST_ITEM_RE = /^ {0,3}(?:[-+*]|\d+[.)])\s/
      STASH_PREFIX = '@@MDWHITESPACE'

      def self.normalize(content)
        stashed = {}
        body = stash_code_blocks(content, stashed)
        body = normalize_prose(body)
        restore_code_blocks(body, stashed)
      end

      def self.stash_code_blocks(text, stashed)
        lines = text.lines
        output = []
        line_index = 0

        while line_index < lines.length
          fence = FenceParser.fence_start(lines[line_index], lines: lines, line_index: line_index)
          if fence
            block, line_index = FenceParser.fenced_block(lines, line_index, fence)
            output << stash_block(block, stashed)
            next
          end

          if indented_code_start?(lines, line_index)
            block, line_index = indented_code_block(lines, line_index)
            output << stash_block(block, stashed)
            next
          end

          output << lines[line_index]
          line_index += 1
        end

        output.join
      end
      private_class_method :stash_code_blocks

      def self.indented_code_start?(lines, line_index)
        return false unless lines[line_index].match?(INDENTED_CODE_RE)
        return true if line_index.zero?

        previous_index = line_index - 1
        return false unless blank_line?(lines[previous_index])

        previous_index -= 1 while previous_index >= 0 && blank_line?(lines[previous_index])
        !inside_list_item?(lines, previous_index)
      end
      private_class_method :indented_code_start?

      def self.inside_list_item?(lines, line_index)
        while line_index >= 0
          return true if lines[line_index].match?(LIST_ITEM_RE)
          break unless lines[line_index].match?(INDENTED_CODE_RE)

          line_index -= 1
          line_index -= 1 while line_index >= 0 && blank_line?(lines[line_index])
        end

        false
      end
      private_class_method :inside_list_item?

      def self.indented_code_block(lines, start_index)
        line_index = start_index
        block_lines = []

        while line_index < lines.length
          if lines[line_index].match?(INDENTED_CODE_RE) ||
             (blank_line?(lines[line_index]) && blank_lines_lead_to_code?(lines, line_index))
            block_lines << lines[line_index]
            line_index += 1
          else
            break
          end
        end

        [block_lines.join, line_index]
      end
      private_class_method :indented_code_block

      def self.blank_lines_lead_to_code?(lines, line_index)
        line_index += 1 while line_index < lines.length && blank_line?(lines[line_index])
        line_index < lines.length && lines[line_index].match?(INDENTED_CODE_RE)
      end
      private_class_method :blank_lines_lead_to_code?

      def self.blank_line?(line)
        line.match?(/\A[ \t]*(?:\r?\n|\z)/)
      end
      private_class_method :blank_line?

      def self.stash_block(block, stashed)
        ending = block[/\r?\n\z/] || ''
        protected_content = ending.empty? ? block : block[0...-ending.length]
        placeholder = "#{STASH_PREFIX}_#{stashed.size}@@"
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
        stashed.each do |placeholder, original|
          text.gsub!(placeholder) { original }
        end
        text
      end
      private_class_method :restore_code_blocks
    end
  end
end
