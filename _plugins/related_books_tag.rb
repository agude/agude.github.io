# frozen_string_literal: true

# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/front_matter_utils'
require_relative 'utils/book_list_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Displays related book reviews based on series, author, and recency.
  #
  # Shows books from the same series, by the same authors, or recent reviews
  # to provide contextual recommendations.
  #
  # Usage in Liquid templates:
  #   {% related_books %}
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      finder = RelatedBooksFinder.new(context, @max_books)
      finder.render
    end
  end

  # Helper class that finds and ranks related books for display.
  #
  # Implements the logic for selecting related books based on series
  # membership, shared authors, and publication date.
  class RelatedBooksFinder
    def initialize(context, max_books)
      @context = context
      @max_books = max_books
      @site = context.registers[:site]
      @page = context.registers[:page]
      @logs = String.new
      @candidate_books = []
    end

    def render
      return @logs unless prerequisites_met?
      return @logs unless cache_valid?

      find_related_books
      render_output
    end

    private

    def prerequisites_met?
      if @site && @page && @site.collections.key?('books') && @page['url']
        true
      else
        log_missing_prerequisites
        false
      end
    end

    def log_missing_prerequisites
      missing = collect_missing_prerequisites
      @logs << PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'RELATED_BOOKS',
        reason: "Missing prerequisites: #{missing.join(', ')}.",
        identifiers: { PageURL: @page ? @page['url'] : 'N/A' },
        level: :error
      )
    end

    def collect_missing_prerequisites
      missing = []
      missing << 'site object' unless @site
      missing << 'page object' unless @page
      missing << "site.collections['books']" unless @site&.collections&.key?('books')
      missing << "page['url']" unless @page && @page['url']
      missing
    end

    def cache_valid?
      if @site.data['link_cache'] && @site.data['link_cache']['series_map']
        true
      else
        log_missing_cache
        false
      end
    end

    def log_missing_cache
      @logs << PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'RELATED_BOOKS',
        reason: 'Link cache is missing. Ensure LinkCacheGenerator is running.',
        identifiers: { PageURL: @page['url'] },
        level: :error
      )
    end

    def find_related_books
      urls_to_exclude = build_exclusion_set
      all_potential_books = fetch_potential_books(urls_to_exclude)
      books_by_date_desc = all_potential_books.sort_by(&:date).reverse

      process_series(all_potential_books)
      process_authors(books_by_date_desc)
      process_recent(books_by_date_desc)
    end

    def build_exclusion_set
      urls = Set.new([@page['url']])
      urls.add(@page['canonical_url']) if @page['canonical_url']&.start_with?('/')
      urls
    end

    def fetch_potential_books(urls_to_exclude)
      now_unix = Time.now.to_i
      @site.collections['books'].docs.select do |book|
        valid_potential_book?(book, urls_to_exclude, now_unix)
      end.compact
    end

    def valid_potential_book?(book, urls_to_exclude, now_unix)
      return false unless book&.data
      return false if book.data['published'] == false
      return false if book.data['canonical_url']&.start_with?('/')
      return false if urls_to_exclude.include?(book.url)
      return false unless book.date

      book.date.to_time.to_i <= now_unix
    end

    def process_series(all_books)
      series = @page['series']
      return if series.to_s.strip.empty?

      series_books = find_series_books(all_books, series)
      return unless series_books.any?

      add_series_candidates(series_books, series)
    end

    def find_series_books(all_books, series)
      normalized = TextProcessingUtils.normalize_title(series)
      cache = @site.data['link_cache']['series_map']
      cached_urls = Set.new((cache[normalized] || []).map(&:url))
      all_books.select { |b| cached_urls.include?(b.url) }
    end

    def add_series_candidates(series_books, series)
      current_num = parse_book_num(@page)
      if current_num == Float::INFINITY
        log_unparseable_number(series)
        fallback = series_books.sort_by { |b| parse_book_num(b) }
        @candidate_books.concat(fallback)
      else
        select_series_candidates(series_books, current_num)
      end
    end

    def log_unparseable_number(series)
      @logs << PluginLoggerUtils.log_liquid_failure(
        context: @context,
        tag_type: 'RELATED_BOOKS_SERIES',
        reason: "Current page has unparseable book_number ('#{@page['book_number']}'). " \
                'Using all series books sorted by number.',
        identifiers: { PageURL: @page['url'], Series: series },
        level: :info
      )
    end

    def select_series_candidates(series_books, current_num)
      preceding, succeeding = partition_series_books(series_books, current_num)
      selected = interleave_books(preceding, succeeding)
      @candidate_books.concat(selected.sort_by { |b| parse_book_num(b) })
    end

    def partition_series_books(series_books, current_num)
      parsed = series_books.map { |b| { doc: b, num: parse_book_num(b) } }
                           .reject { |b| b[:num] == Float::INFINITY }

      preceding = extract_preceding_books(parsed, current_num)
      succeeding = extract_succeeding_books(parsed, current_num)
      [preceding, succeeding]
    end

    def extract_preceding_books(parsed, current_num)
      parsed.select { |b| b[:num] < current_num }
            .sort_by { |b| -b[:num] }
            .map { |b| b[:doc] }
    end

    def extract_succeeding_books(parsed, current_num)
      parsed.select { |b| b[:num] > current_num }
            .sort_by { |b| b[:num] }
            .map { |b| b[:doc] }
    end

    def interleave_books(preceding, succeeding)
      selected = []
      idx_pre = 0
      idx_succ = 0

      loop do
        break if selected.length >= @max_books || exhausted_both_lists?(idx_pre, preceding, idx_succ, succeeding)

        idx_pre = add_from_list(selected, preceding, idx_pre)
        break if selected.length >= @max_books

        idx_succ = add_from_list(selected, succeeding, idx_succ)
      end
      selected
    end

    def exhausted_both_lists?(idx_pre, preceding, idx_succ, succeeding)
      idx_pre >= preceding.length && idx_succ >= succeeding.length
    end

    def add_from_list(selected, list, index)
      if index < list.length
        selected << list[index]
        index + 1
      else
        index
      end
    end

    def process_authors(books_by_date)
      return unless @candidate_books.uniq(&:url).length < @max_books

      current_authors = parse_authors(@page['book_authors'])
      return unless current_authors.any?

      author_books = find_author_books(books_by_date, current_authors)
      @candidate_books.concat(author_books)
    end

    def find_author_books(books_by_date, current_authors)
      current_urls = Set.new(@candidate_books.map(&:url))
      books_by_date.select do |book|
        next if current_urls.include?(book.url)

        book_authors = parse_authors(book.data['book_authors'])
        current_authors.intersect?(book_authors)
      end
    end

    def process_recent(books_by_date)
      needed = @max_books - @candidate_books.uniq(&:url).length
      return if needed <= 0

      current_urls = Set.new(@candidate_books.map(&:url))
      books_by_date.each do |book|
        break if needed <= 0
        next if current_urls.include?(book.url)

        @candidate_books << book
        current_urls.add(book.url)
        needed -= 1
      end
    end

    def parse_authors(field)
      FrontMatterUtils.get_list_from_string_or_array(field)
                      .map(&:strip)
                      .map(&:downcase)
                      .reject(&:empty?)
    end

    def parse_book_num(obj)
      data = obj.is_a?(Jekyll::Document) || obj.is_a?(Jekyll::Page) ? obj.data : obj
      BookListUtils.__send__(:_parse_book_number, data['book_number'])
    end

    def render_output
      final_books = @candidate_books.uniq(&:url).slice(0, @max_books)
      return @logs if final_books.empty?

      @logs + build_related_books_html(final_books)
    end

    def build_related_books_html(final_books)
      output = String.new("<aside class=\"related\">\n")
      output << "  <h2>Related Books</h2>\n"
      output << "  <div class=\"card-grid\">\n"
      final_books.each { |book| output << BookCardUtils.render(book, @context) << "\n" }
      output << "  </div>\n"
      output << '</aside>'
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
