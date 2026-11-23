# frozen_string_literal: true

module Jekyll
  module Infrastructure
    # Finds source ranges for Markdown block and inline code.
    module MarkdownCodeRegionParser
      Fence = Struct.new(:marker, :fence_length, :containers, :info, keyword_init: true)
      private_constant :Fence

      QUOTE_PREFIX_RE = /\A {0,3}>[ \t]?/
      private_constant :QUOTE_PREFIX_RE

      class << self
        # Returns sorted character ranges for fenced, indented, and inline code.
        # Consumers use the same ranges to preserve the exact source bytes.
        def protected_code_ranges(text)
          blocks = code_block_ranges(text)
          (blocks + inline_code_ranges(text, blocks)).sort_by(&:first)
        end

        private

        def code_block_ranges(text)
          lines = text.lines
          offsets = line_offsets(lines)
          ranges = []
          line_index = 0

          while line_index < lines.length
            fence = fence_start(lines, line_index)
            next_index = if fence
                           fenced_block_end(lines, line_index, fence)
                         elsif indented_code_start?(lines, line_index)
                           indented_code_end(lines, line_index)
                         end
            if next_index
              ranges << [offsets[line_index], offsets[next_index]]
              line_index = next_index
            else
              line_index += 1
            end
          end

          ranges
        end

        def inline_code_ranges(text, excluded_ranges)
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

        def inline_blank_line_boundaries(text)
          text.to_enum(:scan, /\r?\n[ \t]*(?:>[ \t]*(?:>[ \t]*)*)?[ \t]*\r?\n/).map do
            Regexp.last_match.end(0)
          end
        end

        def assign_run_regions(runs, boundaries)
          boundary_index = 0
          runs.map do |run|
            boundary_index += 1 while boundaries[boundary_index] && boundaries[boundary_index] <= run[0]
            boundary_index
          end
        end

        def find_next_matching_runs(runs, run_regions)
          next_matching_run = Array.new(runs.length)
          nearest_run_by_length = {}
          (runs.length - 1).downto(0) do |run_index|
            key = [runs[run_index][2], run_regions[run_index]]
            next_matching_run[run_index] = nearest_run_by_length[key]
            nearest_run_by_length[key] = run_index
          end
          next_matching_run
        end

        def line_offsets(lines)
          offsets = [0]
          lines.each { |line| offsets << (offsets.last + line.length) }
          offsets
        end

        def indented_code_start?(lines, line_index)
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

        def indented_code_end(lines, start_index)
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

        def code_line_content(line, expected_prefix: nil)
          prefix = +''
          rest = line

          loop do
            quote = rest[QUOTE_PREFIX_RE]
            break unless quote

            prefix << '>'
            rest = rest[quote.length..]
          end

          return [prefix, nil] if expected_prefix && prefix != expected_prefix

          [prefix, rest]
        end

        def indented_code_line?(line)
          return false unless line
          return true if line.start_with?("\t")

          line[/\A */].length >= 4
        end

        def indent_columns(line, starting_column = 0)
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

        def previous_content_line(lines, line_index, prefix)
          line = lines[line_index]
          quote_prefix, content = code_line_content(line)
          quote_prefix == prefix ? content : line
        end

        def blank_line?(line)
          line&.match?(/\A[ \t]*(?:\r?\n|\z)/)
        end

        def next_nonblank_code_line(lines, line_index, prefix)
          next_index = line_index
          while next_index < lines.length
            candidate = code_line_content(lines[next_index], expected_prefix: prefix).last
            return [next_index, candidate] unless blank_line?(candidate)

            next_index += 1
          end

          [next_index, nil]
        end

        def list_item_content_indent(lines, line_index)
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

        def strip_blockquote_prefixes(line)
          line.sub(/\A(?: {0,3}>[ \t]?)+/, '')
        end

        def fence_start(lines, line_index)
          line = lines[line_index]
          allow_indented = indented_fence_candidate?(line) && list_context?(lines, line_index)
          fence = parse_fence_line(line, allow_indented: allow_indented)
          return nil unless fence
          return nil if fence.marker == '`' && fence.info.include?('`')

          fence
        end

        def fenced_block_end(lines, start_index, fence)
          line_index = start_index + 1
          line_index += 1 while line_index < lines.length && !closing_fence?(lines[line_index], fence)
          [line_index + 1, lines.length].min
        end

        def parse_fence_line(line, allow_indented:)
          offset, containers = parse_fence_containers(line, allow_indented: allow_indented)
          fence_line = line[offset..]
          match = fence_line.match(/\A {0,3}(`{3,}|~{3,})([^\r\n]*)(?:\r?\n|\z)/)
          return nil unless match

          Fence.new(
            marker: match[1][0],
            fence_length: match[1].length,
            containers: containers,
            info: match[2],
          )
        end

        def parse_fence_containers(line, allow_indented:)
          offset = 0
          containers = []

          loop do
            remainder = line[offset..]
            quote = remainder[QUOTE_PREFIX_RE]
            if quote
              containers << :blockquote
              offset += quote.length
            elsif allow_indented && (indent = remainder[/\A(?: {4}|\t)/])
              containers << :indent
              offset += indent.length
            else
              break
            end
          end

          [offset, containers]
        end

        def indented_fence_candidate?(line)
          line.match?(/\A(?: {0,3}>[ \t]?)*(?: {4,}|\t)(?: {0,3}>[ \t]?)*(?: {4,}|\t)? {0,3}(?:`{3,}|~{3,})/)
        end

        def list_context?(lines, line_index)
          list_item = /^ {0,3}(?:[-+*]|\d+[.)])\s/
          indentation = /\A(?: {4}|\t)/

          (line_index - 1).downto(0) do |index|
            line = strip_blockquote_prefixes(lines[index])
            return true if line.match?(list_item)
            return false unless line.match?(indentation) || blank_line?(line)
          end

          false
        end

        def closing_fence?(line, fence)
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
      end
    end
  end
end
