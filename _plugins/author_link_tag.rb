# _plugins/author_link_tag.rb
require 'jekyll'
require 'liquid'
require_relative 'liquid_utils' # Use require_relative

module Jekyll
  # Liquid Tag for creating a link to an author page, wrapped in <span>.
  # Handles optional display text override and possessive ('s) suffix.
  # Usage: {% author_link "Name" [link_text="Display Text"] [possessive] %}
  #        {% author_link variable [link_text=var2] [possessive] %}
  class AuthorLinkTag < Liquid::Tag
    # Regex to capture: Name (quoted or variable), optional link_text=..., optional possessive keyword
    SYNTAX = /^(#{Liquid::QuotedFragment})(?:\s+link_text\s*=\s*(#{Liquid::QuotedFragment}))?(?:\s+(possessive))?\s*$/o

    def initialize(tag_name, markup, tokens)
      super
      # Parse the markup string according to the syntax regex
      if markup =~ SYNTAX
        @name_markup = $1 # The part representing the name
        @link_text_markup = $2 # The part representing link_text, might be nil
        @possessive_flag = !!$3 # True if 'possessive' keyword was present, false otherwise
      else
        # Basic fallback
        @name_markup = markup.strip
        @link_text_markup = nil
        @possessive_flag = false
        # Consider raising SyntaxError
        # raise Liquid::SyntaxError, "Syntax Error in 'author_link': Bad syntax. Expected {% author_link \"Name\" [link_text=\"Text\"] [possessive] %}"
      end
    end

    def render(context)
      # Resolve the potentially variable markup into actual strings
      author_name = LiquidUtils.resolve_value(@name_markup, context).to_s.gsub(/\s+/, ' ').strip
      link_text_override = @link_text_markup ? LiquidUtils.resolve_value(@link_text_markup, context) : nil

      # Handle cases where the name resolves to empty
      if author_name.empty?
        LiquidUtils.log_failure(
          context: context,
          tag_type: "AUTHOR_LINK",
          reason: "Input name markup resolved to empty",
          identifiers: { Markup: @name_markup }
        )
        return ""
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
      display_text = author_name # Default
      if !link_text_override.nil? && !link_text_override.empty?
        # 1. Use link_text override if provided
        display_text = link_text_override.to_s.strip
      elsif found_author_doc && found_author_doc.data['title']
        # 2. Use canonical title from found document
        canonical_title = found_author_doc.data['title'].strip
        display_text = canonical_title unless canonical_title.empty?
      end
      # 3. Fallback is the original author_name
      # --- End Display Text ---

      # Escape the display text and create the core element
      escaped_display_text = CGI.escapeHTML(display_text)
      span_element = "<span class=\"author-name\">#{escaped_display_text}</span>"

      # --- Link Generation ---
      # If we found a corresponding document...
      if found_author_doc
        target_url = found_author_doc.url
        current_page_url = context.registers[:page]['url']
        # ...and it's not the current page...
        if target_url && target_url != current_page_url
          # ...wrap in a link
          linked_element = "<a href=\"#{site.config['baseurl']}#{target_url}\">#{span_element}</a>"
        else
          # ...otherwise, use the unlinked element
          linked_element = span_element
        end
      else
        # If no document found, log failure and use the unlinked element
        LiquidUtils.log_failure(
          context: context,
          tag_type: "AUTHOR_LINK",
          reason: "Could not find author page",
          identifiers: { Name: author_name }
        )
        linked_element = span_element
      end
      # --- End Link Generation ---

      # Append 's if the possessive flag was set in the tag usage
      if @possessive_flag
        "#{linked_element}'s"
      else
        linked_element
      end
    end
  end
end

Liquid::Template.register_tag('author_link', Jekyll::AuthorLinkTag)
