# frozen_string_literal: true

# _plugins/utils/rating_utils.rb
require 'jekyll' # For potential future Jekyll context, though not directly used by this method
require 'cgi'    # For CGI.escapeHTML if it were needed (not in current stars logic)

# Utility module for generating HTML star rating displays.
module RatingUtils
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
    return '' if rating.nil?

    rating_int = _validate_and_convert_rating(rating)
    _generate_stars_html(rating_int, wrapper_tag)
  end

  # Validates and converts rating input to an integer.
  #
  # @param rating [Integer, String] The rating value to validate.
  # @return [Integer] The validated rating as an integer.
  # @raise [ArgumentError] if rating is invalid.
  def self._validate_and_convert_rating(rating)
    rating_int = _convert_to_integer(rating)
    _validate_range(rating_int)
    rating_int
  end

  # Converts rating to integer if it's a valid type.
  #
  # @param rating [Integer, String] The rating value to convert.
  # @return [Integer] The rating as an integer.
  # @raise [ArgumentError] if rating type is invalid.
  def self._convert_to_integer(rating)
    if rating.is_a?(Integer)
      rating
    elsif rating.is_a?(String) && rating.match?(/\A\d+\z/)
      _parse_string_rating(rating)
    else
      raise ArgumentError,
            "Invalid rating input type: '#{rating.inspect}' (#{rating.class}). " \
            "Expected Integer(1-5), String('1'-'5'), or nil."
    end
  end

  # Parses a string rating to integer.
  #
  # @param rating [String] The rating string to parse.
  # @return [Integer] The parsed rating.
  # @raise [ArgumentError] if string cannot be converted.
  def self._parse_string_rating(rating)
    Integer(rating)
  rescue ArgumentError
    raise ArgumentError, "Invalid rating input: Cannot convert string '#{rating}' to Integer."
  end

  # Validates that rating is in the 1-5 range.
  #
  # @param rating_int [Integer] The rating to validate.
  # @raise [ArgumentError] if rating is out of range.
  def self._validate_range(rating_int)
    return if (1..5).include?(rating_int)

    raise ArgumentError,
          "Invalid rating value: #{rating_int}. Rating must be between 1 and 5 (inclusive)."
  end

  # Generates the HTML for star rating display.
  #
  # @param rating_int [Integer] The validated rating value (1-5).
  # @param wrapper_tag [String] The HTML tag to wrap the stars.
  # @return [String] The complete HTML string for the rating.
  def self._generate_stars_html(rating_int, wrapper_tag)
    max_stars = 5
    aria_label = "Rating: #{rating_int} out of #{max_stars} stars"
    css_class = "book-rating star-rating-#{rating_int}"
    stars_html = _build_stars_html(rating_int, max_stars)
    safe_wrapper_tag = _safe_wrapper_tag(wrapper_tag)

    "<#{safe_wrapper_tag} class=\"#{css_class}\" role=\"img\" " \
      "aria-label=\"#{aria_label}\">#{stars_html}</#{safe_wrapper_tag}>"
  end

  # Builds the HTML string for individual star elements.
  #
  # @param rating_int [Integer] The rating value (1-5).
  # @param max_stars [Integer] The maximum number of stars.
  # @return [String] The HTML for all star elements.
  def self._build_stars_html(rating_int, max_stars)
    stars_html = +''
    max_stars.times do |i|
      star_type = i < rating_int ? 'full_star' : 'empty_star'
      star_char = i < rating_int ? '★' : '☆'
      stars_html << "<span class=\"book_star #{star_type}\" aria-hidden=\"true\">#{star_char}</span>"
    end
    stars_html
  end

  # Validates and returns a safe wrapper tag.
  #
  # @param wrapper_tag [String] The requested wrapper tag.
  # @return [String] A safe wrapper tag (div or span).
  def self._safe_wrapper_tag(wrapper_tag)
    %w[div span].include?(wrapper_tag.to_s.downcase) ? wrapper_tag.to_s.downcase : 'div'
  end
end
