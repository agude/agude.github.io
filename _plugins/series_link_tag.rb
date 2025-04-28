# _plugins/series_link_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils' # Use require_relative

module Jekyll
  # Liquid Tag for creating a link to a series page, wrapped in <span>.
  # Handles optional display text override.
  # Usage: {% series_link "Title" [link_text="Display Text"] %}
  #        {% series_link variable [link_text=var2] %}
  class SeriesLinkTag < Liquid::Tag
    # Regex to capture: Title (quoted or variable), optional link_text=...
    SYNTAX = /^(#{Liquid::QuotedFragment})(?:\s+link_text\s*=\s*(#{Liquid::QuotedFragment}))?/o

    def initialize(tag_name, markup, tokens)
      super
      # Parse the markup string according to the syntax regex
      if markup =~ SYNTAX
        @title_markup = $1 # The part representing the title
        @link_text_markup = $2 # The part representing link_text, might be nil
      else
        # Basic fallback
        @title_markup = markup.strip
        @link_text_markup = nil
        # Consider raising SyntaxError
        # raise Liquid::SyntaxError, "Syntax Error in 'series_link': Bad syntax. Expected {% series_link \"Title\" [link_text=\"Text\"] %}"
      end
    end

    def render(context)
      # Resolve the potentially variable markup into actual strings
      series_title = LiquidUtils.resolve_value(@title_markup, context).to_s.gsub(/\s+/, ' ').strip
      link_text_override = @link_text_markup ? LiquidUtils.resolve_value(@link_text_markup, context) : nil

      # Handle cases where the title resolves to empty
      if series_title.empty?
        LiquidUtils.log_failure(
          context: context,
          tag_type: "SERIES_LINK",
          reason: "Input title markup resolved to empty",
          identifiers: { Markup: @title_markup }
        )
        return ""
      end

      site = context.registers[:site]
      found_series_doc = nil
      target_url = nil

      # --- Series Lookup Logic ---
      # Search site pages for a matching title and layout 'series_page'
      # Adjust this logic if series are stored differently
      found_series_doc = site.pages.find do |page|
        page.data['layout'] == 'series_page' && page.data['title']&.strip == series_title
      end
      # --- End Series Lookup ---

      # --- Determine Display Text ---
      display_text = series_title # Default
      if !link_text_override.nil? && !link_text_override.empty?
        # 1. Use link_text override if provided
        display_text = link_text_override.to_s.strip
      elsif found_series_doc && found_series_doc.data['title']
        # 2. Use canonical title from found document
        canonical_title = found_series_doc.data['title'].strip
        display_text = canonical_title unless canonical_title.empty?
      end
      # 3. Fallback is the original series_title
      # --- End Display Text ---

      # Escape the display text and create the core element
      escaped_display_text = CGI.escapeHTML(display_text)
      span_element = "<span class=\"book-series\">#{escaped_display_text}</span>"

      # --- Link Generation ---
      # If we found a corresponding document...
      if found_series_doc
        target_url = found_series_doc.url
        current_page_url = context.registers[:page]['url']
        # ...and it's not the current page...
        if target_url && target_url != current_page_url
          # ...wrap in a link
          "<a href=\"#{site.config['baseurl']}#{target_url}\">#{span_element}</a>"
        else
          # ...otherwise, use the unlinked element
          span_element
        end
      else
        # If no document found, log failure and use the unlinked element
        LiquidUtils.log_failure(
          context: context,
          tag_type: "SERIES_LINK",
          reason: "Could not find series page",
          identifiers: { Series: series_title }
        )
        span_element
      end
      # --- End Link Generation ---
    end
  end
end

Liquid::Template.register_tag('series_link', Jekyll::SeriesLinkTag)
