# _plugins/book_backlinks_tag.rb
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
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks (Tag Level) ---
      unless site && page &&
             site.collections.key?('books') &&
             page['url'] && !page['url'].to_s.strip.empty? &&
             page['title'] && !page['title'].to_s.strip.empty?

        missing_parts = []
        missing_parts << 'site object' unless site
        missing_parts << 'page object' unless page
        missing_parts << "site.collections['books']" unless site&.collections&.key?('books')
        unless page && page['url'] && !page['url'].to_s.strip.empty?
          missing_parts << "page['url'] (present and not empty)"
        end
        unless page && page['title'] && !page['title'].to_s.strip.empty?
          missing_parts << "page['title'] (present and not empty)"
        end

        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'BOOK_BACKLINKS_TAG',
          reason: "Tag prerequisites missing: #{missing_parts.join(', ')}.",
          identifiers: {
            PageURL: page ? (page['url'] || 'N/A') : 'N/A',
            PageTitle: page ? (page['title'] || 'N/A') : 'N/A'
          },
          level: :error
        )
      end
      # --- End Sanity Checks ---

      current_title_original = page['title']
      link_cache = site.data['link_cache'] || {}
      backlinks_cache = link_cache['backlinks'] || {}
      canonical_map = link_cache['url_to_canonical_map'] || {}
      book_families = link_cache['book_families'] || {}
      series_map = link_cache['series_map'] || {}

      # --- Identify all versions of this book using the new cache ---
      canonical_url = canonical_map[page['url']]
      return '' unless canonical_url # Exit if the current page isn't in the map.

      all_version_urls = Set.new(book_families[canonical_url] || [])

      # --- Gather and merge backlinks for all versions ---
      merged_backlinks = {}
      all_version_urls.each do |url|
        (backlinks_cache[url] || []).each do |entry|
          source_url = entry[:source].url
          merged_backlinks[source_url] = entry
        end
      end

      # --- NEW: Gather backlinks from series mentions ---
      current_series_name = page['series']
      if current_series_name && !current_series_name.strip.empty?
        normalized_series = TextProcessingUtils.normalize_title(current_series_name)
        books_in_series = series_map[normalized_series] || []
        books_in_series.each do |book_in_series|
          (backlinks_cache[book_in_series.url] || []).each do |entry|
            next unless entry[:type] == 'series'

            source_url = entry[:source].url
            # Don't overwrite a direct book link with a series link
            merged_backlinks[source_url] ||= entry
          end
        end
      end

      # --- Deduplicate sources based on their canonical URL, respecting link priority ---
      unique_canonical_sources = {}
      merged_backlinks.each_value do |entry|
        source_doc = entry[:source]
        source_canonical_url = canonical_map[source_doc.url] || source_doc.url

        existing_entry = unique_canonical_sources[source_canonical_url]

        priority_map = defined?(Jekyll::LinkCacheGenerator::LINK_TYPE_PRIORITY) ? Jekyll::LinkCacheGenerator::LINK_TYPE_PRIORITY : {}
        new_priority = priority_map[entry[:type]] || 0
        existing_priority = existing_entry ? (priority_map[existing_entry[:type]] || 0) : -1

        if new_priority >= existing_priority # Use >= to ensure at least one entry is kept
          unique_canonical_sources[source_canonical_url] = entry
        end
      end
      backlink_entries = unique_canonical_sources.values

      return '' if backlink_entries.empty?

      # Map to [sort_key, canonical_title, url, type] tuples for sorting.
      backlinks_data = backlink_entries.map do |entry|
        book_doc = entry[:source]
        source_canonical_url = canonical_map[book_doc.url] || book_doc.url
        next if source_canonical_url == canonical_url # Exclude self-references

        link_type = entry[:type]
        title = book_doc.data['title']
        next if title.nil? || title.strip.empty?

        sort_key = TextProcessingUtils.normalize_title(title, strip_articles: true)
        [sort_key, title, book_doc.url, link_type]
      end.compact

      # Sort by sort_key, then map to [canonical_title, url, type] tuples
      sorted_backlinks = backlinks_data.sort_by { |tuple| tuple[0] }
                                       .map { |tuple| [tuple[1], tuple[2], tuple[3]] }

      # --- Render Final HTML ---
      return '' if sorted_backlinks.empty?

      output = '<aside class="book-backlinks">'
      output << '<h2 class="book-backlink-section">'
      output << " Reviews that mention <span class=\"book-title\">#{CGI.escapeHTML(current_title_original)}</span>"
      output << '</h2>'
      output << '<ul class="book-backlink-list">'

      has_series_link = false # Flag to track if we need to show the note

      sorted_backlinks.each do |backlink_title, backlink_url, link_type|
        link_html = BookLinkUtils.render_book_link_from_data(backlink_title, backlink_url, context)

        indicator_html = ''
        if link_type == 'series'
          has_series_link = true # Set the flag
          # Add the title attribute for the tooltip
          indicator_html = '<sup class="series-mention-indicator" role="img" aria-label="Mentioned via series link" title="Mentioned via series link">†</sup>'
        end

        output << "<li class=\"book-backlink-item\" data-link-type=\"#{link_type}\">#{link_html}#{indicator_html}</li>"
      end

      output << '</ul>'

      # Conditionally add the explanatory note at the end
      if has_series_link
        output << '<p class="backlink-explanation"><sup>†</sup> <em>Mentioned via a link to the series.</em></p>'
      end

      output << '</aside>'
      output
    end
  end
end

Liquid::Template.register_tag('book_backlinks', Jekyll::BookBacklinksTag)
