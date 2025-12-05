# frozen_string_literal: true

# _plugins/utils/link_helper_utils.rb
require 'jekyll'

module Jekyll
  module Infrastructure
    module Links
      # Utility module for generating HTML links with fallback handling.
      module LinkHelperUtils
        # Determines the correct text to display for a link/span.
        # Prioritizes override_text, then canonical_title from found_doc, then input_text.
        # @param input_text [String] The original text passed to the tag.
        # @param override_text [String, nil] The optional link_text override.
        # @param found_doc [MockDocument, Jekyll::Document, Jekyll::Page, nil] The document if found.
        # @return [String] The text to display.
        def self._get_link_display_text(input_text, override_text, found_doc)
          display_text = input_text.to_s.strip # Default to stripped input
          if override_text && !override_text.empty?
            display_text = override_text.strip
          elsif found_doc && found_doc.data['title'] # Assumes canonical name is in 'title'
            canonical_title = found_doc.data['title'].strip
            # Use canonical title only if it's not empty after stripping
            display_text = canonical_title unless canonical_title.empty?
          end
          # Fallback is the stripped input_text if override is missing/empty
          # AND (doc not found OR doc title is missing/empty)
          display_text
        end

        # Generates the final HTML (<a> or just the inner element) based on the target URL and context.
        # @param context [Liquid::Context] The current Liquid context.
        # @param target_url [String, nil] The URL to link to.
        # @param inner_html_element [String] The pre-built inner HTML (e.g., <cite>...</cite>, <span>...</span>).
        # @return [String] The final HTML string (linked or unlinked).
        def self._generate_link_html(context, target_url, inner_html_element)
          site, page = _extract_context_components(context)
          return inner_html_element unless site && page

          target_url_str = target_url.to_s
          return inner_html_element if target_url_str.empty?

          _build_link_with_url_resolution(site, page, target_url_str, inner_html_element)
        end

        def self._extract_context_components(context)
          return [nil, nil] unless context

          site = context.registers[:site]
          page = context.registers[:page]
          [site, page]
        end
        private_class_method :_extract_context_components

        def self._build_link_with_url_resolution(site, page, target_url_str, inner_html_element)
          current_page_url = page['url']
          target_base_url, target_fragment = _parse_url_parts(target_url_str)
          current_canonical_url, target_canonical_url = _resolve_canonical_urls(
            site, current_page_url, target_base_url
          )

          link_params = {
            current_canonical_url: current_canonical_url,
            target_canonical_url: target_canonical_url,
            target_fragment: target_fragment,
            target_url_str: target_url_str,
            inner_html_element: inner_html_element,
            site: site
          }
          _build_appropriate_link(link_params)
        end
        private_class_method :_build_link_with_url_resolution

        # Parses a URL into its base and fragment parts.
        # @param url [String] The URL to parse.
        # @return [Array<String, String|nil>] The base URL and fragment (or nil if no fragment).
        def self._parse_url_parts(url)
          parts = url.split('#', 2)
          [parts[0], parts[1]]
        end
        private_class_method :_parse_url_parts

        # Resolves canonical URLs for current and target pages using the link cache.
        # @param site [Jekyll::Site] The Jekyll site object.
        # @param current_page_url [String] The current page's URL.
        # @param target_base_url [String] The target page's base URL.
        # @return [Array<String, String>] The canonical URLs for current and target pages.
        def self._resolve_canonical_urls(site, current_page_url, target_base_url)
          canonical_map = site.data.dig('link_cache', 'url_to_canonical_map') || {}
          current_canonical = canonical_map[current_page_url] || current_page_url
          target_canonical = canonical_map[target_base_url] || target_base_url
          [current_canonical, target_canonical]
        end
        private_class_method :_resolve_canonical_urls

        # Builds the appropriate link HTML based on the relationship between current and target pages.
        # @param params [Hash] A hash containing:
        #   :current_canonical_url [String] The canonical URL of the current page.
        #   :target_canonical_url [String] The canonical URL of the target page.
        #   :target_fragment [String, nil] The fragment (anchor) part of the target URL.
        #   :target_url_str [String] The full target URL string.
        #   :inner_html_element [String] The inner HTML element to wrap or return.
        #   :site [Jekyll::Site] The Jekyll site object.
        # @return [String] The final HTML string.
        def self._build_appropriate_link(params)
          current_canonical_url = params[:current_canonical_url]
          target_canonical_url = params[:target_canonical_url]
          target_fragment = params[:target_fragment]
          target_url_str = params[:target_url_str]
          inner_html_element = params[:inner_html_element]
          site = params[:site]

          # Case 1: Different conceptual page - generate full link
          if current_canonical_url != target_canonical_url
            href = _normalize_href(target_url_str, site.config['baseurl'] || '')
            "<a href=\"#{href}\">#{inner_html_element}</a>"
          # Case 2: Same page with anchor - generate relative anchor link
          elsif target_fragment
            "<a href=\"##{target_fragment}\">#{inner_html_element}</a>"
          # Case 3: Same page without anchor - suppress link
          else
            inner_html_element
          end
        end
        private_class_method :_build_appropriate_link

        # Normalizes an href with the site's baseurl.
        # @param href [String] The href to normalize.
        # @param baseurl [String] The site's baseurl.
        # @return [String] The normalized href.
        def self._normalize_href(href, baseurl)
          return href if baseurl.empty?

          href = "/#{href}" unless href.start_with?('/') || href.start_with?(baseurl)
          href = "#{baseurl}#{href}" unless href.start_with?(baseurl)
          href
        end
        private_class_method :_normalize_href
      end
    end
  end
end
