# _plugins/liquid_utils.rb
require 'cgi'
require 'jekyll'

module LiquidUtils

  # Resolves a Liquid markup string that might be a quoted literal or a variable name.
  # Handles single or double quotes for literals.
  # Falls back to the markup itself if it's not quoted and not found in the context.
  #
  # @param markup [String] The markup string from the Liquid tag.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String, Object, nil] The resolved value (String for literals, Object for variables), or nil.
  def self.resolve_value(markup, context)
    return nil if markup.nil? || markup.empty?
    stripped_markup = markup.strip
    # Check if it's a quoted string (single or double)
    if (stripped_markup.start_with?('"') && stripped_markup.end_with?('"')) || \
       (stripped_markup.start_with?("'") && stripped_markup.end_with?("'"))
      # Return the content inside the quotes
      stripped_markup[1..-2]
    else
      # Assume it's a variable name, look it up in the context.
      # If not found in context, return the original markup string itself
      # This handles cases where a literal string without quotes might be passed.
      context[stripped_markup] || stripped_markup
    end
  end

  # Logs a failure message based on environment defaults and specific tag type configuration.
  # Environment Defaults:
  #   - Non-Production: Console=true, HTML=true
  #   - Production:     Console=true, HTML=false
  # Configuration (_config.yml -> plugin_logging -> TAG_TYPE: false) can disable
  # all logging for a specific tag type.
  #
  # @param context [Liquid::Context] The current Liquid context.
  # @param tag_type [String] The type of tag reporting the failure (e.g., "BOOK_LINK").
  # @param reason [String] The reason for the failure.
  # @param identifiers [Hash] A hash of key-value pairs identifying the item.
  # @return [String] HTML comment string (if HTML logging is active) or empty string.
  def self.log_failure(context:, tag_type:, reason:, identifiers: {})
    # Ensure context and site are available
    unless context && (site = context.registers[:site])
      puts "[PLUGIN LOG ERROR] Context or Site unavailable for logging."
      return "" # Cannot proceed
    end

    environment = site.config['environment'] || 'development'

    # --- Determine if logging is enabled for this specific tag type ---
    # Default to enabled (true) unless explicitly set to false in config.
    # Use .to_s on tag_type just in case something non-stringy gets passed.
    log_setting_for_tag = site.config.dig('plugin_logging', tag_type.to_s)
    logging_enabled_for_tag = (log_setting_for_tag != false) # Enabled if true, nil, or missing key

    # --- Determine base logging destinations based on environment ---
    is_production = (environment == 'production')
    base_log_console = true # Console logging is on by default in all environments
    base_log_html = !is_production # HTML logging is on by default ONLY if not production

    # --- Determine final logging actions ---
    # Logging happens only if enabled for the tag AND enabled by environment default
    do_console_log = logging_enabled_for_tag && base_log_console
    do_html_log = logging_enabled_for_tag && base_log_html

    # --- Perform Logging ---
    html_output = "" # Initialize HTML output

    # Only proceed if any logging destination is active
    if do_console_log || do_html_log
      # Prepare message content (only once if needed)
      page_path = context.registers[:page] ? context.registers[:page]['path'] : 'unknown'
      identifier_string = identifiers.map { |key, value| "#{key}='#{CGI.escapeHTML(value.to_s)}'" }.join(' ')
      log_message_base = "#{tag_type}_FAILURE: Reason='#{reason}' #{identifier_string} SourcePage='#{page_path}'"

      # Log to Console if enabled
      if do_console_log
        # Use Jekyll's logger for better integration if available, otherwise puts
        if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:warn)
           Jekyll.logger.warn("[Plugin]", log_message_base)
        else
           puts "[PLUGIN LOG] #{log_message_base}" # Fallback
        end
      end

      # Prepare HTML Comment if enabled
      if do_html_log
        html_output = "<!-- #{log_message_base} -->"
      end
    end
    # --- End Logging ---

    return html_output # Return the HTML comment (or empty string)
  end

  # Finds a book by title (case-insensitive) and renders its link/cite HTML.
  # Replicates the core logic of BookLinkTag.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>).
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil)
    # Ensure context and site are available
    unless context && (site = context.registers[:site])
      puts "[PLUGIN RENDER_BOOK_LINK ERROR] Context or Site unavailable."
      # Return minimal fallback or raise error depending on desired strictness
      return book_title_raw.to_s # Minimal fallback
    end
    page = context.registers[:page]

    # --- Input Validation & Resolution ---
    book_title = book_title_raw.to_s.gsub(/\s+/, ' ').strip
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?

    if book_title.empty?
      # Log failure and return the log message (which might be empty)
      return log_failure(
        context: context,
        tag_type: "RENDER_BOOK_LINK", # Specific type for this utility function's errors
        reason: "Input title resolved to empty",
        identifiers: { TitleInput: book_title_raw || 'nil' }
      )
    end
    # --- End Input Validation ---

    found_book_doc = nil
    target_url = nil

    # --- Book Lookup Logic (Case-Insensitive) ---
    if site.collections.key?('books')
      book_title_downcased = book_title.downcase # For comparison
      found_book_doc = site.collections['books'].docs.find do |doc|
        # Skip unpublished explicitly if front matter exists
        next if doc.data['published'] == false

        # Compare downcased, stripped titles, handling potential nil
        doc.data['title']&.gsub(/\s+/, ' ')&.strip&.downcase == book_title_downcased
      end
    else
      # Log if the collection itself is missing
      return log_failure(
        context: context,
        tag_type: "RENDER_BOOK_LINK",
        reason: "Books collection not found in site configuration",
        identifiers: { Title: book_title }
      )
    end
    # --- End Book Lookup ---

    # --- Determine Display Text ---
    display_text = book_title # Default
    if link_text_override && !link_text_override.empty?
      display_text = link_text_override
    elsif found_book_doc && found_book_doc.data['title']
      # Use the canonical title from the found document's front matter
      canonical_title = found_book_doc.data['title'].strip
      display_text = canonical_title unless canonical_title.empty?
    end
    # --- End Display Text ---

    escaped_display_text = CGI.escapeHTML(display_text)
    cite_element = "<cite class=\"book-title\">#{escaped_display_text}</cite>"

    # --- Link Generation ---
    if found_book_doc
      target_url = found_book_doc.url
      # Ensure page context and URL exist before comparing
      current_page_url = page ? page['url'] : nil

      # Link if target URL exists AND it's not the current page
      if target_url && current_page_url && target_url != current_page_url
        # Use site.baseurl for correct link generation in subdirectories
        baseurl = site.config['baseurl'] || ''
        # Ensure target_url starts with a slash if baseurl is present and url doesn't already have it
        target_url = "/#{target_url}" if !baseurl.empty? && !target_url.start_with?('/') && !target_url.start_with?(baseurl)
        "<a href=\"#{baseurl}#{target_url}\">#{cite_element}</a>"
      else
        cite_element # It's the current page or context is missing/invalid
      end
    else
      # Log failure but still return the unlinked cite element for graceful degradation
      log_output = log_failure(
        context: context,
        tag_type: "RENDER_BOOK_LINK", # Use specific type
        reason: "Could not find book page during link rendering",
        identifiers: { Title: book_title }
      )
      # Return the log comment (if any) prepended to the cite element
      log_output + cite_element
    end
    # --- End Link Generation ---
  end

end
