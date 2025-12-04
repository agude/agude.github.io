# frozen_string_literal: true

# _plugins/logic/book_lists/renderers/by_year_renderer.rb
require_relative '../../core/book_card_utils'
require 'cgi'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Renders books grouped by year in HTML format.
          #
          # Takes year-grouped book data and generates navigation links plus
          # year-sectioned book card grids.
          class ByYearRenderer
            def initialize(context, data)
              @context = context
              @site = context.registers[:site]
              @year_groups = data[:year_groups] || []
            end

            def render
              return '' if @year_groups.empty?

              output = +''
              output << generate_navigation(@year_groups)
              output << render_year_groups(@year_groups)
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
                output << Jekyll::Books::Core::BookCardUtils.render(book, @context) << "\n"
              end

              output << "</div>\n"
              output
            end
          end
        end
      end
    end
  end
end
