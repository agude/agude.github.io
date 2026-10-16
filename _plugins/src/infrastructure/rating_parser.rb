# frozen_string_literal: true

require 'jekyll'

module Jekyll
  module Infrastructure
    # The one parser for a book's `rating`, used by every output mode.
    #
    # A rating is an Integer, or a String of digits, from 1 to 5. A missing
    # rating (nil) is allowed and means "no stars". Anything else, such as
    # 4.9, "4.9", "4 stars", "", or 0, is an error rather than being
    # truncated or coerced by `to_i`.
    module RatingParser
      RANGE = (1..5)

      # @param raw [Integer, String, nil] The raw rating value.
      # @param error [Class] The exception class to raise. Defaults to
      #   FatalException; RatingUtils passes ArgumentError so the HTML card
      #   and preview renderers keep logging a bad rating.
      # @param source [String, nil] Names the book in the error message.
      # @return [Integer, nil] The rating, or nil when raw is nil.
      def self.parse(raw, error: Jekyll::Errors::FatalException, source: nil)
        return nil if raw.nil?

        value = coerce(raw)
        return value if value && RANGE.cover?(value)

        where = source ? " for '#{source}'" : ''
        message = "Invalid rating #{raw.inspect}#{where}: expected an integer from 1 to 5, " \
                  'as a number or a string of digits.'
        raise error, message
      end

      def self.coerce(raw)
        return raw if raw.is_a?(Integer)

        Integer(raw, 10) if raw.is_a?(String) && raw.match?(/\A\d+\z/)
      end
      private_class_method :coerce
    end
  end
end
