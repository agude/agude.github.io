# _plugins/display_books_by_author_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'utils/book_list_utils'
require_relative 'utils/series_link_util'
require_relative 'utils/tag_argument_utils'

module Jekyll
  class DisplayBooksByAuthorTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @author_name_markup = markup.strip
      return unless @author_name_markup.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'display_books_by_author': Author name (string literal or variable) is required."
    end

    def render(context)
      site = context.registers[:site]
      author_name_input = TagArgumentUtils.resolve_value(@author_name_markup, context)

      unless author_name_input && !author_name_input.to_s.strip.empty?
        # Let BookListUtils handle logging for nil/empty author filter
        data = BookListUtils.get_data_for_author_display(
          site: site,
          author_name_filter: author_name_input, # Pass potentially nil/empty
          context: context
        )
        # render_book_groups_html will prepend data[:log_messages]
        return BookListUtils.render_book_groups_html(data, context)
      end

      data = BookListUtils.get_data_for_author_display(
        site: site,
        author_name_filter: author_name_input.to_s, # Ensure string
        context: context
      )

      # BookListUtils.render_book_groups_html will prepend data[:log_messages]
      # and handle cases where standalone_books or series_groups are empty.
      BookListUtils.render_book_groups_html(data, context)
    end
  end
  Liquid::Template.register_tag('display_books_by_author', DisplayBooksByAuthorTag)
end
