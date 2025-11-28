# frozen_string_literal: true

# _plugins/display_books_by_title_alpha_group_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'logic/book_lists/by_title_alpha_finder'
require_relative 'logic/book_lists/renderers/by_title_alpha_renderer'

module Jekyll
  # Liquid Tag to display all books, grouped by the first letter of their
  # normalized title (articles "A", "An", "The" removed for sorting/grouping).
  # Books within each letter group are sorted alphabetically by this normalized title.
  #
  # Usage: {% display_books_by_title_alpha_group %}
  #
  # This tag accepts no arguments.
  class DisplayBooksByTitleAlphaGroupTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      finder = Jekyll::BookLists::ByTitleAlphaFinder.new(site: context.registers[:site], context: context)
      data = finder.find

      output = +(data[:log_messages] || '')
      output << Jekyll::BookLists::ByTitleAlphaRenderer.new(context, data).render
    end
  end
end

Liquid::Template.register_tag('display_books_by_title_alpha_group', Jekyll::DisplayBooksByTitleAlphaGroupTag)
