# _plugins/book_backlinks_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'liquid_utils'

module Jekyll
  class BookBacklinksTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      # No arguments needed for this tag
    end

    # Helper method to create a sortable key from a title
    # Lowercases, removes leading articles, strips whitespace.
    private def create_sort_key(title)
      return "" if title.nil?
      key = title.downcase
      # Remove leading articles "the ", "a ", "an "
      key = key.sub(/^the\s+/, '')
      key = key.sub(/^an?\s+/, '') # Handles 'a' or 'an'
      key.strip
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
           reason: "Missing context, collection, URL, or title",
           identifiers: { URL: page ? page['url'] : 'N/A', Title: page ? page['title'] : 'N/A' }
         )
      end
      current_url = page['url'].downcase.strip
      current_title_downcased = page['title'].downcase.strip # Use downcased title for matching
      current_title_original = page['title'] # Keep original case for H2 display
      # --- End Sanity Checks ---


      # --- Prepare Search Patterns (matching the include's logic) ---
      # Pattern 1: Rendered HTML link URL (href attribute)
      # Match the URL provided by Jekyll's page data
      html_pattern = "href=\"#{CGI.escapeHTML(page['url'])}\""

      # Patterns 2 & 3: Raw Liquid tag content (case-insensitive title match)
      # Check for `book_link "Title"` or `book_link 'Title'` within the content
      title_dq = "\"#{current_title_downcased}\""
      title_sq = "'#{current_title_downcased}'"
      # Check variations: tag name + quoted title, and full liquid tag syntax
      markdown_pattern_dq_base = "book_link #{title_dq}"
      markdown_pattern_sq_base = "book_link #{title_sq}"
      markdown_pattern_dq_liquid = "{% book_link #{title_dq}" # Check with opening delimiter
      markdown_pattern_sq_liquid = "{% book_link #{title_sq}" # Check with opening delimiter
      # --- End Search Patterns ---


      # --- Iterate and Collect Backlinks ---
      # Store as [sort_key, original_title] pairs
      backlinks_data = []

      site.collections['books'].docs.each do |book|
        book_url = book.url&.downcase&.strip
        original_title = book.data['title'] # Keep original case for display/linking

        # Skip self-references
        next if book_url == current_url

        # Skip documents explicitly marked as unpublished in front matter
        next if book.data['published'] == false

        # Skip if the book has no title (can't be linked to by title)
        next if original_title.nil? || original_title.strip.empty?

        # Get content, skip if nil
        book_content = book.content
        next if book_content.nil?

        # Normalize content for searching (downcase, replace newlines)
        normalized_content = book_content.downcase.gsub("\n", " ")

        # --- Perform Checks ---
        found_link = false
        # Check 1: Rendered HTML link (compare downcased pattern)
        if normalized_content.include?(html_pattern.downcase)
          found_link = true
        # Check 2: Raw Liquid tag (double quotes) - check base and full liquid tag
        elsif normalized_content.include?(markdown_pattern_dq_base) || normalized_content.include?(markdown_pattern_dq_liquid)
          found_link = true
        # Check 3: Raw Liquid tag (single quotes) - check base and full liquid tag
        elsif normalized_content.include?(markdown_pattern_sq_base) || normalized_content.include?(markdown_pattern_sq_liquid)
          found_link = true
        end
        # --- End Checks ---

        # Add [sort_key, original_title] pair if a link was found
        if found_link
          sort_key = create_sort_key(original_title)
          backlinks_data << [sort_key, original_title]
        end
      end
      # --- End Iteration ---


      # --- Sort and Render Final HTML ---
      if backlinks_data.empty?
        return "" # Render nothing if no backlinks
      else
        # Sort the array of pairs based on the first element (the sort_key)
        # Then extract just the original titles in the sorted order
        # Use uniq to remove potential duplicates if a page somehow links twice
        sorted_titles = backlinks_data.sort_by { |pair| pair[0] }.map { |pair| pair[1] }.uniq

        # Build the HTML output string
        output = "<aside class=\"book-backlinks\">"

        # Construct the H2 tag without the ID attribute
        output << "<h2 class=\"book-backlink-section\">" # Removed ID attribute
        output << " Reviews that mention <span class=\"book-title\">#{CGI.escapeHTML(current_title_original)}</span>"
        output << "</h2>" # Close H2 tag

        output << "<ul class=\"book-backlink-list\">"

        sorted_titles.each do |backlink_title|
          # Call the utility function to generate the link HTML for each backlink
          link_html = LiquidUtils.render_book_link(backlink_title, context)
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
