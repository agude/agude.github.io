# _plugins/related_books_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi'
require_relative 'liquid_utils'

module Jekyll
  class RelatedBooksTag < Liquid::Tag
    DEFAULT_MAX_BOOKS = 3

    def initialize(tag_name, markup, tokens)
      super
      @max_books = DEFAULT_MAX_BOOKS
    end

    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]

      # --- Basic Sanity Checks ---
      unless site && page && site.collections.key?('books') && page['url']
        return LiquidUtils.log_failure(
          context: context, tag_type: "RELATED_BOOKS",
          reason: "Missing context, collection, or page URL",
          identifiers: { PageURL: page ? page['url'] : 'N/A' }
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
      if current_series && !current_series.empty?
        # Sort by book_number within the series for potential ordering consistency
        series_books = all_books.select { |book| book.data['series'] == current_series }
                                .sort_by { |book| book.data['book_number'] || Float::INFINITY } # Handle nil book_number
        candidate_books.concat(series_books)
      end

      # 2. Same Author (if current page has an author)
      if current_author && !current_author.empty?
        author_books = books_by_date_desc.select { |book| book.data['book_author'] == current_author }
        candidate_books.concat(author_books)
      end

      # 3. Fallback to Recent Books
      candidate_books.concat(books_by_date_desc)

      # --- Deduplicate and Limit ---
      # Use uniq based on book object's identity, then slice
      final_books = candidate_books.uniq { |book| book.url }.slice(0, @max_books)

      # --- Render Output ---
      return "" if final_books.empty?

      output = "<aside class=\"related\">\n"
      output << "  <h2>Related Books</h2>\n"
      output << "  <div class=\"card-grid\">\n"

      final_books.each do |book|
        # Use the utility function to render the card
        output << LiquidUtils.render_book_card(book, context) << "\n"
      end

      output << "  </div>\n"
      output << "</aside>"

      output
    end # End render
  end # End class
end # End module

Liquid::Template.register_tag('related_books', Jekyll::RelatedBooksTag)
