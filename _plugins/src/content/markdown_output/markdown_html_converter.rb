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
        body.gsub!(ANCHOR_RE, '[\2](\1)')

        restore_code_blocks(body, stashed)
      end

      # --- private helpers ---

      def self.stash_code_blocks(text, stashed)
        # Fenced code blocks first (greedy match between triple-backticks),
        # then inline code spans.
        text.gsub(/(```[\s\S]*?```|`[^`\n]+`)/) do |match|
          placeholder = "#{STASH_PREFIX}_#{stashed.size}@@"
          stashed[placeholder] = match
          placeholder
        end
      end
      private_class_method :stash_code_blocks

      def self.restore_code_blocks(text, stashed)
        stashed.each do |placeholder, original|
          # Use block form to avoid backreference interpretation in original.
          text.gsub!(placeholder) { original }
        end
        text
      end
      private_class_method :restore_code_blocks
    end
  end
end
