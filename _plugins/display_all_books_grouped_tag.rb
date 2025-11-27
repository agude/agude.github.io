# frozen_string_literal: true

# _plugins/display_all_books_grouped_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/book_lists/all_books_finder'
require_relative 'utils/book_list_renderer_utils'

# Jekyll namespace for custom plugins.
module Jekyll
  # Renders all books grouped by author and series.
  #
  # Usage in Liquid templates:
  #   {% display_all_books_grouped %}
  class DisplayAllBooksGroupedTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      return if markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'display_all_books_grouped': This tag does not accept any arguments."
    end

    def render(context)
      site = context.registers[:site]
      finder = Jekyll::BookLists::AllBooksFinder.new(site: site, context: context)
      data = finder.find

      # BookListRendererUtils.render_book_groups_html will prepend data[:log_messages] (if any)
      # and handle cases where no books are found.
      BookListRendererUtils.render_book_groups_html(data, context, generate_nav: true)
    end
  end
  Liquid::Template.register_tag('display_all_books_grouped', DisplayAllBooksGroupedTag)
end
