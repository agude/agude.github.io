# frozen_string_literal: true

require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module LinkCache
      # Builds a cache of short stories found in anthology books.
      #
      # Scans books marked as anthologies for short story titles mentioned in
      # their content and caches them for linking.
      class ShortStoryBuilder
        def initialize(site, link_cache)
          @site = site
          @cache = link_cache['short_stories']
        end

        def build
          return unless @site.collections.key?('books')

          @site.collections['books'].docs.each do |book|
            next if book.data['published'] == false
            next unless book.data['is_anthology'] == true

            scan_book(book)
          end
        end

        private

        def scan_book(book)
          parent_title = book.data['title']
          parent_url = book.url
          return if parent_title.nil? || parent_url.nil?

          regex = /^#+\s*\{%\s*short_story_title\s+["'](.+?)["'](?!\s+no_id)\s*%\}/
          book.content.scan(regex).each do |match|
            add_story(match.first.strip, parent_title, parent_url)
          end
        end

        def add_story(title, parent_title, parent_url)
          return if title.empty?

          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
          data = {
            'title' => title,
            'parent_book_title' => parent_title,
            'url' => parent_url,
            'slug' => Jekyll::Infrastructure::TextProcessingUtils.slugify(title)
          }
          @cache[normalized] ||= []
          @cache[normalized] << data
        end
      end
    end
  end
end
