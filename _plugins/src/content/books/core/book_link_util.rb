# frozen_string_literal: true

# _plugins/src/content/books/core/book_link_util.rb
require 'jekyll'
require_relative '../../../infrastructure/links/link_formatter'
require_relative '../../../infrastructure/links/link_helper_utils'
require_relative '../../../infrastructure/links/markdown_link_utils'
require_relative '../../../infrastructure/typography_utils'
require_relative 'book_link_finder'
require_relative 'book_link_resolver'

module Jekyll
  module Books
    module Core
      # Utility module for rendering book title links with citations.
      #
      # Uses BookLinkFinder to locate data and LinkFormatter to produce output.
      # Supports explicit format selection or automatic detection from context.
      module BookLinkUtils
        Finder = Jekyll::Books::Core::BookLinkFinder
        Formatter = Jekyll::Infrastructure::Links::LinkFormatter
        MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils
        LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
        Typography = Jekyll::Infrastructure::TypographyUtils
        private_constant :Finder, :Formatter, :MarkdownUtils, :LinkHelper, :Typography

        # --- Public Methods ---

        # Renders the book link/cite HTML directly from title and URL data.
        # Used when the book data is already known (e.g., from backlinks).
        #
        # @param title [String] The canonical title to display (will be processed).
        # @param url [String] The URL of the book page.
        # @param context [Liquid::Context] The current Liquid context.
        # @param cite [Boolean] true (default) for <cite> wrapper, false for span.book-text.
        # @param format [Symbol, nil] Output format (:html or :markdown).
        #   If nil, determined from context (markdown_mode? check).
        # @return [String] The generated HTML or markdown link.
        def self.render_book_link_from_data(title, url, context, cite: true, format: nil)
          output_format = format || detect_format(context)
          format_book_link(title, url, context, cite, output_format)
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
        # @param format [Symbol, nil] Output format (:html or :markdown).
        #   If nil, determined from context (markdown_mode? check).
        # @return [String] The generated HTML, potentially prepended with an HTML comment.
        # @raise [Jekyll::Errors::FatalException] if the title is ambiguous and no author is provided.
        def self.render_book_link(book_title_raw, context, link_text_override_raw = nil, author_filter_raw = nil,
                                  date_filter_raw = nil, cite: true, format: nil)
          # Find book data
          data = Finder.new(context).find(
            book_title_raw,
            override: link_text_override_raw,
            author_filter: author_filter_raw,
            date_filter: date_filter_raw,
            cite: cite
          )

          # Determine output format
          output_format = format || detect_format(context)

          # Format and return
          data[:log_output] + format_book_link(data[:display_name], data[:url], context, data[:cite], output_format)
        end

        # --- Private Helper Methods ---

        def self.detect_format(context)
          MarkdownUtils.markdown_mode?(context) ? :markdown : :html
        end
        private_class_method :detect_format

        def self.format_book_link(title, url, context, cite, output_format)
          case output_format
          when :markdown
            format_markdown(title, url, cite)
          else
            format_html(title, url, context, cite)
          end
        end
        private_class_method :format_book_link

        def self.format_markdown(title, url, cite)
          Formatter.markdown(title, url, italic: cite)
        end
        private_class_method :format_markdown

        def self.format_html(title, url, context, cite)
          inner_element = cite ? _build_book_cite_element(title) : _build_book_text_element(title)
          LinkHelper._generate_link_html(context, url, inner_element)
        end
        private_class_method :format_html

        # Prepares display text and wraps it in a <cite> tag.
        def self._build_book_cite_element(display_text)
          prepared_display_text = Typography.prepare_display_title(display_text)
          "<cite class=\"book-title\">#{prepared_display_text}</cite>"
        end

        # Prepares display text and wraps it in a <span class="book-text"> tag.
        def self._build_book_text_element(display_text)
          prepared_display_text = Typography.prepare_display_title(display_text)
          "<span class=\"book-text\">#{prepared_display_text}</span>"
        end

        # Helper to track mentions of books that don't have a review page.
        # Kept for backward compatibility.
        def self._track_unreviewed_mention(context, title)
          Jekyll::Books::Core::BookLinkResolver.new(context).send(:track_unreviewed_mention_explicit, title)
        end
      end
    end
  end
end
