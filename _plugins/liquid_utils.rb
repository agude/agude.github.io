# _plugins/liquid_utils.rb
require 'cgi'
require 'jekyll'

# Ensure Kramdown is loaded (Jekyll usually handles this, but belt-and-suspenders)
begin
  require 'kramdown'
rescue LoadError
  STDERR.puts "Error: Kramdown gem not found. Please ensure it's in your Gemfile and installed."
  exit(1) # Or handle more gracefully depending on desired robustness
end

module LiquidUtils

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


  # Resolves a Liquid markup string.
  # - If the markup is quoted (single or double), returns the literal string content.
  # - If the markup is NOT quoted, assumes it's a variable name (simple or dot notation)
  #   and attempts to look it up in the context using context[].
  # - Returns the variable's value if found (which can be any object, including nil or false).
  # - Returns nil if the unquoted variable name is not found in the context.
  #
  # @param markup [String] The markup string from the Liquid tag.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String, Object, nil] The resolved value.
  def self.resolve_value(markup, context)
    return nil if markup.nil? || markup.empty?
    stripped_markup = markup.strip
    return nil if stripped_markup.empty?

    # Check if it's a quoted string (single or double)
    if (stripped_markup.start_with?('"') && stripped_markup.end_with?('"')) || \
       (stripped_markup.start_with?("'") && stripped_markup.end_with?("'"))
      # It's a quoted literal. Return the content inside the quotes.
      stripped_markup[1..-2]
    else
      # Not quoted. Assume it's a variable name (simple or dot notation).
      # Look it up using context[]. This handles dot notation and returns nil
      # for failed lookups or if the variable's actual value is nil.
      context[stripped_markup]
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
    unless context && (site = context.registers[:site]) # <--- Check fails
      # Use Jekyll logger if available, otherwise puts
      log_msg = "[PLUGIN LOG ERROR] Context or Site unavailable for logging."
      if defined?(Jekyll.logger) && Jekyll.logger.respond_to?(:warn)
        Jekyll.logger.warn(log_msg)
      else
        puts log_msg # Uses puts ONLY if logger/warn isn't available
      end
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


  # --- Internal Helper for Preparing Display Titles ---
  # Applies manual "SmartyPants"-like transformations, minimal HTML escaping,
  # and allows <br> tags through. NO Kramdown involved.
  # @param title [String, nil] The title string to prepare.
  # @return [String] The prepared title string, safe for HTML content.
  def self._prepare_display_title(title)
    return "" if title.nil?
    text = title.to_s

    # 1. Minimal HTML Escape FIRST (Only &, <, >)
    # Do this before typography to avoid escaping entities we create.
    # This will turn literal <br> into <br> and <Tags> into <Tags>
    escaped_text = text.gsub('&', '&amp;')
                       .gsub('<', '&lt;')
                       .gsub('>', '&gt;')
                       # Leave all quote types alone.

    # 2. Manual Typographic Transformations (Order matters for quotes)
    escaped_text.gsub!(/---/, '—')    # Em dash
    escaped_text.gsub!(/--/, '–')     # En dash
    escaped_text.gsub!(/\.\.\./, '…') # Ellipsis

    # Double quotes: “ ”
    # Match " preceded by space/start/(/[ or followed by word char
    escaped_text.gsub!(/(?<=\s|^|\[|\()"|"(?=\w)/, '“') # Opening "" (using lookbehind/lookahead)
    escaped_text.gsub!(/"/, '”') # Closing "" (remaining)

    # Single quotes: ‘ ’ - Apostrophes first
    escaped_text.gsub!(/(\w)'(\w)/, '\1’\2') # Apostrophe within word
    escaped_text.gsub!(/'(\d{2}s)/, '’\1') # Year abbreviations
    escaped_text.gsub!(/(\w)'(?=\s|$|,|\.|;|\?|!)/, '\1’') # Possessive at end
    # Match ' preceded by space/start/(/[ or followed by word char
    escaped_text.gsub!(/(?<=\s|^|\[|\()'|'(?=\w)/, '‘') # Opening ''
    escaped_text.gsub!(/'/, '’') # Closing '' / Remaining apostrophes

    # 3. Restore literal <br> tags
    escaped_text.gsub!('&lt;br /&gt;', '<br>')
    escaped_text.gsub!('&lt;br/&gt;', '<br>')
    escaped_text.gsub!('&lt;br&gt;', '<br>')

    # Return the final text
    escaped_text
  end


  # --- Render Rating Stars ---
  # Generates HTML for star rating display.
  # Accepts Integer or integer-like String input for rating (1-5), or nil.
  # Returns empty string for nil input.
  # Throws ArgumentError for invalid types or values outside the 1-5 range.
  #
  # @param rating [Integer, String, nil] The rating value (1-5).
  # @param wrapper_tag [String] The HTML tag to wrap the stars (default: 'div').
  # @return [String] HTML string for the rating stars.
  # @raise [ArgumentError] if rating is not nil, Integer(1-5), or String("1"-"5").
  def self.render_rating_stars(rating, wrapper_tag = 'div')
    # Allow nil input to return empty string silently
    return "" if rating.nil?

    rating_int = nil

    # --- Input Type Validation and Conversion ---
    if rating.is_a?(Integer)
      rating_int = rating
    elsif rating.is_a?(String) && rating.match?(/\A\d+\z/) # Only positive integer strings
      begin
        rating_int = Integer(rating)
      rescue ArgumentError
        # This should be rare with the regex, but catch just in case
        raise ArgumentError, "Invalid rating input: Cannot convert string '#{rating}' to Integer."
      end
    else
      # Invalid type (float, array, non-numeric string, negative string etc.)
      raise ArgumentError, "Invalid rating input type: '#{rating.inspect}' (#{rating.class}). Expected Integer(1-5), String('1'-'5'), or nil."
    end
    # --- End Input Type Validation ---


    # --- Range Validation ---
    unless (1..5).include?(rating_int)
      raise ArgumentError, "Invalid rating value: #{rating_int}. Rating must be between 1 and 5 (inclusive)."
    end
    # --- End Range Validation ---


    # --- HTML Generation (only runs if input is valid 1-5) ---
    max_stars = 5
    aria_label = "Rating: #{rating_int} out of #{max_stars} stars"
    css_class = "book-rating star-rating-#{rating_int}"

    stars_html = ""
    max_stars.times do |i|
      star_type = (i < rating_int) ? "full_star" : "empty_star"
      star_char = (i < rating_int) ? "★" : "☆"
      stars_html << "<span class=\"book_star #{star_type}\" aria-hidden=\"true\">#{star_char}</span>"
    end

    # Validate wrapper_tag
    safe_wrapper_tag = %w[div span].include?(wrapper_tag.to_s.downcase) ? wrapper_tag.to_s.downcase : 'div'

    "<#{safe_wrapper_tag} class=\"#{css_class}\" role=\"img\" aria-label=\"#{aria_label}\">#{stars_html}</#{safe_wrapper_tag}>"
    # --- End HTML Generation ---
  end


 # --- Render Article Card Utility ---
  # Applies typographic transformations and handles <br> tags safely via helper.
  def self.render_article_card(post_object, context)
    unless post_object && post_object.respond_to?(:data) && post_object.respond_to?(:url) && context && (site = context.registers[:site])
      puts "[PLUGIN RENDER_ARTICLE_CARD ERROR] Invalid post_object or context."
      return ""
    end

    # Extract data with defaults
    data = post_object.data
    raw_title = data['title'] || 'Untitled Post' # Get the raw title
    image_path = data['image'] # Optional
    image_alt = data['image_alt'] || "Article header image, used for decoration." # Default alt text

    # --- Description Logic (Prioritize 'description', fallback to 'excerpt') ---
    # Jekyll 4: post.data['excerpt'] holds the Excerpt object.
    # We need its string representation.
    description = data['description'] # Check front matter first
    if description.nil? || description.to_s.strip.empty?
      excerpt_obj = data['excerpt']
      description = excerpt_obj.to_s if excerpt_obj # Convert Excerpt object to string
    end
    description_str = description.to_s.strip
    # --- End Description Logic ---


    # --- Prepare Title for Display using the updated helper ---
    # This single call now handles Kramdown, minimal escaping, AND restoring <br>
    prepared_title = _prepare_display_title(raw_title)

    # Prepare other values for HTML
    escaped_alt = CGI.escapeHTML(image_alt) # Still escape alt text fully
    baseurl = site.config['baseurl'] || ''
    post_url_path = post_object.url.to_s
    post_url = post_url_path.empty? ? '#' : "#{baseurl}#{post_url_path}" # Handle missing URL

    image_url = nil
    if image_path && !image_path.empty?
        image_path_str = image_path.to_s
        image_path_str = "/#{image_path_str}" if !baseurl.empty? && !image_path_str.start_with?('/')
        image_url = "#{baseurl}#{image_path_str}"
    end

    # Build HTML structure
    card_html = "<div class=\"article-card\">\n"

    # Image section (optional)
    if image_url
      card_html << "  <div class=\"card-element card-image\">\n"
      card_html << "    <a href=\"#{post_url}\">\n"
      card_html << "      <img src=\"#{image_url}\" alt=\"#{escaped_alt}\" />\n"
      card_html << "    </a>\n"
      card_html << "  </div>\n"
    end

    # Text section
    card_html << "  <div class=\"card-element card-text\">\n"
    # Title link - uses the fully prepared title directly from the helper
    card_html << "    <a href=\"#{post_url}\">\n"
    card_html << "      <strong>#{prepared_title}</strong>\n"
    card_html << "    </a>\n"

    # Description (optional)
    if !description_str.empty?
      card_html << "    <br>\n"
      # Description likely already processed by Kramdown during page render
      card_html << "    #{description_str}\n"
    end

    card_html << "  </div>\n" # Close card-text
    card_html << "</div>" # Close article-card
    card_html
  end


  # --- Render Book Card Utility ---
  # Uses _prepare_display_title for correct quoting and escaping.
  def self.render_book_card(book_object, context)
    unless book_object && book_object.respond_to?(:data) && book_object.respond_to?(:url) && context && (site = context.registers[:site])
      # Cannot render card without valid object and context
      puts "[PLUGIN RENDER_BOOK_CARD ERROR] Invalid book_object or context."
      return ""
    end

    # Extract data with defaults
    data = book_object.data
    title = data['title'] || 'Untitled Book'
    author = data['book_author'] # Optional
    rating = data['rating'] # Optional
    image_path = data['image'] # Optional
    description_obj = data['excerpt']

    # --- Use helper to prepare the title for display ---
    prepared_title = _prepare_display_title(title)

    # Prepare other values for HTML
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


    # Build HTML structure
    card_html = "<div class=\"book-card\">\n"

    # Image section
    if image_url
      card_html << "  <div class=\"card-element card-book-cover\">\n"
      card_html << "    <a href=\"#{book_url}\">\n"
      # Alt text: Use original title, fully escaped for attribute safety
      card_html << "      <img src=\"#{image_url}\" alt=\"Book cover of #{CGI.escapeHTML(title)}.\" />\n"
      card_html << "    </a>\n"
      card_html << "  </div>\n"
    end

    # Text section
    card_html << "  <div class=\"card-element card-text\">\n"
    # Title link - uses the prepared title
    card_html << "    <a href=\"#{book_url}\">\n"
    card_html << "      <strong><cite class=\"book-title\">#{prepared_title}</cite></strong>\n"
    card_html << "    </a>\n"

    # Author (optional) - Use the helper function
    if author && !author.empty?
      # Call the new utility function to generate the author link/span
      author_html = AuthorLinkUtils.render_author_link(author, context)
      card_html << "    <span class=\"by-author\"> by #{author_html}</span>\n"
    end

    # Rating (optional) - Use the helper function
    if rating
      card_html << "    " << render_rating_stars(rating, 'div') << "\n"
    end

    # Description (optional)
    if description_obj
      # Convert the Excerpt object to its string representation
      description_str = description_obj.to_s

      # Check if the *string* is non-empty after stripping whitespace
      unless description_str.strip.empty?
        # Description from excerpt likely already has smart quotes from Kramdown
        card_html << "    <div class=\"card-element card-text\">\n"
        card_html << "      #{description_str}\n"
        card_html << "    </div>\n"
      end
    end
    card_html << "  </div>\n" # Close card-text
    card_html << "</div>" # Close book-card
    card_html
  end


end
