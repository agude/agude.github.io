# frozen_string_literal: true

# _plugins/display_books_by_title_alpha_group_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For CGI.escapeHTML
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
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      TitleAlphaGroupRenderer.new(context).render
    end

    # Helper class to handle rendering logic
    class TitleAlphaGroupRenderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
      end

      def render
        data = BookListUtils.get_data_for_all_books_by_title_alpha_group(
          site: @site,
          context: @context
        )

        output = data[:log_messages] || ''
        return output if data[:alpha_groups].empty? && !output.empty?
        return '' if data[:alpha_groups].empty?

        output << generate_navigation(data[:alpha_groups])
        output << render_alpha_groups(data[:alpha_groups])
        output
      end

      private

      def generate_navigation(alpha_groups)
        existing_letters = Set.new(alpha_groups.map { |g| g[:letter] })
        all_chars_for_nav = ['#'] + ('A'..'Z').to_a
        nav_links = all_chars_for_nav.map do |char|
          generate_nav_link(char, existing_letters.include?(char))
        end

        "<nav class=\"alpha-jump-links\">\n  #{nav_links.join(' ')}\n</nav>\n"
      end

      def generate_nav_link(char, exists)
        id_letter = char == '#' ? 'hash' : char.downcase
        if exists
          "<a href=\"#letter-#{CGI.escapeHTML(id_letter)}\">" \
            "#{CGI.escapeHTML(char)}</a>"
        else
          "<span>#{CGI.escapeHTML(char)}</span>"
        end
      end

      def render_alpha_groups(alpha_groups)
        output = +''
        alpha_groups.each do |alpha_group|
          output << render_single_alpha_group(alpha_group)
        end
        output
      end

      def render_single_alpha_group(alpha_group)
        letter = alpha_group[:letter]
        books_in_group = alpha_group[:books]
        id_letter = letter == '#' ? 'hash' : letter.downcase

        output = '<h2 class="book-list-headline" ' \
                 "id=\"letter-#{CGI.escapeHTML(id_letter)}\">" \
                 "#{CGI.escapeHTML(letter)}</h2>\n"
        output << "<div class=\"card-grid\">\n"

        books_in_group.each do |book|
          output << BookCardUtils.render(book, @context) << "\n"
        end

        output << "</div>\n"
        output
      end
    end
  end
end

Liquid::Template.register_tag('display_books_by_title_alpha_group', Jekyll::DisplayBooksByTitleAlphaGroupTag)
