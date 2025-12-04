# frozen_string_literal: true

require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'

module Jekyll
  module Books
    module Backlinks
      # Finds and processes backlinks for a book review page.
      #
      # Handles all data retrieval from caches, aggregation, deduplication,
      # and sorting of backlinks. Returns structured data without HTML.
      class Finder
        def initialize(context)
          @context = context
          @site = context.registers[:site]
          @page = context.registers[:page]
          @caches = fetch_caches
        end

        def find
          return validation_error_result if missing_prerequisites?

          canonical_url = @caches[:canonical_map][@page['url']]
          return { logs: '', backlinks: [] } unless canonical_url

          entries = gather_backlinks(canonical_url)
          return { logs: '', backlinks: [] } if entries.empty?

          sorted = sort_entries(entries, canonical_url)
          return { logs: '', backlinks: [] } if sorted.empty?

          { logs: '', backlinks: sorted }
        end

        private

        def fetch_caches
          # Use safe navigation for site/data in case site is nil (handled in validation)
          lc = @site&.data&.[]('link_cache') || {}
          {
            backlinks: lc['backlinks'] || {},
            canonical_map: lc['url_to_canonical_map'] || {},
            book_families: lc['book_families'] || {},
            series_map: lc['series_map'] || {}
          }
        end

        def missing_prerequisites?
          !(@site && @page && @site.collections.key?('books') &&
            present?(@page['url']) && present?(@page['title']))
        end

        def present?(val)
          !val.to_s.strip.empty?
        end

        def validation_error_result
          missing = collect_missing_prerequisites
          log_output = log_validation_failure(missing)
          { logs: log_output, backlinks: [] }
        end

        def collect_missing_prerequisites
          missing = []
          missing << 'site object' unless @site
          missing << 'page object' unless @page
          missing << "site.collections['books']" unless @site&.collections&.key?('books')
          missing << "page['url'] (present and not empty)" unless present?(@page&.[]('url'))
          missing << "page['title'] (present and not empty)" unless present?(@page&.[]('title'))
          missing
        end

        def log_validation_failure(missing)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: @context,
            tag_type: 'BOOK_BACKLINKS_TAG',
            reason: "Tag prerequisites missing: #{missing.join(', ')}.",
            identifiers: { PageURL: @page&.[]('url') || 'N/A', PageTitle: @page&.[]('title') || 'N/A' },
            level: :error
          )
        end

        def gather_backlinks(canonical_url)
          merged = {}
          # Direct versions
          (@caches[:book_families][canonical_url] || []).each do |url|
            (@caches[:backlinks][url] || []).each { |e| merged[e[:source].url] = e }
          end
          # Series mentions
          add_series_links(merged)
          # Deduplicate
          deduplicate(merged)
        end

        def add_series_links(merged)
          series = @page['series']
          return unless present?(series)

          norm_series = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(series)
          series_books = @caches[:series_map][norm_series] || []
          series_books.each { |book| add_series_backlinks_for_book(book, merged) }
        end

        def add_series_backlinks_for_book(book, merged)
          (@caches[:backlinks][book.url] || []).each do |e|
            merged[e[:source].url] ||= e if e[:type] == 'series'
          end
        end

        def deduplicate(merged)
          unique = {}
          prio_map = link_type_priority_map
          merged.each_value { |entry| update_unique_entry(unique, entry, prio_map) }
          unique.values
        end

        def link_type_priority_map
          defined?(Jekyll::Infrastructure::LinkCache::BacklinkBuilder::LINK_TYPE_PRIORITY) ? Jekyll::Infrastructure::LinkCache::BacklinkBuilder::LINK_TYPE_PRIORITY : {}
        end

        def update_unique_entry(unique, entry, prio_map)
          canon = @caches[:canonical_map][entry[:source].url] || entry[:source].url
          return if should_skip_entry?(unique[canon], entry, prio_map)

          unique[canon] = entry
        end

        def should_skip_entry?(existing, new_entry, prio_map)
          return false unless existing

          new_priority = prio_map[new_entry[:type]] || 0
          old_priority = prio_map[existing[:type]] || 0
          new_priority < old_priority
        end

        def sort_entries(entries, current_canon)
          sortable = build_sortable_entries(entries, current_canon)
          sorted = sortable.sort_by(&:first)
          sorted.map { |t| t[1..3] }
        end

        def build_sortable_entries(entries, current_canon)
          entries.map do |e|
            src = e[:source]
            src_canon = @caches[:canonical_map][src.url] || src.url
            next if src_canon == current_canon

            title = src.data['title']
            next unless present?(title)

            [Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title, strip_articles: true), title,
             src.url, e[:type]]
          end.compact
        end
      end
    end
  end
end
