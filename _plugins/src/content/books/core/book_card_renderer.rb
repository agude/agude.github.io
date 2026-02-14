# frozen_string_literal: true

# _plugins/src/content/books/core/book_card_renderer.rb
require 'cgi'
require_relative '../../../infrastructure/links/link_formatter'
require_relative '../../../infrastructure/links/markdown_link_utils'
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
      # Helper class to handle book card rendering logic
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
        MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils
        Formatter = Jekyll::Infrastructure::Links::LinkFormatter
        private_constant :Logger, :Typography, :FrontMatter, :Text, :CardExtractor, :CardRenderer, :Ratings,
                         :AuthorLinker, :MarkdownUtils, :Formatter

        def initialize(book_obj, context, title_override, subtitle, format: nil)
          @book_obj = book_obj
          @context = context
          @title_override = title_override
          @subtitle = subtitle
          @format = format
          @log_out = ''
        end

        def render
          @base = CardExtractor.extract_base_data(
            @book_obj, @context,
            default_title: Jekyll::Books::Core::BookCardUtils::DEFAULT_TITLE_FOR_BOOK_CARD,
            log_tag_type: 'BOOK_CARD_UTIL'
          )
          @log_out = @base[:log_output] || ''
          return @log_out if @base[:site].nil? || @base[:data_source_for_keys].nil?

          @data = @base[:data_source_for_keys]

          # Check markdown mode and render accordingly
          if markdown_mode?
            render_markdown
          else
            render_html
          end
        end

        private

        def markdown_mode?
          # Explicit format parameter takes precedence over context
          return @format == :markdown if @format

          MarkdownUtils.markdown_mode?(@context)
        end

        def render_html
          card_data = build_card_data(title_html, image_alt, description_html, extra_elements_html)
          @log_out + CardRenderer.render_card(context: @context, card_data: card_data)
        end

        def render_markdown
          desc = description_text
          lines = []
          lines << '---'
          lines << title_line_markdown
          lines << rating_markdown if rating_value
          lines << image_markdown if @base[:absolute_image_url]
          lines << ''
          lines << desc if desc && !desc.strip.empty?
          lines << '---'
          @log_out + lines.join("\n")
        end

        def title_line_markdown
          title = resolved_title
          url = @base[:absolute_url]
          title_link = Formatter.markdown(title, url, italic: true)
          author_links = authors_markdown

          if author_links && !author_links.empty?
            "**#{title_link}** by #{author_links}"
          else
            "**#{title_link}**"
          end
        end

        def authors_markdown
          names = FrontMatter.get_list_from_string_or_array(@data['book_authors'])
          return nil if names.empty?

          # Let author links auto-detect format from context (markdown mode)
          links = names.map { |n| AuthorLinker.render_author_link(n, @context) }
          Text.format_list_as_sentence(links, etal_after: 3)
        end

        def rating_markdown
          val = rating_value
          return nil unless val

          full_stars = val.to_i
          half_star = (val % 1) >= 0.5
          empty_stars = 5 - full_stars - (half_star ? 1 : 0)

          ('★' * full_stars) + (half_star ? '⯨' : '') + ('☆' * empty_stars)
        end

        def rating_value
          @data['rating']
        end

        def image_markdown
          url = @base[:absolute_image_url]
          alt = image_alt
          "![#{alt}](#{url})"
        end

        def description_text
          html = CardExtractor.extract_description_html(@data, type: :book)
          Text.clean_text_from_html(html)
        end

        def resolved_title
          t = @title_override.to_s.strip.empty? ? @base[:raw_title] : @title_override
          if t == Jekyll::Books::Core::BookCardUtils::DEFAULT_TITLE_FOR_BOOK_CARD
            log('BOOK_CARD_MISSING_TITLE', 'Book title is missing and defaulted.', :error,
                { book_url: @base[:absolute_url] || @data['url'] || 'N/A' })
          end
          @final_title = t
          t
        end

        def extra_elements_html
          [authors_html, subtitle_html, rating_html].compact
        end

        def title_html
          t = resolved_title
          "<strong><cite class=\"book-title\">#{Typography.prepare_display_title(t)}</cite></strong>"
        end

        def image_alt
          path = @data['image']
          alt = @data['image_alt']

          return alt unless alt.to_s.strip.empty?

          log_image_alt_issue(path)
          "Book cover of #{@final_title}."
        end

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

        def description_html
          html = CardExtractor.extract_description_html(@data, type: :book)
          if html.strip.empty?
            log('BOOK_CARD_MISSING_EXCERPT', 'Book excerpt is missing or empty.', :warn,
                { book_title: @base[:raw_title] })
          end
          html
        end

        def authors_html
          names = FrontMatter.get_list_from_string_or_array(@data['book_authors'])
          if names.empty?
            log('BOOK_CARD_MISSING_AUTHORS', "'book_authors' field resolved to an empty list.", :warn,
                { book_title: @base[:raw_title] })
            return nil
          end
          # Explicitly use HTML format since we're rendering HTML card
          links = names.map { |n| AuthorLinker.render_author_link(n, @context, format: :html) }
          "    <span class=\"by-author\"> by #{Text.format_list_as_sentence(
            links, etal_after: 3
          )}</span>\n"
        end

        def subtitle_html
          return unless @subtitle && !@subtitle.to_s.strip.empty?

          "    <div class=\"card-subtitle\"><i>#{CGI.escapeHTML(@subtitle)}</i></div>\n"
        end

        def rating_html
          return unless (val = @data['rating'])

          html = Ratings.render_rating_stars(val, 'div')
          html && !html.empty? ? "    #{html}\n" : nil
        rescue ArgumentError => e
          log('BOOK_CARD_RATING_ERROR', "Invalid or malformed 'rating' value for book: #{e.message}", :warn,
              { title: @base[:raw_title], rating_input: val.inspect })
          nil
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
