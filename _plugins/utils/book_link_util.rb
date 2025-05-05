# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative '../liquid_utils' # For normalize_title, log_failure, _prepare_display_title
require_relative './link_helper_utils' # For shared helpers

module BookLinkUtils

  # --- Public Method ---

  # Finds a book by title (case-insensitive) and renders its link/cite HTML.
  # Uses shared helpers and LiquidUtils where appropriate.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>), potentially prepended with an HTML comment.
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN BOOK_LINK_UTIL ERROR] Context or Site unavailable."
      defined?(LiquidUtils) ? LiquidUtils.log_failure(context: nil, tag_type: "BOOK_LINK_UTIL_ERROR", reason: log_msg, identifiers: {}) : puts(log_msg)
      return book_title_raw.to_s # Minimal fallback
    end

    book_title_input = book_title_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    normalized_lookup_title = LiquidUtils.normalize_title(book_title_input)

    if normalized_lookup_title.empty?
      return LiquidUtils.log_failure(
        context: context, tag_type: "RENDER_BOOK_LINK",
        reason: "Input title resolved to empty after normalization",
        identifiers: { TitleInput: book_title_raw || 'nil' }
      )
    end

    # 2. Lookup & Logging
    log_output = ""
    found_book_doc = nil

    unless site.collections.key?('books')
      log_output = _log_book_collection_missing(context, book_title_input)
    else
      found_book_doc = _find_book_by_title(site, normalized_lookup_title)
      if found_book_doc.nil? && log_output.empty? # Avoid double logging
        log_output = _log_book_not_found(context, book_title_input)
      end
    end

    # 3. Determine Display Text & Build Cite Element
    # Use shared helper for display text
    display_text = LinkHelperUtils._get_link_display_text(book_title_input, link_text_override, found_book_doc)
    # Use book-specific helper for cite element
    cite_element = _build_book_cite_element(display_text)

    # 4. Generate Final HTML (Link or Span) using shared helper
    final_html_element = LinkHelperUtils._generate_link_html(context, found_book_doc, cite_element)

    # 5. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
  end

  # --- Private Helper Methods ---
  private

  # Finds the book document in the 'books' collection.
  def self._find_book_by_title(site, normalized_title)
    site.collections['books'].docs.find do |doc|
      next if doc.data['published'] == false
      LiquidUtils.normalize_title(doc.data['title']) == normalized_title
    end
  end

  # Prepares display text and wraps it in a <cite> tag.
  def self._build_book_cite_element(display_text)
    # Use _prepare_display_title from LiquidUtils (must be public)
    prepared_display_text = LiquidUtils._prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Logs the failure when the 'books' collection is missing.
  def self._log_book_collection_missing(context, input_title)
    LiquidUtils.log_failure(
      context: context, tag_type: "RENDER_BOOK_LINK",
      reason: "Books collection not found in site configuration",
      identifiers: { Title: input_title.strip }
    )
  end

  # Logs the failure when the book is not found within the collection.
  def self._log_book_not_found(context, input_title)
    LiquidUtils.log_failure(
      context: context, tag_type: "RENDER_BOOK_LINK",
      reason: "Could not find book page during link rendering",
      identifiers: { Title: input_title.strip }
    )
  end

end # End Module BookLinkUtils