# frozen_string_literal: true

# _plugins/src/content/short_stories/short_story_link_util.rb
require 'jekyll'
require_relative '../../infrastructure/links/link_formatter'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/links/markdown_link_utils'
require_relative '../../infrastructure/typography_utils'
require_relative 'short_story_link_finder'
require_relative 'short_story_resolver'

module Jekyll
  module ShortStories
    # Utility module for generating links to short stories within anthology books.
    #
    # Uses ShortStoryLinkFinder to locate data and LinkFormatter to produce output.
    # Supports explicit format selection or automatic detection from context.
    module ShortStoryLinkUtils
      Finder = Jekyll::ShortStories::ShortStoryLinkFinder
      Formatter = Jekyll::Infrastructure::Links::LinkFormatter
      MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      Typography = Jekyll::Infrastructure::TypographyUtils
      private_constant :Finder, :Formatter, :MarkdownUtils, :LinkHelper, :Typography

      # Renders the HTML for a short story link.
      #
      # @param story_title_raw [String] The title of the story.
      # @param context [Liquid::Context] The current Liquid context.
      # @param from_book_title_raw [String, nil] The title of the book to disambiguate.
      # @param format [Symbol, nil] Output format (:html or :markdown).
      #   If nil, determined from context (markdown_mode? check).
      # @return [String] The generated HTML link or span.
      def self.render_short_story_link(story_title_raw, context, from_book_title_raw = nil, format: nil)
        # Find story data
        data = Finder.new(context).find(
          story_title_raw,
          from_book: from_book_title_raw
        )

        # Determine output format
        output_format = format || detect_format(context)

        # Format and return
        data[:log_output] + format_story_link(data, context, output_format)
      end

      # --- Private Helper Methods ---

      def self.detect_format(context)
        MarkdownUtils.markdown_mode?(context) ? :markdown : :html
      end
      private_class_method :detect_format

      def self.format_story_link(data, context, output_format)
        case output_format
        when :markdown
          format_markdown(data)
        else
          format_html(data, context)
        end
      end
      private_class_method :format_story_link

      def self.format_markdown(data)
        Formatter.markdown(data[:display_name], data[:url], italic: true)
      end
      private_class_method :format_markdown

      def self.format_html(data, context)
        cite = _build_story_cite_element(data[:display_name])

        if data[:found] && data[:url]
          LinkHelper._generate_link_html(context, data[:url], cite)
        else
          cite
        end
      end
      private_class_method :format_html

      def self._build_story_cite_element(display_text)
        prepared_display_text = Typography.prepare_display_title(display_text)
        "<cite class=\"short-story-title\">#{prepared_display_text}</cite>"
      end
    end
  end
end
