# frozen_string_literal: true

# _plugins/src/infrastructure/links/link_resolver_support.rb
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
        def wrap_with_link(inner_html, url)
          LinkHelper._generate_link_html(@context, url, inner_html)
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
