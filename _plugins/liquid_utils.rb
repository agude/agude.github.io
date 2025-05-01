# _plugins/liquid_utils.rb
require 'cgi'
require 'jekyll'

module LiquidUtils

  # --- NEW: Title Normalization Utility ---
  # Normalizes a title string for consistent comparison or key generation.
  # Options include lowercasing, stripping whitespace, handling newlines,
  # and optionally removing leading articles.
  #
  # @param title [String, nil] The title string to normalize.
  # @param strip_articles [Boolean] If true, remove leading "a", "an", "the".
  # @return [String] The normalized title string.
  def self.normalize_title(title, strip_articles: false)
    return "" if title.nil?
    # Convert to string, handle newlines, multiple spaces, downcase, strip ends
    normalized = title.to_s.gsub("\n", " ").gsub(/\s+/, ' ').downcase.strip
    if strip_articles
      normalized = normalized.sub(/^the\s+/, '')
      normalized = normalized.sub(/^an?\s+/, '') # Handles 'a' or 'an'
      normalized.strip! # Strip again in case article removal left leading space
    end
    normalized
  end

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
        tag_type: "RENDER_BOOK_LINK",
        reason: "Input title resolved to empty",
        identifiers: { TitleInput: book_title_raw || 'nil' }
      )
    end
    # --- End Input Validation ---

    found_book_doc = nil
    target_url = nil

    # --- Book Lookup Logic (Case-Insensitive) ---
    if site.collections.key?('books')

      book_title_normalized = normalize_title(book_title)
      found_book_doc = site.collections['books'].docs.find do |doc|
        # Skip unpublished explicitly if front matter exists
        next if doc.data['published'] == false

        # Compare normalized title
        normalize_title(doc.data['title']) == book_title_normalized
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
        tag_type: "RENDER_BOOK_LINK",
        reason: "Could not find book page during link rendering",
        identifiers: { Title: book_title }
      )
      # Return the log comment (if any) prepended to the cite element
      log_output + cite_element
    end
    # --- End Link Generation ---
  end


  # --- NEW: Render Rating Stars ---
  # Generates HTML for star rating display.
  #
  # @param rating [Integer, String, nil] The rating value (1-5).
  # @param wrapper_tag [String] The HTML tag to wrap the stars (default: 'div').
  # @return [String] HTML string for the rating stars.
  def self.render_rating_stars(rating, wrapper_tag = 'div')
    begin
      rating_int = Integer(rating)
      raise ArgumentError unless (1..5).include?(rating_int)
    rescue ArgumentError, TypeError
      # Handle invalid rating input gracefully - return empty or a default/error state?
      # For now, return empty string if rating is invalid.
      # Could also call log_failure here if context was available.
      return ""
      # Example logging (if context were passed):
      # return log_failure(context: context, tag_type: "RATING_STARS", reason: "Invalid rating value", identifiers: { RatingInput: rating.inspect })
    end

    max_stars = 5
    aria_label = "Rating: #{rating_int} out of #{max_stars} stars"
    css_class = "book-rating star-rating-#{rating_int}"

    stars_html = ""
    max_stars.times do |i|
      star_type = (i < rating_int) ? "full_star" : "empty_star"
      star_char = (i < rating_int) ? "★" : "☆"
      stars_html << "<span class=\"book_star #{star_type}\" aria-hidden=\"true\">#{star_char}</span>"
    end

    # Validate wrapper_tag to prevent injection - allow only simple tags like div, span
    safe_wrapper_tag = %w[div span].include?(wrapper_tag.to_s.downcase) ? wrapper_tag : 'div'

    "<#{safe_wrapper_tag} class=\"#{css_class}\" role=\"img\" aria-label=\"#{aria_label}\">#{stars_html}</#{safe_wrapper_tag}>"
  end


  # Generates HTML for a book card using data from a book object.
  #
  # @param book_object [Jekyll::Document] The book document object.
  # @param context [Liquid::Context] The current Liquid context (needed for baseurl).
  # @return [String] HTML string for the book card.
  def self.render_book_card(book_object, context)
    unless book_object && book_object.respond_to?(:data) && book_object.respond_to?(:url) && context && (site = context.registers[:site])
      # Cannot render card without valid object and context
      puts "[PLUGIN RENDER_BOOK_CARD ERROR] Invalid book_object or context."
      # Example logging (if context were available even if book_object was bad):
      # return log_failure(context: context, tag_type: "RENDER_BOOK_CARD", reason: "Invalid book object or context provided", identifiers: { BookPath: book_object&.path || 'N/A' })
      return ""
    end

    # Extract data with defaults
    data = book_object.data
    title = data['title'] || 'Untitled Book'
    author = data['book_author'] # Optional
    rating = data['rating'] # Optional
    image_path = data['image'] # Optional
    # Get the Excerpt object if available
    description_obj = data['excerpt'] # This will be a Jekyll::Excerpt object or nil

    # Prepare values for HTML
    escaped_title = CGI.escapeHTML(title)
    baseurl = site.config['baseurl'] || ''
    # Ensure book_object.url is treated as string before checking start_with?
    book_url_path = book_object.url.to_s
    book_url = book_url_path.empty? ? '#' : "#{baseurl}#{book_url_path}" # Handle missing URL

    image_url = nil
    if image_path && !image_path.empty?
        # Ensure image_path starts with a slash if baseurl is present and path doesn't already have it
        image_path_str = image_path.to_s
        image_path_str = "/#{image_path_str}" if !baseurl.empty? && !image_path_str.start_with?('/')
        image_url = "#{baseurl}#{image_path_str}"
    end


    # Build HTML structure (based on example output, adjust classes/structure as needed)
    card_html = "<div class=\"book-card\">\n"

    # Image section
    if image_url
      card_html << "  <div class=\"card-element card-book-cover\">\n"
      card_html << "    <a href=\"#{book_url}\">\n"
      # Alt text could be improved, maybe add 'image_alt' field?
      card_html << "      <img src=\"#{image_url}\" alt=\"Book cover of #{escaped_title}.\" />\n"
      card_html << "    </a>\n"
      card_html << "  </div>\n"
    end

    # Text section
    card_html << "  <div class=\"card-element card-text\">\n"
    # Title link
    card_html << "    <a href=\"#{book_url}\">\n"
    card_html << "      <strong><cite class=\"book-title\">#{escaped_title}</cite></strong>\n"
    card_html << "    </a>\n"
    # Author (optional) - Assuming simple span for now, could use author_link logic if needed
    if author && !author.empty?
      # TODO: Optionally integrate author_link logic here if desired
      card_html << "    <span class=\"by-author\"> by <span class=\"author-name\">#{CGI.escapeHTML(author)}</span></span>\n"
    end
    # Rating (optional) - Use the helper function
    if rating
      card_html << "    " << render_rating_stars(rating, 'div') << "\n" # Use div wrapper for rating inside card
    end

    # Description (optional)
    if description_obj
      # Convert the Excerpt object to its string representation
      description_str = description_obj.to_s

      # Check if the *string* is non-empty after stripping whitespace
      unless description_str.strip.empty?
        # The description from excerpt might already contain HTML (like <p>), handle appropriately.
        # Jekyll's default excerpt processing often adds <p> tags already.
        # Outputting directly is usually correct.
        # The extra wrapping div might be specific to your card layout needs.
        card_html << "    <div class=\"card-element card-text\">\n"
        card_html << "      #{description_str}\n" # Output the string content
        card_html << "    </div>\n"
      end
    end

    card_html << "  </div>\n" # Close card-text

    card_html << "</div>" # Close book-card

    card_html
  end

end
