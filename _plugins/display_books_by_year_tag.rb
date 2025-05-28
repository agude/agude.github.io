# _plugins/display_books_by_year_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For CGI.escapeHTML
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Liquid Tag to display all books, grouped by year (most recent year first).
  # Books within each year are sorted by date (most recent first).
  #
  # Usage: {% display_books_by_year %}
  #
  # This tag accepts no arguments.
  class DisplayBooksByYearTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
      end
    end

    def render(context)
      site = context.registers[:site]

      data_by_year = BookListUtils.get_data_for_all_books_by_year_display(
        site: site,
        context: context
      )

      output = data_by_year[:log_messages] || ""

      return output if data_by_year[:year_groups].empty? && !output.empty?
      return "" if data_by_year[:year_groups].empty?

      data_by_year[:year_groups].each do |year_group|
        year = year_group[:year]
        books_in_group = year_group[:books]

        # Year heading is H2. ID is "year-YYYY".
        output << "<h2 class=\"book-list-headline\" id=\"year-#{CGI.escapeHTML(year)}\">#{CGI.escapeHTML(year)}</h2>\n"
        output << "<div class=\"card-grid\">\n"

        books_in_group.each do |book|
          output << BookCardUtils.render(book, context) << "\n"
        end

        output << "</div>\n" # Close card-grid
      end

      output
    end
  end
end

Liquid::Template.register_tag('display_books_by_year', Jekyll::DisplayBooksByYearTag)