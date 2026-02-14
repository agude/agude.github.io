# frozen_string_literal: true

# _plugins/display_books_for_series_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/series_finder'
require_relative '../lists/renderers/for_series_renderer'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../markdown_output/markdown_card_utils'

module Jekyll
  module Books
    # Liquid tags related to book content.
    module Tags
      # Liquid tag for displaying all book cards in a specific series.
      # Accepts series name as string literal or variable.
      #
      # Usage in Liquid templates:
      #   {% display_books_for_series "The Lord of the Rings" %}
      #   {% display_books_for_series page.series %}
      class DisplayBooksForSeriesTag < Liquid::Tag
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Finder = Jekyll::Books::Lists::SeriesFinder
        Renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer
        private_constant :TagArgs, :Finder, :Renderer

        def initialize(tag_name, markup, tokens)
          super
          @series_name_markup = markup.strip
          return unless @series_name_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_books_for_series': Series name (string literal or variable) is required."
        end

        MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
        private_constant :MdCards

        def render(context)
          series_name_input = TagArgs.resolve_value(@series_name_markup, context)

          series_filter = if series_name_input && !series_name_input.to_s.strip.empty?
                            series_name_input.to_s
                          else
                            series_name_input
                          end

          finder = Finder.new(
            site: context.registers[:site],
            series_name_filter: series_filter,
            context: context,
          )
          data = finder.find

          if context.registers[:render_mode] == :markdown
            render_markdown(data)
          else
            output = +(data[:log_messages] || '')
            output << Renderer.new(context, data).render
          end
        end

        private

        def render_markdown(data)
          books = data[:books] || []
          return '' if books.empty?

          lines = []
          books.each_with_index do |book, idx|
            authors = book.data['book_authors']
            card = {
              title: book.data['title'],
              url: book.url,
              authors: authors.is_a?(Array) ? authors : [authors].compact,
              rating: book.data['rating'],
            }
            # Numbered list for reading order
            lines << "#{idx + 1}. [#{card[:title]}](#{card[:url]})" \
                     "#{" by #{card[:authors].join(', ')}" if card[:authors]&.any?}" \
                     "#{" --- #{"\u2605" * card[:rating].to_i}#{"\u2606" * (5 - card[:rating].to_i)}" if card[:rating]}"
          end
          lines.join("\n")
        end
      end
      Liquid::Template.register_tag('display_books_for_series', Jekyll::Books::Tags::DisplayBooksForSeriesTag)
    end
  end
end
