# frozen_string_literal: true

require_relative '../core/book_data_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative '../../../infrastructure/page_url'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Related
      # Finds and ranks related books using a waterfall of criteria.
      #
      # Priority order: series → author → mentioned works (books + short stories) →
      # mentioned series → backlink works → backlink series → recent.
      #
      # Books and short stories compete by score within the same tier, allowing
      # a frequently-mentioned short story to outrank a rarely-mentioned book.
      # Tiebreaker when scores match: position asc, date desc, title asc.
      #
      # This class handles the data retrieval logic for finding related books.
      # It does not produce any HTML output.
      #
      class Finder
        DEFAULT_MAX_BOOKS = 3

        # @param site [Jekyll::Site] The Jekyll site object
        # @param page [Jekyll::Document, Jekyll::Page] The current page/document
        # @param max_books [Integer, nil] Maximum related books to return (default from config)
        def initialize(site, page = nil, max_books = nil)
          @site = site
          @page = page
          @max_books = max_books || @site&.config&.dig('display_limits', 'related_books') || DEFAULT_MAX_BOOKS
          @logs = String.new
          @candidate_books = []
        end

        def find
          return { logs: @logs, books: [] } unless prerequisites_met?
          return { logs: @logs, books: [] } unless cache_valid?

          find_related_books
          final_books = @candidate_books.uniq(&:url).slice(0, @max_books)

          { logs: @logs, books: final_books }
        end

        private

        def page_url
          Jekyll::Infrastructure::PageUrl.fetch(@page)
        end

        def prerequisites_met?
          if @site && @page && @site.collections.key?('books') && page_url
            true
          else
            log_missing_prerequisites
            false
          end
        end

        def log_missing_prerequisites
          missing = collect_missing_prerequisites
          @logs << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: log_context,
            tag_type: 'RELATED_BOOKS',
            reason: "Missing prerequisites: #{missing.join(', ')}.",
            identifiers: { PageURL: page_url || 'N/A' },
            level: :error,
          )
        end

        def collect_missing_prerequisites
          missing = []
          missing << 'site object' unless @site
          missing << 'page object' unless @page
          missing << "site.collections['books']" unless @site&.collections&.key?('books')
          missing << 'page.url' unless page_url
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
          @logs << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: log_context,
            tag_type: 'RELATED_BOOKS',
            reason: 'Link cache is missing. Ensure Jekyll::Infrastructure::LinkCacheGenerator is running.',
            identifiers: { PageURL: page_url },
            level: :error,
          )
        end

        def find_related_books
          urls_to_exclude = build_exclusion_set
          all_potential_books = fetch_potential_books(urls_to_exclude)
          books_by_date_desc = all_potential_books.sort_by(&:date).reverse

          # Waterfall priority order — each tier fills slots not claimed by earlier tiers.
          # Works tiers combine books and short stories, sorted by count (position/date/title tiebreaker).
          process_series(all_potential_books)
          process_authors(books_by_date_desc)
          process_link_tier('forward_links', :target, %w[book short_story])
          process_link_tier('forward_links', :target, 'series')
          process_link_tier('backlinks', :source, %w[book short_story])
          process_link_tier('backlinks', :source, 'series')
          process_recent(books_by_date_desc)
        end

        def build_exclusion_set
          urls = Set.new([page_url])
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
          normalized = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(series)
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
          @logs << Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: log_context,
            tag_type: 'RELATED_BOOKS_SERIES',
            reason: "Current page has unparseable book_number ('#{@page['book_number']}'). " \
                    'Using all series books sorted by number.',
            identifiers: { PageURL: page_url, Series: series },
            level: :info,
          )
        end

        # Builds a minimal context-like object for PluginLoggerUtils.
        def log_context
          page = @page
          site = @site
          Object.new.tap do |ctx|
            ctx.define_singleton_method(:registers) { { site: site, page: page } }
          end
        end

        def select_series_candidates(series_books, current_num)
          preceding, succeeding = neighboring_series_books(series_books, current_num)
          selected = interleave_series_books(preceding, succeeding)
          @candidate_books.concat(selected.sort_by { |book| parse_book_num(book) })
        end

        def neighboring_series_books(series_books, current_num)
          parsed = series_books.map { |b| { doc: b, num: parse_book_num(b) } }
                               .reject { |b| b[:num] == Float::INFINITY }
          preceding = parsed.select { |b| b[:num] < current_num }
                            .sort_by { |b| -b[:num] }
                            .map { |b| b[:doc] }
          succeeding = parsed.select { |b| b[:num] > current_num }
                             .sort_by { |b| b[:num] }
                             .map { |b| b[:doc] }
          [preceding, succeeding]
        end

        def interleave_series_books(preceding, succeeding)
          selected = []
          while selected.length < @max_books && (preceding.any? || succeeding.any?)
            selected << preceding.shift unless preceding.empty?
            selected << succeeding.shift if selected.length < @max_books && !succeeding.empty?
          end
          selected
        end

        def process_authors(books_by_date)
          current_urls = Set.new(@candidate_books.map(&:url))
          return unless current_urls.size < @max_books

          current_authors = parse_authors(@page['book_authors'])
          return unless current_authors.any?

          author_books = find_author_books(books_by_date, current_authors, current_urls)
          @candidate_books.concat(author_books)
        end

        def find_author_books(books_by_date, current_authors, current_urls)
          books_by_date.select do |book|
            next if current_urls.include?(book.url)

            book_authors = parse_authors(book.data['book_authors'])
            current_authors.intersect?(book_authors)
          end
        end

        def process_link_tier(cache_key, entry_key, link_type)
          link_types = Array(link_type)
          current_urls = Set.new(@candidate_books.map(&:url))
          return unless current_urls.size < @max_books

          links = @site.data.dig('link_cache', cache_key, page_url) || []
          type_entries = links.select { |entry| link_types.include?(entry[:type]) }
          sorted_entries = sort_link_entries(type_entries, entry_key)

          sorted_entries.each do |entry|
            break if current_urls.size >= @max_books

            book = entry[entry_key]
            next if current_urls.include?(book.url)

            @candidate_books << book
            current_urls.add(book.url)
          end
        end

        def sort_link_entries(entries, entry_key)
          entries.sort_by do |entry|
            book = entry[entry_key]
            # Sort by: count desc, position asc (earlier better), date desc, title asc
            # Prefer direct_min_position (from book/short_story links) over min_position (includes series)
            position = entry[:direct_min_position] || entry[:min_position] || 100
            count = entry[:count] || 0
            [-count, position, -book.date.to_i, book.data['title'].to_s.downcase]
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
          Jekyll::Infrastructure::FrontMatterUtils.get_list_from_string_or_array(field)
                                                  .map(&:strip)
                                                  .map(&:downcase)
                                                  .reject(&:empty?)
        end

        def parse_book_num(obj)
          data = obj.is_a?(Jekyll::Document) || obj.is_a?(Jekyll::Page) ? obj.data : obj
          Jekyll::Books::Core::BookDataUtils.parse_book_number(data['book_number'])
        end
      end
    end
  end
end
