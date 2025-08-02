# _plugins/display_books_by_title_alpha_group_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For CGI.escapeHTML
require 'set'
require_relative 'utils/book_list_utils'
require_relative 'utils/book_card_utils'

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
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
      end
    end

    def render(context)
      site = context.registers[:site]

      # Get the structured data from BookListUtils
      data_by_title_group = BookListUtils.get_data_for_all_books_by_title_alpha_group(
        site: site,
        context: context
      )

      output = data_by_title_group[:log_messages] || ""

      return output if data_by_title_group[:alpha_groups].empty? && !output.empty?
      return "" if data_by_title_group[:alpha_groups].empty?

      # --- Generate the alphabetical jump links navigation ---
      existing_letters = Set.new(data_by_title_group[:alpha_groups].map { |g| g[:letter] })
      all_chars_for_nav = ['#'] + ('A'..'Z').to_a
      nav_links = []

      all_chars_for_nav.each do |char|
        if existing_letters.include?(char)
          # Letter exists, create a link.
          id_letter = char == "#" ? "hash" : char.downcase
          nav_links << "<a href=\"#letter-#{CGI.escapeHTML(id_letter)}\">#{CGI.escapeHTML(char)}</a>"
        else
          # Letter does not exist, create a non-linked span.
          nav_links << "<span>#{CGI.escapeHTML(char)}</span>"
        end
      end

      # Join the links with spaces for a compact horizontal layout
      output << "<nav class=\"alpha-jump-links\">\n"
      output << "  #{nav_links.join(' ')}\n"
      output << "</nav>\n"
      # --- End of jump links navigation ---

      data_by_title_group[:alpha_groups].each do |alpha_group|
        letter = alpha_group[:letter]
        books_in_group = alpha_group[:books]

        # Letter heading is H2. ID is "letter-a", "letter-b", etc. or "letter-hash"
        id_letter = letter == "#" ? "hash" : letter.downcase
        output << "<h2 class=\"book-list-headline\" id=\"letter-#{CGI.escapeHTML(id_letter)}\">#{CGI.escapeHTML(letter)}</h2>\n"
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

Liquid::Template.register_tag('display_books_by_title_alpha_group', Jekyll::DisplayBooksByTitleAlphaGroupTag)
