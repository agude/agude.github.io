# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Finds fenced Markdown code blocks inside lists, block quotes, and prose.
    module MarkdownFenceParser
      Fence = Struct.new(:marker, :fence_length, :containers, :info, keyword_init: true)
      private_constant :Fence

      def self.fence_start(line, lines: [], line_index: 0)
        allow_indented = indented_fence_candidate?(line) && list_context?(lines, line_index)
        fence = parse_fence_line(line, allow_indented: allow_indented)
        return nil unless fence
        return nil if fence.marker == '`' && fence.info.include?('`')

        fence
      end

      def self.fenced_block(lines, start_index, fence)
        line_index = start_index + 1
        line_index += 1 while line_index < lines.length && !closing_fence?(lines[line_index], fence)
        line_index += 1 if line_index < lines.length

        [lines[start_index...line_index].join, line_index]
      end

      def self.parse_fence_line(line, allow_indented: false)
        container_prefix, container_levels = parse_containers(line, allow_indented: allow_indented)
        fence_line = line[container_prefix.length..]
        match = fence_line.match(/\A {0,3}(`{3,}|~{3,})([^\r\n]*)(?:\r?\n|\z)/)
        return nil unless match

        Fence.new(
          marker: match[1][0],
          fence_length: match[1].length,
          containers: container_levels,
          info: match[2],
        )
      end
      private_class_method :parse_fence_line

      def self.parse_containers(line, allow_indented: false)
        offset = 0
        containers = []

        loop do
          remainder = line[offset..]
          quote = remainder.match(/\A {0,3}>[ \t]?/)
          if quote
            containers << :blockquote
            offset += quote[0].length
          elsif allow_indented && remainder.start_with?('    ')
            containers << :indent
            offset += 4
          else
            break
          end
        end

        [line[0...offset], containers]
      end
      private_class_method :parse_containers

      def self.indented_fence_candidate?(line)
        line.match?(/\A(?: {0,3}>[ \t]?)*(?: {4}|\t) {0,3}(?:`{3,}|~{3,})/)
      end
      private_class_method :indented_fence_candidate?

      def self.list_context?(lines, line_index)
        list_item = /^ {0,3}(?:[-+*]|\d+[.)])\s/
        indentation = /\A(?: {4}|\t)/
        blank = /\A[ \t]*(?:\r?\n|\z)/

        (line_index - 1).downto(0) do |index|
          line = lines[index]
          return true if line.match?(list_item)
          return false unless line.match?(indentation) || line.match?(blank)
        end

        false
      end
      private_class_method :list_context?

      def self.closing_fence?(line, fence)
        candidate = parse_fence_line(
          line,
          allow_indented: fence.containers.include?(:indent),
        )
        return false unless candidate
        return false unless candidate.marker == fence.marker
        return false if candidate.fence_length < fence.fence_length
        return false unless candidate.containers == fence.containers

        candidate.info.match?(/\A[ \t]*\z/)
      end
      private_class_method :closing_fence?
    end
  end
end
