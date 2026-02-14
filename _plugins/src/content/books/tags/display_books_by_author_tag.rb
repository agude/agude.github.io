# frozen_string_literal: true

# _plugins/display_books_by_author_tag.rb
require 'jekyll'
require 'liquid'
require_relative '../lists/author_finder'
require_relative '../lists/book_list_renderer_utils'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../markdown_output/markdown_card_utils'

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
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Finder = Jekyll::Books::Lists::AuthorFinder
        Renderer = Jekyll::Books::Lists::BookListRendererUtils
        private_constant :TagArgs, :Finder, :Renderer

        def initialize(tag_name, markup, tokens)
          super
          @author_name_markup = markup.strip
          return unless @author_name_markup.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'display_books_by_author': Author name (string literal or variable) is required."
        end

        def render(context)
          BooksByAuthorRenderer.new(context, @author_name_markup).render
        end

        # Helper class to handle rendering logic
        class BooksByAuthorRenderer
          MdCards = Jekyll::MarkdownOutput::MarkdownCardUtils
          private_constant :MdCards

          def initialize(context, author_name_markup)
            @context = context
            @site = context.registers[:site]
            @author_name_markup = author_name_markup
          end

          def render
            author_name_input = TagArgs.resolve_value(@author_name_markup, @context)

            # Convert to string if not nil, otherwise pass nil to let AuthorFinder handle logging
            author_filter = if author_name_input && !author_name_input.to_s.strip.empty?
                              author_name_input.to_s
                            else
                              author_name_input
                            end

            finder = Finder.new(
              site: @site,
              author_name_filter: author_filter,
              context: @context
            )
            data = finder.find

            if @context.registers[:render_mode] == :markdown
              render_markdown(data)
            else
              # Renderer.render_book_groups_html will prepend data[:log_messages]
              Renderer.render_book_groups_html(data, @context)
            end
          end

          private

          def render_markdown(data)
            lines = []
            (data[:series_groups] || []).each do |group|
              lines << "### #{group[:name]}"
              group[:books].each { |book| lines << MdCards.render_book_card_md(book_to_card(book)) }
            end
            standalone = data[:standalone_books] || []
            unless standalone.empty?
              lines << '### Standalone' unless (data[:series_groups] || []).empty?
              standalone.each { |book| lines << MdCards.render_book_card_md(book_to_card(book)) }
            end
            lines.join("\n")
          end

          def book_to_card(doc)
            authors = doc.data['book_authors']
            {
              title: doc.data['title'],
              url: doc.url,
              authors: authors.is_a?(Array) ? authors : [authors].compact,
              rating: doc.data['rating']
            }
          end
        end
      end
      Liquid::Template.register_tag('display_books_by_author', Jekyll::Books::Tags::DisplayBooksByAuthorTag)
    end
  end
end
