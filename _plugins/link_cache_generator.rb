# _plugins/link_cache_generator.rb
require 'jekyll'
require_relative 'utils/text_processing_utils'
require_relative 'utils/front_matter_utils'

module Jekyll
  # This generator builds a cache of linkable pages (authors, books, series)
  # and navigation items to avoid expensive page traversals in other plugins and tags.
  # The cache is stored in site.data['link_cache'].
  class LinkCacheGenerator < Generator
    priority :normal

    def generate(site)
      Jekyll.logger.info "LinkCacheGenerator:", "Building link cache..."

      # Initialize the cache structure
      link_cache = {
        'authors' => {},
        'books' => {},
        'series' => {},
        'series_map' => {},
        'sidebar_nav' => [],
        'books_topbar_nav' => [],
      }

      # --- Cache Author and Series Pages ---
      site.pages.each do |page|
        layout = page.data['layout']
        title = page.data['title']

        # Cache navigation items
        if title && page.data['sidebar_include'] == true && !page.url.include?("page")
          link_cache['sidebar_nav'] << page
        end
        if title && page.data['book_topbar_include'] == true
          link_cache['books_topbar_nav'] << page
        end

        # Cache linkable pages
        next unless title && !title.strip.empty?
        if layout == 'author_page'
          cache_author_page(page, link_cache['authors'])
        elsif layout == 'series_page'
          cache_series_page(page, link_cache['series'])
        end
      end

      # Sort the navigation lists
      link_cache['sidebar_nav'].sort_by! { |p| p.data['title'] }
      link_cache['books_topbar_nav'].sort_by! { |p| p.data['title'] }

      # --- Cache Book Pages and Build Series Map ---
      if site.collections.key?('books')
        site.collections['books'].docs.each do |book|
          # Only cache published books with a title
          next if book.data['published'] == false
          title = book.data['title']
          next unless title && !title.strip.empty?
          cache_book_page(book, link_cache['books'])
          cache_book_in_series_map(book, link_cache['series_map'])
        end
      end

      # Store the completed cache in site.data for global access
      site.data['link_cache'] = link_cache
      Jekyll.logger.info "LinkCacheGenerator:", "Cache built successfully."
    end

    private

    # Caches an author page, including its pen names.
    def cache_author_page(page, author_cache)
      canonical_title = page.data['title'].strip
      page_data = { 'url' => page.url, 'title' => canonical_title }

      # Cache the canonical name
      normalized_canonical = TextProcessingUtils.normalize_title(canonical_title)
      author_cache[normalized_canonical] = page_data

      # Cache any pen names, pointing to the same canonical data
      pen_names = FrontMatterUtils.get_list_from_string_or_array(page.data['pen_names'])
      pen_names.each do |pen_name|
        normalized_pen_name = TextProcessingUtils.normalize_title(pen_name)
        author_cache[normalized_pen_name] = page_data unless normalized_pen_name.empty?
      end
    end

    # Caches a series page.
    def cache_series_page(page, series_cache)
      title = page.data['title'].strip
      normalized_title = TextProcessingUtils.normalize_title(title)
      series_cache[normalized_title] = { 'url' => page.url, 'title' => title }
    end

    # Caches a book page.
    def cache_book_page(book, book_cache)
      title = book.data['title'].strip
      normalized_title = TextProcessingUtils.normalize_title(title)
      book_cache[normalized_title] = { 'url' => book.url, 'title' => title }
    end

    # Adds a book to the series map.
    def cache_book_in_series_map(book, series_map)
      series_name = book.data['series']
      return unless series_name && !series_name.strip.empty?

      normalized_series_name = TextProcessingUtils.normalize_title(series_name)
      series_map[normalized_series_name] ||= []
      series_map[normalized_series_name] << book
    end
  end
end
