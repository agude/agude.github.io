# _plugins/utils/backlink_utils.rb
require 'jekyll'
require 'cgi'
require_relative 'plugin_logger_utils'

module BacklinkUtils

  # Finds books in the 'books' collection that link back to the current_page.
  # Returns a list of [canonical_title, url] pairs, sorted alphabetically by title (ignoring articles).
  #
  # @param current_page [MockDocument, Jekyll::Page, Jekyll::Document] The page to find backlinks for.
  # @param site [MockSite, Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The current Liquid context (needed for logging).
  # @return [Array<Array(String, String)>] A sorted list of [canonical_title, url] pairs.
  def self.find_book_backlinks(current_page, site, context)
    # --- Basic Sanity Checks ---
    # Simplified check: focus on what's directly used.
    # page['url'] and page['title'] access implies page.data is being used.
    unless site && current_page && \
        site.collections.key?('books') && \
        current_page['url'] && !current_page['url'].to_s.strip.empty? && \
        current_page['title'] && !current_page['title'].to_s.strip.empty?

      missing_parts = []
      missing_parts << "site object" unless site
      missing_parts << "current_page object" unless current_page
      missing_parts << "site.collections['books']" unless site&.collections&.key?('books')
      missing_parts << "current_page['url'] (present and not empty)" unless current_page && current_page['url'] && !current_page['url'].to_s.strip.empty?
      missing_parts << "current_page['title'] (present and not empty)" unless current_page && current_page['title'] && !current_page['title'].to_s.strip.empty?

      PluginLoggerUtils.log_liquid_failure(
        # This returns an HTML comment or "", but the main effect is logging.
        context: context, # Util is called from a tag, so context should be valid here.
        tag_type: "BACKLINK_UTIL",
        reason: "Missing prerequisites for backlink search: #{missing_parts.join(', ')}.",
        identifiers: {
          PageURL: current_page ? (current_page['url'] || 'N/A') : 'N/A',
          PageTitle: current_page ? (current_page['title'] || 'N/A') : 'N/A'
        },
        level: :error,
      )
      return [] # Return empty list if prerequisites fail
    end
    # --- End Sanity Checks ---

    current_url_downcased = current_page['url'].downcase.strip # Use downcased URL for HTML pattern matching only
    current_title_downcased = current_page['title'].downcase.strip # Use downcased title for Liquid tag matching

    # --- Prepare Search Patterns ---
    # Use original case URL from page data for CGI.escapeHTML, then downcase for comparison
    html_pattern = "href=\"#{CGI.escapeHTML(current_page['url'])}\"".downcase
    title_dq = "\"#{current_title_downcased}\""
    title_sq = "'#{current_title_downcased}'"
    markdown_pattern_dq_base = "book_link #{title_dq}"
    markdown_pattern_sq_base = "book_link #{title_sq}"
    markdown_pattern_dq_liquid = "{% book_link #{title_dq}"
    markdown_pattern_sq_liquid = "{% book_link #{title_sq}"
    # --- End Search Patterns ---

    # --- Iterate and Collect Backlinks ---
    # Store as [sort_key, canonical_title, url] triplets
    backlinks_data = []

    site.collections['books'].docs.each do |book|
      book_url = book.url # Keep original case URL for output
      canonical_title = book.data['title'] # Keep original case title for output

      # Skip self-references (compare original case URLs)
      next if book_url == current_page['url']
      # Skip unpublished
      next if book.data['published'] == false
      # Skip if book has no title or URL (needed for output pair)
      next if canonical_title.nil? || canonical_title.strip.empty?
      next if book_url.nil? || book_url.strip.empty?
      # Skip if book has no content
      book_content = book.content
      next if book_content.nil?

      # Normalize content for searching
      normalized_content = book_content.downcase.gsub("\n", " ")

      # --- Perform Checks ---
      found_link = false
      # Compare against downcased html_pattern
      if normalized_content.include?(html_pattern)
        found_link = true
      elsif normalized_content.include?(markdown_pattern_dq_base) || normalized_content.include?(markdown_pattern_dq_liquid)
        found_link = true
      elsif normalized_content.include?(markdown_pattern_sq_base) || normalized_content.include?(markdown_pattern_sq_liquid)
        found_link = true
      end
      # --- End Checks ---

      if found_link
        sort_key = _create_sort_key(canonical_title)
        # Store the triplet: sort_key, canonical_title, original_url
        backlinks_data << [sort_key, canonical_title, book_url]
      end
    end
    # --- End Iteration ---

    # --- Sort and Return Title/URL Pairs ---
    # Sort by sort_key, then map to [canonical_title, url] pairs, remove duplicates based on the pair
    sorted_pairs = backlinks_data.sort_by { |triplet| triplet[0] }
      .map { |triplet| [triplet[1], triplet[2]] } # Map to [title, url]
      .uniq # Remove duplicate [title, url] pairs

    sorted_pairs
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
