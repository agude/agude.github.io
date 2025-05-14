# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative '../liquid_utils'
require_relative './link_helper_utils'
require_relative 'plugin_logger_utils'

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


  # Finds a book by title (case-insensitive) and renders its link/cite HTML.
  # Uses shared helpers and LiquidUtils where appropriate. Now calls render_book_link_from_data internally.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>), potentially prepended with an HTML comment.
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      log_msg = "[PLUGIN BOOK_LINK_UTIL ERROR] Context or Site unavailable."
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:error)
        Jekyll.logger.error("BookLinkUtil:", log_msg)
      else
        STDERR.puts log_msg
      end
      # Fallback to simple string if critical context is missing.
      # Use _prepare_display_title for consistency if possible, else basic escape.
      prepared_fallback_title = defined?(LiquidUtils) ? LiquidUtils._prepare_display_title(book_title_raw.to_s) : CGI.escapeHTML(book_title_raw.to_s)
      return "<cite class=\"book-title\">#{prepared_fallback_title}</cite>" # Return unlinked cite
    end

    book_title_input = book_title_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    normalized_lookup_title = LiquidUtils.normalize_title(book_title_input)

    if normalized_lookup_title.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: "RENDER_BOOK_LINK",
        reason: "Input title resolved to empty after normalization.",
        identifiers: { TitleInput: book_title_raw || 'nil' },
        level: :warn,
      )
    end

    # 2. Lookup & Logging
    log_output = ""
    found_book_doc = nil

    unless site.collections.key?('books')
      log_output = _log_book_collection_missing(context, book_title_input)
      # If collection missing, we can't find the book, proceed to render unlinked
    else
      found_book_doc = _find_book_by_title(site, normalized_lookup_title)
      if found_book_doc.nil? && log_output.empty? # Avoid double logging if collection was missing
        log_output = _log_book_not_found(context, book_title_input)
      end
    end

    # 3. Determine Display Text & Generate HTML
    final_html = ""
    # Determine display text regardless of whether book was found
    display_text = LinkHelperUtils._get_link_display_text(book_title_input, link_text_override, found_book_doc)

    if found_book_doc
      # Book found: Call the new helper with found data
      book_url = found_book_doc.url
      # Pass the determined display_text and the found URL
      final_html = render_book_link_from_data(display_text, book_url, context)
    else
      # Book not found (or collection missing): Render unlinked cite
      # Use the determined display_text (input or override)
      final_html = _build_book_cite_element(display_text)
    end

    # 4. Combine Log Output (if any) and HTML Element
    log_output + final_html
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
    # Use _prepare_display_title from LiquidUtils
    prepared_display_text = LiquidUtils._prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Logs the failure when the 'books' collection is missing.
  def self._log_book_collection_missing(context, input_title)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: "RENDER_BOOK_LINK",
      reason: "Books collection not found in site configuration.",
      identifiers: { Title: input_title.strip },
      level: :error,
    )
  end

  # Logs the failure when the book is not found within the collection.
  def self._log_book_not_found(context, input_title)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: "RENDER_BOOK_LINK",
      reason: "Could not find book page during link rendering.",
      identifiers: { Title: input_title.strip },
      level: :info,
    )
  end

end # End Module BookLinkUtils
