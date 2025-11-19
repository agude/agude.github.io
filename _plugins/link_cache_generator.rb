# frozen_string_literal: true

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
      Jekyll.logger.info 'LinkCacheGenerator:', 'Building link cache...'
      @link_cache = initialize_cache
      site.data['mention_tracker'] ||= {}

      process_pages(site)
      url_to_book_doc_map = process_books(site)

      build_caches(site, url_to_book_doc_map)

      site.data['link_cache'] = @link_cache
      Jekyll.logger.info 'LinkCacheGenerator:', 'Cache built successfully.'
    end

    private

    def build_caches(site, url_to_book_doc_map)
      ShortStoryBuilder.new(site, @link_cache).build

      maps = CacheMaps.new(@link_cache)
      LinkValidator.new(site, maps).validate
      BacklinkBuilder.new(site, @link_cache, maps).build

      FavoritesManager.new(site, @link_cache, url_to_book_doc_map).build
    end

    def initialize_cache
      {
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
    end

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

      if page.data['sidebar_include'] == true && !page.url.include?('page')
        @link_cache['sidebar_nav'] << page
      end
      @link_cache['books_topbar_nav'] << page if page.data['book_topbar_include'] == true
    end

    def cache_linkable_page(page)
      title = page.data['title']
      return unless title && !title.strip.empty?

      if page.data['layout'] == 'author_page'
        cache_author_page(page)
      elsif page.data['layout'] == 'series_page'
        cache_series_page(page)
      end
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

      author_cache[TextProcessingUtils.normalize_title(canonical_title)] = page_data

      pen_names = FrontMatterUtils.get_list_from_string_or_array(page.data['pen_names'])
      pen_names.each do |pen_name|
        normalized = TextProcessingUtils.normalize_title(pen_name)
        author_cache[normalized] = page_data unless normalized.empty?
      end
    end

    def cache_series_page(page)
      title = page.data['title'].strip
      normalized = TextProcessingUtils.normalize_title(title)
      @link_cache['series'][normalized] = { 'url' => page.url, 'title' => title }
    end

    def cache_book_page(book)
      title = book.data['title'].strip
      normalized = TextProcessingUtils.normalize_title(title)

      book_data = {
        'url' => book.url,
        'title' => title,
        'authors' => FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors']),
        'canonical_url' => book.data['canonical_url']
      }

      @link_cache['books'][normalized] ||= []
      @link_cache['books'][normalized] << book_data

      update_book_families(book)
    end

    def update_book_families(book)
      canonical_url = book.data['canonical_url'] || book.url
      @link_cache['url_to_canonical_map'][book.url] = canonical_url
      @link_cache['book_families'][canonical_url] << book.url
    end

    def cache_book_in_series_map(book)
      series_name = book.data['series']
      return unless series_name && !series_name.strip.empty?

      normalized = TextProcessingUtils.normalize_title(series_name)
      @link_cache['series_map'][normalized] ||= []
      @link_cache['series_map'][normalized] << book
    end
  end

  # --- Helper Classes ---

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

      normalized = TextProcessingUtils.normalize_title(title)
      data = {
        'title' => title,
        'parent_book_title' => parent_title,
        'url' => parent_url,
        'slug' => TextProcessingUtils.slugify(title)
      }
      @cache[normalized] ||= []
      @cache[normalized] << data
    end
  end

  class LinkValidator
    def initialize(site, maps)
      @site = site
      @maps = maps
    end

    def validate
      found_raw_links = {}
      (@site.documents + @site.pages).each do |doc|
        check_doc(doc, found_raw_links)
      end
      raise_error(found_raw_links) if found_raw_links.any?
    end

    private

    def check_doc(doc, found_raw_links)
      return unless doc.respond_to?(:content) && doc.content

      check_regex(doc, /\[[^\]]+\]\(([^)\s]+)/, 'Markdown', found_raw_links)
      check_regex(doc, /<a\s+(?:[^>]*?\s+)?href="([^"]+)"/, 'HTML', found_raw_links)
    end

    def check_regex(doc, regex, type, found_raw_links)
      doc.content.scan(regex).each do |match|
        url = match.first&.split('#')&.first
        if url && known_url?(url)
          found_raw_links[doc.relative_path] ||= []
          found_raw_links[doc.relative_path] << "#{type}: #{match.first}"
        end
      end
    end

    def known_url?(url)
      @maps.books.key?(url) || @maps.authors.key?(url) || @maps.series.key?(url)
    end

    def raise_error(found_raw_links)
      msg = 'Found raw Markdown/HTML links. Please convert them to use custom tags ' \
        "('book_link', 'author_link', 'series_link').\n".dup
      found_raw_links.each do |path, links|
        msg << "  - In file '#{path}':\n"
        links.uniq.each { |link| msg << "    - Found: #{link}\n" }
      end
      raise Jekyll::Errors::FatalException, msg
    end
  end

  class BacklinkBuilder
    LINK_TYPE_PRIORITY = { 'book' => 3, 'short_story' => 2, 'series' => 1 }.freeze

    def initialize(site, link_cache, maps)
      @site = site
      @link_cache = link_cache
      @maps = maps
      @backlinks = Hash.new { |h, k| h[k] = {} }
    end

    def build
      return unless @link_cache['books']&.any? && @site.collections.key?('books')

      @site.collections['books'].docs.each do |source_doc|
        scan_doc(source_doc)
      end

      finalize_backlinks
    end

    private

    def scan_doc(doc)
      return unless doc.respond_to?(:content) && doc.content && !doc.content.empty?

      scan_book_links(doc)
      scan_series_links(doc)
      scan_short_story_links(doc)
    end

    def scan_book_links(doc)
      doc.content.scan(/\{%\s*book_link\s+(?:'([^']+)'|"([^"]+)")/).each do |match|
        title = match.compact.first
        locs = @link_cache['books'][TextProcessingUtils.normalize_title(title)]
        add_backlink(locs.first['url'], doc, 'book') if locs
      end
    end

    def scan_series_links(doc)
      doc.content.scan(/\{%\s*series_link\s+(?:'([^']+)'|"([^"]+)")/).each do |match|
        title = match.compact.first
        books = @link_cache['series_map'][TextProcessingUtils.normalize_title(title)]
        books&.each { |book| add_backlink(book.url, doc, 'series') }
      end
    end

    def scan_short_story_links(doc)
      regex = /\{%\s*short_story_link\s+["'](.+?)["'](?:\s+from_book=["'](.+?)["'])?\s*%\}/
      doc.content.scan(regex).each do |match|
        process_short_story_match(match, doc)
      end
    end

    def process_short_story_match(match, doc)
      title, from_book = match
      locs = @link_cache['short_stories'][TextProcessingUtils.normalize_title(title)]
      return unless locs

      target = find_target_story(locs, from_book)
      add_backlink(target['url'], doc, 'short_story') if target
    end

    def find_target_story(locs, from_book)
      if from_book && !from_book.strip.empty?
        locs.find { |l| l['parent_book_title'].casecmp(from_book).zero? }
      elsif locs.map { |l| l['url'] }.uniq.length == 1
        locs.first
      end
    end

    def add_backlink(target_url, source_doc, type)
      return if source_doc.url == target_url

      existing = @backlinks[target_url][source_doc.url]
      new_p = LINK_TYPE_PRIORITY[type]

      return unless existing.nil? || new_p > LINK_TYPE_PRIORITY[existing[:type]]

      @backlinks[target_url][source_doc.url] = { source: source_doc, type: type }
    end

    def finalize_backlinks
      final = {}
      @backlinks.each { |target, sources| final[target] = sources.values }
      @link_cache['backlinks'] = final
    end
  end

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
      normalized = TextProcessingUtils.normalize_title(title)
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
