# frozen_string_literal: true

# _plugins/display_books_by_author_then_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/all_books_by_author_finder'
require_relative '../lists/renderers/by_author_then_series_renderer'
require_relative '../../markdown_output/markdown_card_utils'

# Liquid Tag to display all books, grouped first by author (alphabetically),
# then by series (alphabetically), with books in series sorted by book_number (numerically).
# Standalone books for each author are also listed alphabetically by title.
#
# Usage: {% display_books_by_author_then_series %}
#
module Jekyll
  # This tag accepts no arguments.
  module Books
    module Tags
      # Liquid tag for displaying all books grouped by author, then by series.
      # Books are sorted alphabetically within each group.
      class DisplayBooksByAuthorThenSeriesTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          # No arguments to parse for this tag.
          return if markup.strip.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          finder = Jekyll::Books::Lists::AllBooksByAuthorFinder.new(
            site: context.registers[:site], context: context,
          )
          data = finder.find

          if context.registers[:render_mode] == :markdown
            render_markdown(data)
          else
            output = +(data[:log_messages] || '')
            output << Jekyll::Books::Lists::Renderers::ByAuthorThenSeriesRenderer.new(context, data).render
          end
        end

        private

        def render_markdown(data)
          authors = data[:authors_data] || []
          return '' if authors.empty?

          lines = []
          authors.each do |author|
            lines << "### #{author[:author_name]}"
            (author[:series_groups] || []).each do |group|
              lines << "#### #{group[:name]}"
              group[:books].each { |book| lines << MdCards.render_book_card_md(book_to_card(book)) }
            end
            (author[:standalone_books] || []).each { |book| lines << MdCards.render_book_card_md(book_to_card(book)) }
          end
          lines.join("\n")
        end

        def book_to_card(doc)
          authors = doc.data['book_authors']
          {
            title: doc.data['title'],
            url: doc.url,
            authors: authors.is_a?(Array) ? authors : [authors].compact,
            rating: doc.data['rating'],
          }
        end
      end
    end
  end
end

Liquid::Template.register_tag('display_books_by_author_then_series', Jekyll::Books::Tags::DisplayBooksByAuthorThenSeriesTag)
