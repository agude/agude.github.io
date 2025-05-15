# _plugins/utils/book_list_utils.rb
require_relative '../liquid_utils'
require_relative './series_link_util'
require_relative './url_utils'
require_relative 'plugin_logger_utils'
require_relative 'book_card_utils'

module BookListUtils

  # --- Public Methods for Tags ---

  def self.get_data_for_series_display(site:, series_name_filter:, context:)
    log_output_accumulator = ""

    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "series", series_name: series_name_filter || "N/A" },
        level: :error,
      )
      return { books: [], series_name: series_name_filter, log_messages: log_output_accumulator }
    end

    all_books = _get_all_published_books(site) # No context needed here anymore
    books_in_series = []

    series_name_provided_and_valid = series_name_filter && !series_name_filter.to_s.strip.empty?

    if series_name_provided_and_valid
      normalized_filter = series_name_filter.to_s.strip.downcase
      books_in_series = all_books.select { |book| book.data['series']&.strip&.downcase == normalized_filter }
        .sort_by { |book| [book.data['book_number'] || Float::INFINITY, book.data['title'].to_s.downcase] }

      if books_in_series.empty?
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_LIST_SERIES_DISPLAY",
          reason: "No books found for the specified series.",
          identifiers: { SeriesFilter: series_name_filter },
          level: :info,
        )
      end
    else
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_SERIES_DISPLAY",
        reason: "Series name filter was empty or nil.",
        identifiers: { SeriesFilterInput: series_name_filter || "N/A" },
        level: :warn,
      )
    end
    { books: books_in_series, series_name: series_name_filter, log_messages: log_output_accumulator }
  end

  def self.get_data_for_author_display(site:, author_name_filter:, context:)
    log_output_accumulator = ""

    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "author", author_name: author_name_filter || "N/A" },
        level: :error,
      )
      return { standalone_books: [], series_groups: [], log_messages: log_output_accumulator }
    end

    all_published = _get_all_published_books(site)
    author_books = []

    if author_name_filter && !author_name_filter.to_s.strip.empty?
      normalized_author_filter = author_name_filter.to_s.strip.downcase
      author_books = all_published.select { |book| book.data['book_author']&.strip&.downcase == normalized_author_filter }
      # If author_books is empty here, it means the author exists but has no books, or the author doesn't exist.
      # This is an expected empty state for a valid filter.
      if author_books.empty?
        log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: "BOOK_LIST_AUTHOR_DISPLAY",
          reason: "No books found for the specified author.",
          identifiers: { AuthorFilter: author_name_filter },
          level: :info,
        )
      end
    else
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_AUTHOR_DISPLAY",
        reason: "Author name filter was empty or nil when fetching data.",
        identifiers: { AuthorFilterInput: author_name_filter || "N/A" },
        level: :warn,
      )
    end

    structured_data = _structure_books_for_display(author_books)
    # Combine log messages
    structured_data[:log_messages] = (structured_data[:log_messages] || "") + log_output_accumulator
    structured_data
  end

  def self.get_data_for_all_books_display(site:, context:)
    log_output_accumulator = ""
    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "all_books" },
        level: :error,
      )
      return { standalone_books: [], series_groups: [], log_messages: log_output_accumulator }
    end

    all_books = _get_all_published_books(site)
    structured_data = _structure_books_for_display(all_books)
    # Prepend any initial log (like missing collection) to any logs from structuring (though structuring doesn't log currently)
    structured_data[:log_messages] = log_output_accumulator + (structured_data[:log_messages] || "")
    structured_data
  end

  # --- Public HTML Rendering Helper ---

  def self.render_book_groups_html(data, context)
    output = ""
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

  # This private method now assumes the 'books' collection exists,
  # as the public methods should have checked for it.
  def self._get_all_published_books(site)
    site.collections['books'].docs.select { |book| book.data['published'] != false }
  end

  # which is now handled by callers or not at all for this structuring step.
  def self._structure_books_for_display(books_to_process)
    standalone_books = []
    books_with_series = []
    # No logging within this specific structuring method for now.
    # If books_to_process is empty, it's considered a valid state passed from the caller.

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
        book.data['series'].to_s.strip.downcase,
        book.data['book_number'] || Float::INFINITY,
        book.data['title'].to_s.downcase,
      ]
    end

    grouped_by_series_name = books_with_series_sorted_for_grouping.group_by { |book| book.data['series'].to_s.strip }

    series_groups = grouped_by_series_name.map do |name, book_list|
      { name: name, books: book_list }
    end.sort_by { |group| group[:name].downcase }

    {
      standalone_books: sorted_standalone,
      series_groups: series_groups,
      log_messages: "", # Initialize empty, callers will prepend their own logs.
    }
  end
end
