# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_link_util'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/text_processing_utils' # For sorting

module Jekyll
  class BookBacklinksTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      # No arguments needed for this tag
    end

    # Renders the list of books linking back to the current page.
    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks (Tag Level) ---
      unless site && page && \
          site.collections.key?('books') && \
          page['url'] && !page['url'].to_s.strip.empty? && \
          page['title'] && !page['title'].to_s.strip.empty?

        missing_parts = []
        missing_parts << "site object" unless site
        missing_parts << "page object" unless page
        missing_parts << "site.collections['books']" unless site&.collections&.key?('books')
        missing_parts << "page['url'] (present and not empty)" unless page && page['url'] && !page['url'].to_s.strip.empty?
        missing_parts << "page['title'] (present and not empty)" unless page && page['title'] && !page['title'].to_s.strip.empty?

        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_BACKLINKS_TAG",
          reason: "Tag prerequisites missing: #{missing_parts.join(', ')}.",
          identifiers: {
            PageURL: page ? (page['url'] || 'N/A') : 'N/A',
            PageTitle: page ? (page['title'] || 'N/A') : 'N/A'
          },
          level: :error,
        )
      end
      # --- End Sanity Checks ---

      current_title_original = page['title']
      backlinks_cache = site.data.dig('link_cache', 'backlinks') || {}
      backlink_entries = backlinks_cache[page['url']] || []

      return "" if backlink_entries.empty?

      # --- MODIFIED LOGIC: Process the new data structure ---
      # Map to [sort_key, canonical_title, url] tuples for sorting.
      # The logic is now self-contained in the tag instead of a separate util.
      backlinks_data = backlink_entries.map do |entry|
        book_doc = entry[:source]
        title = book_doc.data['title']
        next if title.nil? || title.strip.empty? # Skip if backlinking doc has no title

        sort_key = TextProcessingUtils.normalize_title(title, strip_articles: true)
        [sort_key, title, book_doc.url]
      end.compact

      # Sort by sort_key, then map to [canonical_title, url] pairs
      sorted_backlink_pairs = backlinks_data.sort_by { |tuple| tuple[0] }
        .map { |tuple| [tuple[1], tuple[2]] }

      # --- Render Final HTML ---
      if sorted_backlink_pairs.empty?
        return ""
      else
        output = "<aside class=\"book-backlinks\">"
        output << "<h2 class=\"book-backlink-section\">"
        output << " Reviews that mention <span class=\"book-title\">#{CGI.escapeHTML(current_title_original)}</span>"
        output << "</h2>"
        output << "<ul class=\"book-backlink-list\">"

        # Iterate through the sorted [title, url] pairs
        sorted_backlink_pairs.each do |backlink_title, backlink_url|
          link_html = BookLinkUtils.render_book_link_from_data(backlink_title, backlink_url, context)
          output << "<li class=\"book-backlink-item\">#{link_html}</li>"
        end

        output << "</ul>"
        output << "</aside>"
        return output
      end
    end # End render

  end # End class
end # End module

Liquid::Template.register_tag('book_backlinks', Jekyll::BookBacklinksTag)
