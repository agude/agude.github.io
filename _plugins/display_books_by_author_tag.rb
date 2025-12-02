# frozen_string_literal: true

# _plugins/display_books_by_author_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/book_lists/author_finder'
require_relative 'utils/book_list_renderer_utils'
require_relative 'src/infrastructure/tag_argument_utils'

# Jekyll namespace for custom plugins.
module Jekyll
  # Displays books grouped by series for a specific author.
  #
  # Usage in Liquid templates:
  #   {% display_books_by_author "Ursula K. Le Guin" %}
  #   {% display_books_by_author page.author %}
  class DisplayBooksByAuthorTag < Liquid::Tag
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
      def initialize(context, author_name_markup)
        @context = context
        @site = context.registers[:site]
        @author_name_markup = author_name_markup
      end

      def render
        author_name_input = TagArgumentUtils.resolve_value(@author_name_markup, @context)

        # Convert to string if not nil, otherwise pass nil to let AuthorFinder handle logging
        author_filter = if author_name_input && !author_name_input.to_s.strip.empty?
                          author_name_input.to_s
                        else
                          author_name_input
                        end

        finder = Jekyll::BookLists::AuthorFinder.new(
          site: @site,
          author_name_filter: author_filter,
          context: @context
        )
        data = finder.find

        # BookListRendererUtils.render_book_groups_html will prepend data[:log_messages]
        BookListRendererUtils.render_book_groups_html(data, @context)
      end
    end
  end
  Liquid::Template.register_tag('display_books_by_author', DisplayBooksByAuthorTag)
end
