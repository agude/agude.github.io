# frozen_string_literal: true

# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative 'link_helper_utils'
require_relative '../src/infrastructure/plugin_logger_utils'
require_relative '../src/infrastructure/text_processing_utils'
require_relative '../src/infrastructure/typography_utils'
require_relative '../src/infrastructure/front_matter_utils'

# Utility module for rendering book title links with citations.
#
# Generates HTML links to book review pages wrapped in cite elements,
# with support for disambiguation by author.
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
    BookLinkResolver.new(context).resolve(book_title_raw, link_text_override_raw, author_filter_raw)
  end

  # --- Private Helper Methods ---

  # Prepares display text and wraps it in a <cite> tag.
  def self._build_book_cite_element(display_text)
    # Use _prepare_display_title from TypographyUtils
    prepared_display_text = TypographyUtils.prepare_display_title(display_text)
    "<cite class=\"book-title\">#{prepared_display_text}</cite>"
  end

  # Helper to track mentions of books that don't have a review page.
  # Kept for backward compatibility if used elsewhere, though logic is now in Resolver.
  def self._track_unreviewed_mention(context, title)
    BookLinkResolver.new(context).send(:track_unreviewed_mention_explicit, title)
  end
end

# Helper class to handle the complexity of resolving a book link
class BookLinkResolver
  def initialize(context)
    @context = context
    registers = context.respond_to?(:registers) ? context.registers : nil
    @site = registers&.[](:site)
  end

  def resolve(title_raw, text_override, author_filter)
    return fallback(title_raw) unless @site

    @title = title_raw.to_s
    @norm_title = TextProcessingUtils.normalize_title(@title)
    return log_empty_title if @norm_title.empty?

    candidates = find_candidates
    display_text = determine_display_text(text_override)
    return log_not_found + fallback(display_text) if candidates.empty?

    result = filter_candidates(candidates, author_filter)
    return result + fallback(display_text) if result.is_a?(String)

    render_result(result, text_override)
  end

  # Public method for the module delegate to call
  def track_unreviewed_mention_explicit(title)
    @title = title.to_s
    @norm_title = TextProcessingUtils.normalize_title(@title)
    track_unreviewed_mention
  end

  private

  def fallback(title)
    BookLinkUtils._build_book_cite_element(title.to_s)
  end

  def log_empty_title
    PluginLoggerUtils.log_liquid_failure(
      context: @context, tag_type: 'RENDER_BOOK_LINK',
      reason: 'Input title resolved to empty after normalization.',
      identifiers: { TitleInput: @title || 'nil' }, level: :warn
    )
  end

  def determine_display_text(text_override)
    if text_override && !text_override.to_s.empty?
      text_override.to_s.strip
    else
      @title
    end
  end

  def find_candidates
    cache = @site.data['link_cache'] || {}
    (cache.dig('books', @norm_title) || []).reject { |b| b['canonical_url']&.start_with?('/') }
  end

  def log_not_found
    track_unreviewed_mention
    PluginLoggerUtils.log_liquid_failure(
      context: @context, tag_type: 'RENDER_BOOK_LINK',
      reason: 'Could not find book page in cache.',
      identifiers: { Title: @title.strip }, level: :info
    )
  end

  def track_unreviewed_mention
    page = @context.registers[:page]
    return unless page && page['url'] && !@norm_title.empty?

    tracker = @site.data['mention_tracker']
    initialize_tracker_entry(tracker)
    update_tracker_entry(tracker, page)
  end

  def initialize_tracker_entry(tracker)
    tracker[@norm_title] ||= { original_titles: Hash.new(0), sources: Set.new }
  end

  def update_tracker_entry(tracker, page)
    tracker[@norm_title][:original_titles][@title.strip] += 1
    tracker[@norm_title][:sources] << page['url']
  end

  def filter_candidates(candidates, author_filter)
    if author_filter && !author_filter.to_s.strip.empty?
      filter_by_author(candidates, author_filter.to_s.strip)
    elsif candidates.length > 1
      raise_ambiguous_error(candidates)
    else
      candidates.first
    end
  end

  def filter_by_author(candidates, author_filter)
    ac = @site.data.dig('link_cache', 'authors') || {}
    target = get_canonical_author(author_filter, ac)

    found = candidates.find do |book|
      book['authors'].any? do |auth|
        bc = get_canonical_author(auth, ac)
        bc && target && bc.casecmp(target).zero?
      end
    end

    return log_author_mismatch(author_filter) unless found

    found
  end

  def get_canonical_author(name, cache)
    return nil if name.to_s.strip.empty?

    norm = TextProcessingUtils.normalize_title(name.to_s.strip)
    cache[norm] ? cache[norm]['title'] : name.to_s.strip
  end

  def log_author_mismatch(author_filter)
    PluginLoggerUtils.log_liquid_failure(
      context: @context, tag_type: 'RENDER_BOOK_LINK',
      reason: 'Book title exists, but not by the specified author.',
      identifiers: { Title: @title, AuthorFilter: author_filter }, level: :warn
    )
  end

  def raise_ambiguous_error(candidates)
    names = candidates.map { |c| "'#{c['authors'].join(', ')}'" }.join('; ')
    raise Jekyll::Errors::FatalException, <<~MSG
      [FATAL] Ambiguous book title in `book_link` tag.
      Page: #{@context.registers[:page]['path']}
      Tag: {% book_link "#{@title}" %}
      Reason: The book title "#{@title}" is used by multiple authors: #{names}.
      Fix: Add an author parameter, e.g., {% book_link "#{@title}" author="Author Name" %}
    MSG
  end

  def render_result(book_data, text_override)
    display = if text_override && !text_override.to_s.empty?
                text_override.to_s.strip
              else
                book_data['title']
              end
    BookLinkUtils.render_book_link_from_data(display, book_data['url'], @context)
  end
end
