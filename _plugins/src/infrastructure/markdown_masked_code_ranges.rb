# frozen_string_literal: true

require_relative 'markdown_code_region_parser'

module Jekyll
  module Infrastructure
    # Reports Markdown code positions while raw HTML ranges are blanked one
    # at a time.
    #
    # #in_code? returns what MarkdownCodeRegionParser.protected_code_ranges
    # reports for the text with every masked range replaced by spaces
    # (newlines kept). Recomputing those ranges after every mask makes a
    # document with many raw HTML regions quadratic, so after a mask they are
    # recomputed only when the queried position could be in code. A position
    # can be in code only if at least one of these holds:
    #
    # - Its line, with masks applied, starts with a space, tab, or `>`. Every
    #   indented code line does.
    # - A backtick lies between the start of the last blank line before the
    #   position's line and the position. An inline code span opens in the
    #   same paragraph, and masking only adds blank lines.
    # - A fence marker (three backticks or tildes) lies between the start of
    #   the line holding the first mask added since the last recompute and
    #   the position. A fence that opened before that line closed before it,
    #   because the mask's start was outside code.
    #
    # @gotcha The fence rule holds only if every masked range starts at a
    #   position that #in_code? reported as outside code, positions are
    #   queried in increasing order, and each range ends at or before the
    #   next queried position. MarkdownHtmlRegionParser meets all three.
    class MarkdownMaskedCodeRanges
      FENCE_MARKER_RE = /`{3}|~{3}/
      BLANK_LINE_RE = /\A[ \t]*\r?\n\z/

      # @param text [String] The Markdown source.
      def initialize(text)
        @text = text
        @masks = []
        @first_unapplied_mask = nil
        @code_ranges = MarkdownCodeRegionParser.protected_code_ranges(text)
        index_text
      end

      # Blanks `text[start_index...end_index]` for later queries. Ranges must
      # be added in increasing order and must not overlap.
      def mask(start_index, end_index)
        @first_unapplied_mask ||= @masks.length
        @masks << [start_index, end_index]
      end

      # @return [Boolean] Whether `position` is inside a code range of the
      #   masked text.
      def in_code?(position)
        if @first_unapplied_mask
          return false unless possibly_in_code?(position)

          recompute
        end
        @code_ranges.any? { |start_index, end_index| position >= start_index && position < end_index }
      end

      private

      def index_text
        @line_starts = []
        @line_first_characters = []
        @last_blank_line_starts = []
        offset = 0
        last_blank_line_start = 0
        @text.each_line do |line|
          @line_starts << offset
          @line_first_characters << line[0]
          @last_blank_line_starts << last_blank_line_start
          last_blank_line_start = offset if line.match?(BLANK_LINE_RE)
          offset += line.length
        end
        @backticks = match_starts(/`/)
        @fence_markers = match_starts(FENCE_MARKER_RE)
      end

      def match_starts(pattern)
        @text.to_enum(:scan, pattern).map { Regexp.last_match.begin(0) }
      end

      def possibly_in_code?(position)
        line = line_index(position)
        anchor_line = line_index(@masks[@first_unapplied_mask][0])
        indented_line?(line) ||
          any_between?(@backticks, @last_blank_line_starts[line], position) ||
          any_between?(@fence_markers, @line_starts[anchor_line], position)
      end

      def indented_line?(line)
        masked?(@line_starts[line]) || [' ', "\t", '>'].include?(@line_first_characters[line])
      end

      def masked?(position)
        after = @masks.bsearch_index { |start_index, _| start_index > position } || @masks.length
        after.positive? && position < @masks[after - 1][1]
      end

      def any_between?(sorted_positions, from, to)
        index = sorted_positions.bsearch_index { |position| position >= from }
        !index.nil? && sorted_positions[index] < to
      end

      def line_index(position)
        (@line_starts.bsearch_index { |start| start > position } || @line_starts.length) - 1
      end

      def recompute
        @masked ||= @text.dup
        @masks[@first_unapplied_mask..].each do |start_index, end_index|
          @masked[start_index...end_index] = @masked[start_index...end_index].gsub(/[^\r\n]/, ' ')
        end
        @code_ranges = MarkdownCodeRegionParser.protected_code_ranges(@masked)
        @first_unapplied_mask = nil
      end
    end
  end
end
