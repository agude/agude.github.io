# frozen_string_literal: true

# _plugins/src/content/books/core/book_card_renderer.rb
require 'cgi'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../infrastructure/typography_utils'
require_relative '../../../infrastructure/front_matter_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../ui/cards/card_data_extractor_utils'
require_relative '../../../ui/cards/card_renderer_utils'
require_relative '../../../ui/ratings/rating_utils'
require_relative '../../authors/author_link_util'
require_relative 'book_card_utils'

module Jekyll
  module Books
    module Core
      # Helper class to handle book card rendering logic.
      #
      # Provides two public interfaces:
      # - extract_data: returns a frozen hash of raw card data (no HTML)
      # - render: returns the full HTML card string
      class BookCardRenderer
        # Aliases for readability
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Typography = Jekyll::Infrastructure::TypographyUtils
        FrontMatter = Jekyll::Infrastructure::FrontMatterUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        CardExtractor = Jekyll::UI::Cards::CardDataExtractorUtils
        CardRenderer = Jekyll::UI::Cards::CardRendererUtils
        Ratings = Jekyll::UI::Ratings::RatingUtils
        AuthorLinker = Jekyll::Authors::AuthorLinkUtils
        private_constant :Logger, :Typography, :FrontMatter, :Text, :CardExtractor, :CardRenderer, :Ratings,
                         :AuthorLinker

        def initialize(book_obj, context, title_override, subtitle)
          @book_obj = book_obj
          @context = context
          @title_override = title_override
          @subtitle = subtitle
          @log_out = ''
        end

        def extract_data
          extract_base
          return nil if @base[:site].nil? || @base[:data_source_for_keys].nil?

          @data = @base[:data_source_for_keys]
          title = resolve_title
          {
            title: title,
            authors: resolve_authors,
            rating: @data['rating'],
            excerpt: resolve_excerpt,
            url: @base[:absolute_url],
            image_url: @base[:absolute_image_url],
            image_alt: resolve_image_alt(title),
            subtitle: resolve_subtitle
          }.freeze
        end

        def render
          data = extract_data
          return @log_out unless data

          card_data = build_card_data(
            format_title_html(data[:title]),
            data[:image_alt],
            data[:excerpt],
            format_extra_elements(data)
          )
          @log_out + CardRenderer.render_card(context: @context, card_data: card_data)
        end

        private

        def extract_base
          @base = CardExtractor.extract_base_data(
            @book_obj, @context,
            default_title: Jekyll::Books::Core::BookCardUtils::DEFAULT_TITLE_FOR_BOOK_CARD,
            log_tag_type: 'BOOK_CARD_UTIL'
          )
          @log_out = @base[:log_output] || ''
        end

        # --- Data resolution (extract raw values, log issues) ---

        def resolve_title
          t = @title_override.to_s.strip.empty? ? @base[:raw_title] : @title_override
          if t == Jekyll::Books::Core::BookCardUtils::DEFAULT_TITLE_FOR_BOOK_CARD
            log('BOOK_CARD_MISSING_TITLE', 'Book title is missing and defaulted.', :error,
                { book_url: @base[:absolute_url] || @data['url'] || 'N/A' })
          end
          t
        end

        def resolve_authors
          names = FrontMatter.get_list_from_string_or_array(@data['book_authors'])
          if names.empty?
            log('BOOK_CARD_MISSING_AUTHORS', "'book_authors' field resolved to an empty list.", :warn,
                { book_title: @base[:raw_title] })
          end
          names
        end

        def resolve_excerpt
          html = CardExtractor.extract_description_html(@data, type: :book)
          if html.strip.empty?
            log('BOOK_CARD_MISSING_EXCERPT', 'Book excerpt is missing or empty.', :warn,
                { book_title: @base[:raw_title] })
          end
          html
        end

        def resolve_image_alt(title)
          path = @data['image']
          alt = @data['image_alt']

          return alt unless alt.to_s.strip.empty?

          log_image_alt_issue(path)
          "Book cover of #{title}."
        end

        def resolve_subtitle
          @subtitle.to_s.strip.empty? ? nil : @subtitle
        end

        # --- HTML formatting ---

        def format_title_html(title)
          "<strong><cite class=\"book-title\">#{Typography.prepare_display_title(title)}</cite></strong>"
        end

        def format_extra_elements(data)
          [format_authors_html(data[:authors]),
           format_subtitle_html(data[:subtitle]),
           format_rating_html(data[:rating])].compact
        end

        def format_authors_html(authors)
          return nil if authors.empty?

          links = authors.map { |n| AuthorLinker.render_author_link(n, @context) }
          "    <span class=\"by-author\"> by #{Text.format_list_as_sentence(
            links, etal_after: 3
          )}</span>\n"
        end

        def format_subtitle_html(subtitle)
          return nil unless subtitle

          "    <div class=\"card-subtitle\"><i>#{CGI.escapeHTML(subtitle)}</i></div>\n"
        end

        def format_rating_html(rating)
          return nil unless rating

          html = Ratings.render_rating_stars(rating, 'div')
          html && !html.empty? ? "    #{html}\n" : nil
        rescue ArgumentError => e
          log('BOOK_CARD_RATING_ERROR', "Invalid or malformed 'rating' value for book: #{e.message}", :warn,
              { title: @base[:raw_title], rating_input: rating.inspect })
          nil
        end

        # --- Shared helpers ---

        def log_image_alt_issue(path)
          if path.to_s.strip.empty?
            log('BOOK_CARD_MISSING_IMAGE_PATH',
                "Required 'image' front matter (path to cover image) is missing for book.",
                :error, { book_title: @base[:raw_title] })
          else
            log('BOOK_CARD_USER_ALT_MISSING',
                "User-provided 'image_alt' front matter missing for book image. Constructing default.",
                :debug, { book_title: @base[:raw_title], image_path: path })
          end
        end

        def build_card_data(title, alt, desc, extras)
          {
            base_class: 'book-card', url: @base[:absolute_url], image_url: @base[:absolute_image_url],
            image_alt: alt, image_div_class: 'card-book-cover', title_html: title, extra_elements_html: extras,
            description_html: desc, description_wrapper_html_open: "    <div class=\"card-element card-text\">\n      ",
            description_wrapper_html_close: "\n    </div>\n"
          }
        end

        def log(tag, reason, level, ids)
          @log_out << Logger.log_liquid_failure(
            context: @context, tag_type: tag, reason: reason, identifiers: ids, level: level
          )
        end
      end
    end
  end
end
