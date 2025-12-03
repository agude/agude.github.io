# frozen_string_literal: true

# _plugins/logic/book_lists/renderers/by_title_alpha_renderer.rb
require_relative '../../core/book_card_utils'
require 'cgi'

module Jekyll
  module BookLists
    # Renders books grouped by first letter of title in HTML format.
    #
    # Takes alphabetically-grouped book data and generates navigation links
    # plus letter-sectioned book card grids.
    class ByTitleAlphaRenderer
      def initialize(context, data)
        @context = context
        @site = context.registers[:site]
        @alpha_groups = data[:alpha_groups] || []
      end

      def render
        return '' if @alpha_groups.empty?

        output = +''
        output << generate_navigation(@alpha_groups)
        output << render_alpha_groups(@alpha_groups)
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
