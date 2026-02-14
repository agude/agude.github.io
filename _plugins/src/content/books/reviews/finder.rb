# frozen_string_literal: true

# _plugins/logic/previous_reviews/finder.rb
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  module Books
    module Reviews
      # Finds archived book reviews that share the same canonical URL.
      #
      # Returns a hash with:
      #   - logs: Error/warning messages (empty string if none)
      #   - reviews: Array of Jekyll::Document objects sorted by date (newest first)
      class Finder
        # Accepts site + page directly (for use outside Liquid context).
        # Legacy: also accepts a Liquid::Context as the sole argument.
        def initialize(site_or_context, page = nil)
          if site_or_context.respond_to?(:registers)
            @site = site_or_context.registers[:site]
            @page = site_or_context.registers[:page]
          else
            @site = site_or_context
            @page = page
          end
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

          Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
            context: log_context,
            tag_type: 'PREVIOUS_REVIEWS',
            reason: 'Prerequisites missing: site, page, or page.url.',
            level: :error,
          )
        end

        # Builds a minimal context-like object for PluginLoggerUtils.
        def log_context
          page = @page
          site = @site
          Object.new.tap do |ctx|
            ctx.define_singleton_method(:registers) { { site: site, page: page } }
          end
        end

        def find_archived_docs
          @site.collections['books'].docs.select do |book|
            book.data['canonical_url'] == @page['url'] && book != @page
          end
        end
      end
    end
  end
end
