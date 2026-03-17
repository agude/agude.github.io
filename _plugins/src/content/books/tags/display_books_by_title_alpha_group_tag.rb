# frozen_string_literal: true

# _plugins/display_books_by_title_alpha_group_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/by_title_alpha_finder'
require_relative '../lists/renderers/by_title_alpha_renderer'
require_relative '../../markdown_output/markdown_card_utils'
require_relative '../../../ui/tags/display_tag_renderable'

# Liquid Tag to display all books, grouped by the first letter of their
# normalized title (articles "A", "An", "The" removed for sorting/grouping).
# Books within each letter group are sorted alphabetically by this normalized title.
#
# Usage: {% display_books_by_title_alpha_group %}
#
module Jekyll
  # This tag accepts no arguments.
  module Books
    module Tags
      # Liquid tag for displaying books grouped by first letter of title.
      # Ignores articles (A, An, The) when determining the grouping letter.
      class DisplayBooksByTitleAlphaGroupTag < Liquid::Tag
        include Jekyll::UI::DisplayTagRenderable

        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        def render(context)
          finder = Jekyll::Books::Lists::ByTitleAlphaFinder.new(
            site: context.registers[:site],
            context: context,
          )
          data = finder.find

          render_display_tag(context, data) do |d|
            Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(context, d).render
          end
        end

        private

        def render_markdown(data)
          groups = data[:alpha_groups] || []
          return '' if groups.empty?

          lines = []
          groups.each do |group|
            lines << "## #{group[:letter]}"
            group[:books].each { |book| lines << MdCards.render_book_card_md(MdCards.book_doc_to_card_data(book)) }
          end
          lines.join("\n")
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_books_by_title_alpha_group', Jekyll::Books::Tags::DisplayBooksByTitleAlphaGroupTag)
