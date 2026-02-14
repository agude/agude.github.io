# frozen_string_literal: true

# _plugins/display_ranked_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'

require_relative '../ranking/ranked_books/processor'
require_relative '../ranking/ranked_books/renderer'
require_relative '../../markdown_output/markdown_card_utils'

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
module Jekyll
  module Books
    module Tags
      # Liquid tag for displaying books grouped by rating.
      # Validates monotonic rating order in non-production builds.
      class DisplayRankedBooksTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
          super
          @list_variable_markup = markup.strip
          return if @list_variable_markup && !@list_variable_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_ranked_books': A variable name holding the list must be provided."
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          processor = Jekyll::Books::Ranking::RankedBooks::Processor.new(context,
                                                                         @list_variable_markup)
          result = processor.process

          return result[:log_messages] if result[:rating_groups].empty?

          if context.registers[:render_mode] == :markdown
            render_markdown(result)
          else
            renderer = Jekyll::Books::Ranking::RankedBooks::Renderer.new(context,
                                                                         result[:rating_groups])
            result[:log_messages] + renderer.render
          end
        end

        private

        def render_markdown(result)
          lines = []
          (result[:rating_groups] || []).each do |group|
            stars = ("\u2605" * group[:rating]) + ("\u2606" * (5 - group[:rating]))
            lines << "### #{stars}"
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

Liquid::Template.register_tag('display_ranked_books', Jekyll::Books::Tags::DisplayRankedBooksTag)
