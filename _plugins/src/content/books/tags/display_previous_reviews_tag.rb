# frozen_string_literal: true

# _plugins/display_previous_reviews_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../reviews/finder'
require_relative '../reviews/renderer'

# Displays previous reviews of the same book sorted by date.
#
# Finds all book reviews that share the same canonical URL and displays
# them chronologically.
#
# Usage in Liquid templates:
module Jekyll
  #   {% display_previous_reviews %}
  module Books
    module Tags
      # Liquid tag for displaying previous reviews of the same book.
      # Shows all reviews that share the same canonical URL, sorted chronologically.
      class DisplayPreviousReviewsTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_previous_reviews': This tag does not accept any arguments."
        end

        def render(context)
          finder = Jekyll::Books::Reviews::Finder.new(context)
          result = finder.find

          return result[:logs] if result[:reviews].empty?

          renderer = Jekyll::Books::Reviews::Renderer.new(context, result[:reviews])
          html_output = renderer.render

          result[:logs] + html_output
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_previous_reviews', Jekyll::Books::Tags::DisplayPreviousReviewsTag)
