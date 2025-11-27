# frozen_string_literal: true

# _plugins/display_books_by_author_then_series_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_list_utils'
require_relative 'utils/book_list_renderer_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Liquid Tag to display all books, grouped first by author (alphabetically),
  # then by series (alphabetically), with books in series sorted by book_number (numerically).
  # Standalone books for each author are also listed alphabetically by title.
  #
  # Usage: {% display_books_by_author_then_series %}
  #
  # This tag accepts no arguments.
  class DisplayBooksByAuthorThenSeriesTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      # No arguments to parse for this tag.
      return if markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
    end

    def render(context)
      Renderer.new(context).render
    end

    # Helper class to handle rendering logic
    class Renderer
      def initialize(context)
        @context = context
        @site = context.registers[:site]
      end

      def render
        data = fetch_data
        log_msg = data[:log_messages] || ''

        return log_msg if data[:authors_data].empty?

        content, anchors = build_content(data[:authors_data])
        nav = build_navigation(anchors)

        log_msg + nav + content
      end

      private

      def fetch_data
        BookListUtils.get_data_for_all_books_by_author_display(
          site: @site,
          context: @context
        )
      end

      def build_content(authors_data)
        buffer = +'' # Initialize as mutable string
        anchors = {}

        authors_data.each do |author_data|
          name = author_data[:author_name]
          slug = _slugify(name)
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
        books.each { |book| html << BookCardUtils.render(book, @context) << "\n" }
        html << "</div>\n"
      end

      def render_series(author_data)
        return '' unless author_data[:series_groups]&.any?

        data = {
          standalone_books: [],
          series_groups: author_data[:series_groups],
          log_messages: ''
        }
        BookListRendererUtils.render_book_groups_html(data, @context, series_heading_level: 3)
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

      def _slugify(text)
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

Liquid::Template.register_tag('display_books_by_author_then_series', Jekyll::DisplayBooksByAuthorThenSeriesTag)
