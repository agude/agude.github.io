# frozen_string_literal: true

# _plugins/display_ranked_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative 'logic/display_ranked_books/processor'
require_relative 'logic/display_ranked_books/renderer'

module Jekyll
  # Liquid Tag to validate (in non-prod) and render a list of books
  # grouped by rating, based on a monotonically sorted list of titles.
  # (e.g., page.ranked_list).
  #
  # Combines the logic previously in check_monotonic_rating and render_ranked_books.
  #
  # Validation (Non-Production Only):
  # 1. Each title in the ranked list exists in the site.books collection
  #    and has a valid integer rating.
  # 2. The rating associated with each title is less than or equal to the
  #    rating of the preceding title in the list.
  # Validation failures raise an error, halting the build.
  #
  # Rendering:
  # - Outputs books grouped by rating using H2 tags and book cards.
  # - Uses LiquidUtils helpers for stars and cards.
  #
  # Syntax: {% display_ranked_books list_variable %}
  # Example: {% display_ranked_books page.ranked_list %}
  #
  class DisplayRankedBooksTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @list_variable_markup = markup.strip
      return if @list_variable_markup && !@list_variable_markup.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'display_ranked_books': A variable name holding the list must be provided."
    end

    def render(context)
      processor = Jekyll::DisplayRankedBooks::Processor.new(context, @list_variable_markup)
      result = processor.process

      return result[:log_messages] if result[:rating_groups].empty?

      renderer = Jekyll::DisplayRankedBooks::Renderer.new(context, result[:rating_groups])
      html_output = renderer.render

      result[:log_messages] + html_output
    end
  end
end

Liquid::Template.register_tag('display_ranked_books', Jekyll::DisplayRankedBooksTag)
