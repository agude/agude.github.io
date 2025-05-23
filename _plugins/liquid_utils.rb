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
