# _plugins/utils/series_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../liquid_utils' # For normalize_title, log_failure, _prepare_display_title (if needed)
require_relative './link_helper_utils' # For shared helpers

module SeriesLinkUtils

  # --- Public Method ---

  # Finds a series page by title (case-insensitive, whitespace-normalized)
  # and renders its link/span HTML.
  #
  # @param series_title_raw [String] The title of the series to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><span>...</span></a> or <span>...</span>).
  def self.render_series_link(series_title_raw, context, link_text_override_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN SERIES_LINK_UTIL ERROR] Context or Site unavailable."
      defined?(LiquidUtils) ? LiquidUtils.log_failure(context: nil, tag_type: "SERIES_LINK_UTIL_ERROR", reason: log_msg, identifiers: {}) : puts(log_msg)
      return series_title_raw.to_s # Minimal fallback
    end

    series_title_input = series_title_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    # Use normalize_title from LiquidUtils for lookup comparison
    normalized_lookup_title = LiquidUtils.normalize_title(series_title_input)

    if normalized_lookup_title.empty?
      return LiquidUtils.log_failure(
        context: context, tag_type: "RENDER_SERIES_LINK",
        reason: "Input title resolved to empty after normalization",
        identifiers: { TitleInput: series_title_raw || 'nil' }
      )
    end

    # 2. Lookup & Logging
    log_output = ""
    found_series_doc = _find_series_page(site, normalized_lookup_title)

    if found_series_doc.nil?
      log_output = _log_series_not_found(context, series_title_input)
    end

    # 3. Determine Display Text & Build Inner Span Element
    # Use shared helper for display text
    display_text = LinkHelperUtils._get_link_display_text(series_title_input, link_text_override, found_series_doc)
    # Use series-specific helper for span element
    span_element = _build_series_span_element(display_text)

    # 4. Generate Final HTML (Link or Span) using shared helper
    target_url = found_series_doc ? found_series_doc.url : nil
    final_html_element = LinkHelperUtils._generate_link_html(context, target_url, span_element)

    # 5. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
  end


  # --- Private Helper Methods ---
  private

  # Finds the series page document.
  def self._find_series_page(site, normalized_title)
    # Handle case where site.pages might be nil during early build stages or in tests
    return nil unless site.pages

    site.pages.find do |p|
      p.data['layout'] == 'series_page' && LiquidUtils.normalize_title(p.data['title']) == normalized_title
    end
  end

  # Builds the inner <span> element for the series name.
  def self._build_series_span_element(display_text)
    escaped_display_text = CGI.escapeHTML(display_text)
    "<span class=\"book-series\">#{escaped_display_text}</span>"
  end

  # Logs the failure when the series page is not found.
  def self._log_series_not_found(context, input_title)
    LiquidUtils.log_failure(
      context: context,
      tag_type: "RENDER_SERIES_LINK",
      reason: "Could not find series page during link rendering",
      identifiers: { Series: input_title.strip }
    )
  end

end # End Module SeriesLinkUtils
    # Series names typically don't need complex typography, use basic escape.
