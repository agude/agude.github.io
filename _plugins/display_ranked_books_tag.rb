# _plugins/display_ranked_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/rating_utils'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'
require_relative 'utils/text_processing_utils'

module Jekyll
  # Liquid Tag to validate (in non-prod) and render a list of books
  # grouped by rating, based on a monotonically sorted list of titles
  # (e.g., page.ranked_list).
  #
  # Combines the logic previously in check_monotonic_rating and render_ranked_books.
  #
  # Validation (Non-Production Only):
  # 1. Each title in the ranked list exists in the site.books collection
  #    and has a valid integer rating.
  # 2. The rating associated with each title is less than or equal to the
  #    rating of the preceding title in the list.
  # Validation failures raise an error, halting the build.
  #
  # Rendering:
  # - Outputs books grouped by rating using H2 tags and book cards.
  # - Uses LiquidUtils helpers for stars and cards.
  #
  # Syntax: {% display_ranked_books list_variable %}
  # Example: {% display_ranked_books page.ranked_list %}
  #
  class DisplayRankedBooksTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      @list_variable_markup = markup.strip
      unless @list_variable_markup && !@list_variable_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'display_ranked_books': A variable name holding the list must be provided."
      end
    end

    def render(context)
      site = context.registers[:site]
      environment = site.config['environment'] || 'development'
      is_production = (environment == 'production')

      # --- Step 1: Resolve the input list ---
      ranked_list = context[@list_variable_markup]

      unless ranked_list.is_a?(Array)
        # Log or raise? Let's raise, as it's a fundamental input error.
        raise "DisplayRankedBooks Error: Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{ranked_list.class}"
      end

      return "" if ranked_list.empty? # Nothing to render

      # --- Step 2: Build the Title -> Book Object Lookup Map ---
      unless site.collections.key?('books')
        # Log or raise? Raise, as the collection is essential.
        raise "DisplayRankedBooks Error: Collection 'books' not found in site configuration."
      end

      book_map = {}
      site.collections['books'].docs.each do |book|
        next if book.data['published'] == false
        title = book.data['title']
        next unless title && !title.to_s.strip.empty?
        normalized = TextProcessingUtils.normalize_title(title, strip_articles: false)
        book_map[normalized] = book
      end

      # --- Step 3: Initialize State ---
      output_buffer = ""
      current_rating_group = nil
      is_div_open = false
      found_ratings = [] # To collect unique ratings for the nav
      # Validation state (only used if not is_production)
      previous_rating = Float::INFINITY
      previous_title = nil

      # --- Step 4: Single Pass through Ranked List for Validation & Rendering ---
      ranked_list.each_with_index do |current_title_raw, index|
        current_title_normalized = TextProcessingUtils.normalize_title(current_title_raw, strip_articles: false)
        book_object = book_map[current_title_normalized]
        book_rating = nil # Initialize rating for this iteration

        # --- Validation Step (Non-Production Only) ---
        unless is_production
          # Check 1: Existence
          unless book_object
            raise "DisplayRankedBooks Validation Error: Title '#{current_title_raw}' (position #{index + 1} in '#{@list_variable_markup}') not found in the 'books' collection."
          end

          # Check 2: Valid Rating
          book_rating_raw = book_object.data['rating']
          begin
            book_rating = Integer(book_rating_raw)
          rescue ArgumentError, TypeError
            raise "DisplayRankedBooks Validation Error: Title '#{current_title_raw}' (position #{index + 1} in '#{@list_variable_markup}') has invalid non-integer rating: '#{book_rating_raw.inspect}'."
          end

          # Check 3: Monotonicity
          if book_rating > previous_rating
            raise "DisplayRankedBooks Validation Error: Monotonicity violation in '#{@list_variable_markup}'. \n" \
              "  Title '#{current_title_raw}' (Rating: #{book_rating}) at position #{index + 1} \n" \
              "  cannot appear after \n" \
              "  Title '#{previous_title}' (Rating: #{previous_rating}) at position #{index}."
          end

          # Update validation state for next iteration
          previous_rating = book_rating
          previous_title = current_title_raw
        end
        # --- End Validation Step ---

        # --- Rendering Step ---
        # Ensure we have the book object for rendering (even in production)
        unless book_object
          # This should only happen in production if validation is skipped and list is bad
          # or if a book was unpublished after the list was generated.
          output_buffer << PluginLoggerUtils.log_liquid_failure(
            context: context, tag_type: "DISPLAY_RANKED_BOOKS",
            reason: "Book title from ranked list not found in lookup map (Production Mode).",
            identifiers: { Title: current_title_raw, ListVariable: @list_variable_markup },
            level: :error,
          )
          next # Skip rendering this item
        end

        # Get rating for rendering (re-calculate if in production)
        if is_production
          book_rating_raw = book_object.data['rating']
          begin
            book_rating = Integer(book_rating_raw)
          rescue ArgumentError, TypeError
            output_buffer << PluginLoggerUtils.log_liquid_failure(
              context: context, tag_type: "DISPLAY_RANKED_BOOKS",
              reason: "Book has invalid non-integer rating (Production Mode).",
              identifiers: { Title: current_title_raw, Rating: book_rating_raw.inspect, ListVariable: @list_variable_markup },
              level: :error,
            )
            next # Skip rendering this item
          end
        end

        # If book_rating is still nil here (e.g. validation failed in non-prod, or parsing failed in prod and was skipped),
        # or if it became nil for any other reason, skip this item.
        next unless book_rating

        # Check for Rating Group Change
        if book_rating != current_rating_group
          if is_div_open
            output_buffer << "</div>\n" # Close card-grid div
            is_div_open = false
          end

          found_ratings << book_rating # Collect the rating for the nav

          # Add the id attribute back to the H2 tag
          h2_id = "rating-#{book_rating}"
          output_buffer << "<h2 class=\"book-list-headline\" id=\"#{h2_id}\">"
          output_buffer << RatingUtils.render_rating_stars(book_rating, 'span')
          output_buffer << "</h2>\n"
          output_buffer << "<div class=\"card-grid\">\n"
          is_div_open = true
          current_rating_group = book_rating
        end

        # Render Book Card
        output_buffer << BookCardUtils.render(book_object, context) << "\n"
        # --- End Rendering Step ---

      end # End loop through ranked_list

      # --- Step 5: Final Cleanup ---
      if is_div_open
        output_buffer << "</div>\n" # Close the last card-grid div
      end

      # --- Step 6: Generate and Prepend Navigation ---
      nav_html = ""
      unless found_ratings.empty?
        nav_links = found_ratings.map do |rating|
          rating_text = rating == 1 ? "#{rating}-Star" : "#{rating}-Stars"
          "<a href=\"#rating-#{rating}\">#{rating_text}</a>"
        end
        nav_html << "<nav class=\"alpha-jump-links\">\n"
        nav_html << "  #{nav_links.join(' ')}\n"
        nav_html << "</nav>\n"
      end

      # --- Step 7: Return Rendered HTML ---
      output = nav_html + output_buffer
      output

    rescue => e # This rescue is for the entire render method
      # Re-raise standard errors or provide more context for Liquid syntax or fundamental errors.
      # Errors caught by PluginLoggerUtils above will return an HTML comment and continue if possible.
      # This catch is for unexpected errors in the tag's own logic or unhandled exceptions from utils.
      raise "DisplayRankedBooks Error processing '#{@list_variable_markup}': #{e.message} \n #{e.backtrace.join("\n  ")}"
    end # End render method
  end # End class DisplayRankedBooksTag
end # End module Jekyll

Liquid::Template.register_tag('display_ranked_books', Jekyll::DisplayRankedBooksTag)
