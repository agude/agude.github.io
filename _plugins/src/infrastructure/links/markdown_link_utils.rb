# frozen_string_literal: true

# _plugins/src/infrastructure/links/markdown_link_utils.rb

module Jekyll
  module Infrastructure
    module Links
      # Utility module for generating markdown links.
      #
      # Used when rendering content in markdown mode (for LLM consumption)
      # instead of HTML mode (for web browsers).
      module MarkdownLinkUtils
        # Generates a markdown link, optionally with italic text.
        #
        # @param text [String] The display text for the link.
        # @param url [String, nil] The URL to link to.
        # @param italic [Boolean] Whether to wrap the text in asterisks for italics.
        # @return [String] The markdown link or plain text if no URL.
        def self.render_link(text, url, italic: false)
          display = italic ? "*#{text}*" : text
          url.to_s.empty? ? display : "[#{display}](#{url})"
        end

        # Checks if the context is in markdown mode.
        #
        # @param context [Liquid::Context] The current Liquid context.
        # @return [Boolean] True if markdown mode is enabled.
        def self.markdown_mode?(context)
          return false unless context.respond_to?(:registers)
          return false if context.registers.nil?

          context.registers[:markdown_mode] == true
        end
      end
    end
  end
end
