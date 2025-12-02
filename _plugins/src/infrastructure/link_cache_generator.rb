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
  # This generator builds a cache of linkable pages (authors, books, series)
  # and navigation items to avoid expensive page traversals in other plugins and tags.
  # The cache is stored in site.data['link_cache'].
  class LinkCacheGenerator < Generator
    priority :normal

    def generate(site)
      Jekyll.logger.info 'LinkCacheGenerator:', 'Building link cache...'
      link_cache = initialize_cache
      site.data['mention_tracker'] ||= {}

      builder = CacheBuilder.new(link_cache)
      url_to_book_doc_map = builder.build(site)

      build_secondary_caches(site, link_cache, url_to_book_doc_map)

      site.data['link_cache'] = link_cache
      Jekyll.logger.info 'LinkCacheGenerator:', 'Cache built successfully.'
    end

    private

    def build_secondary_caches(site, link_cache, url_to_book_doc_map)
      ShortStoryBuilder.new(site, link_cache).build

      maps = CacheMaps.new(link_cache)
      LinkValidator.new(site, maps).validate
      BacklinkBuilder.new(site, link_cache, maps).build

      FavoritesManager.new(site, link_cache, url_to_book_doc_map).build
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
