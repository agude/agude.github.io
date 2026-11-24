# frozen_string_literal: true

require 'jekyll'
require 'liquid'

require_relative '../ranking/ranked_books/processor'
require_relative '../ranking/ranked_books/renderer'

module Jekyll
  module Books
    module Tags
      # Liquid tag for displaying books grouped by rating.
      # Validates monotonic rating order in every build.
      class DisplayRankedBooksTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          @list_variable_markup = markup.strip
          return unless @list_variable_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_ranked_books': A variable name holding the list must be provided."
        end

        def render(context)
          groups = Jekyll::Books::Ranking::RankedBooks::Processor.new(context, @list_variable_markup).process
          renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(context, groups)

          context.registers[:render_mode] == :markdown ? renderer.render_markdown : renderer.render
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_ranked_books', Jekyll::Books::Tags::DisplayRankedBooksTag)
