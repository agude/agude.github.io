# _plugins/utils/author_link_util.rb
require 'jekyll'
require 'cgi'
require_relative 'link_helper_utils'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'

module AuthorLinkUtils
  # --- Public Method ---

  # Finds an author page by name from the link_cache and renders the link/span HTML.
  #
  # @param author_name_raw [String] The name of the author.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional display text.
  # @param possessive [Boolean] If true, append ’s to the output.
  # @return [String] The generated HTML (e.g., <a><span>...</span></a> or <span>...</span>’s).
  def self.render_author_link(author_name_raw, context, link_text_override_raw = nil, possessive = false)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      # Fallback for critical context failure
      return CGI.escapeHTML(author_name_raw.to_s)
    end

    author_name_input = author_name_raw.to_s
    if link_text_override_raw && !link_text_override_raw.to_s.empty?
      link_text_override = link_text_override_raw.to_s.strip
    end
    # Use normalize_title from LiquidUtils for lookup comparison
    normalized_lookup_name = TextProcessingUtils.normalize_title(author_name_input)

    if normalized_lookup_name.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'RENDER_AUTHOR_LINK',
        reason: 'Input author name resolved to empty after normalization.',
        identifiers: { NameInput: author_name_raw || 'nil' },
        level: :warn
      )
    end

    # 2. Lookup from Cache
    log_output = ''
    link_cache = site.data['link_cache'] || {}
    author_cache = link_cache['authors'] || {}
    found_author_data = author_cache[normalized_lookup_name] # Direct hash lookup

    log_output = _log_author_not_found(context, author_name_input) if found_author_data.nil?

    # 3. Determine Display Text & Build Inner Span Element
    display_text = author_name_input.strip # Default to the raw input name

    if link_text_override && !link_text_override.empty?
      # Priority 1: An explicit link_text override always wins.
      display_text = link_text_override
    elsif found_author_data
      # If a page was found, check if we should "correct" the display text to the canonical title.
      canonical_title_from_cache = found_author_data['title']
      normalized_canonical_title = TextProcessingUtils.normalize_title(canonical_title_from_cache)

      display_text = if normalized_lookup_name == normalized_canonical_title
                       # The input was a fuzzy match for the canonical name. Use the canonical name for display.
                       canonical_title_from_cache
                     else
                       # The input was a pen name (or a fuzzy match of one). Keep the original input as display text.
                       author_name_input.strip
                     end
    end
    span_element = _build_author_span_element(display_text)

    # 4. Handle Possessive Suffix
    # Possessive suffix is added *inside* the link if linked, *outside* if not.
    possessive_suffix = possessive ? '’s' : ''
    inner_html_with_suffix_if_linked = "#{span_element}#{possessive_suffix}"
    inner_html_without_suffix = span_element

    # 5. Generate Final HTML (Link or Span)
    target_url = found_author_data ? found_author_data['url'] : nil
    final_html_element = LinkHelperUtils._generate_link_html(
      context,
      target_url,
      inner_html_with_suffix_if_linked # Pass span+suffix to helper
    )

    # 6. Add Suffix if Not Linked
    # If the result is still just the span (meaning it wasn't linked), add the suffix now.
    final_html_element << possessive_suffix if final_html_element == inner_html_without_suffix && possessive

    # 7. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
  end

  # --- Private Helper Methods ---

  # Builds the inner <span> element for the author name.
  def self._build_author_span_element(display_text)
    # Author names typically don't need complex typography, use basic escape.
    escaped_display_text = CGI.escapeHTML(display_text)
    "<span class=\"author-name\">#{escaped_display_text}</span>"
  end

  # Logs the failure when the author page is not found.
  def self._log_author_not_found(context, input_name)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_AUTHOR_LINK',
      reason: 'Could not find author page in cache.',
      identifiers: { Name: input_name.strip },
      level: :info
    )
  end
end # End Module AuthorLinkUtils
