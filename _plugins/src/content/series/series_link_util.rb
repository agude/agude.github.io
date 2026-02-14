# frozen_string_literal: true

# _plugins/utils/series_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative 'series_link_resolver'

module Jekyll
  module Series
    # Utility module for generating links to book series pages.
    module SeriesLinkUtils
      # --- Public Method ---

      # Finds a series page by title from the link_cache and renders its link/span HTML.
      #
      # @param series_title_raw [String] The title of the series to link to.
      # @param context [Liquid::Context] The current Liquid context.
      # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
      # @return [String] The generated HTML (<a href=...><span>...</span></a> or <span>...</span>).
      def self.render_series_link(series_title_raw, context, link_text_override_raw = nil)
        Jekyll::Series::SeriesLinkResolver.new(context).resolve(series_title_raw, link_text_override_raw)
      end

      # Returns a structured data hash (not HTML) for a series link resolution.
      def self.find_series_link_data(series_title_raw, context, link_text_override_raw = nil)
        Jekyll::Series::SeriesLinkResolver.new(context).resolve_data(series_title_raw, link_text_override_raw)
      end

      # --- Private Helper Methods ---

      # Builds the inner <span> element for the series name.
      def self._build_series_span_element(display_text)
        # Series names typically don't need complex typography, use basic escape.
        escaped_display_text = CGI.escapeHTML(display_text)
        "<span class=\"book-series\">#{escaped_display_text}</span>"
      end

      # Logs the failure when the series page is not found.
      def self._log_series_not_found(context, input_title)
        Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RENDER_SERIES_LINK',
          reason: 'Could not find series page in cache.',
          identifiers: { Series: input_title.strip },
          level: :info,
        )
      end
    end
  end
end
