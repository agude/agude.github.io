# frozen_string_literal: true

# _plugins/utils/book_data_utils.rb
# Utility module for parsing and processing book-related data.
module BookDataUtils
  # Parses a book number value into a Float for sorting purposes.
  #
  # @param book_number_raw [String, Integer, Float, nil] The raw book number value
  # @return [Float] The parsed book number, or Float::INFINITY if invalid
  def self.parse_book_number(book_number_raw)
    return Float::INFINITY if book_number_raw.nil? || book_number_raw.to_s.strip.empty?

    Float(book_number_raw.to_s)
  rescue ArgumentError
    Float::INFINITY
  end
end
