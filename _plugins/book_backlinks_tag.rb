# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'liquid_utils'       # Still need for log_failure (initial checks)
require_relative 'utils/book_link_util' # Need for rendering the links
require_relative 'utils/backlink_utils' # Require the backlink util

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

      # --- Basic Sanity Checks ---
      unless site && page && site.collections.key?('books') && page['url'] && page['title']
        # Use LiquidUtils to log failure (returns HTML comment or empty string)
        return LiquidUtils.log_failure(
          context: context,
          tag_type: "BOOK_BACKLINKS",
          reason: "Tag prerequisites missing: context, collection, URL, or title",
          identifiers: { URL: page ? page['url'] : 'N/A', Title: page ? page['title'] : 'N/A' }
        )
      end
      # Keep original title for H2 display
      current_title_original = page['title']
      # --- End Sanity Checks ---


      # --- Call Utility to Find Backlinks ---
      # Utility now returns sorted [title, url] pairs
      sorted_backlink_pairs = BacklinkUtils.find_book_backlinks(page, site, context)
      # --- End Call Utility ---


      # --- Render Final HTML ---
      if sorted_backlink_pairs.empty?
        return "" # Render nothing if no backlinks found
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

        return output # Return the complete HTML string
      end
    end # End render

  end # End class
end # End module

Liquid::Template.register_tag('book_backlinks', Jekyll::BookBacklinksTag)
