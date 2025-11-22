# frozen_string_literal: true

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
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      BooksByYearRenderer.new(context).render
    end

    # Helper class to handle rendering logic
    class BooksByYearRenderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
      end

      def render
        data = BookListUtils.get_data_for_all_books_by_year_display(
          site: @site,
          context: @context
        )

        output = data[:log_messages] || ''
        return output if data[:year_groups].empty? && !output.empty?
        return '' if data[:year_groups].empty?

        output << generate_navigation(data[:year_groups])
        output << render_year_groups(data[:year_groups])
        output
      end

      private

      def generate_navigation(year_groups)
        years = year_groups.map { |g| g[:year] }
        nav_links = years.map do |year|
          "<a href=\"#year-#{CGI.escapeHTML(year)}\">#{CGI.escapeHTML(year)}</a>"
        end

        "<nav class=\"alpha-jump-links\">\n  #{nav_links.join(' &middot; ')}\n</nav>\n"
      end

      def render_year_groups(year_groups)
        output = +''
        year_groups.each do |year_group|
          output << render_single_year_group(year_group)
        end
        output
      end

      def render_single_year_group(year_group)
        year = year_group[:year]
        books_in_group = year_group[:books]

        output = '<h2 class="book-list-headline" ' \
                 "id=\"year-#{CGI.escapeHTML(year)}\">" \
                 "#{CGI.escapeHTML(year)}</h2>\n"
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

Liquid::Template.register_tag('display_books_by_year', Jekyll::DisplayBooksByYearTag)
