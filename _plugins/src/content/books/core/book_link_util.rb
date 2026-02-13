# frozen_string_literal: true

# _plugins/utils/book_link_util.rb
require 'jekyll'
require_relative '../../../infrastructure/links/link_helper_utils'
require_relative '../../../infrastructure/links/markdown_link_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/typography_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative 'book_link_resolver'

module Jekyll
  module Books
    module Core
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
        # @param cite [Boolean] true (default) for <cite> wrapper, false for span.book-text.
        # @return [String] The generated HTML or markdown link.
        def self.render_book_link_from_data(title, url, context, cite: true)
          # Check for markdown mode
          if Jekyll::Infrastructure::Links::MarkdownLinkUtils.markdown_mode?(context)
            return Jekyll::Infrastructure::Links::MarkdownLinkUtils.render_link(title, url, italic: cite)
          end

          # Build the inner element based on cite flag
          inner_element = cite ? _build_book_cite_element(title) : _build_book_text_element(title)

          # Generate Final HTML (Link or Span) using shared helper
          Jekyll::Infrastructure::Links::LinkHelperUtils._generate_link_html(context, url, inner_element)
        end

        # Finds a book by title from the link_cache and renders its link/cite HTML.
        # Handles disambiguation for titles shared by multiple authors.
        #
        # @param book_title_raw [String] The title of the book to link to.
        # @param context [Liquid::Context] The current Liquid context.
        # @param link_text_override_raw [String, nil] Optional text to display instead of the title.
        # @param author_filter_raw [String, nil] Optional author name to disambiguate.
        # @param date_filter_raw [String, nil] Optional date to filter to a specific review.
        # @param cite [Boolean] true (default) for <cite> wrapper, false for span.book-text.
        # @return [String] The generated HTML, potentially prepended with an HTML comment.
        # @raise [Jekyll::Errors::FatalException] if the title is ambiguous and no author is provided.
        def self.render_book_link(book_title_raw, context, link_text_override_raw = nil, author_filter_raw = nil,
                                  date_filter_raw = nil, cite: true)
          Jekyll::Books::Core::BookLinkResolver.new(context).resolve(
            book_title_raw,
            link_text_override_raw,
            author_filter_raw,
            date_filter_raw,
            cite: cite
          )
        end

        # --- Private Helper Methods ---

        # Prepares display text and wraps it in a <cite> tag.
        def self._build_book_cite_element(display_text)
          prepared_display_text = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(display_text)
          "<cite class=\"book-title\">#{prepared_display_text}</cite>"
        end

        # Prepares display text and wraps it in a <span class="book-text"> tag.
        def self._build_book_text_element(display_text)
          prepared_display_text = Jekyll::Infrastructure::TypographyUtils.prepare_display_title(display_text)
          "<span class=\"book-text\">#{prepared_display_text}</span>"
        end

        # Helper to track mentions of books that don't have a review page.
        # Kept for backward compatibility if used elsewhere, though logic is now in Resolver.
        def self._track_unreviewed_mention(context, title)
          Jekyll::Books::Core::BookLinkResolver.new(context).send(:track_unreviewed_mention_explicit, title)
        end
      end
    end
  end
end
