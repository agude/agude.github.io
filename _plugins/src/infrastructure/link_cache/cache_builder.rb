# frozen_string_literal: true

require_relative '../text_processing_utils'
require_relative '../front_matter_utils'

module Jekyll
  module Infrastructure
    module LinkCache
      # Builds the primary caches for authors, books, series, and navigation.
      #
      # Processes Jekyll pages and book documents to populate lookup caches
      # for linking and navigation throughout the site.
      class CacheBuilder
        def initialize(link_cache)
          @link_cache = link_cache
        end

        def build(site)
          process_pages(site)
          process_books(site)
        end

        private

        def process_pages(site)
          site.pages.each do |page|
            cache_nav_items(page)
            cache_linkable_page(page)
          end
          @link_cache['sidebar_nav'].sort_by! { |p| p.data['title'] }
          @link_cache['books_topbar_nav'].sort_by! { |p| p.data['title'] }
        end

        def cache_nav_items(page)
          title = page.data['title']
          return unless title

          @link_cache['sidebar_nav'] << page if include_in_sidebar?(page)
          @link_cache['books_topbar_nav'] << page if page.data['book_topbar_include'] == true
        end

        def include_in_sidebar?(page)
          page.data['sidebar_include'] == true && !page.url.include?('page')
        end

        def cache_linkable_page(page)
          title = page.data['title']
          return unless title && !title.strip.empty?

          cache_author_page(page) if page.data['layout'] == 'author_page'
          cache_series_page(page) if page.data['layout'] == 'series_page'
        end

        def process_books(site)
          url_to_book_doc_map = {}
          return url_to_book_doc_map unless site.collections.key?('books')

          site.collections['books'].docs.each do |book|
            url_to_book_doc_map[book.url] = book
            next if book.data['published'] == false

            process_single_book(book)
          end
          url_to_book_doc_map
        end

        def process_single_book(book)
          title = book.data['title']
          return unless title && !title.strip.empty?

          cache_book_page(book)
          cache_book_in_series_map(book)
        end

        def cache_author_page(page)
          canonical_title = page.data['title'].strip
          page_data = { 'url' => page.url, 'title' => canonical_title }
          author_cache = @link_cache['authors']

          author_cache[Jekyll::Infrastructure::TextProcessingUtils.normalize_title(canonical_title)] = page_data

          pen_names = Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(page.data['pen_names'])
          pen_names.each do |pen_name|
            normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(pen_name)
            author_cache[normalized] = page_data unless normalized.empty?
          end
        end

        def cache_series_page(page)
          title = page.data['title'].strip
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)
          @link_cache['series'][normalized] = { 'url' => page.url, 'title' => title }
        end

        def cache_book_page(book)
          title = book.data['title'].strip
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title)

          @link_cache['books'][normalized] ||= []
          @link_cache['books'][normalized] << build_book_data(book)

          update_book_families(book)
        end

        def build_book_data(book)
          {
            'url' => book.url,
            'title' => book.data['title'].strip,
            'authors' => Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors']),
            'canonical_url' => book.data['canonical_url'],
            'date' => book.data['date'],
          }
        end

        def update_book_families(book)
          canonical_url = book.data['canonical_url'] || book.url
          @link_cache['url_to_canonical_map'][book.url] = canonical_url
          @link_cache['book_families'][canonical_url] << book.url
        end

        def cache_book_in_series_map(book)
          series_name = book.data['series']
          return unless series_name && !series_name.strip.empty?

          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(series_name)
          @link_cache['series_map'][normalized] ||= []
          @link_cache['series_map'][normalized] << book
        end
      end
    end
  end
end
