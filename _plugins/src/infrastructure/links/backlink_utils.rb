# frozen_string_literal: true

# _plugins/utils/backlink_utils.rb
require 'jekyll'
require 'cgi'
require_relative '../plugin_logger_utils'
require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module Links
      # Utility module for finding and processing book backlinks.
      #
      # Identifies books that reference the current page and returns sorted lists
      # of backlinks for display.
      module BacklinkUtils
        # Finds books in the 'books' collection that link back to the current_page.
        # Returns a list of [canonical_title, url] pairs, sorted alphabetically by title (ignoring articles).
        #
        # @param current_page [MockDocument, Jekyll::Page, Jekyll::Document] The page to find backlinks for.
        # @param site [MockSite, Jekyll::Site] The Jekyll site object.
        # @param context [Liquid::Context] The current Liquid context (needed for logging).
        # @return [Array<Array(String, String)>] A sorted list of [canonical_title, url] pairs.
        def self.find_book_backlinks(current_page, site, context)
          return [] unless _valid_prerequisites?(current_page, site, context)

          current_url = current_page['url']
          backlinks_cache = site.data['link_cache']['backlinks']
          backlinking_docs = backlinks_cache[current_url] || []
          return [] if backlinking_docs.empty?

          _process_and_sort_backlinks(backlinking_docs)
        end

        def self._valid_prerequisites?(current_page, site, context)
          has_prerequisites = site && current_page && site.data['link_cache'] &&
                              site.data['link_cache']['backlinks'] && current_page['url']
          return true if has_prerequisites

          _log_missing_prerequisites(current_page, context)
          false
        end

        def self._log_missing_prerequisites(current_page, context)
          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: context,
            tag_type: 'BACKLINK_UTIL',
            reason: 'Prerequisites missing: site, page, link_cache, or backlinks cache unavailable.',
            identifiers: { PageURL: current_page ? (current_page['url'] || 'N/A') : 'N/A' },
            level: :error,
          )
        end

        def self._process_and_sort_backlinks(backlinking_docs)
          backlinks_data = backlinking_docs.map do |book_doc|
            title = book_doc.data['title']
            next if title.nil? || title.strip.empty?

            sort_key = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(title, strip_articles: true)
            [sort_key, title, book_doc.url]
          end.compact

          backlinks_data.sort_by(&:first).map { |triplet| [triplet[1], triplet[2]] }
        end
      end
    end
  end
end
