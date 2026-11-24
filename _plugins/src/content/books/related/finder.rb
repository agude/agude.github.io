# frozen_string_literal: true

require_relative '../core/book_data_utils'
require_relative '../../related_candidates'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative '../../../infrastructure/page_url'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Related
      # Finds and ranks related books using a waterfall of criteria.
      #
      # This class handles the data retrieval logic for finding related books.
      # It does not produce any HTML output.
      #
      # @pipeline Fill up to the configured limit (default 3) in this order:
      #   nearby books in the same series, books by the same authors,
      #   forward-linked works, forward-linked series, backlink works,
      #   backlink series, then remaining books by date. Same-series books
      #   are selected by alternating before and after the current number, then
      #   displayed in number order. If the current number is unparseable,
      #   candidates are taken in number order. Work tiers combine
      #   book and short-story links. A short-story link targets its parent
      #   book URL, so mentions of that book and its stories share one score.
      #   Link tiers sort by count descending, direct-link position when present
      #   (otherwise earliest position) ascending, date descending, then title.
      # @gotcha HTML and Markdown share final selections by page URL and limit
      #   in `site.data['related_books_cache']`. The `:site, :post_read` hook
      #   clears this memo before each build.
      # @gotcha Collection-derived tiers skip the current page, its canonical
      #   URL, archived reviews, unpublished books, and future-dated books.
      #   The link tiers take documents directly from the link-cache graph.
      class Finder
        DEFAULT_MAX_BOOKS = 3
        LINK_TIERS = {
          mentioned_works: { cache_key: 'forward_links', entry_key: :target, types: %w[book short_story] },
          mentioned_series: { cache_key: 'forward_links', entry_key: :target, types: ['series'] },
          backlink_works: { cache_key: 'backlinks', entry_key: :source, types: %w[book short_story] },
          backlink_series: { cache_key: 'backlinks', entry_key: :source, types: ['series'] },
        }.freeze

        # @param site [Jekyll::Site] The Jekyll site object
        # @param page [Jekyll::Document, Jekyll::Page] The current page/document
        # @param max_books [Integer, nil] Maximum related books to return (default from config)
        def initialize(site, page = nil, max_books = nil)
          @site = site
          @page = page
          @max_books = max_books || @site&.config&.dig('display_limits', 'related_books') || DEFAULT_MAX_BOOKS
          @logs = String.new
        end

        def find
          return { logs: @logs, books: [] } unless prerequisites_met?
          return { logs: @logs, books: [] } unless cache_valid?

          results = @site.data['related_books_cache'] ||= {}
          results[[page_url, @max_books]] ||= select_books
        end

        private

        def select_books
          @candidate_books = []
          find_related_books
          final_books = Jekyll::Content::RelatedCandidates.limit(@candidate_books, @max_books)

          { logs: @logs, books: final_books }
        end

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
          LINK_TIERS.each_value { |tier| process_link_tier(**tier) }
          process_recent(books_by_date_desc)
        end

        def process_recent(books_by_date)
          selected_urls = Set.new(@candidate_books.map(&:url))
          return if selected_urls.size >= @max_books

          books_by_date.each do |book|
            next unless selected_urls.add?(book.url)

            @candidate_books << book
            break if selected_urls.size >= @max_books
          end
        end

        def build_exclusion_set
          urls = Set.new([page_url])
          urls.add(@page['canonical_url']) if @page['canonical_url']
          urls
        end

        def fetch_potential_books(urls_to_exclude)
          books = @site.collections['books'].docs
          Jekyll::Content::RelatedCandidates.select(books, urls_to_exclude, @site.time.to_i) do |book|
            book&.data && !book.data['canonical_url']
          end
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

        def process_link_tier(cache_key:, entry_key:, types:)
          current_urls = Set.new(@candidate_books.map(&:url))
          return unless current_urls.size < @max_books

          links = @site.data.dig('link_cache', cache_key, page_url) || []
          type_entries = links.select { |entry| types.include?(entry[:type]) }
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

Jekyll::Hooks.register :site, :post_read do |site|
  site.data.delete('related_books_cache')
end
