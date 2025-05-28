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
      unless markup.strip.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': This tag does not accept any arguments."
      end
    end

    # Simple slugify: downcase, replace non-alphanumeric with hyphen, consolidate hyphens.
    # More robust slugification could be moved to TextProcessingUtils if needed elsewhere.
    private def _slugify(text)
      return "" if text.nil?
      text.to_s.downcase.strip
        .gsub(/\s+/, '-')           # Replace spaces with hyphens
        .gsub(/[^\w-]+/, '')       # Remove all non-word chars except hyphens
        .gsub(/--+/, '-')          # Replace multiple hyphens with a single one
        .gsub(/^-+|-+$/, '')       # Remove leading/trailing hyphens
    end

    def render(context)
      site = context.registers[:site]

      # Get the structured data from BookListUtils
      # This method handles its own logging for critical issues like missing 'books' collection
      # or if no books with valid authors are found.
      data_by_author = BookListUtils.get_data_for_all_books_by_author_display(
        site: site,
        context: context,
      )

      # Initialize output with any top-level log messages from the utility
      # (e.g., "books collection not found" or "no books with valid authors found")
      output = data_by_author[:log_messages] || ""

      # If there's no actual author data to display (e.g., collection was empty or no valid authors),
      # and we already have a log message, just return that.
      # If no log message and no data, it will correctly return an empty string.
      return output if data_by_author[:authors_data].empty? && !output.empty?
      return "" if data_by_author[:authors_data].empty? # No data and no logs, return empty

      # Iterate over each author's data
      data_by_author[:authors_data].each do |author_data|
        author_name = author_data[:author_name]
        author_slug = self._slugify(author_name)

        # Author heading is H2
        output << "<h2 class=\"book-list-headline\">#{CGI.escapeHTML(author_name)}</h2>\n"

        # Handle Standalone Books for this author (as H3)
        if author_data[:standalone_books]&.any?
          # Construct unique ID for the standalone books section
          standalone_id = "standalone-books-#{author_slug}"
          output << "<h3 class=\"book-list-headline\" id=\"#{standalone_id}\">Standalone Books</h3>\n"
          output << "<div class=\"card-grid\">\n"
          author_data[:standalone_books].each do |book|
            output << BookCardUtils.render(book, context) << "\n"
          end
          output << "</div>\n"
        end

        # Handle Series Groups for this author (Series titles will be H3)
        # Create a temporary data hash for render_book_groups_html, excluding standalone books
        series_only_data = {
          standalone_books: [], # Already handled
          series_groups: author_data[:series_groups],
          log_messages: "",
        }

        if author_data[:series_groups]&.any?
          output << BookListUtils.render_book_groups_html(
            series_only_data,
            context,
            series_heading_level: 3, # Specify H3 for series titles
          )
        end
      end

      output
    end
  end
end

Liquid::Template.register_tag('display_books_by_author_then_series', Jekyll::DisplayBooksByAuthorThenSeriesTag)
