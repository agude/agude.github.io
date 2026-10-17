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
    # - Its line, with masks applied, could be an indented code line: after
    #   any `>` markers it starts with a tab or four spaces. The original line
    #   is checked, unless a mask covers or starts inside the line's leading
    #   `>` markers and whitespace, which can lengthen that whitespace.
    # - Backticks lie on both sides of the position within its paragraph:
    #   between the start of the last blank line before its line and the
    #   position, and between the position and the next blank line. A code
    #   span covering the position opens before it and closes after it in
    #   the same paragraph, and masking only adds blank lines.
    # - A fence marker (three backticks or tildes) lies between the start of
    #   the line holding the first mask added since the last recompute and
    #   the position. A fence that opened before that line closed before it,
    #   because the mask's start was outside code.
    #
    # Code detection still reruns for every region in two layouts: regions
    # with backticks before and after them in the same paragraph, and
    # regions followed by more HTML on a line they start.
    #
    # @gotcha The fence rule holds only if every masked range starts at a
    #   position that #in_code? reported as outside code, positions are
    #   queried in increasing order, and each range ends at or before the
    #   next queried position. MarkdownHtmlRegionParser meets all three.
    class MarkdownMaskedCodeRanges
      FENCE_MARKER_RE = /`{3}|~{3}/
      BLANK_LINE_RE = /\A[ \t]*\r?\n\z/
      # Leading `>` markers and whitespace, which masking can lengthen.
      LEADING_RUN_RE = /\A[ \t>]*/
      # Matches every line MarkdownCodeRegionParser can treat as indented
      # code, and some it cannot.
      INDENTED_CODE_LINE_RE = /\A(?: {0,3}>[ \t]?)*(?:\t| {4})/

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
        @leading_run_ends = []
        @indented_candidates = []
        @blank_lines = []
        offset = 0
        @text.each_line do |line|
          @line_starts << offset
          @leading_run_ends << (offset + line[LEADING_RUN_RE].length)
          @indented_candidates << line.match?(INDENTED_CODE_LINE_RE)
          @blank_lines << line.match?(BLANK_LINE_RE)
          offset += line.length
        end
        index_paragraphs(offset)
        @backticks = match_starts(/`/)
        @fence_markers = match_starts(FENCE_MARKER_RE)
      end

      # For each line, the start of the last blank line before it (or 0) and
      # of the next blank line after it (or the end of the text).
      def index_paragraphs(text_length)
        @last_blank_line_starts = []
        last_start = 0
        @line_starts.each_with_index do |start, line|
          @last_blank_line_starts << last_start
          last_start = start if @blank_lines[line]
        end

        @next_blank_line_starts = Array.new(@line_starts.length)
        next_start = text_length
        (@line_starts.length - 1).downto(0) do |line|
          @next_blank_line_starts[line] = next_start
          next_start = @line_starts[line] if @blank_lines[line]
        end
      end

      def match_starts(pattern)
        @text.to_enum(:scan, pattern).map { Regexp.last_match.begin(0) }
      end

      def possibly_in_code?(position)
        line = line_index(position)
        anchor_line = line_index(@masks[@first_unapplied_mask][0])
        indented_line?(line) ||
          (any_between?(@backticks, @last_blank_line_starts[line], position) &&
            any_between?(@backticks, position, @next_blank_line_starts[line])) ||
          any_between?(@fence_markers, @line_starts[anchor_line], position)
      end

      def indented_line?(line)
        start = @line_starts[line]
        masked?(start) || mask_starts_within?(start, @leading_run_ends[line]) || @indented_candidates[line]
      end

      # Whether a mask starts at or after `from` and at or before `to`.
      def mask_starts_within?(from, to)
        index = @masks.bsearch_index { |start_index, _| start_index >= from }
        !index.nil? && @masks[index][0] <= to
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
