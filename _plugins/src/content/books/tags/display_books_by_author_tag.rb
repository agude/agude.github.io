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
          lines = []
          standalone = data[:standalone_books] || []
          series_groups = data[:series_groups] || []
          unless standalone.empty?
            lines << '## Standalone'
            standalone.each { |book| lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book)) }
          end
          series_groups.each do |group|
            lines << "## #{group[:name]}"
            group[:books].each { |book| lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book)) }
          end
          lines.join("\n")
        end
      end
      Liquid::Template.register_tag('display_books_by_author', Jekyll::Books::Tags::DisplayBooksByAuthorTag)
    end
  end
end
