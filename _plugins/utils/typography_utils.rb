# frozen_string_literal: true

# _plugins/utils/typography_utils.rb
require 'cgi' # Still needed for the initial minimal escape, though not for full CGI.escapeHTML

module TypographyUtils
  # Applies manual "SmartyPants"-like transformations, minimal HTML escaping,
  # and allows <br> tags through. NO Kramdown involved.
  # @param title [String, nil] The title string to prepare.
  # @return [String] The prepared title string, safe for HTML content.
  # Renamed from _prepare_display_title
  def self.prepare_display_title(title)
    return '' if title.nil?

    text = title.to_s

    # 1. Minimal HTML Escape FIRST (Only &, <, >)
    # Do this before typography to avoid escaping entities we create.
    # This will turn literal <br> into <br> and <Tags> into <Tags>
    escaped_text = text.gsub('&', '&amp;')
                       .gsub('<', '&lt;')
                       .gsub('>', '&gt;')

    # 2. Manual Typographic Transformations (Order matters for quotes)
    escaped_text.gsub!('---', '—')    # Em dash
    escaped_text.gsub!('--', '–')     # En dash
    escaped_text.gsub!('...', '…') # Ellipsis

    # Double quotes: “ ”
    # Match " preceded by space/start/(/[ or followed by word char
    escaped_text.gsub!(/(?<=\s|^|\[|\()"|"(?=\w)/, '“') # Opening "" (using lookbehind/lookahead)
    escaped_text.gsub!('"', '”') # Closing "" (remaining)

    # Single quotes: ‘ ’ - Apostrophes first
    escaped_text.gsub!(/(\w)'(\w)/, '\1’\2') # Apostrophe within word
    escaped_text.gsub!(/'(\d{2}s)/, '’\1') # Year abbreviations
    escaped_text.gsub!(/(\w)'(?=\s|$|,|\.|;|\?|!)/, '\1’') # Possessive at end
    # Match ' preceded by space/start/(/[ or followed by word char
    escaped_text.gsub!(/(?<=\s|^|\[|\()'|'(?=\w)/, '‘') # Opening ''
    escaped_text.gsub!('\'', '’') # Closing '' / Remaining apostrophes

    # 3. Restore literal <br> tags that were escaped in step 1
    # Ensure we match various forms of <br> that might have been escaped.
    escaped_text.gsub!('&lt;br&gt;', '<br>')
    escaped_text.gsub!('&lt;br/&gt;', '<br>')
    escaped_text.gsub!('&lt;br /&gt;', '<br>') # With space

    # Return the final text
    escaped_text
  end
end
