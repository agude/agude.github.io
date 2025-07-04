# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative './link_helper_utils'
require_relative 'plugin_logger_utils'

require_relative 'text_processing_utils'
require_relative 'typography_utils'
module BookLinkUtils

  # --- Public Method ---

  # Renders the book link/cite HTML directly from title and URL data.
  # Used when the book data is already known (e.g., from backlinks).
  #
  # @param title [String] The canonical title to display (will be processed).
  # @param url [String] The URL of the book page.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>).
  def self.render_book_link_from_data(title, url, context)
    # 1. Prepare Display Text & Build Cite Element
    cite_element = _build_book_cite_element(title) # Uses canonical title directly

    # 2. Generate Final HTML (Link or Span) using shared helper
    # Pass the known URL to the helper
    final_html_element = LinkHelperUtils._generate_link_html(context, url, cite_element)

    # 3. Return HTML Element
    final_html_element
  end


  # Finds a book by title from the link_cache and renders its link/cite HTML.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>), potentially prepended with an HTML comment.
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      # Fallback for critical context failure
      prepared_fallback_title = TypographyUtils.prepare_display_title(book_title_raw.to_s)
      return "<cite class=\"book-title\">#{prepared_fallback_title}</cite>"
    end

    book_title_input = book_title_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    normalized_lookup_title = TextProcessingUtils.normalize_title(book_title_input)

    if normalized_lookup_title.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: "RENDER_BOOK_LINK",
        reason: "Input title resolved to empty after normalization.",
        identifiers: { TitleInput: book_title_raw || 'nil' },
        level: :warn,
      )
    end

    # 2. Lookup from Cache
    log_output = ""
    link_cache = site.data['link_cache'] || {}
    book_cache = link_cache['books'] || {}
    found_book_data = book_cache[normalized_lookup_title] # Direct hash lookup

    if found_book_data.nil?
      log_output = _log_book_not_found(context, book_title_input)
    end

    # 3. Determine Display Text & Generate HTML
    final_html = ""
    # Determine display text regardless of whether book was found
    display_text = book_title_input.strip
    if link_text_override && !link_text_override.empty?
      display_text = link_text_override
    elsif found_book_data
      # Use the canonical title from the cache for display
      display_text = found_book_data['title']
    end

    if found_book_data
      # Book found: Call the helper with found data and determined display text
      final_html = render_book_link_from_data(display_text, found_book_data['url'], context)
    else
      # Book not found: Render unlinked cite with determined display text
      # Use the determined display_text (input or override)
      final_html = _build_book_cite_element(display_text)
    end

    # 4. Combine Log Output (if any) and HTML Element
    log_output + final_html
  end

  # --- Private Helper Methods ---
  private

  # Prepares display text and wraps it in a <cite> tag.
  def self._build_book_cite_element(display_text)
    # Use _prepare_display_title from LiquidUtils
    prepared_display_text = TypographyUtils.prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Logs the failure when the book is not found within the collection.
  def self._log_book_not_found(context, input_title)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: "RENDER_BOOK_LINK",
      reason: "Could not find book page in cache.",
      identifiers: { Title: input_title.strip },
      level: :info,
    )
  end

end # End Module BookLinkUtils
