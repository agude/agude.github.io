# frozen_string_literal: true

require_relative '../core/book_link_util'

module Jekyll
  module Books
    module Backlinks
      module BookBacklinks
        # Renders HTML output for book backlinks.
        #
        # Takes structured backlink data and generates the final HTML
        # including the container, list items, and series explanations.
        class Renderer
          def initialize(context, page, backlinks)
            @context = context
            @page = page
            @backlinks = backlinks
          end

          def render
            return '' if @backlinks.empty?

            has_series = false
            list_items = @backlinks.map do |title, url, type|
              has_series = true if type == 'series'
              render_item(title, url, type)
            end.join

            build_container(list_items, has_series)
          end

          private

          def render_item(title, url, type)
            link = Jekyll::Books::Core::BookLinkUtils.render_book_link_from_data(title, url, @context)
            indicator = type == 'series' ? series_indicator : ''
            "<li class=\"book-backlink-item\" data-link-type=\"#{type}\">#{link}#{indicator}</li>"
          end

          def build_container(list_items, has_series)
            title = CGI.escapeHTML(@page['title'])
            out = '<aside class="book-backlinks"><h2 class="book-backlink-section"> ' \
                  "Reviews that mention <span class=\"book-title\">#{title}</span></h2>" \
                  "<ul class=\"book-backlink-list\">#{list_items}</ul>"
            out << series_explanation if has_series
            out << '</aside>'
          end

          def series_explanation
            '<p class="backlink-explanation"><sup>†</sup> <em>Mentioned via a link to the series.</em></p>'
          end

          def series_indicator
            '<sup class="series-mention-indicator" role="img" aria-label="Mentioned via series link" ' \
              'title="Mentioned via series link">†</sup>'
          end
        end
      end
    end
  end
end
