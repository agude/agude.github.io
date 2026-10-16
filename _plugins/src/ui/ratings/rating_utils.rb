# frozen_string_literal: true

require 'jekyll' # For potential future Jekyll context, though not directly used by this method
require 'cgi'    # For CGI.escapeHTML if it were needed (not in current stars logic)
require_relative '../../infrastructure/rating_parser'

module Jekyll
  # Utility module for generating HTML star rating displays.
  module UI
    module Ratings
      # Utility module for rendering star rating HTML.
      # Generates visual star ratings from numeric values (1-5).
      module RatingUtils
        # Human-readable labels for each star rating, used in title and aria-label.
        RATING_LABELS = {
          1 => "Bad — I didn't like it",
          2 => 'Flawed — It was OK',
          3 => 'Good — I liked it',
          4 => 'Great — I really liked it',
          5 => 'Masterpiece — I loved it',
        }.freeze

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
          raise ArgumentError, 'Invalid rating input: nil.' if rating.nil?

          Jekyll::Infrastructure::RatingParser.parse(rating, error: ArgumentError)
        end

        # Generates the HTML for star rating display.
        #
        # @param rating_int [Integer] The validated rating value (1-5).
        # @param wrapper_tag [String] The HTML tag to wrap the stars.
        # @return [String] The complete HTML string for the rating.
        def self._generate_stars_html(rating_int, wrapper_tag)
          max_stars = 5
          label = RATING_LABELS[rating_int]
          escaped_label = CGI.escapeHTML(label)
          aria_label = "Rating: #{rating_int} out of #{max_stars} stars. #{escaped_label}"
          css_class = "book-rating star-rating-#{rating_int}"
          stars_html = _build_stars_html(rating_int, max_stars)
          safe_wrapper_tag = _safe_wrapper_tag(wrapper_tag)

          "<#{safe_wrapper_tag} class=\"#{css_class}\" role=\"img\" " \
            "aria-label=\"#{aria_label}\" title=\"#{escaped_label}\">#{stars_html}</#{safe_wrapper_tag}>"
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
    end
  end
end
