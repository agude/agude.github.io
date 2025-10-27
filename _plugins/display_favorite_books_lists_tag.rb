# _plugins/display_favorite_books_lists_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Liquid Tag to display books from "Favorite Books of..." lists.
  #
  # Usage: {% display_favorite_books_lists %}
  #
  # This tag accepts no arguments.
  class DisplayFavoriteBooksListsTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
      end
    end

    def render(context)
      site = context.registers[:site]
      baseurl = site.config['baseurl'] || ''

      data = BookListUtils.get_data_for_favorites_lists(
        site: site,
        context: context
      )

      output = data[:log_messages] || ""
      return output if data[:favorites_lists].empty?

      data[:favorites_lists].each do |list_data|
        post = list_data[:post]
        books = list_data[:books]
        next if books.empty?

        post_url = "#{baseurl}#{post.url}"
        post_title = CGI.escapeHTML(post.data['title'])

        output << "<h3 class=\"book-list-headline\"><a href=\"#{post_url}\">#{post_title}</a></h3>\n"
        output << "<div class=\"card-grid\">\n"

        books.each do |book|
          output << BookCardUtils.render(book, context) << "\n"
        end

        output << "</div>\n"
      end

      output
    end
  end
end

Liquid::Template.register_tag('display_favorite_books_lists', Jekyll::DisplayFavoriteBooksListsTag)
