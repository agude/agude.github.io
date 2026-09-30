# frozen_string_literal: true

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

      # Emphasis tags become Markdown emphasis, including tags with attributes.
      EM_RE = %r{<em(?:\s+[^>]*)?>(.*?)</em>}m

      # Strong tags become Markdown strong emphasis, including attributes.
      STRONG_RE = %r{<strong(?:\s+[^>]*)?>(.*?)</strong>}m

      # Span classes that should be stripped to plain text.
      SPAN_RE = %r{<span[^>]*class=["'](?:author-name|book-series|written-by)["'][^>]*>(.*?)</span>}m

      # Wrappers handled below, while preserving other wrapper tags.
      SPAN_WRAPPER_RE = %r{(<span\b[^>]*>)(.*?)(</span\s*>)}im
      DIV_WRAPPER_RE = %r{(<div\b[^>]*>)(.*?)(</div\s*>)}im
      PRESENTATION_SPAN_CLASSES = %w[nowrap band-name].freeze
      WRITTEN_BY_CLASSES = %w[written-by].freeze
      CHATGPT_DIV_CLASSES = %w[
        chatgpt-edit-block
        chatgpt-prompt
        chatgpt-output
        chatgpt-prompt-only
        chatgpt-output-only
      ].freeze
      DIV_TAG_RE = %r{</?div\b[^>]*>}im

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
      DETAILS_RE = %r{<details\b[^>]*>(.*?)</details\s*>}im
      SUMMARY_RE = %r{<summary\b[^>]*>(.*?)</summary\s*>}im

      def self.convert(markdown_body)
        return markdown_body if markdown_body.nil? || markdown_body.empty?

        stashed = {}
        body = stash_code_blocks(markdown_body, stashed)
        body = convert_chatgpt_edit_blocks(body)
        body = convert_chatgpt_divs(body)
        body = convert_disclosures(body)

        # Convert inner tags before outer tags (cite/span before anchors).
        body.gsub!(CITE_RE) { "_#{Regexp.last_match(1)}_" }
        body = convert_presentation_wrappers(body)
        body.gsub!(SPAN_RE, '\1')
        body.gsub!(ABBR_RE, '\1')
        body.gsub!(EM_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(STRONG_RE) { "**#{Regexp.last_match(1)}**" }
        body.gsub!(ANCHOR_RE, '[\2](\1)')

        restore_code_blocks(body, stashed)
      end

      # --- private helpers ---

      def self.convert_chatgpt_edit_blocks(text)
        text.gsub(CHATGPT_EDIT_RE) do
          prompt, output = Regexp.last_match.captures
          [
            '**Prompt**',
            '',
            format_chatgpt_quote(prompt),
            '',
            '    **Output**',
            '',
            format_chatgpt_quote(output),
          ].join("\n")
        end
      end
      private_class_method :convert_chatgpt_edit_blocks

      def self.format_chatgpt_quote(content)
        stashed = {}
        protected_content = stash_code_blocks(content, stashed)
        protected_content.gsub!(BREAK_RE, "\n")
        markdown = restore_code_blocks(convert(protected_content), stashed).strip
        return '    >' if markdown.empty?

        markdown.split("\n", -1).map do |line|
          line.empty? ? '    >' : "    > #{line}"
        end.join("\n")
      end
      private_class_method :format_chatgpt_quote

      def self.convert_chatgpt_divs(text)
        output = +''
        stripped_divs = []
        position = 0

        text.to_enum(:scan, DIV_TAG_RE).each do
          match = Regexp.last_match
          start = match.begin(0)
          finish = match.end(0)
          tag = match[0]
          output << text[position...start]

          if tag.match?(%r{\A</div}i)
            output << tag unless stripped_divs.pop
          else
            strip_tag = class_attribute_includes?(tag, CHATGPT_DIV_CLASSES)
            stripped_divs << strip_tag
            output << tag unless strip_tag
          end

          position = finish
        end

        output << text[position..]
      end
      private_class_method :convert_chatgpt_divs

      def self.convert_disclosures(text)
        text.gsub(DETAILS_RE) do
          contents = Regexp.last_match(1)
          summary = nil
          answer = contents.sub(SUMMARY_RE) do
            summary = Regexp.last_match(1).strip
            ''
          end.strip
          sections = [summary, answer].compact.reject(&:empty?)
          "\n\n#{sections.join("\n\n")}\n\n"
        end
      end
      private_class_method :convert_disclosures

      def self.convert_presentation_wrappers(text)
        body = convert_presentation_spans(text)
        convert_written_by_divs(body)
      end
      private_class_method :convert_presentation_wrappers

      def self.convert_presentation_spans(text)
        text.gsub(SPAN_WRAPPER_RE) do |wrapper|
          opening_tag, content, closing_tag = Regexp.last_match.captures
          converted_content = convert_presentation_wrappers(content)

          if class_attribute_includes?(opening_tag, PRESENTATION_SPAN_CLASSES)
            converted_content
          elsif converted_content == content
            wrapper
          else
            "#{opening_tag}#{converted_content}#{closing_tag}"
          end
        end
      end
      private_class_method :convert_presentation_spans

      def self.convert_written_by_divs(text)
        text.gsub(DIV_WRAPPER_RE) do |wrapper|
          opening_tag, content, closing_tag = Regexp.last_match.captures
          converted_content = convert_presentation_wrappers(content)

          if class_attribute_includes?(opening_tag, WRITTEN_BY_CLASSES)
            "\n\n#{converted_content}\n\n"
          elsif converted_content == content
            wrapper
          else
            "#{opening_tag}#{converted_content}#{closing_tag}"
          end
        end
      end
      private_class_method :convert_written_by_divs

      def self.class_attribute_includes?(opening_tag, expected_classes)
        class_attribute = opening_tag.match(/(?<![\w:-])class\s*=\s*["']([^"']*)["']/i)
        return false unless class_attribute

        class_attribute[1].split.intersect?(expected_classes)
      end
      private_class_method :class_attribute_includes?

      def self.stash_code_blocks(text, stashed)
        body = stash_block_code(text, stashed)
        stash_inline_code_spans(body, stashed)
      end
      private_class_method :stash_code_blocks

      def self.stash_block_code(text, stashed)
        lines = text.lines
        output = []
        line_index = 0

        while line_index < lines.length
          fence = fence_start(lines[line_index])
          if fence
            block, line_index = fenced_block(lines, line_index, fence)
            ending = block[/\r?\n\z/] || ''
            fenced_content = ending.empty? ? block : block[0...-ending.length]
            output << stash(fenced_content, stashed) << ending
            next
          end

          output << lines[line_index]
          line_index += 1
        end

        output.join
      end
      private_class_method :stash_block_code

      def self.fence_start(line)
        match = line.match(/^ {0,3}(`{3,}|~{3,})/)
        return nil unless match
        return nil if match[1].start_with?('`') && line[match[0].length..].include?('`')

        [match[1][0], match[1].length]
      end
      private_class_method :fence_start

      def self.fenced_block(lines, start_index, fence)
        marker, length = fence
        close_pattern = /^ {0,3}#{Regexp.escape(marker)}{#{length},}[ \t]*\r?(?:\n|\z)/
        line_index = start_index + 1
        line_index += 1 while line_index < lines.length && !lines[line_index].match?(close_pattern)
        line_index += 1 if line_index < lines.length

        [lines[start_index...line_index].join, line_index]
      end
      private_class_method :fenced_block

      def self.stash_inline_code_spans(text, stashed)
        runs = []
        text.to_enum(:scan, /`+/).each do
          match = Regexp.last_match
          runs << [match.begin(0), match.end(0), match[0].length]
        end

        next_matching_run = find_next_matching_runs(runs)

        output = +''
        text_position = 0
        run_index = 0

        while run_index < runs.length
          closing_index = next_matching_run[run_index]
          if closing_index.nil?
            run_index += 1
            next
          end

          opening_start = runs[run_index][0]
          closing_end = runs[closing_index][1]
          output << text[text_position...opening_start]
          output << stash(text[opening_start...closing_end], stashed)
          text_position = closing_end
          run_index = closing_index + 1
        end

        output << text[text_position..]
      end
      private_class_method :stash_inline_code_spans

      def self.find_next_matching_runs(runs)
        next_matching_run = Array.new(runs.length)
        nearest_run_by_length = {}
        (runs.length - 1).downto(0) do |run_index|
          delimiter_length = runs[run_index][2]
          next_matching_run[run_index] = nearest_run_by_length[delimiter_length]
          nearest_run_by_length[delimiter_length] = run_index
        end

        next_matching_run
      end
      private_class_method :find_next_matching_runs

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
