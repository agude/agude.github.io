# frozen_string_literal: true

# _plugins/utils/book_list_utils.rb
require_relative 'url_utils'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'
require_relative 'front_matter_utils'

# Utility module for fetching and organizing lists of books.
#
# Provides methods to filter, sort, and group books by various criteria
# (series, author, title, awards, year) for use in various list formats.
module BookListUtils
  # --- Private Helper Methods ---

  def self._validate_collection(site, context, params)
    return nil if _books_collection_exists?(site)

    identifiers = params.except(:structure, :key)

    _return_error(context,
                  "Required 'books' collection not found in site configuration.",
                  identifiers: identifiers,
                  structure: params[:structure],
                  key: params[:key])
  end

  def self._books_collection_exists?(site)
    site&.collections&.key?('books')
  end

  def self._return_error(context, reason, identifiers: {}, structure: false, key: nil, tag_type: 'BOOK_LIST_UTIL')
    log = PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: tag_type, reason: reason,
      identifiers: identifiers, level: :error
    )
    log = log.dup
    return { standalone_books: [], series_groups: [], log_messages: log } if structure

    { key || :books => [], log_messages: log }
  end

  def self._return_info(context, tag_type, reason, key:)
    log = PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: tag_type, reason: reason, identifiers: {}, level: :info
    )
    { key => [], log_messages: log.dup }
  end

  # --- General Helpers ---

  def self._get_canonical_author(name, author_cache)
    return nil if name.nil? || name.to_s.strip.empty?

    stripped = name.to_s.strip
    normalized = TextProcessingUtils.normalize_title(stripped)
    data = author_cache[normalized]
    data ? data['title'] : stripped
  end

  def self._get_all_published_books(site, include_archived: false)
    books = site.collections['books'].docs.reject { |book| book.data['published'] == false }
    return books if include_archived

    books.reject { |book| book.data['canonical_url']&.start_with?('/') }
  end

  def self._parse_book_number(book_number_raw)
    return Float::INFINITY if book_number_raw.nil? || book_number_raw.to_s.strip.empty?

    Float(book_number_raw.to_s)
  rescue ArgumentError
    Float::INFINITY
  end

  def self._structure_books_for_display(books_to_process)
    standalone, series_books = _partition_books(books_to_process)
    sorted_standalone = _sort_books_by_title(standalone)
    series_groups = _group_and_sort_series_books(series_books)

    { standalone_books: sorted_standalone, series_groups: series_groups, log_messages: String.new }
  end

  def self._partition_books(books)
    books.partition do |book|
      book.data['series'].nil? || book.data['series'].to_s.strip.empty?
    end
  end

  def self._sort_books_by_title(books)
    books.sort_by do |book|
      TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    end
  end

  def self._group_and_sort_series_books(books)
    sorted = _sort_series_books(books)
    grouped = sorted.group_by { |book| book.data['series'].to_s.strip }
    _map_and_sort_series_groups(grouped)
  end

  def self._sort_series_books(books)
    books.sort_by do |book|
      [
        TextProcessingUtils.normalize_title(book.data['series'].to_s, strip_articles: true),
        _parse_book_number(book.data['book_number']),
        TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
      ]
    end
  end

  def self._map_and_sort_series_groups(grouped)
    grouped.map { |name, list| { name: name, books: list } }
           .sort_by { |g| TextProcessingUtils.normalize_title(g[:name], strip_articles: true) }
  end
end
