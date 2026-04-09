# frozen_string_literal: true

require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module LinkCache
      # Builds backlink data showing which books reference other books.
      #
      # Scans book content for book_link, series_link, and short_story_link tags
      # to track which books mention other books for display in backlink sections.
      class BacklinkBuilder
        LINK_TYPE_PRIORITY = { 'book' => 3, 'short_story' => 2, 'series' => 1 }.freeze
        LINK_FALSE_PATTERN = /link\s*=\s*(?:'false'|"false"|false)/

        def initialize(site, link_cache, maps)
          @site = site
          @link_cache = link_cache
          @maps = maps
          @backlinks = Hash.new { |h, k| h[k] = {} }
        end

        def build
          return unless @link_cache['books']&.any? && @site.collections.key?('books')

          @site.collections['books'].docs.each do |source_doc|
            scan_doc(source_doc)
          end

          finalize_backlinks
        end

        private

        def scan_doc(doc)
          return unless doc.respond_to?(:content) && doc.content && !doc.content.empty?

          scan_book_links(doc)
          scan_series_links(doc)
          scan_short_story_links(doc)
        end

        def scan_book_links(doc)
          doc.content.scan(/\{%\s*book_link\s+(?:'([^']+)'|"([^"]+)")/).each do |match|
            title = match.compact.first
            locs = @link_cache['books'][Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)]
            add_backlink(locs.first['url'], doc, 'book') if locs
          end
        end

        def scan_series_links(doc)
          scan_quoted_series_tags(doc)
          scan_variable_series_tags(doc)
        end

        # Matches series_link and series_text tags with quoted string arguments:
        #   {% series_link "Foundation Series" %}
        #   {% series_text "Honor Harrington" %}
        # Skips tags with link=false since no link is rendered.
        def scan_quoted_series_tags(doc)
          doc.content.scan(/\{%\s*series_(?:link|text)\s+(?:'([^']+)'|"([^"]+)")(.*?)%\}/).each do |match|
            next if match[2]&.match?(LINK_FALSE_PATTERN)

            title = match[0..1].compact.first
            register_series_backlinks(doc, title)
          end
        end

        # Matches series_link and series_text tags with page.series variable:
        #   {% series_link page.series %}
        #   {% series_text page.series %}
        # Resolves the variable from the document's front matter.
        # Skips tags with link=false since no link is rendered.
        def scan_variable_series_tags(doc)
          doc.content.scan(/\{%\s*series_(?:link|text)\s+page\.series(.*?)%\}/).each do |match|
            next if match[0]&.match?(LINK_FALSE_PATTERN)

            series = doc.data['series']
            next if series.nil? || series.to_s.strip.empty?

            register_series_backlinks(doc, series)
          end
        end

        def register_series_backlinks(doc, title)
          books = @link_cache['series_map'][Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)]
          books&.each { |book| add_backlink(book.url, doc, 'series') }
        end

        def scan_short_story_links(doc)
          regex = /\{%\s*short_story_link\s+["'](.+?)["'](?:\s+from_book=["'](.+?)["'])?\s*%\}/
          doc.content.scan(regex).each do |match|
            process_short_story_match(match, doc)
          end
        end

        def process_short_story_match(match, doc)
          title, from_book = match
          locs = @link_cache['short_stories'][Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)]
          return unless locs

          target = find_target_story(locs, from_book)
          add_backlink(target['url'], doc, 'short_story') if target
        end

        def find_target_story(locs, from_book)
          if from_book && !from_book.strip.empty?
            locs.find { |l| l['parent_book_title'].casecmp(from_book).zero? }
          elsif locs.map { |l| l['url'] }.uniq.length == 1
            locs.first
          end
        end

        def add_backlink(target_url, source_doc, type)
          return if source_doc.url == target_url

          existing = @backlinks[target_url][source_doc.url]
          new_p = LINK_TYPE_PRIORITY[type]

          return unless existing.nil? || new_p > LINK_TYPE_PRIORITY[existing[:type]]

          @backlinks[target_url][source_doc.url] = { source: source_doc, type: type }
        end

        def finalize_backlinks
          final = {}
          @backlinks.each { |target, sources| final[target] = sources.values }
          @link_cache['backlinks'] = final
        end
      end
    end
  end
end
