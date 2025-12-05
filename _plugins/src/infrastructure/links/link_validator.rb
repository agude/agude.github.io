# frozen_string_literal: true

module Jekyll
  module Infrastructure
    module Links
      # Validates that no raw Markdown or HTML links exist for cached items.
      #
      # Ensures all links to books, authors, and series use custom Liquid tags
      # rather than raw links, raising fatal errors if violations are found.
      class LinkValidator
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

          check_regex(doc, /\[[^\]]+\]\(([^)\s]+)/, 'Markdown', found_raw_links)
          check_regex(doc, /<a\s+(?:[^>]*?\s+)?href="([^"]+)"/, 'HTML', found_raw_links)
        end

        def check_regex(doc, regex, type, found_raw_links)
          doc.content.scan(regex).each do |match|
            url = match.first&.split('#')&.first
            if url && known_url?(url)
              found_raw_links[doc.relative_path] ||= []
              found_raw_links[doc.relative_path] << "#{type}: #{match.first}"
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
