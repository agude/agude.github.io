# _plugins/utils/book_list_utils.rb
require_relative '../liquid_utils'
require_relative './series_link_util'
require_relative './url_utils'
require_relative 'plugin_logger_utils'
require_relative 'book_card_utils'

module BookListUtils

  # --- Public Methods for Tags ---

  def self.get_data_for_series_display(site:, series_name_filter:, context:)
    all_books = _get_all_published_books(site, context) # Pass context for logging
    books_in_series = []
    log_output_accumulator = ""

    series_name_provided_and_valid = series_name_filter && !series_name_filter.to_s.strip.empty?

    if series_name_provided_and_valid
      normalized_filter = series_name_filter.to_s.strip.downcase # Ensure string before strip/downcase
      books_in_series = all_books.select { |book| book.data['series']&.strip&.downcase == normalized_filter }
        .sort_by { |book| [book.data['book_number'] || Float::INFINITY, book.data['title'].to_s.downcase] }

      if books_in_series.empty?
        # Valid series name was provided, but no books matched it. This is informational.
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_LIST_SERIES_DISPLAY",
          reason: "No books found for the specified series.", # More specific reason
          identifiers: { SeriesFilter: series_name_filter }, # series_name_filter is valid here
          level: :info
        )
      end
    else
      # Series name filter itself was nil, empty, or whitespace. This is a warning.
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_SERIES_DISPLAY",
        reason: "Series name filter was empty or nil.", # More specific reason
        identifiers: { SeriesFilterInput: series_name_filter || "N/A" }, # Log what was passed
        level: :warn
      )
      # books_in_series remains empty
    end
    # Return data structure for the tag, including any accumulated log messages
    { books: books_in_series, series_name: series_name_filter, log_messages: log_output_accumulator }
  end

  def self.get_data_for_author_display(site:, author_name_filter:, context:)
    all_published = _get_all_published_books(site, context)
    author_books = []
    log_output_accumulator = ""

    if author_name_filter && !author_name_filter.to_s.strip.empty?
      normalized_author_filter = author_name_filter.to_s.strip.downcase
      author_books = all_published.select { |book| book.data['book_author']&.strip&.downcase == normalized_author_filter }
    else
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_AUTHOR_DISPLAY",
        reason: "Author name filter was empty or nil when fetching data.",
        identifiers: { AuthorFilter: author_name_filter || "N/A" },
        level: :warn # This is a warning about bad input
      )
    end

    structured_data = _structure_books_for_display(author_books, context)
    # Combine log messages
    structured_data[:log_messages] = (structured_data[:log_messages] || "") + log_output_accumulator
    structured_data
  end

  def self.get_data_for_all_books_display(site:, context:)
    all_books = _get_all_published_books(site, context)
    _structure_books_for_display(all_books, context)
  end

  # --- Public HTML Rendering Helper ---

  def self.render_book_groups_html(data, context)
    output = ""
    # Prepend any log messages generated during data fetching
    output << data[:log_messages] if data[:log_messages] && !data[:log_messages].empty?

    if data[:standalone_books]&.any?
      output << "<h2 class=\"book-list-headline\">Standalone Books</h2>\n"
      output << "<div class=\"card-grid\">\n"
      data[:standalone_books].each do |book|
        output << BookCardUtils.render(book, context) << "\n"
      end
      output << "</div>\n"
    end

    data[:series_groups]&.each do |series_group|
      series_title_html = SeriesLinkUtils.render_series_link(series_group[:name], context)
      output << "<h2 class=\"series-title\">#{series_title_html}</h2>\n"
      output << "<div class=\"card-grid\">\n"
      series_group[:books].each do |book|
        output << BookCardUtils.render(book, context) << "\n"
      end
      output << "</div>\n"
    end
    output
  end

  # --- Private Helper Methods ---

  private

  def self._get_all_published_books(site, context)
    unless site&.collections&.key?('books')
      # Log this failure directly as it's a prerequisite
      # The calling public method will then return this log message as part of its result.
      return [] # Return empty, the log will be handled by the caller's accumulator
    end
    site.collections['books'].docs.select { |book| book.data['published'] != false }
  end

  def self._structure_books_for_display(books_to_process, context)
    standalone_books = []
    books_with_series = []
    log_output_accumulator = "" # For logs specific to this structuring step

    # Check if books_to_process is empty and if it's due to a filter (e.g. author not found)
    # This might be logged by the calling function already.
    # If books_to_process is empty and no prior logs, it means no books matched initial criteria.
    if books_to_process.empty?
      # This situation (e.g., author exists but has no books, or no books on site for all_books_display)
      # might not be an "error" to log via log_failure, but rather just results in empty display.
      # log_failure is more for when something unexpected happens or data is malformed.
      # For now, let's assume if books_to_process is empty, it's a valid state.
    end

    books_to_process.each do |book|
      if book.data['series'].nil? || book.data['series'].to_s.strip.empty?
        standalone_books << book
      else
        books_with_series << book
      end
    end

    sorted_standalone = standalone_books.sort_by do |book|
      LiquidUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    end

    books_with_series_sorted_for_grouping = books_with_series.sort_by do |book|
      [
        book.data['series'].to_s.strip.downcase, # Primary sort by series name
        book.data['book_number'] || Float::INFINITY, # Secondary sort by book_number
        book.data['title'].to_s.downcase # Tertiary sort by title
      ]
    end

    grouped_by_series_name = books_with_series_sorted_for_grouping.group_by { |book| book.data['series'].to_s.strip }

    series_groups = grouped_by_series_name.map do |name, book_list|
      { name: name, books: book_list }
    end.sort_by { |group| group[:name].downcase } # Sort groups by series name alphabetically

    {
      standalone_books: sorted_standalone,
      series_groups: series_groups,
      log_messages: log_output_accumulator # Include logs from this step
    }
  end
end
