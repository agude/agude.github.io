# frozen_string_literal: true

require_relative 'markdown_code_region_parser'

module Jekyll
  module Infrastructure
    # Finds HTML ranges whose source must remain opaque to Markdown conversion.
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
        code_ranges = MarkdownCodeRegionParser.protected_code_ranges(text)
        ranges = []
        state = { position: 0, skipped_wrapper_end: nil }

        text.to_enum(:scan, HTML_TOKEN_RE).each do
          match = Regexp.last_match
          next if ignored_token?(match.begin(0), state, code_ranges)

          range = protected_range_for_token(text, match, state, raw_tags, markdown_div_classes)
          next unless range

          ranges << range
          state[:position] = range[1]
          code_ranges = code_ranges_outside_raw_html(text, ranges)
        end

        ranges
      end

      def self.ignored_token?(position, state, code_ranges)
        position < state[:position] ||
          (state[:skipped_wrapper_end] && position < state[:skipped_wrapper_end]) ||
          in_code_range?(position, code_ranges)
      end
      private_class_method :ignored_token?

      def self.protected_range_for_token(text, match, state, raw_tags, markdown_div_classes)
        token = match[0]
        return [match.begin(0), match.end(0)] if token.start_with?('<!--')

        tag = parse_tag(token)
        return nil unless tag && opening_tag?(tag)

        track_supported_container(text, match.begin(0), tag, state)
        return nil if state[:skipped_wrapper_end] && match.begin(0) < state[:skipped_wrapper_end]

        if tag[:name] == 'details'
          return [match.begin(0), text.length] if tag_pairs(text[match.begin(0)..], 'details').empty?

          return nil
        end

        return nil unless raw_tags.include?(tag[:name])
        return nil if markdown_enabled?(tag[:attributes])
        return nil if supported_div_wrapper?(tag, markdown_div_classes)

        ending = raw_html_region_end(text, match.begin(0), tag[:name])
        [match.begin(0), ending] if ending
      end
      private_class_method :protected_range_for_token

      def self.track_supported_container(text, position, tag, state)
        return unless chatgpt_wrapper?(tag)

        state[:skipped_wrapper_end] = raw_html_region_end(text, position, 'div')
      end
      private_class_method :track_supported_container

      def self.tag_pairs(text, name)
        stack = []
        pairs = []
        text.to_enum(:scan, HTML_TOKEN_RE).each do
          match = Regexp.last_match
          tag = parse_tag(match[0])
          next unless tag && tag[:name] == name

          if tag[:closing]
            opening = stack.pop
            pairs << [opening[0], opening[1], match.begin(0), match.end(0), opening[2]] if opening
          elsif !tag[:self_closing]
            stack << [match.begin(0), match.end(0), !stack.empty?]
          end
        end
        return [] unless stack.empty?

        pairs.sort_by(&:first)
      end

      def self.raw_html_region_end(text, opening_start, tag_name)
        tag_pairs(text[opening_start..], tag_name).first&.then do |pair|
          opening_start + pair[3]
        end
      end
      private_class_method :raw_html_region_end

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

      def self.in_code_range?(position, code_ranges)
        code_ranges.any? { |start_index, end_index| position >= start_index && position < end_index }
      end
      private_class_method :in_code_range?

      def self.code_ranges_outside_raw_html(text, ranges)
        masked = text.dup
        ranges.reverse_each do |start_index, end_index|
          masked[start_index...end_index] = masked[start_index...end_index].gsub(/[^\r\n]/, ' ')
        end
        MarkdownCodeRegionParser.protected_code_ranges(masked)
      end
      private_class_method :code_ranges_outside_raw_html

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
    end
  end
end
