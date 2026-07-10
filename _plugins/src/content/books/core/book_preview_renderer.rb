# frozen_string_literal: true

require 'cgi'
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

        # --- Class-level lede extraction (shared by all resolvers) ---

        # True when we are already inside excerpt rendering, so callers
        # can skip preview building entirely to avoid wasted work.
        def self.building_lede?(site)
          site&.data&.[]('_building_lede')
        end

        # Extracts and sanitizes the first-paragraph lede for a book at
        # the given URL. Returns nil when the book has no excerpt, when
        # we are already inside a lede extraction (re-entrance guard), or
        # when the URL is not in the doc map.
        def self.extract_lede(site, url)
          return nil unless url && site
          return nil if site.data['_building_lede']

          base_url = url.to_s.split('#', 2).first
          doc = (site.data['url_to_book_doc'] || {})[base_url]
          return nil unless doc

          excerpt = doc.data['excerpt']
          return nil unless excerpt.respond_to?(:output)

          site.data['_building_lede'] = true
          begin
            sanitize_lede(excerpt.output)
          ensure
            site.data['_building_lede'] = false
          end
        end

        def self.sanitize_lede(html)
          return nil if html.to_s.strip.empty?

          clean = Text.strip_link_previews(html)
          clean = Text.strip_links(clean)
          clean = clean.gsub(%r{</?p[^>]*>}, '').strip
          clean.empty? ? nil : clean
        end

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
        # @param lede_html [String, nil] Pre-sanitized HTML lede (first paragraph) for the book.
        def initialize(context, canonical_title, authors, rating, image, series: nil, book_number: nil, lede_html: nil)
          @context = context
          @canonical_title = canonical_title
          @authors = authors || []
          @rating = rating
          @image = image
          @series = series
          @book_number = book_number
          @lede_html = lede_html
          @log_output = ''
        end

        # @return [String] The single-line preview HTML.
        def render
          '<!--book-preview--><span class="book-link-preview" aria-hidden="true" hidden>' \
            "#{cover_html}<span class=\"book-link-preview-text\">" \
            "<span class=\"book-link-preview-title\">#{title_html}</span>" \
            "#{author_html}#{stars_html}#{series_html}</span>#{lede_html}</span><!--/book-preview-->"
        end

        private

        def title_html
          Typography.prepare_display_title(@canonical_title)
        end

        def cover_html
          return '' if @image.to_s.strip.empty?

          escaped_image = CGI.escapeHTML(@image.to_s)
          escaped_title = CGI.escapeHTML(@canonical_title.to_s)
          "<img class=\"book-link-preview-cover\" src=\"#{escaped_image}\" alt=\"Cover of #{escaped_title}\" loading=\"lazy\" decoding=\"async\" />"
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
          number_html = @book_number.to_s.strip.empty? ? '' : "&thinsp;##{CGI.escapeHTML(@book_number.to_s)}"
          '<span class="book-link-preview-series">' \
            "<span class=\"book-series\">#{escaped_series}</span>#{number_html}</span>"
        end

        def lede_html
          return '' if @lede_html.to_s.strip.empty?

          "<span class=\"book-link-preview-lede\">#{@lede_html}</span>"
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
