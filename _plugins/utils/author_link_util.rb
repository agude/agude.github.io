# frozen_string_literal: true

# _plugins/utils/author_link_util.rb
require 'jekyll'
require 'cgi'
require_relative 'link_helper_utils'
require_relative '../src/infrastructure/plugin_logger_utils'
require_relative '../src/infrastructure/text_processing_utils'

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
    AuthorLinkResolver.new(context).resolve(author_name_raw, link_text_override_raw, possessive)
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
    PluginLoggerUtils.log_liquid_failure(
      context: context, tag_type: 'RENDER_AUTHOR_LINK',
      reason: 'Could not find author page in cache.',
      identifiers: { Name: input_name.strip },
      level: :info
    )
  end

  # Helper class to handle author link resolution logic
  class AuthorLinkResolver
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

      norm_name = TextProcessingUtils.normalize_title(@name_input)
      return log_empty_name(name_raw) if norm_name.empty?

      author_data = find_author(norm_name)
      display_text = determine_display_text(author_data, norm_name)

      generate_html(display_text, author_data)
    end

    private

    def log_empty_name(raw)
      PluginLoggerUtils.log_liquid_failure(
        context: @context, tag_type: 'RENDER_AUTHOR_LINK',
        reason: 'Input author name resolved to empty after normalization.',
        identifiers: { NameInput: raw || 'nil' }, level: :warn
      )
    end

    def find_author(norm_name)
      cache = @site.data['link_cache'] || {}
      author_data = (cache['authors'] || {})[norm_name]

      @log_output = AuthorLinkUtils._log_author_not_found(@context, @name_input) unless author_data
      author_data
    end

    def determine_display_text(author_data, norm_name)
      return @override if @override
      return @name_input.strip unless author_data

      canonical = author_data['title']
      norm_canonical = TextProcessingUtils.normalize_title(canonical)

      norm_name == norm_canonical ? canonical : @name_input.strip
    end

    def generate_html(display_text, author_data)
      span = AuthorLinkUtils._build_author_span_element(display_text)
      suffix = @possessive ? '’s' : ''
      content = "#{span}#{suffix}"
      url = author_data ? author_data['url'] : nil

      html = LinkHelperUtils._generate_link_html(@context, url, content)

      # Fallback logic from original code: if result is just the span (unlinked) and possessive requested,
      # ensure suffix is present. (Though content passed to generator already has it).
      html << suffix if html == span && @possessive

      @log_output + html
    end
  end
end
