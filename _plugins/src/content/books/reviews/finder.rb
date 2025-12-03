# frozen_string_literal: true

# _plugins/logic/previous_reviews/finder.rb
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module PreviousReviews
    # Finds archived book reviews that share the same canonical URL.
    #
    # Returns a hash with:
    #   - logs: Error/warning messages (empty string if none)
    #   - reviews: Array of Jekyll::Document objects sorted by date (newest first)
    class Finder
      def initialize(context)
        @context = context
        @site = context.registers[:site]
        @page = context.registers[:page]
      end

      def find
        log_message = check_prerequisites
        return { logs: log_message, reviews: [] } if log_message

        archived_docs = find_archived_docs
        sorted_docs = archived_docs.sort_by(&:date).reverse

        { logs: '', reviews: sorted_docs }
      end

      private

      def check_prerequisites
        return nil if @site && @page && @page['url']

        PluginLoggerUtils.log_liquid_failure(
          context: @context,
          tag_type: 'PREVIOUS_REVIEWS',
          reason: 'Prerequisites missing: site, page, or page.url.',
          level: :error
        )
      end

      def find_archived_docs
        @site.collections['books'].docs.select do |book|
          book.data['canonical_url'] == @page['url'] && book != @page
        end
      end
    end
  end
end
