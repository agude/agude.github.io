# frozen_string_literal: true

# _plugins/src/content/series/series_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../../infrastructure/links/link_formatter'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/links/markdown_link_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative 'series_link_finder'
require_relative 'series_link_resolver'

module Jekyll
  module Series
    # Utility module for generating links to book series pages.
    #
    # Uses SeriesLinkFinder to locate data and LinkFormatter to produce output.
    # Supports explicit format selection or automatic detection from context.
    module SeriesLinkUtils
      Finder = Jekyll::Series::SeriesLinkFinder
      Formatter = Jekyll::Infrastructure::Links::LinkFormatter
      MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      private_constant :Finder, :Formatter, :MarkdownUtils, :LinkHelper

      # --- Public Method ---

      # Finds a series page by title from the link_cache and renders its link/span HTML.
      #
      # @param series_title_raw [String] The title of the series to link to.
      # @param context [Liquid::Context] The current Liquid context.
      # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
      # @param format [Symbol, nil] Output format (:html or :markdown).
      #   If nil, determined from context (markdown_mode? check).
      # @return [String] The generated HTML (<a href=...><span>...</span></a> or <span>...</span>).
      def self.render_series_link(series_title_raw, context, link_text_override_raw = nil, format: nil)
        # Find series data
        data = Finder.new(context).find(
          series_title_raw,
          override: link_text_override_raw
        )

        # Determine output format
        output_format = format || detect_format(context)

        # Format and return
        data[:log_output] + format_series_link(data, context, output_format)
      end

      # --- Private Helper Methods ---

      def self.detect_format(context)
        MarkdownUtils.markdown_mode?(context) ? :markdown : :html
      end
      private_class_method :detect_format

      def self.format_series_link(data, context, output_format)
        case output_format
        when :markdown
          format_markdown(data)
        else
          format_html(data, context)
        end
      end
      private_class_method :format_series_link

      def self.format_markdown(data)
        Formatter.markdown(data[:display_name], data[:url], italic: false)
      end
      private_class_method :format_markdown

      def self.format_html(data, context)
        span = _build_series_span_element(data[:display_name])

        if data[:found] && data[:url]
          LinkHelper._generate_link_html(context, data[:url], span)
        else
          span
        end
      end
      private_class_method :format_html

      # Builds the inner <span> element for the series name.
      def self._build_series_span_element(display_text)
        # Series names typically don't need complex typography, use basic escape.
        escaped_display_text = CGI.escapeHTML(display_text.to_s)
        "<span class=\"book-series\">#{escaped_display_text}</span>"
      end

      # Logs the failure when the series page is not found.
      # Kept for backward compatibility with resolver.
      def self._log_series_not_found(context, input_title)
        Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RENDER_SERIES_LINK',
          reason: 'Could not find series page in cache.',
          identifiers: { Series: input_title.strip },
          level: :info
        )
      end
    end
  end
end
