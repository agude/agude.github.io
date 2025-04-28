# _plugins/series_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require 'strscan' # For flexible argument parsing
require_relative 'liquid_utils' # Use require_relative for local utils

module Jekyll
  # Liquid Tag for creating a link to a series page, wrapped in <span>.
  # Handles optional display text override.
  # Arguments can be in flexible order after the title.
  # Usage: {% series_link "Title" [link_text="Display Text"] %}
  #        {% series_link variable [link_text=var2] %}
  class SeriesLinkTag < Liquid::Tag
    # Keep QuotedFragment handy for parsing values
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup # Store original for potential error messages

      # --- Improved Argument Parsing using StringScanner ---
      @title_markup = nil
      @link_text_markup = nil

      # Use a scanner to step through the markup
      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Title (first argument, must be quoted or a variable)
      if scanner.scan(QuotedFragment)
        @title_markup = scanner.matched
      else
        # If not quoted, try matching a sequence of non-whitespace characters (potential variable)
        if scanner.scan(/\S+/)
           @title_markup = scanner.matched
        else
           # If nothing is found, it's a syntax error
           raise Liquid::SyntaxError, "Syntax Error in 'series_link': Could not find series title in '#{@raw_markup}'"
        end
      end

      # 2. Scan the rest of the string for optional arguments (link_text)
      until scanner.eos?
        scanner.skip(/\s+/) # Consume leading whitespace
        break if scanner.eos?

        # Check for link_text=... argument
        if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
          @link_text_markup ||= scanner[1] # Take the first one found
        else
          # Found an unrecognized argument
          unknown_arg = scanner.scan(/\S+/)
          raise Liquid::SyntaxError, "Syntax Error in 'series_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end
      # --- End Improved Argument Parsing ---

    end # End initialize

    # Renders the series link HTML
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
          identifiers: { Markup: @title_markup || @raw_markup }
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
    end # End render

  end # End class SeriesLinkTag
end # End module Jekyll

# Register the tag with Liquid so Jekyll recognizes {% series_link ... %}
Liquid::Template.register_tag('series_link', Jekyll::SeriesLinkTag)
