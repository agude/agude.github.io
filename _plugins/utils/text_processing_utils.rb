# _plugins/utils/text_processing_utils.rb
require 'nokogiri'

module TextProcessingUtils

  # Cleans HTML content to plain text, normalizes whitespace.
  # Removes script and style tag contents.
  # @param html_content [String] The HTML string to clean.
  # @return [String] The cleaned plain text.
  def self.clean_text_from_html(html_content)
    return "" if html_content.nil? || html_content.strip.empty?
    doc = Nokogiri::HTML(html_content.to_s)
    doc.xpath('//script | //style').remove # Remove script and style elements
    doc.text.gsub(/\s+/, ' ').strip       # Get text from remaining, normalize whitespace
  end

  # Truncates a string to a specified number of words.
  # Input text is stripped of leading/trailing whitespace before processing.
  # @param text [String] The text to truncate.
  # @param num_words [Integer] The maximum number of words.
  # @param omission [String] The string to append if truncated.
  # @return [String] The truncated (or original) text.
  def self.truncate_words(text, num_words, omission = "...")
    return "" if text.nil?
    # Strip leading/trailing whitespace from the input first
    stripped_text = text.to_s.strip
    # If after stripping, the text is empty, return empty string
    return "" if stripped_text.empty?

    words = stripped_text.split
    # If not enough words to truncate, return the already stripped text
    return stripped_text if words.length <= num_words
    # If truncating to 0 words, just return the omission
    return omission if num_words == 0 && words.any? # Ensure there were words to omit

    words[0...num_words].join(" ") + omission
  end

end
