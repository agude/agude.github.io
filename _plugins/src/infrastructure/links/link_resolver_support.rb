# frozen_string_literal: true

# Tested by: _tests/src/infrastructure/links/test_link_resolver_skeleton.rb

require 'jekyll'
require 'cgi'
require_relative 'link_helper_utils'
require_relative '../plugin_logger_utils'
require_relative '../text_processing_utils'

module Jekyll
  module Infrastructure
    module Links
      # Shared plumbing for link resolvers. Provides initialization, cache
      # lookup, HTML rendering, and logging. Each resolver supplies
      # `resolve_data` and `link_content`, which returns the inner element
      # and any hover preview.
      #
      # @pattern Resolvers include this module directly rather than going
      #   through a separate `*_link_util.rb` wrapper — all resolution logic
      #   lives on the resolver. `LinkResolverSkeleton` builds a full
      #   template-method flow on top for the simple (author/series) case.
      module LinkResolverSupport
        LinkHelper = Jekyll::Infrastructure::Links::LinkHelperUtils
        Logger = Jekyll::Infrastructure::PluginLoggerUtils
        Text = Jekyll::Infrastructure::TextProcessingUtils

        def initialize(context)
          @context = context
          @site = (context.registers&.[](:site) if context.respond_to?(:registers))
          @log_output = ''
        end

        def resolve(...)
          render_html_from_data(resolve_data(...))
        end

        # Both rendered links and backlink targets select from current reviews.
        # @gotcha A review that sets canonical_url is an archive.
        def self.canonical_book_candidates(entries)
          (entries || []).reject { |book| book['canonical_url'] }
        end

        private

        def render_html_from_data(data)
          case data[:status]
          when :no_site
            no_site_html(data)
          when :empty_name, :empty_title
            @log_output
          when :found, :not_found, :ambiguous
            content, preview = link_content(data)
            @log_output.to_s + wrap_with_link(content, data[:url], preview)
          else
            raise Jekyll::Errors::FatalException,
                  "#{self.class.name}#render_html_from_data: unrecognized status #{data[:status].inspect}"
          end
        end

        def no_site_html(data)
          link_content(data).first
        end

        # Keep non-fatal diagnostics outside the preview span.
        def build_preview_html(renderer, data, title)
          return nil if renderer.building_lede?(@site)

          preview = renderer.new(
            @context,
            title,
            data[:authors],
            data[:rating],
            data[:image],
            series: data[:series],
            book_number: data[:book_number],
            lede_html: renderer.extract_lede(@site, data[:url]),
          )
          html = preview.render
          @log_output = @log_output.to_s + preview.log_output.to_s
          html
        end

        # Look up a normalized key in a link-cache section.
        # Returns the cached entry or nil.
        def find_in_cache(section, normalized_key)
          cache = @site.data['link_cache'] || {}
          (cache[section] || {})[normalized_key]
        end

        # Wrap inner HTML with a link tag via LinkHelperUtils.
        # @param preview_html [String, nil] Optional hover-preview markup, only emitted
        #   when a real cross-page link is generated (see LinkHelperUtils._generate_link_html).
        def wrap_with_link(inner_html, url, preview_html = nil)
          LinkHelper._generate_link_html(@context, url, inner_html, preview_html)
        end

        # Convenience wrapper around PluginLoggerUtils that pre-fills @context.
        def log_failure(tag_type:, reason:, identifiers:, level:)
          Logger.log_liquid_failure(
            context: @context,
            tag_type: tag_type,
            reason: reason,
            identifiers: identifiers,
            level: level,
          )
        end
      end
    end
  end
end
