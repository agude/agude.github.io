# frozen_string_literal: true

# _plugins/link_cache_generator.rb
require 'jekyll'
require_relative 'link_cache/cache_builder'
require_relative 'link_cache/cache_maps'
require_relative 'link_cache/short_story_builder'
require_relative 'links/link_validator'
require_relative 'link_cache/backlink_builder'
require_relative 'link_cache/favorites_manager'

module Jekyll
  module Infrastructure
    # This generator builds a cache of linkable pages (authors, books, series)
    # and navigation items to avoid expensive page traversals in other plugins and tags.
    # The cache is stored in site.data['link_cache'].
    class LinkCacheGenerator < Generator
      priority :normal

      def generate(site)
        Jekyll.logger.info 'Jekyll::Infrastructure::LinkCacheGenerator:', 'Building link cache...'
        link_cache = initialize_cache
        site.data['mention_tracker'] ||= {}

        builder = Jekyll::Infrastructure::LinkCache::CacheBuilder.new(link_cache)
        url_to_book_doc_map = builder.build(site)

        build_secondary_caches(site, link_cache, url_to_book_doc_map)

        site.data['link_cache'] = link_cache
        Jekyll.logger.info 'Jekyll::Infrastructure::LinkCacheGenerator:', 'Cache built successfully.'
      end

      private

      def build_secondary_caches(site, link_cache, url_to_book_doc_map)
        Jekyll::Infrastructure::LinkCache::ShortStoryBuilder.new(site, link_cache).build

        maps = Jekyll::Infrastructure::LinkCache::CacheMaps.new(link_cache)
        Jekyll::Infrastructure::Links::LinkValidator.new(site, maps).validate
        Jekyll::Infrastructure::LinkCache::BacklinkBuilder.new(site, link_cache, maps).build

        Jekyll::Infrastructure::LinkCache::FavoritesManager.new(site, link_cache, url_to_book_doc_map).build
      end

      def initialize_cache
        {
          'authors' => {}, 'books' => {}, 'series' => {}, 'series_map' => {},
          'short_stories' => {}, 'sidebar_nav' => [], 'books_topbar_nav' => [],
          'backlinks' => {}, 'favorites_mentions' => {}, 'favorites_posts_to_books' => {},
          'url_to_canonical_map' => {}, 'book_families' => Hash.new { |h, k| h[k] = [] }
        }
      end
    end
  end
end
