# frozen_string_literal: true

module Jekyll
  # Provides convenient URL-to-data lookups for cached items.
  #
  # Creates indexed maps of books, authors, and series keyed by their URLs
  # for efficient lookup during validation and backlink building.
  class CacheMaps
    attr_reader :books, :authors, :series

    def initialize(link_cache)
      @books = {}
      link_cache['books'].values.flatten.each { |d| @books[d['url']] = d }

      @authors = {}
      link_cache['authors'].each_value { |d| @authors[d['url']] = d }

      @series = {}
      link_cache['series'].each_value { |d| @series[d['url']] = d }
    end
  end
end
