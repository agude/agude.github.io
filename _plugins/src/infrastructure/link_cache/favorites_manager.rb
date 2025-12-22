# frozen_string_literal: true

require_relative '../text_processing_utils'
require_relative 'favorites_validator'

module Jekyll
  module Infrastructure
    module LinkCache
      # Manages caching for favorites lists and their book mentions.
      #
      # Scans posts marked as favorites lists for book_card_lookup tags and builds
      # mappings between posts and the books they mention.
      class FavoritesManager
        TAG_REGEX = /\{%\s*book_card_lookup\s+(.*?)%\}/m
        TITLE_REGEX = /(?:title\s*=\s*)?(?:'([^']+)'|"([^"]+)")/
        DATE_REGEX = /date\s*=\s*(?:'([^']+)'|"([^"]+)")/

        def initialize(site, link_cache, url_map)
          @site = site
          @link_cache = link_cache
          @url_map = url_map
          @mentions = link_cache['favorites_mentions']
          @posts_to_books = link_cache['favorites_posts_to_books']
        end

        def build
          return unless @site.posts&.docs.is_a?(Array) && @link_cache['books']&.any?

          validator = FavoritesValidator.new
          @site.posts.docs.select { |p| p.data.key?('is_favorites_list') }.each do |post|
            scan_post(post, validator)
          end
          validator.raise_if_errors!
        end

        private

        def scan_post(post, validator)
          post.content.scan(TAG_REGEX).each do |match|
            tag_content = match.first
            validator.check_tag(post, tag_content)

            title = extract_title(tag_content)
            date = extract_date(tag_content)
            process_match(title, date, post, validator) if title && !title.strip.empty?
          end
        end

        def extract_title(tag_content)
          match = tag_content.match(TITLE_REGEX)
          return nil unless match

          match.captures.compact.first
        end

        def extract_date(tag_content)
          match = tag_content.match(DATE_REGEX)
          return nil unless match

          match.captures.compact.first
        end

        def process_match(title, date, post, validator)
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
          locs = @link_cache['books'][normalized]
          return unless locs&.any?

          book = find_book_by_date(locs, date)
          unless book
            validator.check_date_match(post, title, date)
            return
          end

          book_url = book['url']
          add_mention(book_url, post)
          add_post_link(post, book_url)
        end

        def find_book_by_date(locs, date_string)
          return nil unless date_string

          locs.find { |loc| format_date(loc['date']) == date_string }
        end

        def format_date(date)
          return nil unless date

          date.strftime('%Y-%m-%d')
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
