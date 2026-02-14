# frozen_string_literal: true

# _plugins/author_link_tag.rb
require 'jekyll'
require 'liquid'
require 'cgi' # For HTML escaping
require 'strscan' # For flexible argument parsing

require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../author_link_util'
require_relative '../../markdown_output/markdown_link_formatter'

module Jekyll
  module Authors
    module Tags
      # Liquid tag for creating links to author pages.
      # Supports optional display text override and possessive suffix.
      # Usage: {% author_link "Name" [link_text="Display Text"] [possessive] %}
      #        {% author_link variable [link_text=var2] [possessive] %}
      #        {% author_link "Name" [possessive] [link_text="Display Text"] %}
      class AuthorLinkTag < Liquid::Tag
        # Keep QuotedFragment handy for parsing values
        QuotedFragment = Liquid::QuotedFragment
        # Aliases for readability
        TagArgs = Jekyll::Infrastructure::TagArgumentUtils
        Linker = Jekyll::Authors::AuthorLinkUtils
        MdLink = Jekyll::MarkdownOutput::MarkdownLinkFormatter
        private_constant :TagArgs, :Linker, :MdLink

        def initialize(tag_name, markup, tokens)
          super
          @tag_name = tag_name
          @raw_markup = markup # Store original for potential error messages
          @name_markup = nil
          @link_text_markup = nil
          @possessive_flag = false

          parse_arguments(markup)
        end

        # Renders the author link HTML (or Markdown in markdown mode)
        def render(context)
          # Resolve the potentially variable markup into actual strings
          author_name = TagArgs.resolve_value(@name_markup, context)
          link_text_override = (TagArgs.resolve_value(@link_text_markup, context) if @link_text_markup)

          if context.registers[:render_mode] == :markdown
            data = Linker.find_author_link_data(author_name, context, link_text_override, @possessive_flag)
            result = MdLink.format_link(data)
            data[:possessive] ? "#{result}'s" : result
          else
            Linker.render_author_link(author_name, context, link_text_override, @possessive_flag)
          end
        end

        private

        def parse_arguments(markup)
          scanner = StringScanner.new(markup.strip)

          parse_name(scanner)
          parse_options(scanner)
          validate_name
        end

        def parse_name(scanner)
          # 1. Extract the Name (first argument, must be quoted or a variable)
          unless scanner.scan(QuotedFragment) || scanner.scan(/\S+/)
            raise Liquid::SyntaxError, "Syntax Error in 'author_link': Could not find author name in '#{@raw_markup}'"
          end

          @name_markup = scanner.matched
        end

        def parse_options(scanner)
          # 2. Scan the rest of the string for optional arguments (link_text, possessive)
          until scanner.eos?
            scanner.skip(/\s+/) # Consume leading whitespace before the next argument
            break if scanner.eos? # Stop if only whitespace remained

            if scanner.scan(/link_text\s*=\s*(#{QuotedFragment})/)
              # scanner[1] contains the captured quoted fragment (the value)
              # Prevent overwriting if it appears multiple times (take the first one)
              @link_text_markup ||= scanner[1]
            elsif scanner.scan(/possessive(?!\S)/) # Ensure 'possessive' is a whole word
              @possessive_flag = true
            else
              handle_unknown_argument(scanner)
            end
          end
        end

        def handle_unknown_argument(scanner)
          # Found an unrecognized argument
          unknown_arg = scanner.scan(/\S+/) # Capture the unknown part
          # Raise an error to break the build
          raise Liquid::SyntaxError,
                "Syntax Error in 'author_link': Unknown argument '#{unknown_arg}' in '#{@raw_markup}'"
        end

        def validate_name
          return if @name_markup && !@name_markup.strip.empty?

          raise Liquid::SyntaxError,
                "Syntax Error in 'author_link': Author name value is missing or empty in '#{@raw_markup}'"
        end
      end
    end
  end
end

# Register the tag with Liquid so Jekyll recognizes {% author_link ... %}
Liquid::Template.register_tag('author_link', Jekyll::Authors::Tags::AuthorLinkTag)
