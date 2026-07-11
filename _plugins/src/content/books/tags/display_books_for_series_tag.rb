# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../lists/series_finder'
require_relative '../lists/renderers/for_series_renderer'
require_relative '../../../ui/cards/markdown_card_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../ui/tags/display_tag_renderable'

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
        include Jekyll::UI::DisplayTagRenderable

        # Aliases for readability
        Finder = Jekyll::Books::Lists::SeriesFinder
        Renderer = Jekyll::Books::Lists::Renderers::ForSeriesRenderer
        MdText = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :Finder, :Renderer, :MdText

        def initialize(tag_name, markup, tokens)
          super
          @series_name_markup = markup.strip
          return unless @series_name_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_books_for_series': Series name (string literal or variable) is required."
        end

        private

        def finder_for(context)
          Finder.new(
            site: context.registers[:site],
            series_name_filter: resolve_filter_value(@series_name_markup, context),
            context: context,
          )
        end

        def renderer_for(context, data)
          Renderer.new(context, data).render
        end

        def render_markdown(data)
          books = data[:books] || []
          return '' if books.empty?

          lines = []
          books.each_with_index do |book, idx|
            card = MdCards.book_doc_to_card_data(book)
            # Numbered list for reading order
            line = "#{idx + 1}. [#{MdText.escape_link_text(card[:title])}](#{MdText.escape_url(card[:url])})"
            line += " by #{card[:authors].join(', ')}" if card[:authors]&.any?
            stars = MdCards.format_stars(card[:rating])
            line += " --- #{stars}" if stars
            lines << line
          end
          lines.join("\n")
        end
      end
      Liquid::Template.register_tag('display_books_for_series', Jekyll::Books::Tags::DisplayBooksForSeriesTag)
    end
  end
end
