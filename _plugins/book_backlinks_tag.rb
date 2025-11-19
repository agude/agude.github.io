# _plugins/book_backlinks_tag.rb
# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_link_util'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/text_processing_utils' # For sorting

module Jekyll
  class BookBacklinksTag < Liquid::Tag
    # Renders the list of books linking back to the current page.
    def render(context)
      BacklinksProcessor.new(context).process
    end
  end

  # Helper class to process and render backlinks
  class BacklinksProcessor
    def initialize(context)
      @context = context
      @site = context.registers[:site]
      @page = context.registers[:page]
      @caches = fetch_caches
    end

    def process
      return validation_error if missing_prerequisites?

      canonical_url = @caches[:canonical_map][@page['url']]
      return '' unless canonical_url

      entries = gather_backlinks(canonical_url)
      return '' if entries.empty?

      sorted = sort_entries(entries, canonical_url)
      return '' if sorted.empty?

      render_html(sorted)
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

    def validation_error
      missing = []
      missing << 'site object' unless @site
      missing << 'page object' unless @page
      missing << "site.collections['books']" unless @site&.collections&.key?('books')
      missing << "page['url'] (present and not empty)" unless present?(@page&.[]('url'))
      missing << "page['title'] (present and not empty)" unless present?(@page&.[]('title'))

      PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'BOOK_BACKLINKS_TAG',
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

      norm_series = TextProcessingUtils.normalize_title(series)
      (@caches[:series_map][norm_series] || []).each do |book|
        (@caches[:backlinks][book.url] || []).each do |e|
          merged[e[:source].url] ||= e if e[:type] == 'series'
        end
      end
    end

    def deduplicate(merged)
      unique = {}
      prio_map = defined?(Jekyll::LinkCacheGenerator::LINK_TYPE_PRIORITY) ? Jekyll::LinkCacheGenerator::LINK_TYPE_PRIORITY : {}

      merged.each_value do |entry|
        canon = @caches[:canonical_map][entry[:source].url] || entry[:source].url
        exist = unique[canon]

        new_p = prio_map[entry[:type]] || 0
        old_p = exist ? (prio_map[exist[:type]] || 0) : -1

        unique[canon] = entry if new_p >= old_p
      end
      unique.values
    end

    def sort_entries(entries, current_canon)
      entries.map do |e|
        src = e[:source]
        src_canon = @caches[:canonical_map][src.url] || src.url
        next if src_canon == current_canon

        title = src.data['title']
        next unless present?(title)

        [TextProcessingUtils.normalize_title(title, strip_articles: true), title, src.url, e[:type]]
      end.compact.sort_by(&:first).map { |t| t[1..3] }
    end

    def render_html(sorted)
      has_series = false
      list_items = sorted.map do |title, url, type|
        has_series = true if type == 'series'
        render_item(title, url, type)
      end.join

      build_container(list_items, has_series)
    end

    def render_item(title, url, type)
      link = BookLinkUtils.render_book_link_from_data(title, url, @context)
      indicator = type == 'series' ? series_indicator : ''
      "<li class=\"book-backlink-item\" data-link-type=\"#{type}\">#{link}#{indicator}</li>"
    end

    def build_container(list_items, has_series)
      title = CGI.escapeHTML(@page['title'])
      out = '<aside class="book-backlinks"><h2 class="book-backlink-section">' \
        " Reviews that mention <span class=\"book-title\">#{title}</span></h2>" \
        "<ul class=\"book-backlink-list\">#{list_items}</ul>"
      out << '<p class="backlink-explanation"><sup>†</sup> <em>Mentioned via a link to the series.</em></p>' if has_series
      out << '</aside>'
    end

    def series_indicator
      '<sup class="series-mention-indicator" role="img" aria-label="Mentioned via series link" ' \
        'title="Mentioned via series link">†</sup>'
    end
  end
end

Liquid::Template.register_tag('book_backlinks', Jekyll::BookBacklinksTag)
