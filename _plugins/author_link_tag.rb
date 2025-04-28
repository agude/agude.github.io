# _plugins/author_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require 'strscan' # For flexible argument parsing
require_relative 'liquid_utils' # Use require_relative for local utils

module Jekyll
  # Liquid Tag for creating a link to an author page, wrapped in <span>.
  # Handles optional display text override and possessive ('s) suffix.
  # Arguments can be in flexible order after the name.
  # Usage: {% author_link "Name" [link_text="Display Text"] [possessive] %}
  #        {% author_link variable [link_text=var2] [possessive] %}
  #        {% author_link "Name" [possessive] [link_text="Display Text"] %}
  class AuthorLinkTag < Liquid::Tag
    # Keep QuotedFragment handy for parsing values
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup # Store original for potential error messages

      # --- Improved Argument Parsing using StringScanner ---
      @name_markup = nil
      @link_text_markup = nil
      @possessive_flag = false

      # Use a scanner to step through the markup
      scanner = StringScanner.new(markup.strip)

      # 1. Extract the Name (first argument, must be quoted or a variable)
      # Try matching a quoted fragment first
      if scanner.scan(QuotedFragment)
        @name_markup = scanner.matched
      else
        # If not quoted, try matching a sequence of non-whitespace characters (potential variable)
        if scanner.scan(/\S+/)
           @name_markup = scanner.matched
        else
           # If nothing is found, it's a syntax error
           raise Liquid::SyntaxError, "Syntax Error in 'author_link': Could not find author name in '#{@raw_markup}'"
        end
      end

      # 2. Scan the rest of the string for optional arguments (link_text, possessive)
      # Loop while there's content left to scan
      until scanner.eos? # eos? means End Of String?
        scanner.skip(/\s+/) # Consume leading whitespace before the next argument
        break if scanner.eos? # Stop if only whitespace remained

        # Check for link_text=... argument
        if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
          # scanner[1] contains the captured quoted fragment (the value)
          # Prevent overwriting if it appears multiple times (take the first one)
          @link_text_markup ||= scanner[1]
        # Check for the standalone 'possessive' keyword
        elsif scanner.scan(/possessive(?!\S)/) # Ensure 'possessive' is a whole word
          @possessive_flag = true
        else
          # Found an unrecognized argument
          unknown_arg = scanner.scan(/\S+/) # Capture the unknown part
          # Option 1: Ignore unknown arguments silently
          # Option 2: Log a warning
          # puts "WARNING: Unknown argument '#{unknown_arg}' in author_link tag: '#{@raw_markup}'"
          # Option 3: Raise an error to break the build
          raise Liquid::SyntaxError, "Syntax Error in 'author_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
          # scanner.terminate # Stop scanning if raising error
        end
      end
      # --- End Improved Argument Parsing ---

    end # End initialize

    # Renders the author link HTML
    def render(context)
      # Resolve name and optional link_text using the parsed markups from initialize
      author_name = LiquidUtils.resolve_value(@name_markup, context).to_s.gsub(/\s+/, ' ').strip
      link_text_override = @link_text_markup ? LiquidUtils.resolve_value(@link_text_markup, context) : nil

      # Handle cases where the name resolves to empty
      if author_name.empty?
        LiquidUtils.log_failure(
          context: context,
          tag_type: "AUTHOR_LINK",
          reason: "Input name markup resolved to empty",
          identifiers: { Markup: @name_markup || @raw_markup } # Use raw if name parsing failed
        )
        return "" # Render nothing if name is invalid
      end

      site = context.registers[:site]
      found_author_doc = nil
      target_url = nil

      # --- Author Lookup Logic ---
      # Search site pages for a matching title and layout 'author_page'
      # Adjust this logic if authors are stored differently (e.g., in a collection)
      found_author_doc = site.pages.find do |page|
        page.data['layout'] == 'author_page' && page.data['title']&.strip == author_name
      end
      # --- End Author Lookup ---

      # --- Determine Display Text ---
      display_text = author_name # Default to the resolved author name
      if !link_text_override.nil? && !link_text_override.empty?
        # 1. Use link_text override if provided and not empty
        display_text = link_text_override.to_s.strip
      elsif found_author_doc && found_author_doc.data['title']
        # 2. If no override, use the canonical title from the found document's front matter
        canonical_title = found_author_doc.data['title'].strip
        display_text = canonical_title unless canonical_title.empty?
      end
      # 3. Fallback is the original author_name (already set)
      # --- End Display Text ---

      # Escape the display text for HTML safety and create the core element
      escaped_display_text = CGI.escapeHTML(display_text)
      span_element = "<span class=\"author-name\">#{escaped_display_text}</span>"

      # --- Link Generation ---
      # If we found a corresponding document...
      if found_author_doc
        target_url = found_author_doc.url
        current_page_url = context.registers[:page]['url']
        # ...and it's not the current page...
        if target_url && target_url != current_page_url
          # ...wrap the element in a link
          linked_element = "<a href=\"#{site.config['baseurl']}#{target_url}\">#{span_element}</a>"
        else
          # ...otherwise, just use the unlinked element
          linked_element = span_element
        end
      else
        # If no document was found, log the failure and use the unlinked element
        LiquidUtils.log_failure(
          context: context,
          tag_type: "AUTHOR_LINK",
          reason: "Could not find author page",
          identifiers: { Name: author_name }
        )
        linked_element = span_element
      end
      # --- End Link Generation ---

      # Append 's if the possessive flag was set during initialization
      if @possessive_flag
        "#{linked_element}'s"
      else
        linked_element
      end
    end # End render

  end # End class AuthorLinkTag
end # End module Jekyll

# Register the tag with Liquid so Jekyll recognizes {% author_link ... %}
Liquid::Template.register_tag('author_link', Jekyll::AuthorLinkTag)
