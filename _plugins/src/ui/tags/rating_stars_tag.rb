# frozen_string_literal: true

# _plugins/rating_stars_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative '../ratings/rating_utils'
require_relative '../../infrastructure/tag_argument_utils'

module Jekyll
  module UI
    module Tags
      # Liquid Tag to render rating stars using the LiquidUtils helper.
      # Handles optional wrapper tag argument.
      #
      # Usage: {% rating_stars rating_value [wrapper_tag="tag"] %}
      # Example:
      #   {% rating_stars 4 %}
      #   {% rating_stars page.rating %}
      #   {% rating_stars 5 wrapper_tag="span" %}
      #   {% rating_stars book.rating wrapper_tag='div' %}
      class RatingStarsTag < Liquid::Tag
        SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment})/o # For key=value args

        def initialize(tag_name, markup, tokens)
          super
          @raw_markup = markup
          @rating_markup = nil
          @wrapper_tag_markup = nil # Default to nil -> util defaults to 'div'

          parse_markup(markup)
        end

        def render(context)
          # Resolve rating value
          rating_value = Jekyll::Infrastructure::TagArgumentUtils.resolve_value(@rating_markup, context)

          # Resolve wrapper tag (defaulting to 'div' is handled by the utility)
          wrapper_tag_value = 'div' # Default
          if @wrapper_tag_markup
            # resolve_value removes the quotes
            resolved_tag = Jekyll::Infrastructure::TagArgumentUtils.resolve_value(@wrapper_tag_markup, context)
            # Pass the resolved string (e.g., "span") to the utility
            wrapper_tag_value = resolved_tag if resolved_tag
          end

          # Call the utility function. It handles nil, validation, errors.
          Jekyll::UI::Ratings::RatingUtils.render_rating_stars(rating_value, wrapper_tag_value)
        end

        private

        def parse_markup(markup)
          scanner = StringScanner.new(markup.strip)
          scan_rating(scanner)
          scan_wrapper_tag(scanner)
          validate_end_of_string(scanner)
        end

        def scan_rating(scanner)
          # 1. Extract the Rating (first argument, must be variable or number 1-5)
          # It cannot be a quoted string like "4" because resolve_value would return "4" (String)
          # and render_rating_stars expects Integer or integer-like String.
          # Let render_rating_stars handle the type check.
          unless scanner.scan(/\S+/)
            raise Liquid::SyntaxError,
                  "Syntax Error in 'rating_stars': Rating value/variable is missing in '#{@raw_markup}'"
          end

          @rating_markup = scanner.matched
        end

        def scan_wrapper_tag(scanner)
          # 2. Scan for optional wrapper_tag="tag"
          scanner.skip(/\s*/)
          return unless scanner.scan(SYNTAX)

          key = scanner[1]
          value_markup = scanner[2]
          unless key == 'wrapper_tag'
            raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': Unknown argument '#{key}' in '#{@raw_markup}'"
          end

          # Optional: Raise error for invalid literal tag, or let util handle it
          # raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': wrapper_tag must be 'div' or 'span' " \
          #   "(quoted) in '#{@raw_markup}'"
          # Let's allow any quoted string and let the util default for invalid ones
          @wrapper_tag_markup = value_markup
        end

        def validate_end_of_string(scanner)
          # Ensure no other arguments are present
          scanner.skip(/\s+/)
          return if scanner.eos?

          raise Liquid::SyntaxError,
                "Syntax Error in 'rating_stars': Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
        end
      end
    end
  end
end

Liquid::Template.register_tag('rating_stars', Jekyll::UI::Tags::RatingStarsTag)
