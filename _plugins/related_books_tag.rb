# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require 'set'

require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  # Liquid Tag to display related books.
  # It prioritizes books from the same series, then by the same author,
  # and finally falls back to recent books to fill up to a defined maximum.
  #
  # Usage: {% related_books %}
  #
  # No arguments are currently accepted by this tag.
  # The maximum number of books to display is controlled by DEFAULT_MAX_BOOKS.
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      # No arguments to parse for this tag.
      # @max_books could be made configurable via markup in the future if needed.
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks ---
      # Ensure essential Jekyll objects and data are available.
      unless site && page && site.collections.key?('books') && page['url']
        missing_parts = []
        missing_parts << "site object" unless site
        missing_parts << "page object" unless page
        missing_parts << "site.collections['books']" unless site&.collections&.key?('books')
        missing_parts << "page['url']" unless page && page['url']

        return PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "RELATED_BOOKS",
          reason: "Missing prerequisites: #{missing_parts.join(', ')}.",
          identifiers: { PageURL: page ? page['url'] : 'N/A' },
          level: :error, # Critical prerequisite failure
        )
      end

      current_url = page['url']
      current_series = page['series']
      current_author = page['book_author']
      now_unix = Time.now.to_i # For filtering out future-dated books

      # --- Prepare Base Pool of All Potential Books ---
      # Filter out unpublished books, the current page itself, and future-dated books.
      all_potential_books = site.collections['books'].docs.select do |book|
        book.data['published'] != false &&
          book.url != current_url &&
          book.date && book.date.to_time.to_i <= now_unix
      end

      # Create a globally sorted list by date (most recent first).
      # This list is used for the author and recent books fallbacks.
      books_by_date_desc = all_potential_books.sort_by { |book| book.date }.reverse

      # --- Collect Candidate Books (Prioritized Accumulation) ---
      # Books are added to this accumulator in order of priority.
      # Duplicates are allowed at this stage; they will be handled by the final `uniq` call.
      candidate_books_accumulator = []

      # Priority 1: Books from the same series as the current page.
      if current_series && !current_series.to_s.strip.empty?
        series_books = all_potential_books.select { |book| book.data['series'] == current_series }
          .sort_by { |book| book.data['book_number'] || Float::INFINITY } # Sort by book number within the series
        candidate_books_accumulator.concat(series_books)
      end

      # Check the number of unique books found so far before proceeding to the next priority tier.
      # This ensures that fallbacks are only triggered if we haven't met @max_books with unique items.
      current_unique_urls = Set.new(candidate_books_accumulator.map(&:url))

      # Priority 2: Books by the same author (if not enough unique books from series).
      if current_unique_urls.length < @max_books && current_author && !current_author.to_s.strip.empty?
        # Select from the globally date-sorted list.
        # The final `uniq` will ensure that books already added from the series pool aren't duplicated
        # if they are also by the same author.
        author_books = books_by_date_desc.select do |book|
          book.data['book_author'] == current_author
        end
        candidate_books_accumulator.concat(author_books)
      end

      # Re-check unique count before the final fallback.
      current_unique_urls = Set.new(candidate_books_accumulator.map(&:url))

      # Priority 3: Recent books (if still not enough unique books).
      if current_unique_urls.length < @max_books
        # Add all remaining date-sorted books. The final `uniq` and `slice` will pick the most relevant.
        candidate_books_accumulator.concat(books_by_date_desc)
      end

      # --- Deduplicate and Limit Final Selection ---
      # `uniq` by book URL preserves the order of first appearance, respecting the prioritization
      # of how books were added to `candidate_books_accumulator`.
      # Then, slice to get the desired number of books.
      final_books = candidate_books_accumulator.uniq { |book| book.url }.slice(0, @max_books)

      # --- Render Output ---
      # If no related books are found after all filtering and prioritization, return an empty string.
      return "" if final_books.empty? # Expected empty state, no specific log needed here.

      output = "<aside class=\"related\">\n"
      # The header is static for this tag.
      output << "  <h2>Related Books</h2>\n"
      output << "  <div class=\"card-grid\">\n"

      final_books.each do |book|
        # Delegate rendering of individual book cards to the utility.
        output << BookCardUtils.render(book, context) << "\n"
      end

      output << "  </div>\n"
      output << "</aside>"

      output
    end
  end
end

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
