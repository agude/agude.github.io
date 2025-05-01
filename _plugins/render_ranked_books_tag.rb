# _plugins/render_ranked_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For potential escaping in helpers
require_relative 'liquid_utils'

module Jekyll
  # Liquid Tag to render a list of books grouped by rating, based on a
  # pre-validated, monotonically sorted list of titles (e.g., page.ranked_list).
  # Assumes the list has already been checked for validity and order by
  # the {% check_monotonic_rating %} tag in non-production environments.
  #
  # Syntax: {% render_ranked_books list_variable %}
  # Example: {% render_ranked_books page.ranked_list %}
  #
  class RenderRankedBooksTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      @list_variable_markup = markup.strip
      unless @list_variable_markup && !@list_variable_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'render_ranked_books': A variable name holding the list must be provided."
      end
    end

    def render(context)
      site = context.registers[:site]

      # --- Step 1: Resolve the input list ---
      ranked_list = context[@list_variable_markup]

      unless ranked_list.is_a?(Array)
        return LiquidUtils.log_failure(
          context: context, tag_type: "RENDER_RANKED_BOOKS",
          reason: "Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{ranked_list.class}",
          identifiers: { Variable: @list_variable_markup }
        )
      end

      return "" if ranked_list.empty? # Nothing to render

      # --- Step 2: Build the Title -> Book Object Lookup Map ---
      unless site.collections.key?('books')
         return LiquidUtils.log_failure(
           context: context, tag_type: "RENDER_RANKED_BOOKS",
           reason: "Collection 'books' not found in site configuration.", identifiers: {}
         )
      end

      book_map = {}
      site.collections['books'].docs.each do |book|
        next if book.data['published'] == false
        title = book.data['title']
        next unless title && !title.to_s.strip.empty?
        # Use the utility for normalization (basic: lowercase, strip space/newlines)
        normalized = LiquidUtils.normalize_title(title, strip_articles: false)
        book_map[normalized] = book
      end

      # --- Step 3: Initialize State ---
      output = ""
      current_rating_group = nil
      is_div_open = false

      # --- Step 4: Single Pass through Ranked List to Render ---
      ranked_list.each do |current_title_raw|
        # Use the utility for normalization (basic: lowercase, strip space/newlines)
        current_title_normalized = LiquidUtils.normalize_title(current_title_raw, strip_articles: false)
        book_object = book_map[current_title_normalized]

        # Defensive Check: Handle if book is unexpectedly missing
        unless book_object
          output << LiquidUtils.log_failure(
            context: context, tag_type: "RENDER_RANKED_BOOKS",
            reason: "Book title from ranked list not found in lookup map (should have been caught by check tag)",
            identifiers: { Title: current_title_raw }
          )
          next # Skip this title
        end

        # Get rating and ensure it's a valid integer
        book_rating_raw = book_object.data['rating']
        begin
          book_rating = Integer(book_rating_raw)
        rescue ArgumentError, TypeError
          output << LiquidUtils.log_failure(
            context: context, tag_type: "RENDER_RANKED_BOOKS",
            reason: "Book has invalid non-integer rating",
            identifiers: { Title: current_title_raw, Rating: book_rating_raw.inspect }
          )
          next # Skip this book
        end

        # --- Check for Rating Group Change ---
        if book_rating != current_rating_group
          # Close previous group's div if it was open
          if is_div_open
            output << "</div>\n" # Close card-grid div
            is_div_open = false
          end

          # Start new group
          output << "<h2 class=\"book-list-headline\">" # Removed ID
          # --- UPDATED CALL ---
          # Call the LiquidUtils helper to render stars, using 'span' wrapper for H2
          output << LiquidUtils.render_rating_stars(book_rating, 'span')
          output << "</h2>\n"
          output << "<div class=\"card-grid\">\n"
          is_div_open = true
          current_rating_group = book_rating
        end

        # --- Render Book Card ---
        # --- UPDATED CALL ---
        # Call the LiquidUtils helper to render the book card
        output << LiquidUtils.render_book_card(book_object, context) << "\n"

      end # End loop through ranked_list

      # --- Step 5: Final Cleanup ---
      if is_div_open
        output << "</div>\n" # Close the last card-grid div
      end

      # --- Step 6: Return Rendered HTML ---
      output

    end # End render

  end # End class
end # End module

Liquid::Template.register_tag('render_ranked_books', Jekyll::RenderRankedBooksTag)
