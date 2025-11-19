# frozen_string_literal: true

# _plugins/utils/book_list_utils.rb
require 'cgi'
require_relative 'series_link_util'
require_relative 'url_utils'
require_relative 'plugin_logger_utils'
require_relative 'book_card_utils'
require_relative 'text_processing_utils'
require_relative 'front_matter_utils'

module BookListUtils # rubocop:disable Metrics/ModuleLength
  # --- Public Methods for Tags ---

  # Fetches and sorts books for a specific series.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param series_name_filter [String] The name of the series to filter by.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :books (Array of Document), :series_name (String), :log_messages (String).
  def self.get_data_for_series_display(site:, series_name_filter:, context:)
    error = _validate_collection(site, context, filter_type: 'series', series_name: series_name_filter)
    return error if error

    all_books = _get_all_published_books(site, include_archived: false)
    books_in_series = _filter_series_books(all_books, series_name_filter)
    log_msg = _generate_series_log(books_in_series, series_name_filter, context)

    { books: books_in_series, series_name: series_name_filter, log_messages: log_msg }
  end

  # Fetches and structures books for a specific author.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param author_name_filter [String] The name of the author to filter by.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
  def self.get_data_for_author_display(site:, author_name_filter:, context:)
    error = _validate_collection(site, context, filter_type: 'author', author_name: author_name_filter, structure: true)
    return error if error

    author_books = _fetch_books_for_author(site, author_name_filter)
    log_msg = _generate_author_log(author_books, author_name_filter, context)

    structured_data = _structure_books_for_display(author_books)
    structured_data[:log_messages] = (structured_data[:log_messages] || '') + log_msg
    structured_data
  end

  # Fetches and structures all books for display.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :standalone_books (Array), :series_groups (Array), :log_messages (String).
  def self.get_data_for_all_books_display(site:, context:)
    error = _validate_collection(site, context, filter_type: 'all_books', structure: true)
    return error if error

    all_books = _get_all_published_books(site, include_archived: false)
    _structure_books_for_display(all_books)
  end

  # Fetches all books, groups them by author, then structures each author's books.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :authors_data (Array of Hashes), :log_messages (String).
  def self.get_data_for_all_books_by_author_display(site:, context:)
    error = _validate_collection(site, context, filter_type: 'all_books_by_author', key: :authors_data)
    return error if error

    books_by_author = _group_books_by_canonical_author(site)
    authors_data_list = _build_authors_data_list(books_by_author)
    log_msg = _generate_all_authors_log(authors_data_list, context)

    { authors_data: authors_data_list, log_messages: log_msg }
  end

  # Fetches all books, groups them by award.
  def self.get_data_for_all_books_by_award_display(site:, context:)
    error = _validate_collection(site, context, filter_type: 'all_books_by_award', key: :awards_data)
    return error if error

    all_books = _get_all_published_books(site, include_archived: false)
    return { awards_data: [], log_messages: String.new } if all_books.empty?

    unique_awards = _collect_unique_awards(all_books)
    awards_data_list = _build_awards_data_list(unique_awards, all_books)
    log_msg = _generate_awards_log(awards_data_list, context)

    { awards_data: awards_data_list, log_messages: log_msg }
  end

  # Fetches all books, sorts them by normalized title, then groups by first letter.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :alpha_groups (Array of Hashes), :log_messages (String).
  def self.get_data_for_all_books_by_title_alpha_group(site:, context:)
    error = _validate_collection(site, context, filter_type: 'all_books_by_title_alpha_group', key: :alpha_groups)
    return error if error

    all_books = _get_all_published_books(site, include_archived: false)
    if all_books.empty?
      return _return_info(context, 'ALL_BOOKS_BY_TITLE_ALPHA_GROUP',
                          'No published books found to group by title.', key: :alpha_groups)
    end

    alpha_groups_list = _group_books_by_alpha(all_books)
    { alpha_groups: alpha_groups_list, log_messages: String.new }
  end

  # Fetches all books, groups them by year, sorted most recent year first.
  # Books within each year are sorted by date, most recent first.
  # @param site [Jekyll::Site] The Jekyll site object.
  # @param context [Liquid::Context] The Liquid context.
  # @return [Hash] Contains :year_groups (Array of Hashes), :log_messages (String).
  def self.get_data_for_all_books_by_year_display(site:, context:)
    error = _validate_collection(site, context, filter_type: 'all_books_by_year', key: :year_groups)
    return error if error

    all_books = _get_all_published_books(site, include_archived: true)
    if all_books.empty?
      return _return_info(context, 'ALL_BOOKS_BY_YEAR_DISPLAY',
                          'No published books found to group by year.', key: :year_groups)
    end

    year_groups_list = _group_books_by_year(all_books)
    { year_groups: year_groups_list, log_messages: String.new }
  end

  def self.get_data_for_favorites_lists(site:, context:)
    unless _favorites_prerequisites_met?(site)
      return _return_error(context,
                           'Prerequisites missing: site.posts or favorites_posts_to_books cache.',
                           identifiers: {},
                           key: :favorites_lists,
                           tag_type: 'BOOK_LIST_FAVORITES')
    end

    favorites_lists_data = _build_favorites_lists(site)
    log_msg = _generate_favorites_log(favorites_lists_data, context)

    { favorites_lists: favorites_lists_data, log_messages: log_msg }
  end

  # --- Public HTML Rendering Helper ---

  # Renders HTML for book groups (standalone and series).
  # @param data [Hash] Expected to have :standalone_books, :series_groups, and optionally :log_messages.
  # @param context [Liquid::Context] The Liquid context.
  # @param series_heading_level [Integer] The HTML heading level for series titles. Defaults to 2.
  # @param generate_nav [Boolean] If true, generates and prepends an A-Z jump-link navigation.
  # @return [String] The rendered HTML.
  def self.render_book_groups_html(data, context, series_heading_level: 2, generate_nav: false)
    output = (data[:log_messages] || '').dup
    standalone_books = data[:standalone_books] || []
    series_groups = data[:series_groups] || []

    return output if standalone_books.empty? && series_groups.empty?

    series_hl = (1..6).include?(series_heading_level.to_i) ? series_heading_level.to_i : 2
    anchors = {}

    options = { series_hl: series_hl, generate_nav: generate_nav, anchors: anchors }
    content_buffer = _render_content_buffer(standalone_books, series_groups, context, options)

    return output + content_buffer unless generate_nav

    nav_html = _render_alpha_nav(anchors)
    output + nav_html + content_buffer
  end

  # --- Private Helper Methods ---

  def self._validate_collection(site, context, params)
    return nil if _books_collection_exists?(site)

    identifiers = params.reject { |k, _| [:structure, :key].include?(k) }

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

    { (key || :books) => [], log_messages: log }
  end

  def self._return_info(context, tag_type, reason, key:)
    log = PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: tag_type, reason: reason, identifiers: {}, level: :info
    )
    { key => [], log_messages: log.dup }
  end

  # --- Series Helpers ---

  def self._filter_series_books(all_books, series_name)
    return [] if series_name.nil? || series_name.to_s.strip.empty?

    normalized = series_name.to_s.strip.downcase
    all_books.select { |book| book.data['series']&.strip&.downcase == normalized }
      .sort_by { |book| _series_sort_key(book) }
  end

  def self._series_sort_key(book)
    [
      _parse_book_number(book.data['book_number']),
      TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    ]
  end

  def self._generate_series_log(books, series_name, context)
    if series_name.nil? || series_name.to_s.strip.empty?
      PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'BOOK_LIST_SERIES_DISPLAY', reason: 'Series name filter was empty or nil.',
        identifiers: { SeriesFilterInput: series_name || 'N/A' }, level: :warn
      ).dup
    elsif books.empty?
      PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'BOOK_LIST_SERIES_DISPLAY', reason: 'No books found for the specified series.',
        identifiers: { SeriesFilter: series_name }, level: :info
      ).dup
    else
      String.new
    end
  end

  # --- Author Helpers ---

  def self._fetch_books_for_author(site, author_name)
    return [] if author_name.nil? || author_name.to_s.strip.empty?

    link_cache = site.data['link_cache'] || {}
    author_cache = link_cache['authors'] || {}
    canonical_filter = _get_canonical_author(author_name, author_cache)
    all_books = _get_all_published_books(site, include_archived: false)

    all_books.select do |book|
      _book_matches_author?(book, canonical_filter, author_cache)
    end
  end

  def self._book_matches_author?(book, canonical_filter, author_cache)
    authors = FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors'])
    authors.any? do |name|
      c_name = _get_canonical_author(name, author_cache)
      c_name && canonical_filter && c_name.casecmp(canonical_filter).zero?
    end
  end

  def self._generate_author_log(books, author_name, context)
    if author_name.nil? || author_name.to_s.strip.empty?
      PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'BOOK_LIST_AUTHOR_DISPLAY',
        reason: 'Author name filter was empty or nil when fetching data.',
        identifiers: { AuthorFilterInput: author_name || 'N/A' }, level: :warn
      ).dup
    elsif books.empty?
      PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'BOOK_LIST_AUTHOR_DISPLAY', reason: 'No books found for the specified author.',
        identifiers: { AuthorFilter: author_name }, level: :info
      ).dup
    else
      String.new
    end
  end

  # --- All Books By Author Helpers ---

  def self._group_books_by_canonical_author(site)
    link_cache = site.data['link_cache'] || {}
    author_cache = link_cache['authors'] || {}
    books_map = {}

    _get_all_published_books(site, include_archived: false).each do |book|
      FrontMatterUtils.get_list_from_string_or_array(book.data['book_authors']).each do |name|
        canonical = _get_canonical_author(name, author_cache)
        next unless canonical

        books_map[canonical] ||= []
        books_map[canonical] << book
      end
    end
    books_map
  end

  def self._build_authors_data_list(books_map)
    list = books_map.map do |name, books|
      structured = _structure_books_for_display(books.uniq)
      {
        author_name: name,
        standalone_books: structured[:standalone_books],
        series_groups: structured[:series_groups]
      }
    end
    list.sort_by { |entry| entry[:author_name].downcase }
  end

  def self._generate_all_authors_log(data, context)
    return String.new unless data.empty?

    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'ALL_BOOKS_BY_AUTHOR_DISPLAY',
      reason: 'No published books with valid author names found.', identifiers: {}, level: :info
    ).dup
  end

  # --- Award Helpers ---

  private_class_method def self._format_award_display_name(award_string_raw)
    return '' if award_string_raw.nil? || award_string_raw.to_s.strip.empty?

    words = award_string_raw.to_s.strip.split.map do |word|
      _format_award_word(word)
    end
    "#{words.join(' ')} Award"
  end

  def self._format_award_word(word)
    if word.length == 2 && word[1] == '.' && word[0].match?(/[a-z]/i)
      "#{word[0].upcase}."
    else
      word.capitalize
    end
  end

  def self._collect_unique_awards(books)
    unique = {}
    books.each do |book|
      next unless book.data['awards'].is_a?(Array)

      book.data['awards'].each do |award|
        next if award.nil? || award.to_s.strip.empty?

        stripped = award.to_s.strip
        unique[stripped.downcase] ||= stripped
      end
    end
    unique
  end

  def self._build_awards_data_list(unique_awards, all_books)
    sorted_awards = unique_awards.sort_by { |k, _v| k }.map { |_k, v| v }

    sorted_awards.filter_map do |raw_award|
      books = _find_books_for_award(all_books, raw_award)
      next if books.empty?

      display_name = _format_award_display_name(raw_award)
      {
        award_name: display_name,
        award_slug: _slugify_award(display_name),
        books: books
      }
    end
  end

  def self._find_books_for_award(all_books, raw_award)
    books = all_books.select do |book|
      book.data['awards'].is_a?(Array) &&
        book.data['awards'].any? { |ba| ba.to_s.strip.casecmp(raw_award.strip).zero? }
    end
    books.sort_by { |b| TextProcessingUtils.normalize_title(b.data['title'].to_s, strip_articles: true) }
  end

  def self._slugify_award(name)
    TextProcessingUtils.normalize_title(name, strip_articles: false)
      .gsub(/\s+/, '-')
      .gsub(/[^\w-]+/, '')
      .gsub(/--+/, '-')
      .gsub(/^-+|-+$/, '')
  end

  def self._generate_awards_log(data, context)
    return String.new unless data.empty?

    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'ALL_BOOKS_BY_AWARD_DISPLAY',
      reason: 'No books with awards found.', identifiers: {}, level: :info
    ).dup
  end

  # --- Alpha Group Helpers ---

  def self._group_books_by_alpha(books)
    books_with_meta = books.map { |book| _create_book_alpha_meta(book) }

    sorted = books_with_meta.sort_by { |m| [m[:sort_title], m[:book].data['title'].to_s.downcase] }
    grouped = sorted.group_by { |m| m[:first_letter] }

    _sort_alpha_groups(grouped)
  end

  def self._create_book_alpha_meta(book)
    sort_title = TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    first_letter = sort_title.empty? ? '#' : sort_title[0].upcase
    first_letter = '#' unless first_letter.match?(/[A-Z]/)
    { book: book, sort_title: sort_title, first_letter: first_letter }
  end

  def self._sort_alpha_groups(grouped)
    keys = grouped.keys.sort do |a, b|
      if a == '#' then -1
      elsif b == '#' then 1
      else
        a <=> b
      end
    end

    keys.map do |letter|
      { letter: letter, books: grouped[letter].map { |m| m[:book] } }
    end
  end

  # --- Year Group Helpers ---

  def self._group_books_by_year(books)
    sorted = books.sort_by do |book|
      book.date.is_a?(Time) ? book.date : Time.now
    end.reverse

    grouped = sorted.group_by { |book| book.date.year.to_s }

    grouped.keys.sort.reverse.map do |year|
      { year: year, books: grouped[year] }
    end
  end

  # --- Favorites Helpers ---

  def self._favorites_prerequisites_met?(site)
    site&.posts&.docs.is_a?(Array) && site.data.dig('link_cache', 'favorites_posts_to_books')
  end

  def self._build_favorites_lists(site)
    cache = site.data['link_cache']['favorites_posts_to_books']
    posts = site.posts.docs.select { |p| p.data.key?('is_favorites_list') }
      .sort_by { |p| p.data['is_favorites_list'].to_i }.reverse

    posts.map do |post|
      books = cache[post.url] || []
      sorted = books.sort_by do |b|
        TextProcessingUtils.normalize_title(b.data['title'].to_s, strip_articles: true)
      end
      { post: post, books: sorted }
    end
  end

  def self._generate_favorites_log(data, context)
    return String.new unless data.empty?

    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'BOOK_LIST_FAVORITES',
      reason: "No posts with 'is_favorites_list' front matter found.", level: :info
    ).dup
  end

  # --- Rendering Helpers ---

  def self._render_content_buffer(standalone, series_groups, context, options)
    buffer = String.new
    if standalone.any?
      buffer << _render_standalone_section(standalone, context, options)
    end

    series_groups.each do |group|
      buffer << _render_series_section(group, context, options)
    end
    buffer
  end

  def self._render_standalone_section(books, context, options)
    slug = 'standalone-books'
    options[:anchors]['#'] = slug if options[:generate_nav]
    html = String.new("<h2 class=\"book-list-headline\" id=\"#{slug}\">Standalone Books</h2>\n")
    html << "<div class=\"card-grid\">\n"
    books.each { |b| html << BookCardUtils.render(b, context) << "\n" }
    html << "</div>\n"
    html
  end

  def self._render_series_section(group, context, options)
    name = group[:name]
    slug = TextProcessingUtils.slugify(name)
    _register_series_anchor(name, slug, options) if options[:generate_nav]

    heading_level = options[:series_hl]
    link = SeriesLinkUtils.render_series_link(name, context)
    html = String.new("<h#{heading_level} class=\"series-title\" id=\"#{slug}\">#{link}</h#{heading_level}>\n")
    html << "<div class=\"card-grid\">\n"
    group[:books].each { |b| html << BookCardUtils.render(b, context) << "\n" }
    html << "</div>\n"
    html
  end

  def self._register_series_anchor(name, slug, options)
    sort_key = TextProcessingUtils.normalize_title(name, strip_articles: true).sub(/^series\s+/, '').strip
    letter = sort_key.empty? ? '#' : sort_key[0].upcase
    options[:anchors][letter] ||= slug
  end

  def self._render_alpha_nav(anchors)
    chars = ['#'] + ('A'..'Z').to_a
    links = chars.map do |char|
      if anchors.key?(char)
        "<a href=\"##{anchors[char]}\">#{CGI.escapeHTML(char)}</a>"
      else
        "<span>#{CGI.escapeHTML(char)}</span>"
      end
    end
    "<nav class=\"alpha-jump-links\">\n  #{links.join(' ')}\n</nav>\n"
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
    standalone, series_books = books_to_process.partition do |book|
      book.data['series'].nil? || book.data['series'].to_s.strip.empty?
    end

    sorted_standalone = standalone.sort_by do |book|
      TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
    end

    series_groups = _group_and_sort_series_books(series_books)

    { standalone_books: sorted_standalone, series_groups: series_groups, log_messages: String.new }
  end

  def self._group_and_sort_series_books(books)
    sorted = books.sort_by do |book|
      [
        TextProcessingUtils.normalize_title(book.data['series'].to_s, strip_articles: true),
        _parse_book_number(book.data['book_number']),
        TextProcessingUtils.normalize_title(book.data['title'].to_s, strip_articles: true)
      ]
    end

    grouped = sorted.group_by { |book| book.data['series'].to_s.strip }
    grouped.map { |name, list| { name: name, books: list } }
      .sort_by { |g| TextProcessingUtils.normalize_title(g[:name], strip_articles: true) }
  end
end
