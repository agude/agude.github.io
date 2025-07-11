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
        'backlinks' => {},
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

      # --- Build Backlinks Cache ---
      # This must run after the 'books' cache is populated.
      build_backlinks_cache(site, link_cache)

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

    # Scans all books for links to other books and builds a backlink map.
    def build_backlinks_cache(site, link_cache)
      Jekyll.logger.info "LinkCacheGenerator:", "Building backlinks cache..."
      backlinks = Hash.new { |h, k| h[k] = [] }
      books_cache = link_cache['books']
      return unless books_cache && !books_cache.empty?

      # Create a reverse map of URL -> book data for efficient markdown link checking
      url_to_book_map = books_cache.values.to_h { |book_data| [book_data['url'], book_data] }

      # Regex for {% book_link 'Title' %} or {% book_link "Title" %}
      book_link_tag_regex = /\{%\s*book_link\s+(?:'([^']+)'|"([^"]+)")/
      # Regex for [link text](url) - captures URL part
      markdown_link_regex = /\[[^\]]+\]\(([^)\s]+)/
      # Regex for <a href="url"> - captures URL part
      html_link_regex = /<a\s+(?:[^>]*?\s+)?href="([^"]+)"/

      site.collections['books'].docs.each do |source_doc|
        content = source_doc.content
        next if content.nil? || content.empty?

        # 1. Find Liquid book_link tags with string literals
        content.scan(book_link_tag_regex).each do |match|
          target_title = match.compact.first
          next unless target_title

          normalized_target_title = TextProcessingUtils.normalize_title(target_title)
          target_book_data = books_cache[normalized_target_title]

          if target_book_data && (target_url = target_book_data['url'])
            backlinks[target_url] << source_doc if source_doc.url != target_url
          end
        end

        # 2. Find standard Markdown links
        content.scan(markdown_link_regex).each do |match|
          linked_url = match.first&.split('#')&.first
          next if linked_url.nil? || linked_url.empty?

          if url_to_book_map.key?(linked_url) && source_doc.url != linked_url
            backlinks[linked_url] << source_doc
          end
        end

        # 3. Find raw HTML links
        content.scan(html_link_regex).each do |match|
          linked_url = match.first&.split('#')&.first
          next if linked_url.nil? || linked_url.empty?

          if url_to_book_map.key?(linked_url) && source_doc.url != linked_url
            backlinks[linked_url] << source_doc
          end
        end
      end

      # Deduplicate the lists of source documents
      backlinks.each_value(&:uniq!)

      link_cache['backlinks'] = backlinks
    end
  end
end
