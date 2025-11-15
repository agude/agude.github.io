# _plugins/author_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require 'strscan' # For flexible argument parsing

require_relative 'utils/tag_argument_utils'
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

      # --- Argument Parsing using StringScanner ---
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
        unless scanner.scan(/\S+/)
          raise Liquid::SyntaxError, "Syntax Error in 'author_link': Could not find author name in '#{@raw_markup}'"
        end

        @name_markup = scanner.matched

        # If nothing is found, it's a syntax error

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
          # Raise an error to break the build
          raise Liquid::SyntaxError,
                "Syntax Error in 'author_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end
      end
      return if @name_markup && !@name_markup.strip.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in 'author_link': Author name value is missing or empty in '#{@raw_markup}'"

      # --- End Argument Parsing ---
    end # End initialize

    # Renders the author link HTML by calling the utility function
    def render(context)
      # Resolve the potentially variable markup into actual strings
      author_name = TagArgumentUtils.resolve_value(@name_markup, context)
      link_text_override = @link_text_markup ? TagArgumentUtils.resolve_value(@link_text_markup, context) : nil

      # Call the centralized utility function from AuthorLinkUtils
      AuthorLinkUtils.render_author_link(
        author_name,
        context,
        link_text_override,
        @possessive_flag # Pass the possessive flag
      )
    end # End render
  end # End class AuthorLinkTag
end # End module Jekyll

# Register the tag with Liquid so Jekyll recognizes {% author_link ... %}
Liquid::Template.register_tag('author_link', Jekyll::AuthorLinkTag)
