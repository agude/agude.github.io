# _plugins/display_all_books_grouped_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/book_list_utils'
require_relative 'utils/series_link_util'

module Jekyll
  class DisplayAllBooksGroupedTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'display_all_books_grouped': This tag does not accept any arguments."
      end
    end

    def render(context)
      site = context.registers[:site]
      data = BookListUtils.get_data_for_all_books_display(
        site: site,
        context: context
      )

      # BookListUtils.render_book_groups_html will prepend data[:log_messages] (if any)
      # and handle cases where no books are found.
      BookListUtils.render_book_groups_html(data, context)
    end
  end
  Liquid::Template.register_tag('display_all_books_grouped', DisplayAllBooksGroupedTag)
end
