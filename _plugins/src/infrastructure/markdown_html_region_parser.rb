# frozen_string_literal: true

require_relative 'markdown_masked_code_ranges'

module Jekyll
  module Infrastructure
    # Finds HTML ranges whose source must remain opaque to Markdown conversion.
    #
    # protected_ranges scans the HTML tokens once. Before the scan it pairs
    # every opening tag with its closing tag (balanced_region_ends), so
    # finding where a region ends is a lookup, not a rescan of the rest of
    # the text. Code detection runs on the text with earlier regions blanked
    # (MarkdownMaskedCodeRanges), so a backtick or fence marker inside raw
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
        code = MarkdownMaskedCodeRanges.new(text)
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

      # Maps the index of each opening tag to the end of its closing tag,
      # when tag_pairs on the text from that opening tag would pair it: the
      # opening tag has a closing tag and every tag of the same name from
      # there to the end of the text is balanced. Other tokens are absent.
      def self.balanced_region_ends(tokens)
        tag_indices_by_name(tokens).each_value.with_object({}) do |indices, ends|
          closing_by_opening = pair_tags(tokens, indices)
          balanced_after = balanced_after_tags(tokens, indices, closing_by_opening)
          closing_by_opening.each do |opening, closing|
            ends[opening] = tokens[closing][:end] if balanced_after[closing]
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

      # Pairs the opening and closing tags of one name the way tag_pairs
      # does: a closing tag closes the most recent unclosed opening tag.
      def self.pair_tags(tokens, indices)
        stack = []
        indices.each_with_object({}) do |index, closing_by_opening|
          if tokens[index][:tag][:closing]
            opening = stack.pop
            closing_by_opening[opening] = index if opening
          else
            stack << index
          end
        end
      end
      private_class_method :pair_tags

      # For each tag of one name, whether walking that name's later tags
      # with an empty stack ends with an empty stack. Walking from a closing
      # tag skips it, since it has nothing to close; walking from an opening
      # tag continues after its closing tag, or fails if it has none.
      def self.balanced_after_tags(tokens, indices, closing_by_opening)
        balanced_after = {}
        balanced_from_next = true
        indices.reverse_each do |index|
          balanced_after[index] = balanced_from_next
          next if tokens[index][:tag][:closing]

          closing = closing_by_opening[index]
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
    end
  end
end
