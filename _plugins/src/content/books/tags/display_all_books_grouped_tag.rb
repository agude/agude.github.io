# frozen_string_literal: true

# _plugins/display_all_books_grouped_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/all_books_finder'
require_relative '../lists/book_list_renderer_utils'
require_relative '../../markdown_output/markdown_card_utils'
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

        def render(context)
          site = context.registers[:site]
          finder = Jekyll::Books::Lists::AllBooksFinder.new(site: site, context: context)
          data = finder.find

          render_display_tag(context, data) do |_d|
            Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, context, generate_nav: true)
          end
        end

        private

        def render_markdown(data)
          lines = []
          standalone = data[:standalone_books] || []
          unless standalone.empty?
            lines << '## Standalone'
            standalone.each do |book|
              lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book))
            end
          end
          (data[:series_groups] || []).each do |group|
            lines << "## #{group[:name]}"
            group[:books].each do |book|
              lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book))
            end
          end
          lines.join("\n")
        end
      end
      Liquid::Template.register_tag('display_all_books_grouped', Jekyll::Books::Tags::DisplayAllBooksGroupedTag)
    end
  end
end
