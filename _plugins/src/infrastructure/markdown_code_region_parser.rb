# frozen_string_literal: true

require_relative 'markdown_fence_parser'

module Jekyll
  module Infrastructure
    # Finds source ranges for Markdown block and inline code.
    module MarkdownCodeRegionParser
      FenceParser = Jekyll::Infrastructure::MarkdownFenceParser

      # Returns character ranges for fenced and indented source code blocks.
      # Consumers use the same ranges so conversion and whitespace cleanup
      # protect exactly the same Markdown regions.
      def self.code_block_ranges(text)
        lines = text.lines
        offsets = line_offsets(lines)
        ranges = []
        line_index = 0

        while line_index < lines.length
          fence = FenceParser.fence_start(lines[line_index], lines: lines, line_index: line_index)
          if fence
            _block, next_index = FenceParser.fenced_block(lines, line_index, fence)
            ranges << [offsets[line_index], offsets[next_index]]
            line_index = next_index
            next
          end

          if indented_code_start?(lines, line_index)
            next_index = indented_code_end(lines, line_index)
            ranges << [offsets[line_index], offsets[next_index]]
            line_index = next_index
            next
          end

          line_index += 1
        end

        ranges
      end

      def self.protected_code_ranges(text)
        blocks = code_block_ranges(text)
        (blocks + inline_code_ranges(text, blocks)).sort_by(&:first)
      end

      def self.inline_code_ranges(text, excluded_ranges = [])
        runs = []
        text.to_enum(:scan, /`+/).each do
          match = Regexp.last_match
          next if excluded_ranges.any? do |start_index, end_index|
            match.begin(0) >= start_index && match.begin(0) < end_index
          end

          runs << [match.begin(0), match.end(0), match[0].length]
        end

        boundaries = inline_blank_line_boundaries(text)
        run_regions = assign_run_regions(runs, boundaries)
        next_matching_run = find_next_matching_runs(runs, run_regions)
        ranges = []
        run_index = 0

        while run_index < runs.length
          closing_index = next_matching_run[run_index]
          if closing_index
            ranges << [runs[run_index][0], runs[closing_index][1]]
            run_index = closing_index + 1
          else
            run_index += 1
          end
        end

        ranges
      end

      def self.inline_blank_line_boundaries(text)
        text.to_enum(:scan, /\r?\n[ \t]*(?:>[ \t]*(?:>[ \t]*)*)?[ \t]*\r?\n/).map do
          Regexp.last_match.end(0)
        end
      end
      private_class_method :inline_blank_line_boundaries

      def self.assign_run_regions(runs, boundaries)
        boundary_index = 0
        runs.map do |run|
          boundary_index += 1 while boundaries[boundary_index] && boundaries[boundary_index] <= run[0]
          boundary_index
        end
      end
      private_class_method :assign_run_regions

      def self.find_next_matching_runs(runs, run_regions)
        next_matching_run = Array.new(runs.length)
        nearest_run_by_length = {}
        (runs.length - 1).downto(0) do |run_index|
          key = [runs[run_index][2], run_regions[run_index]]
          next_matching_run[run_index] = nearest_run_by_length[key]
          nearest_run_by_length[key] = run_index
        end
        next_matching_run
      end
      private_class_method :find_next_matching_runs

      def self.line_offsets(lines)
        offsets = [0]
        lines.each { |line| offsets << (offsets.last + line.length) }
        offsets
      end
      private_class_method :line_offsets

      def self.indented_code_start?(lines, line_index)
        prefix, content = code_line_content(lines[line_index])
        return false unless indented_code_line?(content)
        return true if line_index.zero?

        previous = previous_content_line(lines, line_index - 1, prefix)
        return true unless previous
        return false unless blank_line?(previous)

        list_content_indent = list_item_content_indent(lines, line_index)
        return true unless list_content_indent

        indent_columns(content) >= list_content_indent + 4
      end
      private_class_method :indented_code_start?

      def self.indented_code_end(lines, start_index)
        prefix, = code_line_content(lines[start_index])
        list_content_indent = list_item_content_indent(lines, start_index)
        minimum_indent = list_content_indent ? list_content_indent + 4 : 4
        line_index = start_index + 1

        while line_index < lines.length
          candidate = code_line_content(lines[line_index], expected_prefix: prefix).last
          if indented_code_line?(candidate) && indent_columns(candidate) >= minimum_indent
            line_index += 1
          elsif blank_line?(candidate)
            next_code_index, next_code_line = next_nonblank_code_line(lines, line_index + 1, prefix)
            break unless indented_code_line?(next_code_line) && indent_columns(next_code_line) >= minimum_indent

            line_index = next_code_index
          else
            break
          end
        end

        line_index
      end
      private_class_method :indented_code_end

      def self.code_line_content(line, expected_prefix: nil)
        prefix = +''
        rest = line

        loop do
          quote = rest.match(/\A {0,3}>[ \t]?/)
          break unless quote

          prefix << '>'
          rest = rest[quote[0].length..]
        end

        return [prefix, nil] if expected_prefix && prefix != expected_prefix

        [prefix, rest]
      end
      private_class_method :code_line_content

      def self.indented_code_line?(line)
        return false unless line
        return true if line.start_with?("\t")

        line[/\A */].length >= 4
      end
      private_class_method :indented_code_line?

      def self.indent_columns(line, starting_column = 0)
        column = starting_column
        line.each_char do |character|
          case character
          when ' '
            column += 1
          when "\t"
            column += 4 - (column % 4)
          else
            break
          end
        end
        column
      end
      private_class_method :indent_columns

      def self.previous_content_line(lines, line_index, prefix)
        line = lines[line_index]
        quote_prefix, content = code_line_content(line)
        quote_prefix == prefix ? content : line
      end
      private_class_method :previous_content_line

      def self.blank_line?(line)
        line&.match?(/\A[ \t]*(?:\r?\n|\z)/)
      end
      private_class_method :blank_line?

      def self.next_nonblank_code_line(lines, line_index, prefix)
        next_index = line_index
        while next_index < lines.length
          candidate = code_line_content(lines[next_index], expected_prefix: prefix).last
          return [next_index, candidate] unless blank_line?(candidate)

          next_index += 1
        end

        [next_index, nil]
      end
      private_class_method :next_nonblank_code_line

      def self.list_item_content_indent(lines, line_index)
        list_item = /\A([ \t]{0,3})([-+*]|\d+[.)])([ \t]+)/
        (line_index - 1).downto(0) do |index|
          line = strip_blockquote_prefixes(lines[index])
          match = line.match(list_item)
          if match
            prefix = indent_columns(match[1])
            marker_end = prefix + match[2].length
            spacing = indent_columns(match[3], marker_end) - marker_end
            return marker_end + [spacing, 1].max
          end
          return nil unless line.match?(/\A(?: {4}|\t)/) || blank_line?(line)
        end

        nil
      end
      private_class_method :list_item_content_indent

      def self.strip_blockquote_prefixes(line)
        line.sub(/\A(?: {0,3}>[ \t]?)+/, '')
      end
      private_class_method :strip_blockquote_prefixes
    end
  end
end
