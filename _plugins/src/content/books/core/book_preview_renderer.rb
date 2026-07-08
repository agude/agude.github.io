# frozen_string_literal: true

# _plugins/src/content/books/core/book_preview_renderer.rb
require 'cgi'
require 'date'
require_relative '../../../infrastructure/typography_utils'
require_relative '../../../infrastructure/text_processing_utils'
require_relative '../../../infrastructure/plugin_logger_utils'
require_relative '../../../ui/ratings/rating_utils'

module Jekyll
  module Books
    module Core
      # Renderer: builds the hidden hover-preview markup shown for book links
      # (cover thumbnail, title, authors, rating). Data-in, HTML-out — does
      # not fetch data itself.
      #
      # The output is a single line with no newlines: it is inserted inline
      # into markdown paragraphs and must not be split by kramdown. The
      # `<!--book-preview-->` / `<!--/book-preview-->` comment markers are
      # load-bearing: downstream pipelines match on them to strip the
      # preview when reusing rendered HTML as plain text (meta descriptions,
      # RSS feeds, etc).
      class BookPreviewRenderer
        Typography = Jekyll::Infrastructure::TypographyUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Ratings = Jekyll::UI::Ratings::RatingUtils
        private_constant :Typography, :Text, :Logger, :Ratings

        MAX_AUTHORS_BEFORE_ETAL = 3
        private_constant :MAX_AUTHORS_BEFORE_ETAL

        # Any non-fatal issues encountered while rendering (e.g. an invalid
        # rating value), as an HTML comment. Empty string if none. This is
        # never embedded inside the preview span itself — callers should
        # prepend it outside the preview markup.
        attr_reader :log_output

        # @param context [Liquid::Context] The current Liquid context (for logging).
        # @param canonical_title [String] The book's canonical title.
        # @param authors [Array<String>, nil] The book's author names.
        # @param rating [Integer, String, nil] The book's rating (1-5).
        # @param image [String, nil] Path to the book's cover image.
        # @param series [String, nil] The name of the series the book belongs to.
        # @param book_number [Integer, String, nil] The book's number within the series.
        # @param date_published [Date, String, nil] The book's original publication date.
        def initialize(context, canonical_title, authors, rating, image, series: nil, book_number: nil,
                       date_published: nil)
          @context = context
          @canonical_title = canonical_title
          @authors = authors || []
          @rating = rating
          @image = image
          @series = series
          @book_number = book_number
          @date_published = date_published
          @log_output = ''
        end

        # @return [String] The single-line preview HTML.
        def render
          '<!--book-preview--><span class="book-link-preview" aria-hidden="true">' \
            "#{cover_html}<span class=\"book-link-preview-text\">" \
            "<cite class=\"book-title\">#{title_html}</cite>" \
            "#{author_html}#{stars_html}#{series_html}#{published_html}</span></span><!--/book-preview-->"
        end

        private

        def title_html
          Typography.prepare_display_title(@canonical_title)
        end

        def cover_html
          return '' if @image.to_s.strip.empty?

          escaped_image = CGI.escapeHTML(@image.to_s)
          "<span class=\"book-link-preview-cover\" style=\"background-image: url('#{escaped_image}')\"></span>"
        end

        def author_html
          return '' if @authors.empty?

          names = @authors.map { |name| CGI.escapeHTML(name.to_s) }
          formatted = Text.format_list_as_sentence(names, etal_after: MAX_AUTHORS_BEFORE_ETAL)
          "<span class=\"book-link-preview-author\">by #{formatted}</span>"
        end

        def stars_html
          Ratings.render_rating_stars(@rating, 'span')
        rescue ArgumentError => e
          log_rating_error(e)
          ''
        end

        def series_html
          return '' if @series.to_s.strip.empty?

          escaped_series = CGI.escapeHTML(@series.to_s)
          number_html = @book_number.to_s.strip.empty? ? '' : "&thinsp;##{@book_number}"
          '<span class="book-link-preview-series">' \
            "<span class=\"book-series\">#{escaped_series}</span>#{number_html}</span>"
        end

        def published_html
          year = published_year
          return '' unless year

          "<span class=\"book-link-preview-published\">Published #{year}</span>"
        end

        def published_year
          case @date_published
          when Date
            @date_published.year
          when String
            match = @date_published.match(/\A\d{4}/)
            match && match[0]
          end
        end

        def log_rating_error(error)
          @log_output += Logger.log_liquid_failure(
            context: @context,
            tag_type: 'BOOK_PREVIEW_RATING_ERROR',
            reason: "Invalid or malformed 'rating' value for book preview: #{error.message}",
            identifiers: { Title: @canonical_title.to_s, RatingInput: @rating.inspect },
            level: :warn,
          )
        end
      end
    end
  end
end
