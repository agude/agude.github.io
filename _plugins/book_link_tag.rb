# frozen_string_literal: true

# _plugins/book_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # Keep for QuotedFragment
require 'strscan'
require_relative 'utils/book_link_util' # Require the specific book link util
require_relative 'utils/tag_argument_utils'

module Jekyll
  # Liquid Tag for creating a link to a book page, wrapped in <cite>.
  # Handles optional display text override and author disambiguation.
  # Arguments can be in flexible order after the title.
  # Usage: {% book_link "Title" [link_text="Display Text"] [author="Author Name"] %}
  #        {% book_link variable [link_text=var2] [author=var3] %}
  class BookLinkTag < Liquid::Tag
    # Keep QuotedFragment handy for parsing values
    QuotedFragment = Liquid::QuotedFragment

    def initialize(tag_name, markup, tokens)
      super
      @tag_name = tag_name
      @raw_markup = markup # Store original for potential error messages
      @title_markup = nil
      @link_text_markup = nil
      @author_markup = nil

      parse_markup(markup)
    end

    # Renders the book link HTML by calling the utility function
    def render(context)
      # Resolve the potentially variable markup into actual strings
      book_title = TagArgumentUtils.resolve_value(@title_markup, context)
      link_text_override = @link_text_markup ? TagArgumentUtils.resolve_value(@link_text_markup, context) : nil
      author_filter = @author_markup ? TagArgumentUtils.resolve_value(@author_markup, context) : nil

      # Call the centralized utility function from BookLinkUtils with the new author argument
      BookLinkUtils.render_book_link(book_title, context, link_text_override, author_filter)
    end

    private

    def parse_markup(markup)
      scanner = StringScanner.new(markup.strip)
      parse_title(scanner)
      parse_options(scanner)
      validate_title
    end

    def parse_title(scanner)
      # 1. Extract the Title (first argument, must be quoted or a variable)
      if scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
        @title_markup = scanner.matched
      else
        raise Liquid::SyntaxError, "Syntax Error in 'book_link': Could not find book title in '#{@raw_markup}'"
      end
    end

    def parse_options(scanner)
      # 2. Scan the rest of the string for optional arguments (link_text, author)
      until scanner.eos?
        scanner.skip(/\s+/) # Consume leading whitespace
        break if scanner.eos?

        if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
            @link_text_markup ||= scanner[1] # Take the first one found
        elsif scanner.scan(/author\s*=\s*(#{QuotedFragment})/)
          @author_markup ||= scanner[1] # Take the first one found
        else
          handle_unknown_argument(scanner)
        end
      end
    end

    def handle_unknown_argument(scanner)
      unknown_arg = scanner.scan(/\S+/)
      raise Liquid::SyntaxError,
        "Syntax Error in 'book_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
    end

    def validate_title
      return if @title_markup && !@title_markup.strip.empty?

      raise Liquid::SyntaxError, "Syntax Error in 'book_link': Title value is missing or empty in '#{@raw_markup}'"
    end
  end
end

# Register the tag with Liquid so Jekyll recognizes {% book_link ... %}
Liquid::Template.register_tag('book_link', Jekyll::BookLinkTag)
