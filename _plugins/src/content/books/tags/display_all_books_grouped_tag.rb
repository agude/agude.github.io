# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../lists/all_books_finder'
require_relative '../lists/book_list_renderer_utils'
require_relative '../../../ui/cards/markdown_card_utils'
require_relative '../../../ui/tags/display_tag_renderable'

module Jekyll
  module Books
    # Liquid tags related to book content.
    module Tags
      # Liquid tag for rendering all books grouped by author and series.
      # Automatically generates A-Z navigation for large lists.
      #
      # Usage in Liquid templates:
      #   {% display_all_books_grouped %}
      class DisplayAllBooksGroupedTag < Liquid::Tag
        include Jekyll::UI::DisplayTagRenderable

        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_all_books_grouped': This tag does not accept any arguments."
        end

        private

        def finder_for(context)
          Jekyll::Books::Lists::AllBooksFinder.new(
            site: context.registers[:site],
            context: context,
          )
        end

        def renderer_for(context, data)
          Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, context, generate_nav: true)
        end

        def render_markdown(data)
          MdCards.render_book_groups_md(data, heading_level: 2).join("\n")
        end
      end
      Liquid::Template.register_tag('display_all_books_grouped', Jekyll::Books::Tags::DisplayAllBooksGroupedTag)
    end
  end
end
