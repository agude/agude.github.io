# frozen_string_literal: true

# _plugins/src/ui/quotes/citedquote_utils.rb
require 'cgi'
require_relative '../citations/citation_utils'

module Jekyll
  module UI
    module Quotes
      # Utility module for rendering attributed quotes as semantic HTML.
      # Wraps content in <figure> + <blockquote> with a <figcaption> containing
      # the citation formatted by CitationUtils.
      module CitedQuoteUtils
        CitationUtil = Jekyll::UI::Citations::CitationUtils
        private_constant :CitationUtil

        # Renders an attributed quote as HTML.
        #
        # @param content [String] The quote content (will be processed as Markdown)
        # @param params [Hash] Citation parameters (author_last, work_title, url, etc.)
        # @param site [Jekyll::Site] The Jekyll site object (for Markdown converter)
        # @return [String] The complete HTML figure element wrapped for Kramdown compatibility
        def self.render(content, params, site)
          processed_content = _process_markdown(content, site)
          blockquote_html = _build_blockquote(processed_content, params[:url])
          figcaption_html = _build_figcaption(params, site)

          # Wrap in {::nomarkdown} to prevent Kramdown from escaping HTML when
          # used inside footnotes. Output as single line for extra safety.
          html = "<figure class=\"cited-quote\">#{blockquote_html}#{figcaption_html}</figure>"
          "{::nomarkdown}#{html.gsub("\n", '')}{:/nomarkdown}"
        end

        # Process content through the site's Markdown converter.
        def self._process_markdown(content, site)
          converter = site&.find_converter_instance(Jekyll::Converters::Markdown)
          return content unless converter

          converter.convert(content.to_s)
        end
        private_class_method :_process_markdown

        # Build the blockquote element with optional cite attribute.
        def self._build_blockquote(content, url)
          cite_attr = _present?(url) ? " cite=\"#{_escape_attr(url)}\"" : ''
          "<blockquote#{cite_attr}>#{content}</blockquote>"
        end
        private_class_method :_build_blockquote

        # Build the figcaption element containing the citation.
        def self._build_figcaption(params, site)
          citation_html = CitationUtil.format_citation_html(params, site)
          "<figcaption>—#{citation_html}</figcaption>"
        end
        private_class_method :_build_figcaption

        # Check if a value is present (not nil and not empty string).
        def self._present?(obj)
          !obj.nil? && !obj.to_s.strip.empty?
        end
        private_class_method :_present?

        # Escape HTML attribute value.
        def self._escape_attr(str)
          CGI.escapeHTML(str.to_s)
        end
        private_class_method :_escape_attr
      end
    end
  end
end
