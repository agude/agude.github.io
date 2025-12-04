# frozen_string_literal: true

# _plugins/src/content/series/series_link_resolver.rb
require 'jekyll'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'
require_relative 'series_link_util'

module Jekyll
  module Series
    # Helper class to handle series link resolution logic.
    class SeriesLinkResolver
      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
      end

      def resolve(title_raw, override_raw)
        return fallback(title_raw) unless @site

        @title_input = title_raw.to_s
        @override = override_raw.to_s.strip if override_raw && !override_raw.to_s.empty?

        norm_title = Jekyll::Infrastructure::TextProcessingUtils.normalize_title(@title_input)
        return log_empty_title(title_raw) if norm_title.empty?

        series_data = find_series(norm_title)
        display_text = determine_display_text(series_data)

        generate_html(display_text, series_data)
      end

      private

      def fallback(title)
        Jekyll::Series::SeriesLinkUtils._build_series_span_element(title.to_s)
      end

      def log_empty_title(raw)
        Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SERIES_LINK',
          reason: 'Input title resolved to empty after normalization.',
          identifiers: { TitleInput: raw || 'nil' },
          level: :warn
        )
      end

      def find_series(norm_title)
        cache = @site.data['link_cache'] || {}
        series_cache = cache['series'] || {}
        data = series_cache[norm_title]

        @log_output = Jekyll::Series::SeriesLinkUtils._log_series_not_found(@context, @title_input) unless data
        data
      end

      def determine_display_text(series_data)
        if @override
          @override
        elsif series_data
          series_data['title']
        else
          @title_input.strip
        end
      end

      def generate_html(display_text, series_data)
        span = Jekyll::Series::SeriesLinkUtils._build_series_span_element(display_text)
        url = series_data ? series_data['url'] : nil

        html = Jekyll::Infrastructure::Links::LinkHelperUtils._generate_link_html(@context, url, span)
        @log_output + html
      end
    end
  end
end
