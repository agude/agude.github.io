# frozen_string_literal: true

require_relative 'markdown_code_region_parser'

module Jekyll
  module Infrastructure
    # Finds HTML ranges whose source must remain opaque to Markdown conversion.
    #
    # protected_ranges scans the HTML tokens once. Before the scan it pairs
    # every opening tag with its closing tag (balanced_region_ends), so
    # finding where a region ends is a lookup, not a rescan of the rest of
    # the text. Code detection runs on the text with earlier regions blanked
    # using MaskedCodeRanges, so a backtick or fence marker inside raw
    # HTML does not hide later HTML.
    module MarkdownHtmlRegionParser
      HTML_TOKEN_RE = %r{<!--.*?-->|</?[a-z][^>]*>}im
      # CommonMark block HTML tag families, excluding thematic-break `hr`
      # (which this converter intentionally turns into a Markdown rule).
      RAW_BLOCK_TAGS = %w[
        address
        article
        aside
        base
        basefont
        blockquote
        body
        caption
        center
        col
        colgroup
        dd
        dir
        div
        dl
        dt
        fieldset
        figcaption
        figure
        footer
        form
        frame
        frameset
        h1
        h2
        h3
        h4
        h5
        h6
        head
        header
        hgroup
        html
        iframe
        legend
        li
        link
        main
        menu
        menuitem
        meta
        noframes
        ol
        optgroup
        option
        p
        param
        pre
        script
        section
        source
        style
        table
        tbody
        td
        tfoot
        th
        thead
        title
        tr
        track
        ul
      ].freeze

      def self.protected_ranges(text, raw_tags: RAW_BLOCK_TAGS, markdown_div_classes: [])
        tokens = html_tokens(text)
        region_ends = balanced_region_ends(tokens)
        code = MaskedCodeRanges.new(text)
        options = { text_length: text.length, raw_tags: raw_tags, markdown_div_classes: markdown_div_classes }
        ranges = []
        state = { position: 0, skipped_wrapper_end: nil }

        tokens.each_with_index do |token, index|
          next if ignored_token?(token[:begin], state, code)

          range = protected_range_for_token(token, region_ends[index], state, options)
          next unless range

          ranges << range
          state[:position] = range[1]
          code.mask(*range)
        end

        ranges
      end

      # Every HTML comment and tag in the text, in order.
      def self.html_tokens(text)
        text.to_enum(:scan, HTML_TOKEN_RE).map do
          match = Regexp.last_match
          comment = match[0].start_with?('<!--')
          { begin: match.begin(0), end: match.end(0), comment: comment, tag: comment ? nil : parse_tag(match[0]) }
        end
      end
      private_class_method :html_tokens

      # A raw HTML region ends at the matching closing tag, provided every
      # later opening tag of the same name also has a closer.
      def self.balanced_region_ends(tokens)
        tag_indices_by_name(tokens).each_value.with_object({}) do |indices, ends|
          pairs = pair_tags(tokens, indices)
          balanced_after = balanced_after_tags(tokens, indices, pairs)
          pairs.each do |opening, (closing, _)|
            ends[opening] = tokens[closing][:end] if closing && balanced_after[closing]
          end
        end
      end
      private_class_method :balanced_region_ends

      # Token indices of the tags tag_pairs counts, grouped by tag name:
      # closing tags and opening tags that are not self-closing.
      def self.tag_indices_by_name(tokens)
        tokens.each_with_index.with_object(Hash.new { |hash, name| hash[name] = [] }) do |(token, index), groups|
          tag = token[:tag]
          next unless tag
          next if !tag[:closing] && tag[:self_closing]

          groups[tag[:name]] << index
        end
      end
      private_class_method :tag_indices_by_name

      # Records each opening tag in source order with its closer and whether
      # it is nested inside another tag of the same name.
      def self.pair_tags(tokens, indices)
        stack = []
        indices.each_with_object({}) do |index, pairs|
          if tokens[index][:tag][:closing]
            opening = stack.pop
            pairs[opening][0] = index if opening
          else
            pairs[index] = [nil, !stack.empty?]
            stack << index
          end
        end
      end
      private_class_method :pair_tags

      # For each tag of one name, whether walking that name's later tags
      # with an empty stack ends with an empty stack. Walking from a closing
      # tag skips it, since it has nothing to close; walking from an opening
      # tag continues after its closing tag, or fails if it has none.
      def self.balanced_after_tags(tokens, indices, pairs)
        balanced_after = {}
        balanced_from_next = true
        indices.reverse_each do |index|
          balanced_after[index] = balanced_from_next
          next if tokens[index][:tag][:closing]

          closing, = pairs[index]
          balanced_from_next = closing ? balanced_after[closing] : false
        end
        balanced_after
      end
      private_class_method :balanced_after_tags

      def self.ignored_token?(position, state, code)
        position < state[:position] ||
          (state[:skipped_wrapper_end] && position < state[:skipped_wrapper_end]) ||
          code.in_code?(position)
      end
      private_class_method :ignored_token?

      def self.protected_range_for_token(token, region_end, state, options)
        return [token[:begin], token[:end]] if token[:comment]

        tag = token[:tag]
        return nil unless tag && opening_tag?(tag)

        state[:skipped_wrapper_end] = region_end if chatgpt_wrapper?(tag)
        return nil if state[:skipped_wrapper_end] && token[:begin] < state[:skipped_wrapper_end]
        # An unclosed details element protects the rest of the text.
        return (region_end ? nil : [token[:begin], options[:text_length]]) if tag[:name] == 'details'

        [token[:begin], region_end] if region_end && raw_region_tag?(tag, options)
      end
      private_class_method :protected_range_for_token

      def self.raw_region_tag?(tag, options)
        options[:raw_tags].include?(tag[:name]) &&
          !markdown_enabled?(tag[:attributes]) &&
          !supported_div_wrapper?(tag, options[:markdown_div_classes])
      end
      private_class_method :raw_region_tag?

      def self.tag_pairs(text, name)
        tokens = html_tokens(text)
        indices = tag_indices_by_name(tokens).fetch(name, [])
        pairs = pair_tags(tokens, indices)
        return [] if pairs.any? { |_, (closing, _)| closing.nil? }

        pairs.map do |opening, (closing, nested)|
          start_tag = tokens[opening]
          end_tag = tokens[closing]
          [start_tag[:begin], start_tag[:end], end_tag[:begin], end_tag[:end], nested]
        end
      end

      def self.parse_tag(token)
        match = token.match(%r{\A<(/)?([a-z][\w:-]*)(?=[\s/>])([^>]*)>\z}im)
        return nil unless match

        {
          closing: !match[1].nil?,
          name: match[2].downcase,
          attributes: match[3],
          self_closing: match[3].match?(%r{/\s*\z}),
        }
      end
      private_class_method :parse_tag

      def self.opening_tag?(tag)
        !tag[:closing] && !tag[:self_closing]
      end
      private_class_method :opening_tag?

      def self.markdown_enabled?(attributes)
        match = attributes.match(/(?<![\w:-])markdown\s*=\s*(?:(['"])(.*?)\1|([^\s>]+))/i)
        match && %w[1 block span].include?(match[2] || match[3])
      end
      private_class_method :markdown_enabled?

      def self.supported_div_wrapper?(tag, markdown_div_classes)
        return false unless tag[:name] == 'div'

        classes = tag[:attributes].match(/(?<![\w:-])class\s*=\s*(['"])(.*?)\1/i)&.[](2)&.split
        classes&.intersect?(markdown_div_classes)
      end
      private_class_method :supported_div_wrapper?

      def self.chatgpt_wrapper?(tag)
        tag[:name] == 'div' &&
          tag[:attributes].match?(/(?<![\w:-])class\s*=\s*(['"])chatgpt-edit-markdown\1/i)
      end
      private_class_method :chatgpt_wrapper?

      # Caches code ranges while the HTML walk blanks raw regions. The next
      # query needs a rescan only if its line can be indented code, backticks
      # bracket it within the paragraph, or a fence marker can precede it.
      #
      # @gotcha Masks must start outside code. Queries must be increasing
      #   and each mask must end at or before the next queried position.
      class MaskedCodeRanges
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
      private_constant :MaskedCodeRanges
    end
  end
end
