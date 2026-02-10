# frozen_string_literal: true

# _plugins/src/content/authors/author_link_resolver.rb
require 'jekyll'
require 'cgi'
require_relative '../../infrastructure/links/link_helper_utils'
require_relative '../../infrastructure/plugin_logger_utils'
require_relative '../../infrastructure/text_processing_utils'
require_relative 'author_link_util'

module Jekyll
  module Authors
    # Helper class to handle author link resolution logic
    class AuthorLinkResolver
      # Aliases for readability
      LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
      Logger = Jekyll::Infrastructure::PluginLoggerUtils
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :LinkHelper, :Logger, :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @log_output = ''
      end

      def resolve(name_raw, override, possessive)
        return CGI.escapeHTML(name_raw.to_s) unless @site

        @name_input = name_raw.to_s
        @override = override.to_s.strip if override && !override.to_s.empty?
        @possessive = possessive

        norm_name = Text.normalize_title(@name_input)
        return log_empty_name(name_raw) if norm_name.empty?

        author_data = find_author(norm_name)
        display_text = determine_display_text(author_data, norm_name)

        generate_html(display_text, author_data)
      end

      private

      def log_empty_name(raw)
        Logger.log_liquid_failure(
          context: @context, tag_type: 'RENDER_AUTHOR_LINK',
          reason: 'Input author name resolved to empty after normalization.',
          identifiers: { NameInput: raw || 'nil' }, level: :warn
        )
      end

      def find_author(norm_name)
        cache = @site.data['link_cache'] || {}
        author_data = (cache['authors'] || {})[norm_name]

        @log_output = Jekyll::Authors::AuthorLinkUtils._log_author_not_found(@context, @name_input) unless author_data
        author_data
      end

      def determine_display_text(author_data, norm_name)
        return @override if @override
        return @name_input.strip unless author_data

        canonical = author_data['title']
        norm_canonical = Text.normalize_title(canonical)

        norm_name == norm_canonical ? canonical : @name_input.strip
      end

      def generate_html(display_text, author_data)
        span = Jekyll::Authors::AuthorLinkUtils._build_author_span_element(display_text)
        suffix = @possessive ? "\u2019s" : ''
        content = "#{span}#{suffix}"
        url = author_data ? author_data['url'] : nil

        html = LinkHelper._generate_link_html(@context, url, content)

        @log_output + html
      end
    end
  end
end
