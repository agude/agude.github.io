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

    # --- Define the priority of link types ---
    # Higher number means higher priority.
    LINK_TYPE_PRIORITY = {
      'book' => 3,
      'short_story' => 2,
      'series' => 1
    }.freeze

    def generate(site)
      Jekyll.logger.info 'LinkCacheGenerator:', 'Building link cache...'

      # Initialize the cache structure
      link_cache = {
        'authors' => {},
        'books' => {},
        'series' => {},
        'series_map' => {},
        'short_stories' => {},
        'sidebar_nav' => [],
        'books_topbar_nav' => [],
        'backlinks' => {},
        'favorites_mentions' => {},
        'favorites_posts_to_books' => {},
        'url_to_canonical_map' => {},
        'book_families' => Hash.new { |h, k| h[k] = [] }
      }

      # --- Initialize the mention tracker ---
      site.data['mention_tracker'] ||= {}

      # --- Cache Author and Series Pages ---
      site.pages.each do |page|
        layout = page.data['layout']
        title = page.data['title']

        # Cache navigation items
        link_cache['sidebar_nav'] << page if title && page.data['sidebar_include'] == true && !page.url.include?('page')
        link_cache['books_topbar_nav'] << page if title && page.data['book_topbar_include'] == true

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
      url_to_book_doc_map = {}
      if site.collections.key?('books')
        site.collections['books'].docs.each do |book|
          url_to_book_doc_map[book.url] = book # Populate the reverse map
          # Only cache published books with a title
          next if book.data['published'] == false

          title = book.data['title']
          next unless title && !title.strip.empty?

          cache_book_page(book, link_cache) # Pass the whole cache
          cache_book_in_series_map(book, link_cache['series_map'])
        end
      end

      # Build the short story cache after books are processed.
      build_short_story_cache(site, link_cache)

      # --- Build Backlinks Cache ---
      # This must run after the 'books' and 'short_stories' caches are populated.
      build_backlinks_cache(site, link_cache)

      # --- Build Favorites Mentions Cache ---
      build_favorites_mentions_cache(site, link_cache, url_to_book_doc_map)

      # Store the completed cache in site.data for global access
      site.data['link_cache'] = link_cache
      Jekyll.logger.info 'LinkCacheGenerator:', 'Cache built successfully.'
    end

    private

    # --- Helper method to add backlinks based on priority ---
    def add_backlink(backlinks, target_url, source_doc, type)
      return if source_doc.url == target_url

      source_url = source_doc.url
      new_priority = LINK_TYPE_PRIORITY[type]

      existing_entry = backlinks[target_url][source_url]

      return unless existing_entry.nil? || new_priority > LINK_TYPE_PRIORITY[existing_entry[:type]]

      backlinks[target_url][source_url] = { source: source_doc, type: type }
    end

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

    # Caches a book page. Now handles multiple books with the same title by storing an array.
    def cache_book_page(book, link_cache)
      title = book.data['title'].strip
      normalized_title = TextProcessingUtils.normalize_title(title)
      book_cache = link_cache['books']

      # Get authors for this book entry to store them in the cache.
      author_names = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
      book_data = {
        'url' => book.url,
        'title' => title,
        'authors' => author_names,
        'canonical_url' => book.data['canonical_url'] # This will be nil for canonical books
      }

      book_cache[normalized_title] ||= []
      book_cache[normalized_title] << book_data

      # --- Populate the new cache structures ---
      canonical_url = book.data['canonical_url'] || book.url
      link_cache['url_to_canonical_map'][book.url] = canonical_url
      link_cache['book_families'][canonical_url] << book.url
    end

    # Adds a book to the series map.
    def cache_book_in_series_map(book, series_map)
      series_name = book.data['series']
      return unless series_name && !series_name.strip.empty?

      normalized_series_name = TextProcessingUtils.normalize_title(series_name)
      series_map[normalized_series_name] ||= []
      series_map[normalized_series_name] << book
    end

    # Scans anthologies for short story titles and builds the cache.
    def build_short_story_cache(site, link_cache)
      return unless site.collections.key?('books')

      short_stories_cache = link_cache['short_stories']
      # Regex to find a markdown heading containing our specific Liquid tag.
      # Use a negative lookahead `(?!\s+no_id)` to explicitly ignore tags with the no_id flag.
      # It specifically looks for tags that do NOT include the `no_id` flag.
      short_story_regex = /^#+\s*\{%\s*short_story_title\s+["'](.+?)["'](?!\s+no_id)\s*%\}/

      site.collections['books'].docs.each do |book|
        # Added this line to skip unpublished books
        next if book.data['published'] == false
        # Only scan books explicitly marked as anthologies.
        next unless book.data['is_anthology'] == true

        parent_title = book.data['title']
        parent_url = book.url
        next if parent_title.nil? || parent_url.nil? # Skip if parent book is invalid

        book.content.scan(short_story_regex).each do |match|
          story_title = match.first.strip
          next if story_title.empty?

          normalized_key = TextProcessingUtils.normalize_title(story_title)
          slug = TextProcessingUtils.slugify(story_title)
          location_data = { 'title' => story_title, 'parent_book_title' => parent_title, 'url' => parent_url,
                            'slug' => slug }

          # Initialize an array if this is the first time we see this story title.
          short_stories_cache[normalized_key] ||= []
          # Add the location data. This handles duplicate story titles across different books.
          short_stories_cache[normalized_key] << location_data
        end
      end
    end

    # --- Raw Link Validator ---
    # This method scans content for raw Markdown or HTML links to pages that
    # should be linked via custom tags, and halts the build if any are found.
    def _validate_for_raw_links(site, url_to_book_map, url_to_author_map, url_to_series_map)
      # Regex for [link text](url) - captures URL part
      markdown_link_regex = /\[[^\]]+\]\(([^)\s]+)/
      # Regex for <a href="url"> - captures URL part
      html_link_regex = /<a\s+(?:[^>]*?\s+)?href="([^"]+)"/

      found_raw_links = {}

      (site.documents + site.pages).each do |source_doc|
        # Skip documents without content (e.g., some data files if processed as docs)
        next unless source_doc.respond_to?(:content) && source_doc.content

        content = source_doc.content
        next if content.nil? || content.empty?

        # Find standard Markdown links
        content.scan(markdown_link_regex).each do |match|
          url = match.first&.split('#')&.first
          if url && (url_to_book_map.key?(url) || url_to_author_map.key?(url) || url_to_series_map.key?(url))
            found_raw_links[source_doc.relative_path] ||= []
            found_raw_links[source_doc.relative_path] << "Markdown: #{match.first}"
          end
        end

        # Find raw HTML links
        content.scan(html_link_regex).each do |match|
          url = match.first&.split('#')&.first
          if url && (url_to_book_map.key?(url) || url_to_author_map.key?(url) || url_to_series_map.key?(url))
            found_raw_links[source_doc.relative_path] ||= []
            found_raw_links[source_doc.relative_path] << "HTML: #{match.first}"
          end
        end
      end

      return unless found_raw_links.any?

      error_message = "Found raw Markdown/HTML links. Please convert them to use the appropriate custom tag ('book_link', 'author_link', 'series_link').\n"
      found_raw_links.each do |path, links|
        error_message << "  - In file '#{path}':\n"
        links.uniq.each { |link| error_message << "    - Found: #{link}\n" }
      end
      raise Jekyll::Errors::FatalException, error_message
    end

    # --- build_backlinks_cache now uses the priority system ---
    def build_backlinks_cache(site, link_cache)
      Jekyll.logger.info 'LinkCacheGenerator:', 'Building backlinks cache...'
      # Use a nested hash to enforce uniqueness per source document
      backlinks = Hash.new { |h, k| h[k] = {} }
      books_cache = link_cache['books']
      authors_cache = link_cache['authors']
      series_cache = link_cache['series']
      short_stories_cache = link_cache['short_stories']

      # Create reverse maps of URL -> data object for validation
      url_to_book_map = {}
      books_cache.values.flatten.each { |book_data| url_to_book_map[book_data['url']] = book_data }
      url_to_author_map = {}
      authors_cache.each_value { |author_data| url_to_author_map[author_data['url']] = author_data }
      url_to_series_map = {}
      series_cache.each_value { |series_data| url_to_series_map[series_data['url']] = series_data }

      # --- Run the raw link validator ---
      _validate_for_raw_links(site, url_to_book_map, url_to_author_map, url_to_series_map)

      # The backlink generation logic only makes sense if there are books to be linked TO and FROM.
      return unless books_cache && !books_cache.empty?
      return unless site.collections.key?('books')

      # Regex for {% book_link 'Title' %} or {% book_link "Title" %}
      book_link_tag_regex = /\{%\s*book_link\s+(?:'([^']+)'|"([^"]+)")/
      # Regex for {% series_link 'Title' %}
      series_link_tag_regex = /\{%\s*series_link\s+(?:'([^']+)'|"([^"]+)")/
      # Regex to find short story links
      short_story_link_tag_regex = /\{%\s*short_story_link\s+["'](.+?)["'](?:\s+from_book=["'](.+?)["'])?\s*%\}/

      # Only scan documents in the 'books' collection for backlinks.
      site.collections['books'].docs.each do |source_doc|
        # Skip documents without content
        next unless source_doc.respond_to?(:content) && source_doc.content

        content = source_doc.content
        next if content.nil? || content.empty?

        # 1. Find Liquid book_link tags (1-to-1)
        content.scan(book_link_tag_regex).each do |match|
          target_title = match.compact.first
          if target_title && (locations = books_cache[TextProcessingUtils.normalize_title(target_title)])
            add_backlink(backlinks, locations.first['url'], source_doc, 'book')
          end
        end

        # 2. Find Liquid series_link tags (1-to-many)
        content.scan(series_link_tag_regex).each do |match|
          target_series_title = match.compact.first
          if target_series_title && (books = link_cache['series_map'][TextProcessingUtils.normalize_title(target_series_title)])
            books.each { |book| add_backlink(backlinks, book.url, source_doc, 'series') }
          end
        end

        # 3. Find Liquid short_story_link tags
        content.scan(short_story_link_tag_regex).each do |match|
          story_title, from_book_title = match
          locations = short_stories_cache[TextProcessingUtils.normalize_title(story_title)]
          next unless locations

          target = nil
          # Check if from_book_title is present before trying to use it
          if from_book_title && !from_book_title.strip.empty?
            target = locations.find { |loc| loc['parent_book_title'].casecmp(from_book_title).zero? }
          elsif locations.map { |loc| loc['url'] }.uniq.length == 1
            target = locations.first
          end
          add_backlink(backlinks, target['url'], source_doc, 'short_story') if target
        end
      end

      # Convert the nested hash back to the expected array structure
      final_backlinks = {}
      backlinks.each do |target_url, sources|
        final_backlinks[target_url] = sources.values
      end

      link_cache['backlinks'] = final_backlinks
    end

    def build_favorites_mentions_cache(site, link_cache, url_to_book_doc_map)
      Jekyll.logger.info 'LinkCacheGenerator:', 'Building favorites mentions cache...'
      favorites_mentions = link_cache['favorites_mentions']
      favorites_posts_to_books = link_cache['favorites_posts_to_books']
      books_cache = link_cache['books']
      return unless site.posts&.docs.is_a?(Array) && books_cache && !books_cache.empty?

      book_card_lookup_regex = /\{%\s*book_card_lookup\s+(?:title=)?(?:'([^']+)'|"([^"]+)"|(\S+))\s*.*?%\}/

      favorites_posts = site.posts.docs.select { |p| p.data.key?('is_favorites_list') }

      favorites_posts.each do |post|
        post.content.scan(book_card_lookup_regex).each do |match|
          # The title can be in one of three capture groups depending on quotes/variable
          title = match.compact.first
          next unless title && !title.strip.empty?

          normalized_title = TextProcessingUtils.normalize_title(title)
          book_locations = books_cache[normalized_title]
          next unless book_locations && !book_locations.empty?

          # Assume the first match is correct for simplicity. Ambiguity is handled by book_link.
          book_url = book_locations.first['url']
          next unless book_url

          # Populate the original map: book_url => [post]
          favorites_mentions[book_url] ||= []
          favorites_mentions[book_url] << post unless favorites_mentions[book_url].include?(post)

          # Populate the inverted map: post_url => [book_doc]
          book_doc = url_to_book_doc_map[book_url]
          if book_doc
            favorites_posts_to_books[post.url] ||= []
            favorites_posts_to_books[post.url] << book_doc unless favorites_posts_to_books[post.url].include?(book_doc)
          end
        end
      end
    end
  end
end
