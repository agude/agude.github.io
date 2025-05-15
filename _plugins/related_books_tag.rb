# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'utils/plugin_logger_utils'
require_relative 'utils/book_card_utils'

module Jekyll
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      # No arguments to parse for this tag, but could add max_books from markup later if needed.
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks ---
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
          level: :error,
        )
      end

      current_url = page['url']
      current_series = page['series']
      current_author = page['book_author']
      now_unix = Time.now.to_i # Use Ruby Time for comparison

      # --- Prepare Book Data ---
      all_books = site.collections['books'].docs.select do |book|
        # Filter out unpublished books and the current page itself
        book.data['published'] != false &&
        book.url != current_url &&
        book.date && book.date.to_time.to_i <= now_unix
      end

      # Sort once by date descending for author/recent fallback
      books_by_date_desc = all_books.sort_by { |book| book.date }.reverse

      # --- Collect Candidates (Prioritized) ---
      candidate_books = []

      # 1. Same Series (if current page has a series)
      if current_series && !current_series.to_s.strip.empty?
        series_books = all_books.select { |book| book.data['series'] == current_series }
          .sort_by { |book| book.data['book_number'] || Float::INFINITY }
        candidate_books.concat(series_books)
      end

      # 2. Same Author (if current page has an author and not enough books from series)
      if candidate_books.length < @max_books && current_author && !current_author.to_s.strip.empty?
        author_books = books_by_date_desc.select { |book| book.data['book_author'] == current_author }
        candidate_books.concat(author_books)
      end

      # 3. Fallback to Recent Books (if still not enough books)
      if candidate_books.length < @max_books
        candidate_books.concat(books_by_date_desc)
      end

      # --- Deduplicate and Limit ---
      # Use uniq based on book object's identity, then slice
      final_books = candidate_books.uniq { |book| book.url }.slice(0, @max_books)

      # --- Render Output ---
      return "" if final_books.empty? # Expected empty state, no log needed here

      output = "<aside class=\"related\">\n"
      output << "  <h2>Related Books</h2>\n" # Header is always "Related Books" for this tag
      output << "  <div class=\"card-grid\">\n"

      final_books.each do |book|
        # Use the utility function to render the card
        output << BookCardUtils.render(book, context) << "\n"
      end

      output << "  </div>\n"
      output << "</aside>"

      output
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
