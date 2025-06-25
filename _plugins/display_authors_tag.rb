# _plugins/display_authors_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'
require 'cgi'

require_relative 'utils/front_matter_utils'
require_relative 'utils/author_link_util'
require_relative 'utils/text_processing_utils'
require_relative 'utils/tag_argument_utils'
require_relative 'utils/plugin_logger_utils'

module Jekyll
  class DisplayAuthorsTag < Liquid::Tag
    SYNTAX_NAMED_ARG = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o
    ALLOWED_NAMED_KEYS = ['linked', 'etal_after'].freeze

    def initialize(tag_name, markup, tokens)
      super
      @raw_markup = markup.strip
      @authors_list_markup = nil
      @options_markup = {}

      scanner = StringScanner.new(@raw_markup)
      scanner.skip(/\s*/)

      # Attempt to parse the first part as the authors_list_markup
      # It's a variable name or a quoted string that doesn't look like a key=value pair.
      # Regex captures: 1=QuotedFragment, 2=UnquotedWordNotFollowedByEquals
      # This needs to be careful not to consume a key if it's the first thing.

      # More robust: scan for the first token. If it's not a recognized named arg key
      # followed by an equals, then it's the authors_list_markup.

      # Peek at the first potential token to see if it's a named argument key
      is_first_token_a_key = false
      if scanner.match?(/(#{ALLOWED_NAMED_KEYS.join('|')})\s*=\s*/)
          is_first_token_a_key = true
      end

      if !is_first_token_a_key && scanner.scan(/(#{Liquid::QuotedFragment}|\S+)/)
          # If the first token is not a key for a named argument, it's the authors_list_markup
          @authors_list_markup = scanner[1].strip
        scanner.skip(/\s*/) # Consume space after it
      end

      # Now parse named arguments from the rest of the string
      while !scanner.eos?
        scanner.skip(/\s*/) # Skip whitespace before arg
        break if scanner.eos? # Break if only whitespace remained

        unless scanner.scan(SYNTAX_NAMED_ARG)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Invalid argument syntax near '#{scanner.rest}'. Expected key='value' or key=variable."
        end
        key = scanner[1].downcase
        value_markup = scanner[2]

        unless ALLOWED_NAMED_KEYS.include?(key)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Unknown argument '#{key}' in '#{@raw_markup}'"
        end
        if @options_markup.key?(key.to_sym)
          raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Duplicate argument '#{key}' in '#{@raw_markup}'"
        end

        @options_markup[key.to_sym] = value_markup # Store as :linked_markup
      end

      # Final check for the required authors_list_markup
      if @authors_list_markup.nil? || @authors_list_markup.empty?
        raise Liquid::SyntaxError, "Syntax Error in '#{tag_name}': Missing required authors list (e.g., page.book_authors) as the first argument in '#{@raw_markup}'"
      end
    end

    def render(context)
      authors_input = TagArgumentUtils.resolve_value(@authors_list_markup, context)
      author_names = FrontMatterUtils.get_list_from_string_or_array(authors_input)

      return "" if author_names.empty?

      actual_linked = true
      if @options_markup.key?(:linked)
        resolved_linked_val = TagArgumentUtils.resolve_value(@options_markup[:linked], context)
        if resolved_linked_val != nil
          val_str = resolved_linked_val.to_s.downcase
          if val_str == 'false' || resolved_linked_val == false
            actual_linked = false
          end
        end
      end

      # If 'etal_after' is not provided in the tag, resolved_etal_after will be nil.
      resolved_etal_after = nil
      if @options_markup.key?(:etal_after)
        resolved_etal_val = TagArgumentUtils.resolve_value(@options_markup[:etal_after], context)
        begin
          resolved_etal_after = Integer(resolved_etal_val.to_s) if resolved_etal_val
        rescue ArgumentError
          resolved_etal_after = nil
        end
      end

      processed_authors = author_names.map do |name|
        if actual_linked
          AuthorLinkUtils.render_author_link(name, context)
        else
          "<span class=\"author-name\">#{CGI.escapeHTML(name)}</span>"
        end
      end

      # Pass the value (either the number or nil) to the utility.
      TextProcessingUtils.format_list_as_sentence(processed_authors, etal_after: resolved_etal_after)
    end
  end
end

Liquid::Template.register_tag('display_authors', Jekyll::DisplayAuthorsTag)
