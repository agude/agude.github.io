# frozen_string_literal: true

# _plugins/utils/front_matter_utils.rb

# Utility module for processing and normalizing front matter values.
module FrontMatterUtils
  # Helper to consistently return an array of unique strings from a front matter value
  # that could be a single string or an array of strings.
  # Strips whitespace from each string, removes any resulting empty strings,
  # and ensures the final list contains only unique values.
  # Returns an empty array if the input is nil, not a string/array, or results in no valid items.
  #
  # @param fm_value [String, Array<String>, nil] The front matter value.
  # @return [Array<String>] An array of unique, processed, non-empty strings, or an empty array.
  def self.get_list_from_string_or_array(fm_value)
    items_list = []

    if fm_value.is_a?(String)
      stripped_item = fm_value.strip
      items_list << stripped_item unless stripped_item.empty?
    elsif fm_value.is_a?(Array)
      items_list = fm_value.compact.map { |item| item.to_s.strip }.reject(&:empty?)
    end
    # If fm_value is nil or any other type, items_list remains empty.

    items_list.uniq # Ensure uniqueness
  end
end
