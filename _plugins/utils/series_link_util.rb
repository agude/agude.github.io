# frozen_string_literal: true

# _plugins/utils/series_link_util.rb
require 'jekyll'
require 'cgi'
require_relative 'link_helper_utils'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'

module SeriesLinkUtils
  # --- Public Method ---

  # Finds a series page by title from the link_cache and renders its link/span HTML.
  #
  # @param series_title_raw [String] The title of the series to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><span>...</span></a> or <span>...</span>).
  def self.render_series_link(series_title_raw, context, link_text_override_raw = nil)
    SeriesLinkResolver.new(context).resolve(series_title_raw, link_text_override_raw)
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
    PluginLoggerUtils.log_liquid_failure(
      context: context,
      tag_type: 'RENDER_SERIES_LINK',
      reason: 'Could not find series page in cache.',
      identifiers: { Series: input_title.strip },
      level: :info
    )
  end
end

# Helper class to handle series link resolution logic
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

    norm_title = TextProcessingUtils.normalize_title(@title_input)
    return log_empty_title(title_raw) if norm_title.empty?

    series_data = find_series(norm_title)
    display_text = determine_display_text(series_data)

    generate_html(display_text, series_data)
  end

  private

  def fallback(title)
    SeriesLinkUtils._build_series_span_element(title.to_s)
  end

  def log_empty_title(raw)
    PluginLoggerUtils.log_liquid_failure(
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

    @log_output = SeriesLinkUtils._log_series_not_found(@context, @title_input) unless data
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
    span = SeriesLinkUtils._build_series_span_element(display_text)
    url = series_data ? series_data['url'] : nil

    html = LinkHelperUtils._generate_link_html(@context, url, span)
    @log_output + html
  end
end
