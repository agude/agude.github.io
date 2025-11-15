# _plugins/display_books_by_author_then_series_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/book_list_utils'
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

    # Simple slugify: downcase, replace non-alphanumeric with hyphen, consolidate hyphens.
    # More robust slugification could be moved to TextProcessingUtils if needed elsewhere.
    private def _slugify(text)
      return '' if text.nil?

      text.to_s.downcase.strip
          .gsub(/\s+/, '-')          # Replace spaces with hyphens
          .gsub(/[^\w-]+/, '')       # Remove all non-word chars except hyphens
          .gsub(/--+/, '-')          # Replace multiple hyphens with a single one
          .gsub(/^-+|-+$/, '')       # Remove leading/trailing hyphens
    end

    def render(context)
      site = context.registers[:site]

      data_by_author = BookListUtils.get_data_for_all_books_by_author_display(
        site: site,
        context: context
      )

      log_messages = data_by_author[:log_messages] || ''

      return log_messages if data_by_author[:authors_data].empty? && !log_messages.empty?
      return '' if data_by_author[:authors_data].empty?

      # --- Pass 1: Build content buffer and collect first anchor for each letter ---
      output_buffer = ''
      first_anchor_for_letter = {}

      data_by_author[:authors_data].each do |author_data|
        author_name = author_data[:author_name]
        author_slug = _slugify(author_name)
        current_letter = author_name[0].upcase

        # Store the first slug we encounter for this letter
        first_anchor_for_letter[current_letter] ||= author_slug

        # Author heading is H2 with a semantic ID
        output_buffer << "<h2 class=\"book-list-headline\" id=\"#{author_slug}\">#{CGI.escapeHTML(author_name)}</h2>\n"

        # Handle Standalone Books for this author (as H3)
        if author_data[:standalone_books]&.any?
          standalone_id = "standalone-books-#{author_slug}"
          output_buffer << "<h3 class=\"book-list-headline\" id=\"#{standalone_id}\">Standalone Books</h3>\n"
          output_buffer << "<div class=\"card-grid\">\n"
          author_data[:standalone_books].each do |book|
            output_buffer << BookCardUtils.render(book, context) << "\n"
          end
          output_buffer << "</div>\n"
        end

        # Handle Series Groups for this author (Series titles will be H3)
        series_only_data = {
          standalone_books: [],
          series_groups: author_data[:series_groups],
          log_messages: ''
        }

        next unless author_data[:series_groups]&.any?

        output_buffer << BookListUtils.render_book_groups_html(
          series_only_data,
          context,
          series_heading_level: 3
        )
      end

      # --- Pass 2: Build navigation using the collected anchors ---
      existing_letters = Set.new(first_anchor_for_letter.keys)
      all_chars_for_nav = ('A'..'Z').to_a
      nav_links = []

      all_chars_for_nav.each do |char|
        if existing_letters.include?(char)
          anchor_slug = first_anchor_for_letter[char]
          nav_links << "<a href=\"##{anchor_slug}\">#{char}</a>"
        else
          nav_links << "<span>#{char}</span>"
        end
      end

      nav_html = "<nav class=\"alpha-jump-links\">\n"
      nav_html << "  #{nav_links.join(' ')}\n"
      nav_html << "</nav>\n"

      # --- Final Assembly ---
      log_messages + nav_html + output_buffer
    end
  end
end

Liquid::Template.register_tag('display_books_by_author_then_series', Jekyll::DisplayBooksByAuthorThenSeriesTag)
