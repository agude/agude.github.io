# _plugins/utils/author_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../liquid_utils' # For log_failure, _prepare_display_title (if needed, though basic CGI escape is used here)
require_relative './link_helper_utils' # For shared helpers
require_relative 'plugin_logger_utils'

module AuthorLinkUtils

  # --- Public Method ---

  # Finds an author page by name (case-insensitive, whitespace-normalized)
  # and renders the link/span HTML, handling possessive suffix.
  #
  # @param author_name_raw [String] The name of the author.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional display text.
  # @param possessive [Boolean] If true, append ’s to the output.
  # @return [String] The generated HTML (e.g., <a><span>...</span>’s</a> or <span>...</span>’s).
  def self.render_author_link(author_name_raw, context, link_text_override_raw = nil, possessive = false)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN AUTHOR_LINK_UTIL ERROR] Context or Site unavailable."
      defined?(LiquidUtils) ? PluginLoggerUtils.log_liquid_failure(context: nil, tag_type: "AUTHOR_LINK_UTIL_ERROR", reason: log_msg, identifiers: {}) : puts(log_msg)
      return author_name_raw.to_s # Minimal fallback
    end

    author_name_input = author_name_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    # Use normalize_title from LiquidUtils for lookup comparison
    normalized_lookup_name = LiquidUtils.normalize_title(author_name_input)

    if normalized_lookup_name.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: "RENDER_AUTHOR_LINK",
        reason: "Input author name resolved to empty after normalization",
        identifiers: { NameInput: author_name_raw || 'nil' }
      )
    end

    # 2. Lookup & Logging
    log_output = ""
    found_author_doc = _find_author_page(site, normalized_lookup_name)

    if found_author_doc.nil?
      log_output = _log_author_not_found(context, author_name_input)
    end

    # 3. Determine Display Text & Build Inner Span Element
    # Use shared helper for display text
    display_text = LinkHelperUtils._get_link_display_text(author_name_input, link_text_override, found_author_doc)
    # Use author-specific helper for span element
    span_element = _build_author_span_element(display_text)

    # 4. Handle Possessive Suffix
    # Possessive suffix is added *inside* the link if linked, *outside* if not.
    possessive_suffix = possessive ? "’s" : ""
    inner_html_with_suffix_if_linked = "#{span_element}#{possessive_suffix}"
    inner_html_without_suffix = span_element

    # 5. Generate Final HTML (Link or Span) using shared helper
    target_url = found_author_doc ? found_author_doc.url : nil
    # Pass the span *with* the suffix if we intend to link it.
    final_html_element = LinkHelperUtils._generate_link_html(
      context,
      target_url,
      inner_html_with_suffix_if_linked # Pass span+suffix to helper
    )

    # 6. Add Suffix if Not Linked
    # If the result is still just the span (meaning it wasn't linked), add the suffix now.
    if final_html_element == inner_html_without_suffix && possessive
      final_html_element << possessive_suffix
    end

    # 7. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
  end


  # --- Private Helper Methods ---
  private

  # Finds the author page document.
  def self._find_author_page(site, normalized_name)
    site.pages.find do |p|
      p.data['layout'] == 'author_page' && LiquidUtils.normalize_title(p.data['title']) == normalized_name
    end
  end

  # Builds the inner <span> element for the author name.
  def self._build_author_span_element(display_text)
    # Author names typically don't need complex typography, use basic escape.
    escaped_display_text = CGI.escapeHTML(display_text)
    "<span class=\"author-name\">#{escaped_display_text}</span>"
  end

  # Logs the failure when the author page is not found.
  def self._log_author_not_found(context, input_name)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: "RENDER_AUTHOR_LINK",
      reason: "Could not find author page",
      identifiers: { Name: input_name.strip }
    )
  end

end # End Module AuthorLinkUtils
