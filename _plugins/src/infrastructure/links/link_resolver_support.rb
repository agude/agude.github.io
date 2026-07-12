# frozen_string_literal: true

require 'jekyll'
require 'cgi'
require_relative 'link_helper_utils'
require_relative '../plugin_logger_utils'
require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module Links
      # Shared plumbing for link resolvers. Provides initialization, cache
      # lookup, link wrapping, and logging helpers. Each resolver keeps its
      # own `resolve`, `resolve_data`, and rendering logic.
      #
      # @pattern Resolvers include this module directly rather than going
      #   through a separate `*_link_util.rb` wrapper — all resolution logic
      #   lives on the resolver. `LinkResolverSkeleton` builds a full
      #   template-method flow on top for the simple (author/series) case.
      module LinkResolverSupport
        LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils

        def initialize(context)
          @context = context
          @site = (context.registers&.[](:site) if context.respond_to?(:registers))
          @log_output = ''
        end

        private

        # Look up a normalized key in a link-cache section.
        # Returns the cached entry or nil.
        def find_in_cache(section, normalized_key)
          cache = @site.data['link_cache'] || {}
          (cache[section] || {})[normalized_key]
        end

        # Wrap inner HTML with a link tag via LinkHelperUtils.
        # @param preview_html [String, nil] Optional hover-preview markup, only emitted
        #   when a real cross-page link is generated (see LinkHelperUtils._generate_link_html).
        def wrap_with_link(inner_html, url, preview_html = nil)
          LinkHelper._generate_link_html(@context, url, inner_html, preview_html)
        end

        # Convenience wrapper around PluginLoggerUtils that pre-fills @context.
        def log_failure(tag_type:, reason:, identifiers:, level:)
          Logger.log_liquid_failure(
            context: @context,
            tag_type: tag_type,
            reason: reason,
            identifiers: identifiers,
            level: level,
          )
        end
      end
    end
  end
end
