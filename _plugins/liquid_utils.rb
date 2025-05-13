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


end
