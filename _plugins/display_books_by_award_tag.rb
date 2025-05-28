# _plugins/display_books_by_award_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For CGI.escapeHTML
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Liquid Tag to display all books, grouped by award.
  # Awards are sorted alphabetically. Books within each award are sorted by title.
  #
  # Usage: {% display_books_by_award %}
  #
  # This tag accepts no arguments.
  class DisplayBooksByAwardTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
      end
    end

    def render(context)
      site = context.registers[:site]

      data_by_award = BookListUtils.get_data_for_all_books_by_award_display(
        site: site,
        context: context
      )

      output = data_by_award[:log_messages] || ""

      return output if data_by_award[:awards_data].empty? && !output.empty?
      return "" if data_by_award[:awards_data].empty?

      data_by_award[:awards_data].each_with_index do |award_group, index|
        # Award heading is H2, using the formatted name and slug from the util
        # Ensure award_slug and award_name are HTML escaped for safety in attributes/content
        escaped_slug = CGI.escapeHTML(award_group[:award_slug] || "")
        escaped_name = CGI.escapeHTML(award_group[:award_name] || "")

        output << "<h2 class=\"book-list-headline\" id=\"#{escaped_slug}\">#{escaped_name}</h2>\n"
        output << "<div class=\"card-grid\">\n"

        award_group[:books].each do |book|
          output << BookCardUtils.render(book, context) << "\n"
        end

        output << "</div>\n"
      end

      output
    end
  end
end

Liquid::Template.register_tag('display_books_by_award', Jekyll::DisplayBooksByAwardTag)
