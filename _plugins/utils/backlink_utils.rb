# _plugins/utils/backlink_utils.rb
require 'jekyll'
require 'cgi'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'

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
    unless site && current_page && site.data['link_cache'] && site.data['link_cache']['backlinks'] && current_page['url']
      PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BACKLINK_UTIL",
        reason: "Prerequisites missing: site, page, link_cache, or backlinks cache unavailable.",
        identifiers: { PageURL: current_page ? (current_page['url'] || 'N/A') : 'N/A' },
        level: :error,
      )
      return [] # Return empty list if prerequisites fail
    end
    # --- End Sanity Checks ---

    current_url = current_page['url']
    backlinks_cache = site.data['link_cache']['backlinks']

    # --- Retrieve Backlinks from Cache ---
    backlinking_docs = backlinks_cache[current_url] || []

    # --- Sort and Return Title/URL Pairs ---
    if backlinking_docs.empty?
      return []
    end

    # Map to [sort_key, canonical_title, url] triplets for sorting
    backlinks_data = backlinking_docs.map do |book_doc|
      title = book_doc.data['title']
      next if title.nil? || title.strip.empty? # Skip if backlinking doc has no title

      sort_key = TextProcessingUtils.normalize_title(title, strip_articles: true)
      [sort_key, title, book_doc.url]
    end.compact # Remove any nils from skipped items

    # Sort by sort_key, then map to [canonical_title, url] pairs
    sorted_pairs = backlinks_data.sort_by { |triplet| triplet[0] }
      .map { |triplet| [triplet[1], triplet[2]] } # Map to [title, url]

    sorted_pairs
  end

end # End Module BacklinkUtils
