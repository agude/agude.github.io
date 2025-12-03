# frozen_string_literal: true

# _plugins/display_authors_tag.rb
require 'jekyll'
require 'liquid'
require 'strscan'

require_relative '../display_authors_util'
require_relative '../../../infrastructure/tag_argument_utils'
require_relative '../../../infrastructure/plugin_logger_utils'

module Jekyll
  # Formats and displays a list of author names as a sentence.
  #
  # Supports optional linking to author pages and "et al." truncation.
  #
  # Usage in Liquid templates:
  #   {% display_authors page.book_authors %}
  #   {% display_authors page.book_authors linked=true %}
  #   {% display_authors page.book_authors etal_after=3 %}
  class DisplayAuthorsTag < Liquid::Tag
    SYNTAX_NAMED_ARG = /([\w-]+)\s*=\s*(#{Liquid::QuotedFragment}|\S+)/o
    ALLOWED_NAMED_KEYS = %w[linked etal_after].freeze

    def initialize(tag_name, markup, tokens)
      super
      @tag_name = tag_name
      @raw_markup = markup.strip
      @authors_list_markup = nil
      @options_markup = {}

      parse_markup
    end

    def render(context)
      authors_input = TagArgumentUtils.resolve_value(@authors_list_markup, context)
      linked_option = linked?(context)
      etal_option = resolve_etal_after_option(context)

      DisplayAuthorsUtil.render_author_list(
        author_input: authors_input,
        context: context,
        linked: linked_option,
        etal_after: etal_option
      )
    end

    private

    def parse_markup
      scanner = StringScanner.new(@raw_markup)
      scanner.skip(/\s*/)

      parse_authors_list(scanner)
      parse_named_arguments(scanner)
      validate_required_arguments
    end

    def parse_authors_list(scanner)
      # Peek at the first potential token to see if it's a named argument key
      is_key = scanner.match?(/(#{ALLOWED_NAMED_KEYS.join('|')})\s*=\s*/)

      return if is_key
      return unless scanner.scan(/(#{Liquid::QuotedFragment}|\S+)/)

      @authors_list_markup = scanner[1].strip
      scanner.skip(/\s*/)
    end

    def parse_named_arguments(scanner)
      until scanner.eos?
        scanner.skip(/\s*/)
        break if scanner.eos?

        parse_single_named_argument(scanner)
      end
    end

    def parse_single_named_argument(scanner)
      unless scanner.scan(SYNTAX_NAMED_ARG)
        raise Liquid::SyntaxError,
              "Syntax Error in '#{@tag_name}': Invalid argument syntax near '#{scanner.rest}'. " \
              "Expected key='value' or key=variable."
      end

      key = scanner[1].downcase
      value = scanner[2]

      validate_named_argument(key)
      @options_markup[key.to_sym] = value
    end

    def validate_named_argument(key)
      unless ALLOWED_NAMED_KEYS.include?(key)
        raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Unknown argument '#{key}' in '#{@raw_markup}'"
      end

      return unless @options_markup.key?(key.to_sym)

      raise Liquid::SyntaxError, "Syntax Error in '#{@tag_name}': Duplicate argument '#{key}' in '#{@raw_markup}'"
    end

    def validate_required_arguments
      return unless @authors_list_markup.nil? || @authors_list_markup.empty?

      raise Liquid::SyntaxError,
            "Syntax Error in '#{@tag_name}': Missing required authors list (e.g., page.book_authors) " \
            "as the first argument in '#{@raw_markup}'"
    end

    def linked?(context)
      return true unless @options_markup.key?(:linked)

      val = TagArgumentUtils.resolve_value(@options_markup[:linked], context)
      return true if val.nil?

      val_str = val.to_s.downcase
      !(val_str == 'false' || val == false)
    end

    def resolve_etal_after_option(context)
      return nil unless @options_markup.key?(:etal_after)

      val = TagArgumentUtils.resolve_value(@options_markup[:etal_after], context)
      return nil unless val

      Integer(val.to_s)
    rescue ArgumentError
      nil
    end
  end
end

Liquid::Template.register_tag('display_authors', Jekyll::DisplayAuthorsTag)
