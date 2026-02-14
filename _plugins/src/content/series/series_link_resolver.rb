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
      # Aliases for readability
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :LinkHelper, :Logger, :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
      end

      def resolve(title_raw, override_raw)
        data = resolve_data(title_raw, override_raw)
        render_html_from_data(data)
      end

      def resolve_data(title_raw, override_raw)
        return { status: :no_site, url: nil, display_text: title_raw.to_s }.freeze unless @site

        @title_input = title_raw.to_s
        @override = override_raw.to_s.strip if override_raw && !override_raw.to_s.empty?

        norm_title = Text.normalize_title(@title_input)
        if norm_title.empty?
          @log_output = log_empty_title(title_raw)
          return { status: :empty_title, url: nil, display_text: nil }.freeze
        end

        series_data = find_series(norm_title)
        display_text = determine_display_text(series_data)

        if series_data
          { status: :found, url: series_data['url'], display_text: display_text }.freeze
        else
          { status: :not_found, url: nil, display_text: display_text }.freeze
        end
      end

      private

      def render_html_from_data(data)
        case data[:status]
        when :no_site
          fallback(data[:display_text])
        when :empty_title
          @log_output
        when :found, :not_found
          generate_html(data)
        end
      end

      def fallback(title)
        Jekyll::Series::SeriesLinkUtils._build_series_span_element(title.to_s)
      end

      def log_empty_title(raw)
        Logger.log_liquid_failure(
          context: @context,
          tag_type: 'RENDER_SERIES_LINK',
          reason: 'Input title resolved to empty after normalization.',
          identifiers: { TitleInput: raw || 'nil' },
          level: :warn,
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

      def generate_html(data)
        span = Jekyll::Series::SeriesLinkUtils._build_series_span_element(data[:display_text])

        html = LinkHelper._generate_link_html(@context, data[:url], span)
        @log_output + html
      end
    end
  end
end
