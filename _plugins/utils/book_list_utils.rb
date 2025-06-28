# _plugins/utils/book_list_utils.rb
require_relative './series_link_util'
require_relative './url_utils'
require_relative 'plugin_logger_utils'
require_relative 'book_card_utils'
require_relative 'text_processing_utils'
require_relative 'front_matter_utils'

module BookListUtils

  # --- Public Methods for Tags ---

  # Fetches and sorts books for a specific series.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param series_name_filter [String] The name of the series to filter by.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :books (Array of Document), :series_name (String), :log_messages (String).
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
        .sort_by do |book|
        [
          _parse_book_number(book.data['book_number']), # Use helper for numerical sort
          TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true) # Secondary sort by title
        ]
      end

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

  # Fetches and structures books for a specific author.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param author_name_filter [String] The name of the author to filter by.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
  def self.get_data_for_author_display(site:, author_name_filter:, context:)
    log_output_accumulator = ""
    link_cache = site.data['link_cache'] || {}
    author_cache = link_cache['authors'] || {}

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
      normalized_filter = TextProcessingUtils.normalize_title(author_name_filter)
      canonical_author_data = author_cache[normalized_filter]
      canonical_filter_name = canonical_author_data ? canonical_author_data['title'] : author_name_filter

      author_books = all_published.select do |book|
        # For each book, resolve its authors to their canonical names and check for a match.
        authors_list = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
        authors_list.any? do |book_author_name|
          normalized_book_author = TextProcessingUtils.normalize_title(book_author_name)
          book_author_data = author_cache[normalized_book_author]
          book_canonical_name = book_author_data ? book_author_data['title'] : book_author_name
          book_canonical_name.casecmp(canonical_filter_name).zero?
        end
      end

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

  # Fetches and structures all books for display.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
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

  # Fetches all books, groups them by author, then structures each author's books.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :authors_data (Array of Hashes), :log_messages (String).
  #   Each hash in :authors_data has :author_name, :standalone_books, :series_groups.
  def self.get_data_for_all_books_by_author_display(site:, context:)
    log_output_accumulator = ""
    link_cache = site.data['link_cache'] || {}
    author_cache = link_cache['authors'] || {}

    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL", # Generic util error for missing collection
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "all_books_by_author" }, # New filter type identifier
        level: :error,
      )
      return { authors_data: [], log_messages: log_output_accumulator }
    end

    all_published_books = _get_all_published_books(site)
    books_by_canonical_author = {} # Use a hash for easier accumulation

    all_published_books.each do |book|
      # Use FrontMatterUtils to get the list of authors for the current book
      author_names_for_book = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])

      author_names_for_book.each do |author_name_str|
        next if author_name_str.to_s.strip.empty?

        normalized_author_name = TextProcessingUtils.normalize_title(author_name_str)
        author_data = author_cache[normalized_author_name]
        canonical_name = author_data ? author_data['title'] : author_name_str.strip

        books_by_canonical_author[canonical_name] ||= []
        books_by_canonical_author[canonical_name] << book
      end
    end

    authors_data_list = []
    books_by_canonical_author.each do |canonical_name, books_for_this_author|
      # Deduplicate books for this author in case a book was added multiple times
      # (e.g., if 'book_authors' had ["A", "A"] - though FrontMatterUtils.uniq handles this for the list itself)
      # However, the grouping logic above should handle this correctly by adding the book object once per unique author.
      structured_author_books = _structure_books_for_display(books_for_this_author.uniq)
      authors_data_list << {
        author_name: canonical_name,
        standalone_books: structured_author_books[:standalone_books],
        series_groups: structured_author_books[:series_groups]
        # log_messages from _structure_books_for_display are ignored here,
        # as they are usually about empty results for a *specific filter*,
        # which isn't the case when processing a sub-list for an author.
      }
    end

    # Sort the final list of authors alphabetically by name (case-insensitive)
    sorted_authors_data = authors_data_list.sort_by { |author_entry| author_entry[:author_name].downcase }

    if sorted_authors_data.empty? && log_output_accumulator.empty?
      # This means the books collection was present, but no books had valid author names,
      # or there were no published books at all.
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "ALL_BOOKS_BY_AUTHOR_DISPLAY", # Specific tag type for this scenario
        reason: "No published books with valid author names found.",
        identifiers: {}, # No specific filter here
        level: :info, # This is an expected empty state if content is structured that way
      )
    end

    { authors_data: sorted_authors_data, log_messages: log_output_accumulator }
  end

  # Formats an award string into a display name (Title Case + " Award").
  private_class_method def self._format_award_display_name(award_string_raw)
    return "" if award_string_raw.nil? || award_string_raw.to_s.strip.empty?

    award_str = award_string_raw.to_s.strip

    # Titleize the raw award string and append " Award"
    titleized_name = award_str.split.map do |word|
      if word.length == 2 && word[1] == '.' && word[0].match?(/[a-z]/i) # e.g., "c." but not ".."
        word[0].upcase + "."
      else
        word.capitalize # Standard capitalization for other words
      end
    end.join(' ')

    "#{titleized_name} Award"
  end

  # Fetches all books, groups them by award.
  def self.get_data_for_all_books_by_award_display(site:, context:)
    log_output_accumulator = ""
    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "all_books_by_award" },
        level: :error,
      )
      return { awards_data: [], log_messages: log_output_accumulator }
    end

    all_published_books = _get_all_published_books(site)
    return { awards_data: [], log_messages: log_output_accumulator } if all_published_books.empty?

    unique_raw_awards = {}
    all_published_books.each do |book|
      book_awards = book.data['awards']
      if book_awards.is_a?(Array)
        book_awards.each do |award_entry|
          next if award_entry.nil? || award_entry.to_s.strip.empty?
          award_str_stripped = award_entry.to_s.strip
          award_str_downcased = award_str_stripped.downcase
          unique_raw_awards[award_str_downcased] ||= award_str_stripped
        end
      end
    end

    sorted_unique_raw_awards = unique_raw_awards.sort_by { |downcased, _original| downcased }.map { |_downcased, original| original }

    awards_data_list = []
    if sorted_unique_raw_awards.empty?
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "ALL_BOOKS_BY_AWARD_DISPLAY",
        reason: "No books with awards found.",
        identifiers: {},
        level: :info,
      )
      return { awards_data: [], log_messages: log_output_accumulator }
    end

    sorted_unique_raw_awards.each do |current_raw_award|
      books_for_this_award = all_published_books.select do |book|
        book_awards_list = book.data['awards']
        if book_awards_list.is_a?(Array)
          book_awards_list.any? { |ba| ba.to_s.strip.casecmp(current_raw_award.strip).zero? }
        else
          false
        end
      end

      next if books_for_this_award.empty?

      sorted_books_for_award = books_for_this_award.sort_by do |book|
        TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
      end

      display_award_name = _format_award_display_name(current_raw_award)
      award_slug = TextProcessingUtils.normalize_title(display_award_name, strip_articles: false)
        .gsub(/\s+/, '-')
        .gsub(/[^\w-]+/, '')
        .gsub(/--+/, '-')
        .gsub(/^-+|-+$/, '')

      awards_data_list << {
        award_name: display_award_name,
        award_slug: award_slug,
        books: sorted_books_for_award
      }
    end

    { awards_data: awards_data_list, log_messages: log_output_accumulator }
  end

  # Fetches all books, sorts them by normalized title, then groups by first letter.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :alpha_groups (Array of Hashes), :log_messages (String).
  #   Each hash in :alpha_groups has :letter (String) and :books (Array of Document).
  def self.get_data_for_all_books_by_title_alpha_group(site:, context:)
    log_output_accumulator = ""
    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "all_books_by_title_alpha_group" },
        level: :error,
      )
      return { alpha_groups: [], log_messages: log_output_accumulator }
    end

    all_published_books = _get_all_published_books(site)

    if all_published_books.empty?
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "ALL_BOOKS_BY_TITLE_ALPHA_GROUP",
        reason: "No published books found to group by title.",
        identifiers: {},
        level: :info, # Expected empty state if no books
      )
      return { alpha_groups: [], log_messages: log_output_accumulator }
    end

    # Create a temporary structure with sort_title for each book
    books_with_sort_title = all_published_books.map do |book|
      title = book.data['title'].to_s
      sort_title = TextProcessingUtils.normalize_title(title, strip_articles: true)
      # Handle cases where sort_title might be empty after normalization (e.g., title was just "A ")
      first_letter = sort_title.empty? ? "#" : sort_title[0].upcase
      first_letter = "#" unless first_letter.match?(/[A-Z]/) # Group non-alpha under "#"

      { book: book, sort_title: sort_title, first_letter: first_letter }
    end

    # Sort books primarily by their sort_title, then by original title (lowercase) for stability
    sorted_books_with_meta = books_with_sort_title.sort_by do |b_meta|
      [b_meta[:sort_title], b_meta[:book].data['title'].to_s.downcase]
    end

    # Group sorted books by the determined first_letter
    grouped_by_letter = sorted_books_with_meta.group_by { |b_meta| b_meta[:first_letter] }

    alpha_groups_list = []
    # Sort the groups by letter (A-Z, then #)
    sorted_letters = grouped_by_letter.keys.sort do |a, b|
      if a == "#" then 1 # '#' comes last
      elsif b == "#" then -1
      else a <=> b # Standard string comparison for A-Z
      end
    end

    sorted_letters.each do |letter|
      books_in_group = grouped_by_letter[letter].map { |b_meta| b_meta[:book] }
      # Books within the group are already sorted by title due to the earlier sort
      alpha_groups_list << {
        letter: letter,
        books: books_in_group
      }
    end

    { alpha_groups: alpha_groups_list, log_messages: log_output_accumulator }
  end

  # Fetches all books, groups them by year, sorted most recent year first.
  # Books within each year are sorted by date, most recent first.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :year_groups (Array of Hashes), :log_messages (String).
  #   Each hash in :year_groups has :year (String) and :books (Array of Document).
  def self.get_data_for_all_books_by_year_display(site:, context:)
    log_output_accumulator = ""
    unless site&.collections&.key?('books')
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "BOOK_LIST_UTIL",
        reason: "Required 'books' collection not found in site configuration.",
        identifiers: { filter_type: "all_books_by_year" },
        level: :error,
      )
      return { year_groups: [], log_messages: log_output_accumulator }
    end

    all_published_books = _get_all_published_books(site)

    if all_published_books.empty?
      log_output_accumulator << PluginLoggerUtils.log_liquid_failure(
        context: context,
        tag_type: "ALL_BOOKS_BY_YEAR_DISPLAY",
        reason: "No published books found to group by year.",
        identifiers: {},
        level: :info, # Expected empty state if no books
      )
      return { year_groups: [], log_messages: log_output_accumulator }
    end

    # Sort all books by date descending (most recent first)
    # Ensure book.date is a Time object for comparison
    books_sorted_by_date_desc = all_published_books.sort_by do |book|
      book.date.is_a?(Time) ? book.date : Time.now # Fallback for invalid date, sorts them as "now"
    end.reverse

    # Group by year
    grouped_by_year = books_sorted_by_date_desc.group_by { |book| book.date.year.to_s }

    year_groups_list = []
    # Sort year groups by year descending (most recent year first)
    grouped_by_year.keys.sort.reverse.each do |year_str|
      year_groups_list << {
        year: year_str,
        books: grouped_by_year[year_str] # Books are already sorted by date within this year group
      }
    end

    { year_groups: year_groups_list, log_messages: log_output_accumulator }
  end

  # --- Public HTML Rendering Helper ---

  # Renders HTML for book groups (standalone and series).
  # @param data [Hash] Expected to have :standalone_books, :series_groups, and optionally :log_messages.
  # @param context [Liquid::Context] The Liquid context.
  # @param series_heading_level [Integer] The HTML heading level for series titles (e.g., 2 for <h2>, 3 for <h3>). Defaults to 2.
  # @return [String] The rendered HTML.
  def self.render_book_groups_html(data, context, series_heading_level: 2)
    output = ""
    output << data[:log_messages] if data[:log_messages] && !data[:log_messages].empty?

    # Validate heading level to prevent invalid HTML, default to 2 if out of typical range (1-6)
    series_hl = series_heading_level.to_i
    series_hl = 2 unless (1..6).include?(series_hl)

    # "Standalone Books" heading is kept as H2 here for general use by other tags.
    # Specific tags (like DisplayBooksByAuthorThenSeriesTag) can choose to render
    # their own "Standalone Books" section with a different heading level if needed.
    if data[:standalone_books]&.any?
      output << "<h2 class=\"book-list-headline\">Standalone Books</h2>\n" # This remains H2 for general use
      output << "<div class=\"card-grid\">\n"
      data[:standalone_books].each do |book|
        output << BookCardUtils.render(book, context) << "\n"
      end
      output << "</div>\n"
    end

    data[:series_groups]&.each do |series_group|
      series_title_html = SeriesLinkUtils.render_series_link(series_group[:name], context)
      # Use the dynamic series_hl for the heading tag
      output << "<h#{series_hl} class=\"series-title\">#{series_title_html}</h#{series_hl}>\n" # Dynamic heading level
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

  # Retrieves all published books from the site's 'books' collection.
  # Assumes the 'books' collection exists (checked by public methods).
  # @param site [Jekyll::Site] The Jekyll site object.
  # @return [Array<Jekyll::Document>] An array of published book documents.
  def self._get_all_published_books(site)
    site.collections['books'].docs.select { |book| book.data['published'] != false }
  end

  # Parses a raw book number into a Float for sorting, or Float::INFINITY for non-numeric/nil.
  # @param book_number_raw [Object] The raw book number from front matter.
  # @return [Float, Float::INFINITY] The parsed number or infinity.
  def self._parse_book_number(book_number_raw)
    return Float::INFINITY if book_number_raw.nil? || book_number_raw.to_s.strip.empty?
    begin
      # Use Float() to allow for decimal book numbers like 4.5
      Float(book_number_raw.to_s)
    rescue ArgumentError
      Float::INFINITY # Non-numeric strings (e.g., "Part 1", "One")
    end
  end

  # Structures a list of books into standalone books and series groups.
  # Sorts standalone books by title (ignoring articles).
  # Sorts series groups by series name, and books within series by numerical book_number then title.
  # @param books_to_process [Array<Jekyll::Document>] The list of books to structure.
  # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String - usually empty from this method).
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
      TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    end

    # Sort books with series by series name, then by parsed book number, then by title
    books_with_series_sorted_for_grouping = books_with_series.sort_by do |book|
      [
        book.data['series'].to_s.strip.downcase,
        _parse_book_number(book.data['book_number']), # Use helper for numerical sort
        TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true) # Secondary sort by title
      ]
    end

    # Group the pre-sorted books by series name
    grouped_by_series_name = books_with_series_sorted_for_grouping.group_by { |book| book.data['series'].to_s.strip }

    # Map to the desired series_groups structure. The books within each group are already sorted.
    # The groups themselves are implicitly sorted by series name due to the sort before grouping,
    # but an explicit sort on group[:name] ensures this if the grouping strategy changes.
    series_groups = grouped_by_series_name.map do |name, book_list|
      { name: name, books: book_list } # Books are already sorted correctly
    end.sort_by { |group| group[:name].downcase } # Sort series groups by name

    {
      standalone_books: sorted_standalone,
      series_groups: series_groups,
      log_messages: "", # Initialize empty, callers will prepend their own logs.
    }
  end
end
