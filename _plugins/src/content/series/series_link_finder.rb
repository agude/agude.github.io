# frozen_string_literal: true

# _plugins/src/content/series/series_link_finder.rb
require 'jekyll'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module Series
    # Finds series data without any formatting.
    #
    # This class separates data fetching from formatting concerns.
    # It returns a data hash that can be passed to LinkFormatter.
    #
    # @example
    #   finder = SeriesLinkFinder.new(context)
    #   data = finder.find('The Hyperion Cantos')
    #   # => { found: true, display_name: 'The Hyperion Cantos', url: '/series/...', ... }
    #
    #   # Then format with:
    #   LinkFormatter.html(data[:display_name], data[:url], wrapper: :span, css_class: 'book-series')
    class SeriesLinkFinder
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :Logger, :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
      end

      # Finds series data by title.
      #
      # @param title_raw [String] The series title to search for.
      # @param override [String, nil] Optional display text override.
      # @return [Hash] Series data with keys:
      #   - :found [Boolean] Whether series was found in cache
      #   - :display_name [String] Text to display
      #   - :url [String, nil] URL to series page
      #   - :log_output [String] Any log messages generated
      def find(title_raw, override: nil)
        return empty_result(title_raw) unless @site

        @title_input = title_raw.to_s
        @norm_title = Text.normalize_title(@title_input)

        return empty_result_with_log(@title_input, log_empty_title) if @norm_title.empty?

        series_data = lookup_series
        display_name = determine_display_name(series_data, override)

        if series_data
          build_found_result(display_name, series_data['url'])
        else
          @log_output = log_not_found
          build_not_found_result(display_name)
        end
      end

      private

      def empty_result(title_input)
        {
          found: false,
          display_name: title_input.to_s,
          url: nil,
          log_output: ''
        }
      end

      def empty_result_with_log(title_input, log_msg)
        {
          found: false,
          display_name: title_input.to_s,
          url: nil,
          log_output: log_msg
        }
      end

      def build_found_result(display_name, url)
        {
          found: true,
          display_name: display_name,
          url: url,
          log_output: @log_output
        }
      end

      def build_not_found_result(display_name)
        {
          found: false,
          display_name: display_name,
          url: nil,
          log_output: @log_output
        }
      end

      def lookup_series
        cache = @site.data['link_cache'] || {}
        (cache['series'] || {})[@norm_title]
      end

      def determine_display_name(series_data, override)
        # Override takes priority
        return override.to_s.strip if override && !override.to_s.strip.empty?

        # Use canonical title if found, otherwise use input
        series_data ? series_data['title'] : @title_input.strip
      end

      def log_empty_title
        Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SERIES_LINK',
          reason: 'Input title resolved to empty after normalization.',
          identifiers: { TitleInput: @title_input || 'nil' },
          level: :warn
        )
      end

      def log_not_found
        Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_SERIES_LINK',
          reason: 'Could not find series page in cache.',
          identifiers: { Series: @title_input.strip },
          level: :info
        )
      end
    end
  end
end
