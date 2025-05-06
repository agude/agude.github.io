# _plugins/utils/rating_utils.rb
require 'jekyll' # For potential future Jekyll context, though not directly used by this method
require 'cgi'    # For CGI.escapeHTML if it were needed (not in current stars logic)

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
    # Allow nil input to return empty string silently
    return "" if rating.nil?

    rating_int = nil

    # --- Input Type Validation and Conversion ---
    if rating.is_a?(Integer)
      rating_int = rating
    elsif rating.is_a?(String) && rating.match?(/\A\d+\z/) # Only positive integer strings
      begin
        rating_int = Integer(rating)
      rescue ArgumentError
        # This should be rare with the regex, but catch just in case
        raise ArgumentError, "Invalid rating input: Cannot convert string '#{rating}' to Integer."
      end
    else
      # Invalid type (float, array, non-numeric string, negative string etc.)
      raise ArgumentError, "Invalid rating input type: '#{rating.inspect}' (#{rating.class}). Expected Integer(1-5), String('1'-'5'), or nil."
    end
    # --- End Input Type Validation ---


    # --- Range Validation ---
    unless (1..5).include?(rating_int)
      raise ArgumentError, "Invalid rating value: #{rating_int}. Rating must be between 1 and 5 (inclusive)."
    end
    # --- End Range Validation ---


    # --- HTML Generation (only runs if input is valid 1-5) ---
    max_stars = 5
    aria_label = "Rating: #{rating_int} out of #{max_stars} stars"
    css_class = "book-rating star-rating-#{rating_int}"

    stars_html = ""
    max_stars.times do |i|
      star_type = (i < rating_int) ? "full_star" : "empty_star"
      star_char = (i < rating_int) ? "★" : "☆"
      # aria-hidden is appropriate here as the wrapper has the aria-label
      stars_html << "<span class=\"book_star #{star_type}\" aria-hidden=\"true\">#{star_char}</span>"
    end

    # Validate wrapper_tag
    safe_wrapper_tag = %w[div span].include?(wrapper_tag.to_s.downcase) ? wrapper_tag.to_s.downcase : 'div'

    "<#{safe_wrapper_tag} class=\"#{css_class}\" role=\"img\" aria-label=\"#{aria_label}\">#{stars_html}</#{safe_wrapper_tag}>"
    # --- End HTML Generation ---
  end

end
