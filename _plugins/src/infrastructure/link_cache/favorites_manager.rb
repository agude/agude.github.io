# frozen_string_literal: true

require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module LinkCache
      # Manages caching for favorites lists and their book mentions.
      #
      # Scans posts marked as favorites lists for book_link tags and builds
      # mappings between posts and the books they mention.
      class FavoritesManager
        def initialize(site, link_cache, url_map)
          @site = site
          @link_cache = link_cache
          @url_map = url_map
          @mentions = link_cache['favorites_mentions']
          @posts_to_books = link_cache['favorites_posts_to_books']
        end

        def build
          return unless @site.posts&.docs.is_a?(Array) && @link_cache['books']&.any?

          @site.posts.docs.select { |p| p.data.key?('is_favorites_list') }.each do |post|
            scan_post(post)
          end
        end

        private

        def scan_post(post)
          regex = /\{%\s*book_card_lookup\s+(?:title=)?(?:'([^']+)'|"([^"]+)"|(\S+))\s*.*?%\}/
          post.content.scan(regex).each do |match|
            title = match.compact.first
            process_match(title, post) if title && !title.strip.empty?
          end
        end

        def process_match(title, post)
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
          locs = @link_cache['books'][normalized]
          return unless locs&.any?

          book_url = locs.first['url']
          return unless book_url

          add_mention(book_url, post)
          add_post_link(post, book_url)
        end

        def add_mention(book_url, post)
          @mentions[book_url] ||= []
          @mentions[book_url] << post unless @mentions[book_url].include?(post)
        end

        def add_post_link(post, book_url)
          book_doc = @url_map[book_url]
          return unless book_doc

          @posts_to_books[post.url] ||= []
          return if @posts_to_books[post.url].include?(book_doc)

          @posts_to_books[post.url] << book_doc
        end
      end
    end
  end
end
