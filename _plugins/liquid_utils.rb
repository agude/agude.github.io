# _plugins/liquid_utils.rb
require 'cgi'
require 'jekyll'
require_relative 'utils/rating_utils'

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
      card_html << "    " << RatingUtils.render_rating_stars(rating, 'div') << "\n"
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
