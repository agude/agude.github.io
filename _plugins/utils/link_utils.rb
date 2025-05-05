# _plugins/utils/link_utils.rb
require 'cgi'
require 'jekyll'
require_relative '../liquid_utils' # Need access to other utils like normalize_title, log_failure

module LinkUtils

  # --- Public Method ---

  # Finds a book by title (case-insensitive) and renders its link/cite HTML.
  # Uses LiquidUtils._prepare_display_title for correct quoting and escaping.
  # Prepends log failure comment (if applicable) when book/collection not found.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>), potentially prepended with an HTML comment.
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      # Use LiquidUtils logger if possible, otherwise puts
      log_msg = "[PLUGIN LINK_UTILS ERROR] Context or Site unavailable for render_book_link."
      defined?(LiquidUtils) ? LiquidUtils.log_failure(context: nil, tag_type: "LINK_UTILS_ERROR", reason: log_msg, identifiers: {}) : puts(log_msg)
      return book_title_raw.to_s # Minimal fallback
    end

    book_title_input = book_title_raw.to_s
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?
    # Use normalize_title from LiquidUtils
    normalized_lookup_title = LiquidUtils.normalize_title(book_title_input)

    if normalized_lookup_title.empty?
      # Use log_failure from LiquidUtils
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
      if found_book_doc.nil?
        log_output = _log_book_not_found(context, book_title_input)
      end
    end

    # 3. Determine Display Text & Build Cite Element
    display_text = _get_book_display_text(book_title_input, link_text_override, found_book_doc)
    cite_element = _build_book_cite_element(display_text)

    # 4. Generate Final HTML (Link or Span)
    final_html_element = _generate_book_link_html(context, found_book_doc, cite_element)

    # 5. Combine Log Output (if any) and HTML Element
    log_output + final_html_element
  end

  # --- Private Helper Methods ---
  private

  # Finds the book document in the 'books' collection.
  # @param site [MockSite, Jekyll::Site] The site object.
  # @param normalized_title [String] The normalized title to search for.
  # @return [MockDocument, Jekyll::Document, nil] The found document or nil.
  def self._find_book_by_title(site, normalized_title)
    # Assuming site.collections['books'] exists based on caller check
    site.collections['books'].docs.find do |doc|
      next if doc.data['published'] == false
      # Use normalize_title from LiquidUtils
      LiquidUtils.normalize_title(doc.data['title']) == normalized_title
    end
  end

  # Determines the correct text to display for the link/cite.
  # @param input_title [String] The original title passed to the tag.
  # @param override_text [String, nil] The optional link_text override.
  # @param found_doc [MockDocument, Jekyll::Document, nil] The book document if found.
  # @return [String] The text to display.
  def self._get_book_display_text(input_title, override_text, found_doc)
    display_text = input_title.strip # Default to stripped input
    if override_text && !override_text.empty?
      display_text = override_text
    elsif found_doc && found_doc.data['title']
      canonical_title = found_doc.data['title'].strip
      display_text = canonical_title unless canonical_title.empty?
    end
    display_text
  end

  # Prepares display text and wraps it in a <cite> tag.
  # @param display_text [String] The text to display.
  # @return [String] The HTML <cite> element string.
  def self._build_book_cite_element(display_text)
    # Use _prepare_display_title from LiquidUtils
    # NOTE: This assumes _prepare_display_title is made public or moved.
    # If kept private, this call needs adjustment or the method moved here.
    # Let's assume it's made public for now.
    prepared_display_text = LiquidUtils._prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Generates the final HTML (<a> or just <cite>) based on whether the book was found.
  # @param context [Liquid::Context] The current Liquid context.
  # @param found_doc [MockDocument, Jekyll::Document, nil] The book document if found.
  # @param cite_element [String] The pre-built <cite> HTML element.
  # @return [String] The final HTML string (linked or unlinked).
  def self._generate_book_link_html(context, found_doc, cite_element)
    if found_doc
      target_url = found_doc.url
      page = context.registers[:page]
      site = context.registers[:site]
      current_page_url = page ? page['url'] : nil

      # Link if target URL exists AND it's not the current page
      if target_url && current_page_url && target_url != current_page_url
        baseurl = site.config['baseurl'] || ''
        target_url = "/#{target_url}" if !baseurl.empty? && !target_url.start_with?('/') && !target_url.start_with?(baseurl)
        "<a href=\"#{baseurl}#{target_url}\">#{cite_element}</a>"
      else
        cite_element # It's the current page or context/URL is missing/invalid
      end
    else
      cite_element # Book not found, return unlinked cite
    end
  end

  # Logs the failure when the 'books' collection is missing.
  # @param context [Liquid::Context] The current Liquid context.
  # @param input_title [String] The original title passed to the tag.
  # @return [String] The log output (HTML comment or empty string).
  def self._log_book_collection_missing(context, input_title)
    # Use log_failure from LiquidUtils
    LiquidUtils.log_failure(
      context: context,
      tag_type: "RENDER_BOOK_LINK",
      reason: "Books collection not found in site configuration",
      identifiers: { Title: input_title.strip }
    )
  end

  # Logs the failure when the book is not found within the collection.
  # @param context [Liquid::Context] The current Liquid context.
  # @param input_title [String] The original title passed to the tag.
  # @return [String] The log output (HTML comment or empty string).
  def self._log_book_not_found(context, input_title)
    # Use log_failure from LiquidUtils
    LiquidUtils.log_failure(
      context: context,
      tag_type: "RENDER_BOOK_LINK",
      reason: "Could not find book page during link rendering",
      identifiers: { Title: input_title.strip }
    )
  end

end # End Module LinkUtils