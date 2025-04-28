# _plugins/book_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require 'strscan' # For flexible argument parsing
require_relative 'liquid_utils' # Use require_relative for local utils

module Jekyll
  # Liquid Tag for creating a link to a book page, wrapped in <cite>.
  # Handles optional display text override.
  # Arguments can be in flexible order after the title.
  # Usage: {% book_link "Title" [link_text="Display Text"] %}
  #        {% book_link variable [link_text=var2] %}
  class BookLinkTag < Liquid::Tag
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
           raise Liquid::SyntaxError, "Syntax Error in 'book_link': Could not find book title in '#{@raw_markup}'"
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
          raise Liquid::SyntaxError, "Syntax Error in 'book_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end
      # --- End Improved Argument Parsing ---

    end # End initialize

    # Renders the book link HTML
    def render(context)
      # Resolve the potentially variable markup into actual strings using the helper
      book_title = LiquidUtils.resolve_value(@title_markup, context).to_s.gsub(/\s+/, ' ').strip
      link_text_override = @link_text_markup ? LiquidUtils.resolve_value(@link_text_markup, context) : nil

      # Handle cases where the title resolves to empty
      if book_title.empty?
        LiquidUtils.log_failure(
          context: context,
          tag_type: "BOOK_LINK",
          reason: "Input title markup resolved to empty",
          identifiers: { Markup: @title_markup || @raw_markup }
        )
        return "" # Render nothing if title is invalid
      end

      site = context.registers[:site]
      found_book_doc = nil
      target_url = nil

      # --- Book Lookup Logic ---
      # Search the 'books' collection for a matching title
      if site.collections.key?('books')
        found_book_doc = site.collections['books'].docs.find do |doc|
          # Compare stripped titles, handling potential nil values
          doc.data['title']&.strip == book_title
        end
      end
      # --- End Book Lookup ---

      # --- Determine Display Text ---
      # Start with the resolved book title as the default
      display_text = book_title
      if !link_text_override.nil? && !link_text_override.empty?
        # 1. Use link_text override if provided and not empty
        display_text = link_text_override.to_s.strip
      elsif found_book_doc && found_book_doc.data['title']
        # 2. If no override, use the canonical title from the found document's front matter
        canonical_title = found_book_doc.data['title'].strip
        display_text = canonical_title unless canonical_title.empty?
      end
      # 3. Fallback is the original book_title (already set)
      # --- End Display Text ---

      # Escape the display text for HTML safety and create the core element
      escaped_display_text = CGI.escapeHTML(display_text)
      cite_element = "<cite class=\"book-title\">#{escaped_display_text}</cite>"

      # --- Link Generation ---
      # If we found a corresponding document...
      if found_book_doc
        target_url = found_book_doc.url
        current_page_url = context.registers[:page]['url']
        # ...and it's not the page we are currently on...
        if target_url && target_url != current_page_url
          # ...wrap the element in a link
          "<a href=\"#{site.config['baseurl']}#{target_url}\">#{cite_element}</a>"
        else
          # ...otherwise, just return the unlinked element
          cite_element
        end
      else
        # If no document was found, log the failure and return the unlinked element
        LiquidUtils.log_failure(
          context: context,
          tag_type: "BOOK_LINK",
          reason: "Could not find book page",
          identifiers: { Title: book_title }
        )
        cite_element
      end
      # --- End Link Generation ---
    end # End render

  end # End class BookLinkTag
end # End module Jekyll

# Register the tag with Liquid so Jekyll recognizes {% book_link ... %}
Liquid::Template.register_tag('book_link', Jekyll::BookLinkTag)
