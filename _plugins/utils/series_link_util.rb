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
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      # Fallback for critical context failure
      return "<span class=\"book-series\">#{CGI.escapeHTML(series_title_raw.to_s)}</span>"
    end

    series_title_input = series_title_raw.to_s
    if link_text_override_raw && !link_text_override_raw.to_s.empty?
      link_text_override = link_text_override_raw.to_s.strip
    end
    # Use normalize_title from LiquidUtils for lookup comparison
    normalized_lookup_title = TextProcessingUtils.normalize_title(series_title_input)

    if normalized_lookup_title.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'RENDER_SERIES_LINK',
        reason: 'Input title resolved to empty after normalization.',
        identifiers: { TitleInput: series_title_raw || 'nil' },
        level: :warn
      )
    end

    # 2. Lookup from Cache
    log_output = ''
    link_cache = site.data['link_cache'] || {}
    series_cache = link_cache['series'] || {}
    found_series_data = series_cache[normalized_lookup_title] # Direct hash lookup

    log_output = _log_series_not_found(context, series_title_input) if found_series_data.nil?

    # 3. Determine Display Text & Build Inner Span Element
    display_text = series_title_input.strip
    if link_text_override && !link_text_override.empty?
      display_text = link_text_override
    elsif found_series_data
      # Use the canonical title from the cache for display
      display_text = found_series_data['title']
    end
    span_element = _build_series_span_element(display_text)

    # 4. Generate Final HTML (Link or Span) using shared helper
    target_url = found_series_data ? found_series_data['url'] : nil
    final_html_element = LinkHelperUtils._generate_link_html(context, target_url, span_element)

    # 5. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
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
