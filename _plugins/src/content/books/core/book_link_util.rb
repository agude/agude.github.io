# frozen_string_literal: true

# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative '../../../infrastructure/links/link_helper_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/typography_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative 'book_link_resolver'

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
