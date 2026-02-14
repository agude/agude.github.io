# frozen_string_literal: true

# _plugins/src/content/authors/author_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../../infrastructure/links/link_formatter'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/links/markdown_link_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative 'author_link_finder'

module Jekyll
  module Authors
    # Utility module for rendering author name links.
    #
    # Uses AuthorLinkFinder to locate data and LinkFormatter to produce output.
    # Supports explicit format selection or automatic detection from context.
    module AuthorLinkUtils
      Finder = Jekyll::Authors::AuthorLinkFinder
      Formatter = Jekyll::Infrastructure::Links::LinkFormatter
      MarkdownUtils = Jekyll::Infrastructure::Links::MarkdownLinkUtils
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      private_constant :Finder, :Formatter, :MarkdownUtils, :LinkHelper, :Logger

      # --- Public Method ---

      # Finds an author page by name and renders the link in the specified format.
      #
      # @param author_name_raw [String] The name of the author.
      # @param context [Liquid::Context] The current Liquid context.
      # @param link_text_override_raw [String, nil] Optional display text.
      # @param possessive [Boolean, nil] If true, append 's to the output.
      # @param format [Symbol, nil] Output format (:html or :markdown).
      #   If nil, determined from context (markdown_mode? check).
      # @return [String] The formatted link.
      def self.render_author_link(author_name_raw, context, link_text_override_raw = nil, possessive = nil,
                                  format: nil)
        # Find author data
        data = Finder.new(context).find(
          author_name_raw,
          override: link_text_override_raw,
          possessive: possessive
        )

        # Determine output format
        output_format = format || detect_format(context)

        # Format and return
        format_author_link(data, context, output_format)
      end

      # --- Private Helper Methods ---

      def self.detect_format(context)
        MarkdownUtils.markdown_mode?(context) ? :markdown : :html
      end
      private_class_method :detect_format

      def self.format_author_link(data, context, format)
        suffix = data[:possessive] ? "\u2019s" : ''

        case format
        when :markdown
          format_markdown(data, suffix)
        else
          format_html(data, context, suffix)
        end
      end
      private_class_method :format_author_link

      def self.format_markdown(data, suffix)
        link = Formatter.markdown(data[:display_name], data[:url])
        link + suffix
      end
      private_class_method :format_markdown

      def self.format_html(data, context, suffix)
        inner = _build_author_span_element(data[:display_name])
        content = "#{inner}#{suffix}"

        if data[:found] && !data[:is_current_page] && data[:url]
          LinkHelper._generate_link_html(context, data[:url], content)
        else
          content
        end
      end
      private_class_method :format_html

      # Builds the inner <span> element for the author name.
      def self._build_author_span_element(display_text)
        escaped_display_text = CGI.escapeHTML(display_text.to_s)
        "<span class=\"author-name\">#{escaped_display_text}</span>"
      end

      # Logs the failure when the author page is not found.
      def self._log_author_not_found(context, input_name)
        Logger.log_liquid_failure(
          context: context, tag_type: 'RENDER_AUTHOR_LINK',
          reason: 'Could not find author page in cache.',
          identifiers: { Name: input_name.to_s.strip },
          level: :info
        )
      end
    end
  end
end
