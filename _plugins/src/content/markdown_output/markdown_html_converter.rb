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

      # Abbr tags that should be stripped to plain text.
      ABBR_RE = %r{<abbr[^>]*class=["']etal["'][^>]*>(.*?)</abbr>}m

      # Anchor tags → Markdown links.  Runs after inner-tag conversion
      # so nested cites/spans are already converted.
      ANCHOR_RE = %r{<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>}m

      def self.convert(markdown_body)
        return markdown_body if markdown_body.nil? || markdown_body.empty?

        stashed = {}
        body = stash_code_blocks(markdown_body, stashed)

        # Convert inner tags before outer tags (cite/span before anchors).
        body.gsub!(CITE_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(SPAN_RE, '\1')
        body.gsub!(ABBR_RE, '\1')
        body.gsub!(EM_RE) { "_#{Regexp.last_match(1)}_" }
        body.gsub!(STRONG_RE) { "**#{Regexp.last_match(1)}**" }
        body.gsub!(ANCHOR_RE, '[\2](\1)')

        restore_code_blocks(body, stashed)
      end

      # --- private helpers ---

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
