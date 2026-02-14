# frozen_string_literal: true

# _plugins/display_books_by_title_alpha_group_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/by_title_alpha_finder'
require_relative '../lists/renderers/by_title_alpha_renderer'
require_relative '../../markdown_output/markdown_card_utils'

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
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          finder = Jekyll::Books::Lists::ByTitleAlphaFinder.new(site: context.registers[:site],
                                                                context: context)
          data = finder.find

          if context.registers[:render_mode] == :markdown
            render_markdown(data)
          else
            output = +(data[:log_messages] || '')
            output << Jekyll::Books::Lists::Renderers::ByTitleAlphaRenderer.new(context, data).render
          end
        end

        private

        def render_markdown(data)
          groups = data[:alpha_groups] || []
          return '' if groups.empty?

          lines = []
          groups.each do |group|
            lines << "### #{group[:letter]}"
            group[:books].each { |meta| lines << MdCards.render_book_card_md(book_to_card(meta[:book])) }
          end
          lines.join("\n")
        end

        def book_to_card(doc)
          authors = doc.data['book_authors']
          {
            title: doc.data['title'], url: doc.url,
            authors: authors.is_a?(Array) ? authors : [authors].compact,
            rating: doc.data['rating']
          }
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_books_by_title_alpha_group', Jekyll::Books::Tags::DisplayBooksByTitleAlphaGroupTag)
