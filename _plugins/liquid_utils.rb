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


  # Finds an author page and renders the link/span HTML.
  #
  # @param author_name_raw [String] The name of the author.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional display text.
  # @param possessive [Boolean] If true, append ’s to the output.
  # @return [String] The generated HTML (e.g., <a><span>...</span>’s</a> or <span>...</span>’s).
  def self.render_author_link(author_name_raw, context, link_text_override_raw = nil, possessive = false)
    unless context && (site = context.registers[:site])
      puts "[PLUGIN RENDER_AUTHOR_LINK ERROR] Context or Site unavailable."
      return author_name_raw.to_s # Minimal fallback
    end
    page = context.registers[:page]

    # --- Input Validation & Resolution ---
    author_name = author_name_raw.to_s.gsub(/\s+/, ' ').strip
    link_text_override = link_text_override_raw.to_s.strip if link_text_override_raw && !link_text_override_raw.to_s.empty?

    if author_name.empty?
      return log_failure(
        context: context, tag_type: "RENDER_AUTHOR_LINK",
        reason: "Input author name resolved to empty", identifiers: { NameInput: author_name_raw || 'nil' }
      )
    end
    # --- End Input Validation ---

    found_author_doc = nil
    target_url = nil

    # --- Author Lookup Logic ---
    found_author_doc = site.pages.find do |p|
      p.data['layout'] == 'author_page' && p.data['title']&.strip == author_name
    end
    # --- End Author Lookup ---

    # --- Determine Display Text ---
    display_text = author_name # Default
    if link_text_override && !link_text_override.empty?
      display_text = link_text_override
    elsif found_author_doc && found_author_doc.data['title']
      canonical_title = found_author_doc.data['title'].strip
      display_text = canonical_title unless canonical_title.empty?
    end
    # --- End Display Text ---

    escaped_display_text = CGI.escapeHTML(display_text)
    span_element = "<span class=\"author-name\">#{escaped_display_text}</span>"
    # Use the correct right single quotation mark (U+2019)
    possessive_suffix = possessive ? "’s" : ""

    # --- Link Generation ---
    linked_element = nil # Initialize
    log_output = ""

    if found_author_doc
      target_url = found_author_doc.url
      current_page_url = page ? page['url'] : nil

      if target_url && current_page_url && target_url != current_page_url
        baseurl = site.config['baseurl'] || ''
        target_url = "/#{target_url}" if !baseurl.empty? && !target_url.start_with?('/') && !target_url.start_with?(baseurl)
        # Append suffix INSIDE the link tag
        linked_element = "<a href=\"#{baseurl}#{target_url}\">#{span_element}#{possessive_suffix}</a>"
      else
        # Not linking (current page or invalid context), append suffix AFTER span
        linked_element = "#{span_element}#{possessive_suffix}"
      end
    else
      # Author not found, log failure and append suffix AFTER span
      log_output = log_failure(
        context: context, tag_type: "RENDER_AUTHOR_LINK",
        reason: "Could not find author page", identifiers: { Name: author_name }
      )
      linked_element = "#{span_element}#{possessive_suffix}"
    end
    # --- End Link Generation ---

    # Prepend log message (if any) to the generated element
    final_output = log_output + linked_element

    final_output
  end


  # --- Internal Helper for Preparing Display Titles ---
  # Applies smart quote/typographic transformations using Kramdown,
  # performs minimal HTML escaping (&, <, >), and then allows <br> tags through.
  # @param title [String, nil] The title string to prepare.
  # @return [String] The prepared title string, safe for HTML content.
  private
  def self._prepare_display_title(title)
    return "" if title.nil?
    text = title.to_s

    # 1. Apply smart quotes/typographics using Kramdown
    smart_text = text # Initialize fallback
    begin
      # Use a minimal config to avoid unexpected side effects
      kramdown_config = { input: 'SmartyPants' }
      smart_text = Kramdown::Document.new(text, kramdown_config).to_html.chomp
    rescue => e
      # Fallback or log error if Kramdown processing fails
      puts "[PLUGIN LIQUID_UTILS WARNING] Kramdown SmartyPants conversion failed for title: '#{text}'. Error: #{e.message}"
      # smart_text remains the original text in case of error
    end

    # 2. Apply minimal HTML escaping needed for content FIRST
    # Escape only &, <, >. This will turn literal <br /> from step 1 into <br />.
    escaped_text = smart_text.gsub('&', '&amp;')
                             .gsub('<', '&lt;')
                             .gsub('>', '&gt;')
                             # Leave all quote types alone.

    # 3. NOW, specifically un-escape the <br> tag variants using direct replacement
    # Replace the exact patterns produced by step 1 + step 2.
    # Handle both self-closing and non-self-closing variants just in case.
    escaped_text.gsub!('&lt;br /&gt;', '<br>') # Handle self-closing variant first
    escaped_text.gsub!('&lt;br&gt;', '<br>')   # Handle non-self-closing variant

    # Return the final text
    escaped_text
  end


  # Finds a book by title (case-insensitive) and renders its link/cite HTML.
  # Uses _prepare_display_title for correct quoting and escaping.
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

    # --- Use helper to prepare the title for display ---
    prepared_display_text = _prepare_display_title(display_text)
    cite_element = "<cite class=\"book-title\">#{prepared_display_text}</cite>"

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
      author_html = render_author_link(author, context)
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
