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
    escaped_text = _escape_html(text)
    _apply_typography(escaped_text)
    _restore_br_tags(escaped_text)
    escaped_text
  end

  # Escapes HTML entities (&, <, >).
  #
  # @param text [String] The text to escape.
  # @return [String] The escaped text.
  def self._escape_html(text)
    text.gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
  end

  # Applies typographic transformations (dashes, quotes, apostrophes).
  #
  # @param text [String] The text to transform (modified in place).
  def self._apply_typography(text)
    _apply_dashes_and_ellipsis(text)
    _apply_double_quotes(text)
    _apply_single_quotes(text)
  end

  # Applies dash and ellipsis transformations.
  #
  # @param text [String] The text to transform (modified in place).
  def self._apply_dashes_and_ellipsis(text)
    text.gsub!('---', '—')    # Em dash
    text.gsub!('--', '–')     # En dash
    text.gsub!('...', '…')    # Ellipsis
  end

  # Applies double quote transformations.
  #
  # @param text [String] The text to transform (modified in place).
  def self._apply_double_quotes(text)
    # Opening double quotes (preceded by space/start/(/[ or followed by word char)
    text.gsub!(/(?<=\s|^|\[|\()"|"(?=\w)/, "\u201C")
    # Closing double quotes (remaining)
    text.gsub!('"', "\u201D")
  end

  # Applies single quote and apostrophe transformations.
  #
  # @param text [String] The text to transform (modified in place).
  def self._apply_single_quotes(text)
    text.gsub!(/(\w)'(\w)/, "\\1\u2019\\2")                     # Apostrophe within word
    text.gsub!(/'(\d{2}s)/, "\u2019\\1")                        # Year abbreviations
    text.gsub!(/(\w)'(?=\s|$|,|\.|;|\?|!)/, "\\1\u2019")        # Possessive at end
    text.gsub!(/(?<=\s|^|\[|\()'|'(?=\w)/, "\u2018")            # Opening single quotes
    text.gsub!("'", "\u2019")                                   # Remaining apostrophes
  end

  # Restores <br> tags that were escaped earlier.
  #
  # @param text [String] The text to transform (modified in place).
  def self._restore_br_tags(text)
    text.gsub!('&lt;br&gt;', '<br>')
    text.gsub!('&lt;br/&gt;', '<br>')
    text.gsub!('&lt;br /&gt;', '<br>')
  end
end
