# _plugins/utils/backlink_utils.rb
require 'jekyll'
require 'cgi'
require_relative '../liquid_utils' # For normalize_title, log_failure

module BacklinkUtils

  # Finds books in the 'books' collection that link back to the current_page.
  # Returns a list of original book titles, sorted alphabetically (ignoring articles).
  #
  # @param current_page [MockDocument, Jekyll::Page, Jekyll::Document] The page to find backlinks for.
  # @param site [MockSite, Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The current Liquid context (needed for logging).
  # @return [Array<String>] A sorted list of original book titles linking back.
  def self.find_book_backlinks(current_page, site, context)
    # --- Basic Sanity Checks (moved from tag, util needs context for logging) ---
    unless site && current_page && site.collections.key?('books') && current_page['url'] && current_page['title']
      # Log failure if essential data is missing for the operation
      LiquidUtils.log_failure(
        context: context, # Pass context for logging
        tag_type: "BACKLINK_UTIL", # Log source is now the utility
        reason: "Missing site, current_page, books collection, URL, or title for backlink search",
        identifiers: { URL: current_page ? current_page['url'] : 'N/A', Title: current_page ? current_page['title'] : 'N/A' }
      )
      return [] # Return empty list if setup is invalid
    end
    # --- End Sanity Checks ---

    current_url = current_page['url'].downcase.strip
    current_title_downcased = current_page['title'].downcase.strip # Use downcased title for matching

    # --- Prepare Search Patterns ---
    html_pattern = "href=\"#{CGI.escapeHTML(current_page['url'])}\"" # Use original URL from page data
    title_dq = "\"#{current_title_downcased}\""
    title_sq = "'#{current_title_downcased}'"
    markdown_pattern_dq_base = "book_link #{title_dq}"
    markdown_pattern_sq_base = "book_link #{title_sq}"
    markdown_pattern_dq_liquid = "{% book_link #{title_dq}"
    markdown_pattern_sq_liquid = "{% book_link #{title_sq}"
    # --- End Search Patterns ---

    # --- Iterate and Collect Backlinks ---
    backlinks_data = [] # Store as [sort_key, original_title] pairs

    site.collections['books'].docs.each do |book|
      book_url = book.url&.downcase&.strip
      original_title = book.data['title'] # Keep original case for display/linking

      # Skip self-references
      next if book_url == current_url
      # Skip unpublished
      next if book.data['published'] == false
      # Skip if book has no title
      next if original_title.nil? || original_title.strip.empty?
      # Skip if book has no content
      book_content = book.content
      next if book_content.nil?

      # Normalize content for searching
      normalized_content = book_content.downcase.gsub("\n", " ")

      # --- Perform Checks ---
      found_link = false
      if normalized_content.include?(html_pattern.downcase)
        found_link = true
      elsif normalized_content.include?(markdown_pattern_dq_base) || normalized_content.include?(markdown_pattern_dq_liquid)
        found_link = true
      elsif normalized_content.include?(markdown_pattern_sq_base) || normalized_content.include?(markdown_pattern_sq_liquid)
        found_link = true
      end
      # --- End Checks ---

      if found_link
        sort_key = _create_sort_key(original_title)
        backlinks_data << [sort_key, original_title]
      end
    end
    # --- End Iteration ---

    # --- Sort and Return Titles ---
    # Sort by sort_key, map to original title, remove duplicates
    sorted_titles = backlinks_data.sort_by { |pair| pair[0] }.map { |pair| pair[1] }.uniq
    sorted_titles
  end

  # --- Private Helper Methods ---
  private

  # Helper method to create a sortable key from a title
  # Lowercases, removes leading articles, strips whitespace.
  # (Identical to the one previously in the tag)
  def self._create_sort_key(title)
    return "" if title.nil?
    key = title.downcase
    key = key.sub(/^the\s+/, '')  # the
    key = key.sub(/^an?\s+/, '')  # a and an
    key.strip
  end

end # End Module BacklinkUtils
