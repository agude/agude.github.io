# frozen_string_literal: true

require 'jekyll'
require 'liquid'
require_relative '../awards_page/finder'
require_relative '../awards_page/html_renderer'
require_relative '../awards_page/markdown_renderer'
require_relative '../lists/all_books_by_author_finder'
require_relative '../lists/all_books_finder'
require_relative '../lists/author_finder'
require_relative '../lists/book_list_renderer_utils'
require_relative '../lists/by_title_alpha_finder'
require_relative '../lists/by_year_finder'
require_relative '../lists/renderers/by_author_then_series_renderer'
require_relative '../lists/series_finder'
require_relative '../../../ui/tags/display_tag_renderable'

module Jekyll
  module Books
    # Liquid tags for book content.
    module Tags
      # @pattern Each book-list tag selects a finder and two renderers. Only the
      #   author and series filters accept a Liquid literal or variable.
      class DisplayBookListsTag < Liquid::Tag
        include Jekyll::UI::DisplayTagRenderable

        Renderer = Lists::BookListRendererUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        private_constant :Renderer, :Text

        # Finder, HTML method, Markdown method, and optional filter keyword.
        LISTS = {
          'display_all_books_grouped' => [Lists::AllBooksFinder, :all_books_html, :book_groups_markdown],
          'display_awards_page' => [AwardsPage::Finder, :awards_html, :awards_markdown],
          'display_books_by_author' => [Lists::AuthorFinder, :author_html, :book_groups_markdown, :author_name_filter],
          'display_books_by_author_then_series' => [Lists::AllBooksByAuthorFinder, :authors_html, :authors_markdown],
          'display_books_by_title_alpha_group' => [Lists::ByTitleAlphaFinder, :title_html, :title_markdown],
          'display_books_by_year' => [Lists::ByYearFinder, :year_html, :year_markdown],
          'display_books_for_series' => [Lists::SeriesFinder, :series_html, :series_markdown, :series_name_filter],
        }.freeze

        def initialize(tag_name, markup, tokens)
          super
          @finder, @html, @markdown, @filter = LISTS.fetch(tag_name)
          @filter_markup = markup.strip

          if @filter
            return unless @filter_markup.empty?

            label = @filter == :author_name_filter ? 'Author' : 'Series'
            raise Liquid::SyntaxError,
                  "Syntax Error in '#{tag_name}': #{label} name (string literal or variable) is required."
          end

          return if @filter_markup.empty?

          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
        end

        private

        def finder_for(context)
          arguments = { site: context.registers[:site], context: context }
          arguments[@filter] = resolve_filter_value(@filter_markup, context) if @filter
          @finder.new(**arguments)
        end

        def renderer_for(context, data)
          send(@html, context, data)
        end

        def render_markdown(data)
          send(@markdown, data)
        end

        # @gotcha The all-books and single-author HTML lists include finder
        #   diagnostics both in their group output and in the Liquid tag prefix.
        def all_books_html(context, data)
          Renderer.render_book_groups_html(data, context, generate_nav: true)
        end

        def author_html(context, data)
          Renderer.render_book_groups_html(data, context)
        end

        def authors_html(context, data)
          Lists::Renderers::ByAuthorThenSeriesRenderer.new(context, data).render
        end

        def title_html(context, data)
          Renderer.render_by_title_html(data[:alpha_groups], context)
        end

        def year_html(context, data)
          Renderer.render_by_year_html(data[:year_groups], context)
        end

        def series_html(context, data)
          return '' if data[:books].empty?

          Renderer.render_card_grid(data[:books], context)
        end

        def awards_html(context, data)
          AwardsPage::HtmlRenderer.new(context, data).render
        end

        def book_groups_markdown(data)
          MdCards.render_book_groups_md(data, heading_level: 2).join("\n")
        end

        def authors_markdown(data)
          Renderer.render_sections_markdown(data[:authors_data], :author_name) do |author|
            MdCards.render_book_groups_md(author, heading_level: 3)
          end
        end

        def title_markdown(data)
          Renderer.render_sections_markdown(data[:alpha_groups], :letter) do |group|
            Renderer.render_cards_markdown(group[:books])
          end
        end

        def year_markdown(data)
          Renderer.render_sections_markdown(data[:year_groups], :year) do |group|
            Renderer.render_cards_markdown(group[:books])
          end
        end

        def series_markdown(data)
          data[:books].map.with_index(1) do |book, number|
            card = MdCards.book_doc_to_card_data(book)
            line = "#{number}. [#{Text.escape_link_text(card[:title])}](#{Text.escape_url(card[:url])})"
            line += " by #{card[:authors].join(', ')}" if card[:authors]&.any?
            stars = MdCards.format_stars(card[:rating])
            line += " --- #{stars}" if stars
            line
          end.join("\n")
        end

        def awards_markdown(data)
          AwardsPage::MarkdownRenderer.new(data).render
        end
      end

      DisplayBookListsTag::LISTS.each_key do |name|
        Liquid::Template.register_tag(name, DisplayBookListsTag)
      end
    end
  end
end
