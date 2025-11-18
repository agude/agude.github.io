# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative 'link_helper_utils'
require_relative 'plugin_logger_utils'
require_relative 'text_processing_utils'
require_relative 'typography_utils'
require_relative 'front_matter_utils'

module BookLinkUtils
  # --- Public Method ---

  # Renders the book link/cite HTML directly from title and URL data.
  # Used when the book data is already known (e.g., from backlinks).
  #
  # @param title [String] The canonical title to display (will be processed).
  # @param url [String] The URL of the book page.
  # @param context [Liquid::Context] The current Liquid context.
  # @return [String] The generated HTML (<a href=...><cite>...</cite></a> or <cite>...</cite>).
  def self.render_book_link_from_data(title, url, context)
    # 1. Prepare Display Text & Build Cite Element
    cite_element = _build_book_cite_element(title) # Uses canonical title directly

    # 2. Generate Final HTML (Link or Span) using shared helper
    # Pass the known URL to the helper
    LinkHelperUtils._generate_link_html(context, url, cite_element)

    # 3. Return HTML Element
  end

  # Finds a book by title from the link_cache and renders its link/cite HTML.
  # Handles disambiguation for titles shared by multiple authors.
  #
  # @param book_title_raw [String] The title of the book to link to.
  # @param context [Liquid::Context] The current Liquid context.
  # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
  # @param author_filter_raw [String, nil] Optional author name to disambiguate.
  # @return [String] The generated HTML, potentially prepended with an HTML comment.
  # @raise [Jekyll::Errors::FatalException] if the title is ambiguous and no author is provided.
  def self.render_book_link(book_title_raw, context, link_text_override_raw = nil, author_filter_raw = nil)
    # 1. Initial Setup & Validation
    unless context && (site = context.registers[:site])
      # Fallback for critical context failure
      prepared_fallback_title = TypographyUtils.prepare_display_title(book_title_raw.to_s)
      return "<cite class=\"book-title\">#{prepared_fallback_title}</cite>"
    end

    book_title_input = book_title_raw.to_s
    author_filter = author_filter_raw.to_s.strip if author_filter_raw
    if link_text_override_raw && !link_text_override_raw.to_s.empty?
      link_text_override = link_text_override_raw.to_s.strip
    end
    normalized_lookup_title = TextProcessingUtils.normalize_title(book_title_input)

    if normalized_lookup_title.empty?
      return PluginLoggerUtils.log_liquid_failure(
        context: context, tag_type: 'RENDER_BOOK_LINK',
        reason: 'Input title resolved to empty after normalization.',
        identifiers: { TitleInput: book_title_raw || 'nil' },
        level: :warn
      )
    end

    # 2. Lookup from Cache
    log_output = ''
    link_cache = site.data['link_cache'] || {}
    book_cache = link_cache['books'] || {}
    found_book_locations_raw = book_cache[normalized_lookup_title]

    # Filter out archived reviews to find the canonical one(s).
    # An archived review has a canonical_url that starts with '/'.
    found_book_locations = found_book_locations_raw&.reject do |book_data|
      book_data['canonical_url']&.start_with?('/')
    end

    found_book_data = nil # This will hold the single, correct book data

    if found_book_locations.nil? || found_book_locations.empty?
      log_output = _log_book_not_found(context, book_title_input)
    elsif author_filter && !author_filter.empty?
      # Always filter by author if the author_filter is provided.
      author_cache = link_cache['authors'] || {}
      target_canonical_author = _get_canonical_author(author_filter, author_cache)

      # Find the book in the array where one of its authors matches the filter's canonical name.
      found_book_data = found_book_locations.find do |book_data|
        book_data['authors'].any? do |author|
          book_canonical_author = _get_canonical_author(author, author_cache)
          # Ensure both are non-nil before comparing
          book_canonical_author && target_canonical_author && book_canonical_author.casecmp(target_canonical_author).zero?
        end
      end

      # If not found after filtering, log that the title exists but not by that author.
      log_output = _log_book_not_found_by_author(context, book_title_input, author_filter) if found_book_data.nil?
    elsif found_book_locations.length > 1
      # No author filter was provided, now we check for ambiguity.
      author_names = found_book_locations.map do |loc|
        loc['authors'].join(', ')
      end.map { |name| "'#{name}'" }.join('; ')
      page_path = context.registers[:page]['path']
      raise Jekyll::Errors::FatalException, <<~MSG
        # Ambiguous and no author was provided. Halt the build.
          [FATAL] Ambiguous book title in `book_link` tag.
          Page: #{page_path}
          Tag: {% book_link "#{book_title_input}" %}
          Reason: The book title "#{book_title_input}" is used by multiple authors: #{author_names}.
          Fix: Add an author parameter to the tag, e.g., {% book_link "#{book_title_input}" author="Author Name" %}
      MSG
    else
      # Not ambiguous and no author filter, so this is the one.
      found_book_data = found_book_locations.first
    end

    # 3. Determine Display Text & Generate HTML
    # Determine display text regardless of whether book was found
    display_text = book_title_input.strip
    if link_text_override && !link_text_override.empty?
      display_text = link_text_override
    elsif found_book_data
      # Use the canonical title from the cache for display
      display_text = found_book_data['title']
    end
    final_html = if found_book_data
                   # Book found: Call the helper with found data and determined display text
                   render_book_link_from_data(display_text, found_book_data['url'], context)
                 else
                   # Book not found: Render unlinked cite with determined display text
                   # Use the determined display_text (input or override)
                   _build_book_cite_element(display_text)
                 end

    # 4. Combine Log Output (if any) and HTML Element
    log_output + final_html
  end

  # --- Private Helper Methods ---

  # Helper to track mentions of books that don't have a review page.
  def self._track_unreviewed_mention(context, title)
    site = context.registers[:site]
    page = context.registers[:page]
    # Ensure we have the necessary objects and a valid title to track.
    return unless site && page && page['url'] && title && !title.strip.empty?

    # Use a normalized title as the key for consistent grouping.
    normalized_title = TextProcessingUtils.normalize_title(title)
    return if normalized_title.empty?

    tracker = site.data['mention_tracker']
    # Initialize the entry for this normalized title if it's the first time we've seen it.
    tracker[normalized_title] ||= { original_titles: Hash.new(0), sources: Set.new }

    # Store the original casing to find the most common one later, and the source URL.
    tracker[normalized_title][:original_titles][title.strip] += 1
    tracker[normalized_title][:sources] << page['url']
  end

  # Helper to find the canonical author name from the cache.
  # Falls back to the original name if not found in the cache.
  # @param name [String, nil] The author name to look up.
  # @param author_cache [Hash] The site's pre-built author cache.
  # @return [String, nil] The canonical name, or nil if the input is blank.
  def self._get_canonical_author(name, author_cache)
    return nil if name.nil? || name.to_s.strip.empty?

    stripped_name = name.to_s.strip
    normalized_name = TextProcessingUtils.normalize_title(stripped_name)
    author_data = author_cache[normalized_name]
    author_data ? author_data['title'] : stripped_name
  end

  # Prepares display text and wraps it in a <cite> tag.
  def self._build_book_cite_element(display_text)
    # Use _prepare_display_title from TypographyUtils
    prepared_display_text = TypographyUtils.prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Logs the failure and now also tracks the mention.
  def self._log_book_not_found(context, input_title)
    # Call the tracking method.
    _track_unreviewed_mention(context, input_title)

    # The original logging functionality remains.
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_BOOK_LINK',
      reason: 'Could not find book page in cache.',
      identifiers: { Title: input_title.strip },
      level: :info
    )
  end

  # Logs the failure when the book title is found but not for the specified author.
  def self._log_book_not_found_by_author(context, title, author_filter)
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_BOOK_LINK',
      reason: 'Book title exists, but not by the specified author.',
      identifiers: { Title: title, AuthorFilter: author_filter },
      level: :warn
    )
  end
end
