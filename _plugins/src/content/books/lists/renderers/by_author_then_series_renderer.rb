# frozen_string_literal: true

# _plugins/logic/book_lists/renderers/by_author_then_series_renderer.rb
require_relative '../book_list_renderer_utils'
require_relative '../../core/book_card_utils'
require 'cgi'

module Jekyll
  module Books
    module Lists
      module Renderers
        module BookLists
          # Renders books grouped by author, then by series within each author.
          #
          # Takes author-grouped book data and generates navigation links plus
          # author sections with standalone books and series groups.
          class ByAuthorThenSeriesRenderer
            def initialize(context, data)
              @context = context
              @site = context.registers[:site]
              @authors_data = data[:authors_data] || []
            end

            def render
              return '' if @authors_data.empty?

              content, anchors = build_content(@authors_data)
              nav = build_navigation(anchors)

              nav + content
            end

            private

            def build_content(authors_data)
              buffer = +'' # Initialize as mutable string
              anchors = {}

              authors_data.each do |author_data|
                name = author_data[:author_name]
                slug = slugify(name)
                anchors[name[0].upcase] ||= slug

                buffer << render_author_section(author_data, slug)
              end

              [buffer, anchors]
            end

            def render_author_section(author_data, slug)
              name = CGI.escapeHTML(author_data[:author_name])
              html = "<h2 class=\"book-list-headline\" id=\"#{slug}\">#{name}</h2>\n"
              html << render_standalone(author_data, slug)
              html << render_series(author_data)
              html
            end

            def render_standalone(author_data, slug)
              books = author_data[:standalone_books]
              return '' unless books&.any?

              id = "standalone-books-#{slug}"
              html = "<h3 class=\"book-list-headline\" id=\"#{id}\">Standalone Books</h3>\n"
              html << "<div class=\"card-grid\">\n"
              books.each { |book| html << Jekyll::Books::Core::BookCardUtils.render(book, @context) << "\n" }
              html << "</div>\n"
            end

            def render_series(author_data)
              return '' unless author_data[:series_groups]&.any?

              data = {
                standalone_books: [],
                series_groups: author_data[:series_groups],
                log_messages: ''
              }
              Jekyll::Books::Lists::BookListRendererUtils.render_book_groups_html(data, @context,
                                                                                  series_heading_level: 3)
            end

            def build_navigation(anchors)
              links = ('A'..'Z').map do |char|
                if anchors.key?(char)
                  "<a href=\"##{anchors[char]}\">#{char}</a>"
                else
                  "<span>#{char}</span>"
                end
              end

              "<nav class=\"alpha-jump-links\">\n  #{links.join(' ')}\n</nav>\n"
            end

            def slugify(text)
              return '' if text.nil?

              text.to_s.downcase.strip
                  .gsub(/\s+/, '-')          # Replace spaces with hyphens
                  .gsub(/[^\w-]+/, '')       # Remove all non-word chars except hyphens
                  .gsub(/--+/, '-')          # Replace multiple hyphens with a single one
                  .gsub(/^-+|-+$/, '')       # Remove leading/trailing hyphens
            end
          end
        end
      end
    end
  end
end
