# frozen_string_literal: true

require_relative '../../infrastructure/markdown_fence_parser'
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

      # Emphasis tags become Markdown emphasis, including tags with attributes.
      EM_RE = %r{<em(?:\s+[^>]*)?>(.*?)</em>}m

      # Strong tags become Markdown strong emphasis, including attributes.
      STRONG_RE = %r{<strong(?:\s+[^>]*)?>(.*?)</strong>}m

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
      FenceParser = Jekyll::Infrastructure::MarkdownFenceParser
      DETAILS_RE = %r{<details\b[^>]*>(.*?)</details\s*>}im
      SUMMARY_RE = %r{<summary\b[^>]*>(.*?)</summary\s*>}im

      def self.convert(markdown_body)
        return markdown_body if markdown_body.nil? || markdown_body.empty?

        stashed = {}
        body = stash_code_blocks(markdown_body, stashed)
        body = convert_chatgpt_edit_blocks(body, stashed)
        body = WrapperConverter.convert(body)
        body = convert_disclosures(body)
        body.gsub!(HORIZONTAL_RULE_RE, "\n\n---\n\n")

        # Convert inner tags before outer tags (cite/span before anchors).
        body.gsub!(CITE_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(ABBR_RE, '\1')
        body.gsub!(EM_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(STRONG_RE) { "**#{Regexp.last_match(1)}**" }
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
          fence = FenceParser.fence_start(lines[line_index], lines: lines, line_index: line_index)
          if fence
            block, line_index = FenceParser.fenced_block(lines, line_index, fence)
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

      def self.stash_inline_code_spans(text, stashed)
        runs = []
        text.to_enum(:scan, /`+/).each do
          match = Regexp.last_match
          runs << [match.begin(0), match.end(0), match[0].length]
        end

        paragraph_boundaries = blank_line_boundaries(text)
        run_regions = assign_run_regions(runs, paragraph_boundaries)
        next_matching_run = find_next_matching_runs(runs, run_regions)

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

      def self.assign_run_regions(runs, boundaries)
        boundary_index = 0
        runs.map do |run|
          boundary_index += 1 while boundaries[boundary_index] && boundaries[boundary_index] <= run[0]
          boundary_index
        end
      end
      private_class_method :assign_run_regions

      def self.blank_line_boundaries(text)
        text.to_enum(:scan, /\r?\n[ \t]*(?:>[ \t]*(?:>[ \t]*)*)?[ \t]*\r?\n/).map do
          Regexp.last_match.end(0)
        end
      end
      private_class_method :blank_line_boundaries

      def self.find_next_matching_runs(runs, run_regions)
        next_matching_run = Array.new(runs.length)
        nearest_run_by_length = {}
        (runs.length - 1).downto(0) do |run_index|
          delimiter_length = runs[run_index][2]
          region = run_regions[run_index]
          key = [delimiter_length, region]
          next_matching_run[run_index] = nearest_run_by_length[key]
          nearest_run_by_length[key] = run_index
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
