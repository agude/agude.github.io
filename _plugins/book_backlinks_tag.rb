# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_link_util'
require_relative 'utils/backlink_utils'
require_relative 'utils/plugin_logger_utils'

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
          tag_type: "BOOK_BACKLINKS_TAG", # More specific tag type for the tag's own check
          reason: "Tag prerequisites missing: #{missing_parts.join(', ')}.",
          identifiers: {
            PageURL: page ? (page['url'] || 'N/A') : 'N/A',
            PageTitle: page ? (page['title'] || 'N/A') : 'N/A'
          },
          level: :error,
        )
      end
      # --- End Sanity Checks ---

      current_title_original = page['title'] # Keep original title for H2 display

      # --- Call Utility to Find Backlinks ---
      # BacklinkUtils now handles its own prerequisite logging and returns [] on failure.
      sorted_backlink_pairs = BacklinkUtils.find_book_backlinks(page, site, context)
      # --- End Call Utility ---


      # --- Render Final HTML ---
      if sorted_backlink_pairs.empty?
        return "" # Render nothing if no backlinks found (or if util logged an error and returned [])
      else
        # Build the HTML output string
        output = "<aside class=\"book-backlinks\">"

        # Construct the H2 tag
        output << "<h2 class=\"book-backlink-section\">"
        output << " Reviews that mention <span class=\"book-title\">#{CGI.escapeHTML(current_title_original)}</span>"
        output << "</h2>"

        output << "<ul class=\"book-backlink-list\">"

        # Iterate through the sorted [title, url] pairs returned by the utility
        sorted_backlink_pairs.each do |backlink_title, backlink_url|
          # Call the NEW BookLinkUtils utility with the title and URL
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
