# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../lists/author_finder'
require_relative '../lists/book_list_renderer_utils'
require_relative '../../../ui/tags/display_tag_renderable'

module Jekyll
  module Books
    # Liquid tags related to book content.
    module Tags
      # Liquid tag for displaying books grouped by series for a specific author.
      # Accepts author name as string literal or variable.
      #
      # Usage in Liquid templates:
      #   {% display_books_by_author "Ursula K. Le Guin" %}
      #   {% display_books_by_author page.author %}
      class DisplayBooksByAuthorTag < Liquid::Tag
        include Jekyll::UI::DisplayTagRenderable

        # Aliases for readability
        Finder = Jekyll::Books::Lists::AuthorFinder
        Renderer = Jekyll::Books::Lists::BookListRendererUtils
        private_constant :Finder, :Renderer

        def initialize(tag_name, markup, tokens)
          super
          @author_name_markup = markup.strip
          return unless @author_name_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_books_by_author': Author name (string literal or variable) is required."
        end

        private

        def finder_for(context)
          Finder.new(
            site: context.registers[:site],
            author_name_filter: resolve_filter_value(@author_name_markup, context),
            context: context,
          )
        end

        def renderer_for(context, data)
          Renderer.render_book_groups_html(data, context)
        end

        def render_markdown(data)
          MdCards.render_book_groups_md(data, heading_level: 2).join("\n")
        end
      end
      Liquid::Template.register_tag('display_books_by_author', Jekyll::Books::Tags::DisplayBooksByAuthorTag)
    end
  end
end
