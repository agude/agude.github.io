# frozen_string_literal: true

# _plugins/utils/author_link_util.rb
require 'jekyll'
require 'cgi'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'
require_relative 'author_link_resolver'

module Jekyll
  module Authors
    # Utility module for rendering author name links.
    #
    # Generates HTML links to author pages or plain text spans if no author
    # page exists, with support for possessive forms.
    module AuthorLinkUtils
      # --- Public Method ---

      # Finds an author page by name from the link_cache and renders the link/span HTML.
      #
      # @param author_name_raw [String] The name of the author.
      # @param context [Liquid::Context] The current Liquid context.
      # @param link_text_override_raw [String, nil] Optional display text.
      # @param possessive [Boolean, nil] If true, append ’s to the output. Defaults to nil (falsey).
      # @return [String] The generated HTML (e.g., <a><span>...</span></a> or <span>...</span>’s).
      def self.render_author_link(author_name_raw, context, link_text_override_raw = nil, possessive = nil)
        Jekyll::Authors::AuthorLinkResolver.new(context).resolve(author_name_raw, link_text_override_raw, possessive)
      end

      # Returns a structured data hash (not HTML) for an author link resolution.
      def self.find_author_link_data(author_name_raw, context, link_text_override_raw = nil, possessive = nil)
        Jekyll::Authors::AuthorLinkResolver.new(context).resolve_data(
          author_name_raw,
          link_text_override_raw,
          possessive,
        )
      end

      # --- Private Helper Methods ---

      # Builds the inner <span> element for the author name.
      def self._build_author_span_element(display_text)
        # Author names typically don't need complex typography, use basic escape.
        escaped_display_text = CGI.escapeHTML(display_text)
        "<span class=\"author-name\">#{escaped_display_text}</span>"
      end

      # Logs the failure when the author page is not found.
      def self._log_author_not_found(context, input_name)
        Jekyll::Infrastructure::PluginLoggerUtils.log_liquid_failure(
          context: context,
          tag_type: 'RENDER_AUTHOR_LINK',
          reason: 'Could not find author page in cache.',
          identifiers: { Name: input_name.strip },
          level: :info,
        )
      end
    end
  end
end
