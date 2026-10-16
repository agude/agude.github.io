# frozen_string_literal: true

require_relative '../markdown_code_region_parser'

module Jekyll
  module Infrastructure
    module Links
      # Validates that no raw Markdown or HTML links exist for cached items.
      #
      # Ensures all links to books, authors, and series use custom Liquid tags
      # rather than raw links, raising fatal errors if violations are found.
      # Fenced, indented, and inline code is masked first, so code examples
      # that show a raw link are not flagged. An `href` matches in double
      # quotes, single quotes, or unquoted.
      #
      # @validator Raw Markdown/HTML links to items that should use custom
      #   tags.
      class LinkValidator
        HTML_HREF = /<a\s+(?:[^>]*?\s+)?href\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/
        private_constant :HTML_HREF

        def initialize(site, maps)
          @site = site
          @maps = maps
        end

        def validate
          found_raw_links = {}
          (@site.documents + @site.pages).each do |doc|
            check_doc(doc, found_raw_links)
          end
          raise_error(found_raw_links) if found_raw_links.any?
        end

        private

        def check_doc(doc, found_raw_links)
          return unless doc.respond_to?(:content) && doc.content

          text = mask_code(doc.content)
          check_regex(doc, text, /\[[^\]]+\]\(([^)\s]+)/, 'Markdown', found_raw_links)
          check_regex(doc, text, /^ {0,3}\[[^\]]+\]:\s*<?(\S+?)>?(?:\s|$)/, 'Markdown (reference)', found_raw_links)
          check_regex(doc, text, HTML_HREF, 'HTML', found_raw_links)
        end

        # Blanks out code regions, keeping newlines so line-anchored patterns
        # and the remaining offsets are unchanged.
        def mask_code(content)
          masked = content.dup
          Jekyll::Infrastructure::MarkdownCodeRegionParser.protected_code_ranges(content).each do |from, to|
            masked[from...to] = content[from...to].gsub(/[^\n]/, ' ')
          end
          masked
        end

        def check_regex(doc, text, regex, type, found_raw_links)
          text.scan(regex).each do |groups|
            raw = groups.compact.first
            url = raw&.split('#')&.first
            if url && known_url?(url)
              found_raw_links[doc.relative_path] ||= []
              found_raw_links[doc.relative_path] << "#{type}: #{raw}"
            end
          end
        end

        def known_url?(url)
          @maps.books.key?(url) || @maps.authors.key?(url) || @maps.series.key?(url)
        end

        def raise_error(found_raw_links)
          msg = 'Found raw Markdown/HTML links. Please convert them to use custom tags ' \
                "('book_link', 'author_link', 'series_link').\n".dup
          found_raw_links.each do |path, links|
            msg << "  - In file '#{path}':\n"
            links.uniq.each { |link| msg << "    - Found: #{link}\n" }
          end
          raise Jekyll::Errors::FatalException, msg
        end
      end
    end
  end
end
