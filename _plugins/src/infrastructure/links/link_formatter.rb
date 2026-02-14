# frozen_string_literal: true

require 'cgi'

module Jekyll
  module Infrastructure
    module Links
      # Unified interface for generating links in different formats.
      #
      # This class separates formatting concerns from data fetching,
      # allowing callers to explicitly choose output format (HTML or Markdown)
      # rather than having components check context flags.
      #
      # @example Generate HTML link
      #   LinkFormatter.html('Dan Simmons', '/authors/dan_simmons/', wrapper: :span, css_class: 'author-name')
      #   # => '<a href="/authors/dan_simmons/"><span class="author-name">Dan Simmons</span></a>'
      #
      # @example Generate Markdown link
      #   LinkFormatter.markdown('Endymion', '/books/endymion/', italic: true)
      #   # => '[*Endymion*](/books/endymion/)'
      #
      # @example Use unified format method
      #   LinkFormatter.format('Text', '/url/', format: :html, wrapper: :span)
      #   LinkFormatter.format('Text', '/url/', format: :markdown, italic: true)
      module LinkFormatter
        # Generates a markdown link.
        #
        # @param text [String] The display text for the link.
        # @param url [String, nil] The URL to link to.
        # @param italic [Boolean] Whether to wrap text in asterisks for italics.
        # @return [String] Markdown link or plain/italic text if no URL.
        def self.markdown(text, url, italic: false)
          display = italic ? "*#{text}*" : text.to_s
          url.to_s.empty? ? display : "[#{display}](#{url})"
        end

        # Generates an HTML link.
        #
        # @param text [String] The display text for the link.
        # @param url [String, nil] The URL to link to.
        # @param wrapper [Symbol, nil] Element to wrap text (:span, :cite, etc.) or nil for none.
        # @param css_class [String, nil] CSS class for the wrapper element.
        # @return [String] HTML link or wrapped/plain text if no URL.
        def self.html(text, url, wrapper: nil, css_class: nil)
          inner = build_inner_element(text, wrapper, css_class)

          if url.to_s.empty?
            inner
          else
            "<a href=\"#{url}\">#{inner}</a>"
          end
        end

        # Unified format method that delegates to html or markdown.
        #
        # @param text [String] The display text for the link.
        # @param url [String, nil] The URL to link to.
        # @param format [Symbol] Output format (:html or :markdown).
        # @param options [Hash] Format-specific options (wrapper:, css_class:, italic:).
        # @return [String] Formatted link.
        # @raise [ArgumentError] If format is not :html or :markdown.
        def self.format(text, url, format:, **options)
          case format
          when :html
            html(text, url, **options.slice(:wrapper, :css_class))
          when :markdown
            markdown(text, url, **options.slice(:italic))
          else
            raise ArgumentError, "Unknown format: #{format}. Expected :html or :markdown."
          end
        end

        # Builds the inner HTML element with optional wrapper and class.
        #
        # @param text [String] The text content.
        # @param wrapper [Symbol, nil] Element tag (:span, :cite, etc.) or nil.
        # @param css_class [String, nil] CSS class for the wrapper.
        # @return [String] The inner HTML element or escaped text.
        def self.build_inner_element(text, wrapper, css_class)
          escaped_text = CGI.escapeHTML(text.to_s)

          return escaped_text unless wrapper

          class_attr = css_class ? " class=\"#{css_class}\"" : ''
          "<#{wrapper}#{class_attr}>#{escaped_text}</#{wrapper}>"
        end
        private_class_method :build_inner_element
      end
    end
  end
end
