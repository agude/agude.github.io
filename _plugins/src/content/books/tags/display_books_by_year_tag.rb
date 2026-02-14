# frozen_string_literal: true

# _plugins/display_books_by_year_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/by_year_finder'
require_relative '../lists/renderers/by_year_renderer'
require_relative '../../markdown_output/markdown_card_utils'

# Liquid Tag to display all books, grouped by year (most recent year first).
# Books within each year are sorted by date (most recent first).
#
# Usage: {% display_books_by_year %}
#
module Jekyll
  # This tag accepts no arguments.
  module Books
    module Tags
      # Liquid tag for displaying books grouped by year.
      # Most recent year appears first, with most recent books first within each year.
      class DisplayBooksByYearTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          finder = Jekyll::Books::Lists::ByYearFinder.new(site: context.registers[:site],
                                                          context: context)
          data = finder.find

          if context.registers[:render_mode] == :markdown
            render_markdown(data)
          else
            output = +(data[:log_messages] || '')
            output << Jekyll::Books::Lists::Renderers::ByYearRenderer.new(context, data).render
          end
        end

        private

        def render_markdown(data)
          groups = data[:year_groups] || []
          return '' if groups.empty?

          lines = []
          groups.each do |group|
            lines << "### #{group[:year]}"
            group[:books].each { |book| lines << MdCards.render_book_card_md(book_to_card(book)) }
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

Liquid::Template.register_tag('display_books_by_year', Jekyll::Books::Tags::DisplayBooksByYearTag)
