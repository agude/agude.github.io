# _plugins/rating_stars_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require_relative 'liquid_utils'
require_relative 'utils/rating_utils' # Add this
require_relative 'utils/tag_argument_utils'

module Jekyll
  # Liquid Tag to render rating stars using the LiquidUtils helper.
  # Handles optional wrapper tag argument.
  #
  # Usage: {% rating_stars rating_value [wrapper_tag="tag"] %}
  # Example:
  #   {% rating_stars 4 %}
  #   {% rating_stars page.rating %}
  #   {% rating_stars 5 wrapper_tag="span" %}
  #   {% rating_stars book.rating wrapper_tag='div' %}
  #
  class RatingStarsTag < Liquid::Tag
    SYNTAX = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment})/o.freeze # For key=value args

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup
      @rating_markup = nil
      @wrapper_tag_markup = nil # Default to nil -> util defaults to 'div'

      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Rating (first argument, must be variable or number 1-5)
      # It cannot be a quoted string like "4" because resolve_value would return "4" (String)
      # and render_rating_stars expects Integer or integer-like String.
      # Let render_rating_stars handle the type check.
      unless scanner.scan(/\S+/)
        raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': Rating value/variable is missing in '#{@raw_markup}'"
      end
      @rating_markup = scanner.matched

      # 2. Scan for optional wrapper_tag="tag"
      scanner.skip(/\s*/)
      if scanner.scan(SYNTAX)
        key = scanner[1]
        value_markup = scanner[2]
        if key == 'wrapper_tag'
          # Ensure it's quoted 'div' or 'span' for safety, although util validates
          if value_markup == "'div'" || value_markup == '"div"' || value_markup == "'span'" || value_markup == '"span"'
            @wrapper_tag_markup = value_markup
          else
            # Optional: Raise error for invalid literal tag, or let util handle it
            # raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': wrapper_tag must be 'div' or 'span' (quoted) in '#{@raw_markup}'"
            # Let's allow any quoted string and let the util default for invalid ones
            @wrapper_tag_markup = value_markup
          end
        else
          raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': Unknown argument '#{key}' in '#{@raw_markup}'"
        end
      end

      # Ensure no other arguments are present
      scanner.skip(/\s+/)
      unless scanner.eos?
        raise Liquid::SyntaxError, "Syntax Error in 'rating_stars': Unexpected arguments '#{scanner.rest}' in '#{@raw_markup}'"
      end
    end

    def render(context)
      # Resolve rating value
      rating_value = TagArgumentUtils.resolve_value(@rating_markup, context) # This will change later

      # Resolve wrapper tag (defaulting to 'div' is handled by the utility)
      wrapper_tag_value = 'div' # Default
      if @wrapper_tag_markup
        # resolve_value removes the quotes
        resolved_tag = TagArgumentUtils.resolve_value(@wrapper_tag_markup, context) # This will change later
        # Pass the resolved string (e.g., "span") to the utility
        wrapper_tag_value = resolved_tag if resolved_tag
      end

      # Call the utility function. It handles nil, validation, errors.
      RatingUtils.render_rating_stars(rating_value, wrapper_tag_value)
    end
  end
end

Liquid::Template.register_tag('rating_stars', Jekyll::RatingStarsTag)
