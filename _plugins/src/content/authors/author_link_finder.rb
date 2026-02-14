# frozen_string_literal: true

require 'jekyll'
require_relative '../../infrastructure/text_processing_utils'

module Jekyll
  module Authors
    # Finds author data without any formatting.
    #
    # This class separates data fetching from formatting concerns.
    # It returns a data hash that can be passed to LinkFormatter.
    #
    # @example
    #   finder = AuthorLinkFinder.new(context)
    #   data = finder.find('Dan Simmons')
    #   # => { found: true, display_name: 'Dan Simmons', url: '/authors/...', ... }
    #
    #   # Then format with:
    #   LinkFormatter.html(data[:display_name], data[:url], wrapper: :span, css_class: 'author-name')
    class AuthorLinkFinder
      Text = Jekyll::Infrastructure::TextProcessingUtils
      private_constant :Text

      def initialize(context)
        @context = context
        @site = context&.registers&.[](:site)
        @current_page = context&.registers&.[](:page)
      end

      # Finds author data by name.
      #
      # @param name_raw [String] The author name to search for.
      # @param override [String, nil] Optional display text override.
      # @param possessive [Boolean] Whether to mark as possessive.
      # @return [Hash] Author data with keys:
      #   - :found [Boolean] Whether author was found in cache
      #   - :display_name [String] Text to display
      #   - :url [String, nil] URL to author page
      #   - :possessive [Boolean] Whether possessive form requested
      #   - :is_current_page [Boolean] Whether linking to current page
      def find(name_raw, override: nil, possessive: false)
        return empty_result(name_raw) unless @site

        name_input = name_raw.to_s
        norm_name = Text.normalize_title(name_input)

        return empty_result(name_input) if norm_name.empty?

        author_data = lookup_author(norm_name)
        display_name = determine_display_name(name_input, norm_name, author_data, override)

        build_result(
          found: !author_data.nil?,
          display_name: display_name,
          url: author_data&.[]('url'),
          possessive: possessive,
          author_data: author_data
        )
      end

      private

      def empty_result(name_input)
        {
          found: false,
          display_name: name_input.to_s,
          url: nil,
          possessive: false,
          is_current_page: false
        }
      end

      def lookup_author(norm_name)
        cache = @site.data['link_cache'] || {}
        (cache['authors'] || {})[norm_name]
      end

      def determine_display_name(name_input, norm_name, author_data, override)
        # Override takes priority
        return override.to_s.strip if override && !override.to_s.strip.empty?

        # If not found, use input as-is
        return name_input.strip unless author_data

        # If found, use canonical name only when searching by canonical
        canonical = author_data['title']
        norm_canonical = Text.normalize_title(canonical)

        norm_name == norm_canonical ? canonical : name_input.strip
      end

      def build_result(found:, display_name:, url:, possessive:, author_data:)
        {
          found: found,
          display_name: display_name,
          url: url,
          possessive: possessive,
          is_current_page: current_page?(url)
        }
      end

      def current_page?(target_url)
        return false unless target_url && @current_page

        current_url = @current_page['url'] || @current_page.url
        return false unless current_url

        # Use canonical URL resolution if available
        canonical_map = @site.data.dig('link_cache', 'url_to_canonical_map') || {}
        current_canonical = canonical_map[current_url] || current_url
        target_canonical = canonical_map[target_url] || target_url

        current_canonical == target_canonical
      end
    end
  end
end
