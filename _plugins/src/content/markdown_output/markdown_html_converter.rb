# frozen_string_literal: true

require_relative '../../infrastructure/markdown_code_region_parser'
require_relative '../../infrastructure/markdown_html_region_parser'
require_relative 'markdown_wrapper_converter'

module Jekyll
  module MarkdownOutput
    # Converts inline HTML tags to Markdown equivalents in rendered
    # markdown body strings.  Uses a "stash and replace" strategy:
    # code blocks are stashed before conversion and restored after,
    # so HTML examples inside code are never touched.
    module MarkdownHtmlConverter
      # Placeholder prefix unlikely to collide with real content.
      STASH_PREFIX = '@@MDSTASH'

      # Cite classes that should become italic (_Title_).
      CITE_RE = %r{<cite[^>]*class=["'][^"']*\b\w+-title\b[^"']*["'][^>]*>(.*?)</cite>}m

      WrapperConverter = Jekyll::MarkdownOutput::MarkdownWrapperConverter

      # Abbr tags that should be stripped to plain text.
      ABBR_RE = %r{<abbr[^>]*class=["']etal["'][^>]*>(.*?)</abbr>}m

      # Anchor tags → Markdown links.  Runs after inner-tag conversion
      # so nested cites/spans are already converted.
      ANCHOR_RE = %r{<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>}m

      CHATGPT_EDIT_RE = %r{
        <div\s+class=["']chatgpt-edit-markdown["']>
        \s*<strong>Prompt</strong><blockquote>(.*?)</blockquote>
        \s*<strong>Output</strong><blockquote>(.*?)</blockquote>
        </div>
      }mx
      BREAK_RE = %r{<br\s*/?\s*>}i
      HORIZONTAL_RULE_RE = %r{<hr(?=[\s/>])[^>]*\s*/?>}i
      CodeRegionParser = Jekyll::Infrastructure::MarkdownCodeRegionParser
      HtmlRegionParser = Jekyll::Infrastructure::MarkdownHtmlRegionParser
      MARKDOWN_DIV_CLASSES = %w[
        chatgpt-edit-block
        chatgpt-edit-markdown
        chatgpt-prompt
        chatgpt-output
        chatgpt-prompt-only
        chatgpt-output-only
        low-width-table
        written-by
      ].freeze

      def self.convert(markdown_body)
        return markdown_body if markdown_body.nil? || markdown_body.empty?

        stashed = {}
        body = stash_raw_html_regions(markdown_body, stashed)
        body = stash_code_blocks(body, stashed)
        body = convert_chatgpt_edit_blocks(body, stashed)
        body = WrapperConverter.convert(body)
        body = convert_disclosures(body)
        body.gsub!(HORIZONTAL_RULE_RE, "\n\n---\n\n")

        # Convert inner tags before outer tags (cite/span before anchors).
        body.gsub!(CITE_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(ABBR_RE, '\1')
        body = convert_emphasis_tags(body, 'em', '_')
        body = convert_emphasis_tags(body, 'strong', '**')
        body.gsub!(ANCHOR_RE, '[\2](\1)')

        restore_code_blocks(body, stashed)
      end

      # --- private helpers ---

      def self.convert_chatgpt_edit_blocks(text, stashed)
        text.gsub(CHATGPT_EDIT_RE) do
          prompt, output = Regexp.last_match.captures
          [
            '**Prompt**',
            '',
            format_chatgpt_quote(prompt, stashed),
            '',
            '    **Output**',
            '',
            format_chatgpt_quote(output, stashed),
          ].join("\n")
        end
      end
      private_class_method :convert_chatgpt_edit_blocks

      def self.format_chatgpt_quote(content, stashed)
        content = remove_chatgpt_boundary_lines(restore_code_blocks(content, stashed))
        local_stashed = {}
        protected_content = stash_code_blocks(content, local_stashed)
        protected_content.gsub!(BREAK_RE, "\n")
        markdown = convert(protected_content)
        return '    >' if markdown.empty?

        markdown = restore_code_blocks(markdown, local_stashed)
        stash(quote_markdown_lines(markdown), stashed)
      end
      private_class_method :format_chatgpt_quote

      def self.remove_chatgpt_boundary_lines(content)
        content.sub(/\A\r?\n/, '').sub(/\r?\n\z/, '')
      end
      private_class_method :remove_chatgpt_boundary_lines

      def self.quote_markdown_lines(markdown)
        markdown.each_line.map do |line|
          ending = line[/\r?\n\z/] || ''
          content = ending.empty? ? line : line[0...-ending.length]
          content.empty? ? "    >#{ending}" : "    > #{content}#{ending}"
        end.join
      end
      private_class_method :quote_markdown_lines

      def self.convert_disclosures(text)
        loop do
          pair = HtmlRegionParser.tag_pairs(text, 'details').min_by { |item| item[3] - item[0] }
          break text unless pair

          open_start, open_end, close_start, close_end = pair
          contents = text[open_end...close_start]
          summary_pair = HtmlRegionParser.tag_pairs(contents, 'summary').first
          summary = nil
          if summary_pair
            start_index, start_end, end_index, end_end = summary_pair
            summary = contents[start_end...end_index].strip
            contents = contents[0...start_index] + contents[end_end..]
          end
          sections = [summary, contents.strip].compact.reject(&:empty?)
          replacement = "\n\n#{sections.join("\n\n")}\n\n"
          text[open_start...close_end] = replacement
        end
      end
      private_class_method :convert_disclosures

      def self.stash_raw_html_regions(text, stashed)
        ranges = HtmlRegionParser.protected_ranges(text, markdown_div_classes: MARKDOWN_DIV_CLASSES)
        output = +''
        position = 0
        ranges.each do |start_index, end_index|
          output << text[position...start_index]
          output << stash(text[start_index...end_index], stashed)
          position = end_index
        end
        output << text[position..]
        output
      end
      private_class_method :stash_raw_html_regions

      def self.convert_emphasis_tags(text, tag_name, delimiter)
        pairs = HtmlRegionParser.tag_pairs(text, tag_name)
        pairs.reverse_each do |open_start, open_end, close_start, close_end, nested|
          content = text[open_end...close_start]
          next if nested || !safe_emphasis?(text, open_start, close_end, content, delimiter)

          text[open_start...close_end] = "#{delimiter}#{content}#{delimiter}"
        end

        text
      end
      private_class_method :convert_emphasis_tags

      def self.safe_emphasis?(text, open_start, close_end, content, delimiter)
        return false if content.empty? || content.match?(/\A\s|\s\z/)
        return false if content.include?(delimiter[0])
        return false if content.match?(/\n[ \t]*\n/)

        previous = open_start.positive? ? text[open_start - 1] : nil
        following = text[close_end]
        !word_character?(previous) && !word_character?(following)
      end
      private_class_method :safe_emphasis?

      def self.word_character?(character)
        character&.match?(/[\p{Alnum}_]/)
      end
      private_class_method :word_character?

      def self.stash_code_blocks(text, stashed)
        ranges = CodeRegionParser.protected_code_ranges(text)
        return text if ranges.empty?

        output = +''
        position = 0
        ranges.each do |start_index, end_index|
          output << text[position...start_index]
          block = text[start_index...end_index]
          ending = block[/\r?\n\z/] || ''
          protected_content = ending.empty? ? block : block[0...-ending.length]
          output << stash(protected_content, stashed) << ending
          position = end_index
        end
        output << text[position..]
      end
      private_class_method :stash_code_blocks

      def self.stash(original, stashed)
        placeholder = "#{STASH_PREFIX}_#{stashed.size}@@"
        stashed[placeholder] = original
        placeholder
      end
      private_class_method :stash

      def self.restore_code_blocks(text, stashed)
        stashed.to_a.reverse_each do |placeholder, original|
          # Use block form to avoid backreference interpretation in original.
          text.gsub!(placeholder) { original }
        end
        text
      end
      private_class_method :restore_code_blocks
    end
  end
end
