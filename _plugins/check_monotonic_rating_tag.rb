# _plugins/check_monotonic_rating_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils' # May not be needed directly, but good practice

module Jekyll
  # Liquid Tag to validate the monotonicity (descending order) of book ratings
  # based on a provided list of titles in front matter (e.g., page.ranked_list).
  #
  # Checks performed (only in non-production environments):
  # 1. Each title in the ranked list exists in the site.books collection.
  # 2. The rating associated with each title is less than or equal to the
  #    rating of the preceding title in the list.
  #
  # If validation fails, it raises an error, halting the Jekyll build.
  # If validation passes (or in production), it outputs nothing.
  #
  # Syntax: {% check_monotonic_rating list_variable %}
  # Example: {% check_monotonic_rating page.ranked_list %}
  #
  class CheckMonotonicRatingTag < Liquid::Tag

    def initialize(tag_name, markup, tokens)
      super
      @list_variable_markup = markup.strip
      unless @list_variable_markup && !@list_variable_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in 'check_monotonic_rating': A variable name holding the list must be provided."
      end
    end

    # Helper to normalize titles consistently (lowercase, strip, handle newlines)
    private def normalize_title(title)
      title.to_s.gsub("\n", " ").gsub(/\s+/, ' ').downcase.strip
    end

    def render(context)
      site = context.registers[:site]
      environment = site.config['environment'] || 'development'

      # --- Step 1: Only run in non-production environments ---
      return "" if environment == 'production'

      # --- Step 2: Resolve the input list ---
      ranked_list = context[@list_variable_markup] # Directly access variable from context

      unless ranked_list.is_a?(Array)
        raise "CheckMonotonicRating Error: Input '#{@list_variable_markup}' is not a valid list (Array). Found: #{ranked_list.class}"
      end

      return "" if ranked_list.empty? # Nothing to check

      # --- Step 3: Build the Title -> Rating Lookup Map ---
      unless site.collections.key?('books')
         raise "CheckMonotonicRating Error: Collection 'books' not found in site configuration."
      end

      rating_map = {}
      site.collections['books'].docs.each do |book|
        title = book.data['title']
        rating = book.data['rating']

        # Skip books without a title or rating, as they can't be validated
        next unless title && !title.to_s.strip.empty? && rating

        normalized = normalize_title(title)
        begin
          rating_int = Integer(rating) # Ensure rating is an integer
          rating_map[normalized] = rating_int
        rescue ArgumentError, TypeError
          # Log this potentially? For now, just skip books with non-integer ratings.
          # Could also raise an error here if ratings *must* be integers.
          Jekyll.logger.warn "[CheckMonotonicRating]", "Skipping book '#{title}' due to non-integer rating: '#{rating}'"
          next
        end
      end

      # --- Step 4: Validate the Ranked List ---
      previous_rating = Float::INFINITY # Initialize higher than any possible rating
      previous_title = nil

      ranked_list.each_with_index do |current_title_raw, index|
        current_title_normalized = normalize_title(current_title_raw)

        # Check 1: Does the title exist in our map?
        unless rating_map.key?(current_title_normalized)
          raise "CheckMonotonicRating Error: Title '#{current_title_raw}' (position #{index + 1} in '#{@list_variable_markup}') not found in the 'books' collection or has no valid rating."
        end

        current_rating = rating_map[current_title_normalized]

        # Check 2: Is the rating monotonically decreasing?
        if current_rating > previous_rating
          raise "CheckMonotonicRating Error: Monotonicity violation in '#{@list_variable_markup}'. \n" \
                "  Title '#{current_title_raw}' (Rating: #{current_rating}) at position #{index + 1} \n" \
                "  cannot appear after \n" \
                "  Title '#{previous_title}' (Rating: #{previous_rating}) at position #{index}."

        end

        # Update for next iteration
        previous_rating = current_rating
        previous_title = current_title_raw # Store original case title for error messages
      end

      # --- Step 5: Validation Passed ---
      # If we reach here without errors, the list is valid. Output nothing.
      ""

    rescue => e # Catch potential errors during processing
      # Re-raise standard errors or provide more context
      raise "CheckMonotonicRating Error processing '#{@list_variable_markup}': #{e.message}"
    end # End render

  end # End class
end # End module

Liquid::Template.register_tag('check_monotonic_rating', Jekyll::CheckMonotonicRatingTag)
