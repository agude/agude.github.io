# frozen_string_literal: true

# _plugins/book_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # Keep for QuotedFragment
require 'strscan'
require_relative '../core/book_link_util' # Require the specific book link util
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../markdown_output/markdown_link_formatter'

# Liquid Tag for creating a link to a book page, wrapped in <cite>.
# Handles optional display text override and author disambiguation.
# Arguments can be in flexible order after the title.
# Usage: {% book_link "Title" [link_text="Display Text"] [author="Author Name"] [cite=false] %}
module Jekyll
  #        {% book_link variable [link_text=var2] [author=var3] %}
  module Books
    module Tags
      # Liquid tag for creating a link to a book page.
      # Supports optional display text override, author disambiguation, and cite toggle.
      class BookLinkTag < Liquid::Tag
        # Keep QuotedFragment handy for parsing values
        QuotedFragment = Liquid::QuotedFragment
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Linker = Jekyll::Books::Core::BookLinkUtils
        MdLink = Jekyll::MarkdownOutput::MarkdownLinkFormatter
        private_constant :TagArgs, :Linker, :MdLink

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup # Store original for potential error messages
          @title_markup = nil
          @link_text_markup = nil
          @author_markup = nil
          @cite_markup = nil

          parse_markup(markup)
        end

        # Renders the book link HTML (or Markdown in markdown mode)
        def render(context)
          # Resolve the potentially variable markup into actual strings
          book_title = TagArgs.resolve_value(@title_markup, context)
          link_text_override = (TagArgs.resolve_value(@link_text_markup, context) if @link_text_markup)
          author_filter = (TagArgs.resolve_value(@author_markup, context) if @author_markup)
          cite_arg = cite_enabled?(context)

          if context.registers[:render_mode] == :markdown
            data = Linker.find_book_link_data(
              book_title, context, link_text_override, author_filter, nil, cite: cite_arg
            )
            MdLink.format_link(data)
          else
            Linker.render_book_link(book_title, context, link_text_override, author_filter, nil, cite: cite_arg)
          end
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
          unless scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
            raise Liquid::SyntaxError, "Syntax Error in 'book_link': Could not find book title in '#{@raw_markup}'"
          end

          @title_markup = scanner.matched
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
            elsif scanner.scan(/cite\s*=\s*(#{QuotedFragment})/)
              @cite_markup ||= scanner[1]
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

          raise Liquid::SyntaxError,
                "Syntax Error in 'book_link': Title value is missing or empty in '#{@raw_markup}'"
        end

        # Returns true unless cite= is explicitly set to 'false'
        def cite_enabled?(context)
          return true unless @cite_markup

          value = TagArgs.resolve_value(@cite_markup, context)
          value.to_s.downcase != 'false'
        end
      end
    end
  end
end

# Register the tag with Liquid so Jekyll recognizes {% book_link ... %}
Liquid::Template.register_tag('book_link', Jekyll::Books::Tags::BookLinkTag)
